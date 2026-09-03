import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/presentation/widgets/language_sheet.dart';
import '../../../../core/presentation/widgets/design/dismissible_pill.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../core/presentation/widgets/design/story_circle.dart';
import '../../../../core/presentation/widgets/design/glass_app_bar.dart';
import '../../../../core/presentation/widgets/design/discovery_cover.dart';
import '../../../../core/presentation/widgets/design/banner_bar.dart';
import '../../../orb/domain/orb_tier.dart';
import '../../../orb/presentation/widgets/orb_gate_banner.dart';
import '../../../profile/presentation/providers/profile_stats_provider.dart';
import '../../../../core/presentation/widgets/design/memo_card.dart';
import '../../../../core/presentation/widgets/design/app_dialog.dart';
import '../../domain/models/book.dart';
import '../providers/book_provider.dart';
import '../../../books/presentation/providers/user_books_provider.dart';
import '../../../discovery/presentation/providers/discovery_providers.dart';
import '../../../lyra/presentation/providers/lyra_providers.dart';
import '../../../lyra/presentation/widgets/lyra_question_card.dart';
import '../../../lyra/data/models/lyra_prompt.dart';
import '../../../ranking/presentation/providers/ranking_providers.dart';
import '../../../ranking/presentation/widgets/ranking_card.dart';
import '../../../wrapped/presentation/providers/wrapped_providers.dart';
import '../../../memos/domain/models/memo.dart';
import '../../../memos/presentation/providers/memo_provider.dart';
import '../../../calendar/domain/calendar_logic.dart';

/// 홈 = 발견 피드. 좋아하는 책 스토리 + 지금 읽는 책 Lyra 물음 + 다른 사람이 담은 책.
/// (내 서재/책 캐러셀은 '책' 탭으로 이동. N2 '이번 주 함께 읽는 책'은 데이터 준비 후.)
class HomeScreen extends ConsumerStatefulWidget {
  final bool autoBookSearch;

  const HomeScreen({super.key, this.autoBookSearch = false});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _lyraShownLogged = false;

  // 첫 진입 1회만 뜨는 언어 전환 알약. X 또는 언어 선택 시 다시 안 뜸.
  static const _kLangPillSeen = 'home_lang_pill_seen';
  bool _showLangPill = false;

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).logScreenView('home_screen');
    _maybeShowLangPill();
    if (widget.autoBookSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pushNamed(
            AppRoutes.bookSearchName,
            queryParameters: {'isFromOnboarding': 'true'},
          );
        }
      });
    }
  }

  Future<void> _maybeShowLangPill() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    if (!(p.getBool(_kLangPillSeen) ?? false)) {
      setState(() => _showLangPill = true);
    }
  }

  Future<void> _dismissLangPill() async {
    if (_showLangPill) setState(() => _showLangPill = false);
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kLangPillSeen, true);
  }

  Widget _langPill() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: DismissiblePill(
          icon: Icons.language_outlined,
          label: AppL10n.of(context).settingsLanguage,
          onTap: () async {
            await showLanguageSheet(context, ref);
            await _dismissLangPill();
          },
          onClose: _dismissLangPill,
        ),
      ),
    );
  }

  /// 책 탭. 저장 안 한 책(발견/최근 메모)이면 담기 팝업 → 담고 이동.
  /// (저장 안 한 책을 바로 상세로 보내면 user_books 0행 -> PGRST116 에러 페이지)
  Future<void> _openBook(String bookId) async {
    final repo = ref.read(bookRepositoryProvider);
    final userId = repo.getCurrentUserId();
    bool owned = false;
    try {
      owned = await repo.hasUserBookConnection(bookId, userId);
    } catch (_) {}
    if (!mounted) return;
    if (owned) {
      await context.pushNamed(AppRoutes.bookDetailName,
          pathParameters: {'id': bookId});
      // 상세를 보면 book_detail이 markBookViewed로 bookViewed 리비전을 올리므로
      // 스토리 링은 반응형으로 자동 재계산된다(수동 invalidate 불필요).
      return;
    }
    final save = await showAppConfirm(
      context,
      title: '책 담기',
      message: '이 책을 서재에 담을까',
      confirmText: '담기',
    );
    if (!save || !mounted) return;
    try {
      await repo.createUserBookConnection(bookId, userId);
      ref.read(analyticsProvider)
          .logEvent('click_save_book_in_home', {'book_id': bookId});
      ref.invalidate(homeBooksProvider);
      ref.invalidate(userBooksProvider);
      ref.invalidate(booksSavedByOthersProvider);
      if (mounted) {
        context.pushNamed(AppRoutes.bookDetailName,
            pathParameters: {'id': bookId});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceMuted,
            content: Text('책을 담는 중 문제가 생겼어요',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textPrimary)),
          ),
        );
      }
    }
  }

  void _openSearch() => context.pushNamed(AppRoutes.bookSearchName);

  /// Lyra 물음에 답하기. 책 물음이면 그 책으로, 일반 물음이면 책 선택 화면으로.
  /// 답하고 돌아오면 다음 물음으로 갱신.
  Future<void> _answerPrompt(LyraPrompt p) async {
    ref.read(analyticsProvider)
        .logEvent('click_answer_lyra_in_home', {'source': p.source});
    await context.pushNamed(
      AppRoutes.memoCreateName,
      queryParameters: {
        'lyraQuestion': p.question,
        'lyraSource': p.source,
        if (p.questionId != null) 'lyraQuestionId': p.questionId!,
        if (p.isBook && p.bookId != null) 'bookId': p.bookId!,
      },
    );
    ref.invalidate(lyraPromptProvider);
  }

  void _openBooksTab() => context.goNamed(AppRoutes.booksName);
  void _openCalendar() => context.pushNamed(AppRoutes.calendarName);

  /// 최근 공개 메모를 카드로(Threads식). 탭 -> 메모 상세. 긴 본문은 4줄로 자름.
  Widget _recentMemos() {
    final memos =
        ref.watch(homePublicMemoFeedProvider).asData?.value ?? const <Memo>[];
    final items = memos.take(5).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('다른 별들이 남긴 생각들', style: AppTypography.title),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              for (final m in items) ...[
                MemoCard(
                  content: m.content,
                  authorName: m.userNickname ?? '밀키웨이',
                  authorImageUrl: m.userAvatarUrl,
                  dateText: _rel(m.createdAt),
                  bookTitle: m.bookTitle,
                  page: m.page,
                  maxLines: 4,
                  imageUrl: m.imageUrl,
                  commentCount: m.commentCount,
                  lyraQuestion: m.lyraQuestion,
                  onTap: () => context.pushNamed(AppRoutes.memoDetailName,
                      pathParameters: {'id': m.id}, extra: m),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 최근 공개 메모가 올라온 책(피드에서 책 단위로 중복 제거).
  Widget _recentMemoBooks() {
    final memos = ref.watch(homePublicMemoFeedProvider).asData?.value ?? const <Memo>[];
    final seen = <String>{};
    final books = <Memo>[];
    for (final m in memos) {
      if (seen.add(m.bookId)) books.add(m);
      if (books.length >= 10) break;
    }
    if (books.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('최근 메모가 올라온 책', style: AppTypography.title),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 192,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final m = books[i];
              return DiscoveryCover(
                title: m.bookTitle,
                author: (m.books['author'] as String?) ?? '',
                coverUrl: m.books['cover_url'] as String?,
                meta: '${_rel(m.createdAt)} 메모',
                onTap: () => _openBook(m.bookId),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _readPrompt() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: BannerBar(
        icon: Icons.menu_book_outlined,
        tint: const Color(0xFF7E9CE0),
        title: '오늘은 어떤 책을 읽을까',
        subtitle: '내 서재에서 골라보세요',
        onTap: () {
          ref.read(analyticsProvider).logEvent('click_read_prompt_in_home');
          _openBooksTab();
        },
      ),
    );
  }

  /// 오브 섹션: 메모 7개 미만이면 생성 유도 배너, 이상이면 내 우주 진입.
  /// 로딩/실패 시 조용히 숨김(에러는 모니터링됨).
  Widget _orbSection() {
    final memos = ref.watch(profileStatsProvider).asData?.value.memos;
    if (memos == null) return const SizedBox.shrink();
    if (memos < orbGateMemos) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: OrbGateBanner(
          memos: memos,
          onTap: () {
            ref.read(analyticsProvider).logEvent('orb_banner_tap', {'memos': memos});
            showOrbGateSheet(
              context,
              memos: memos,
              onWrite: () => context.pushNamed(AppRoutes.memoCreateName),
            );
          },
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: BannerBar(
        icon: Icons.auto_awesome,
        tint: const Color(0xFF8A7CFF),
        title: '내 우주가 자라고 있어요',
        subtitle: '내 은하수를 확인하고 공유해요',
        onTap: () {
          ref.read(analyticsProvider).logEvent('orb_entry_tap');
          context.pushNamed(AppRoutes.myOrbName);
        },
      ),
    );
  }

  /// 은하 회고 진입: 이번 달(또는 최근 활동 달) 메모가 있으면 노출. 없으면 조용히 숨김.
  Widget _wrappedSection() {
    final w = ref.watch(wrappedProvider).asData?.value;
    if (w == null || !w.hasEnough) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: BannerBar(
        icon: Icons.calendar_month_outlined,
        tint: const Color(0xFFC48CFF),
        title: '${w.monthLabel} 은하 회고',
        subtitle: '그 자리에 남은 ${w.memoCount}개의 별을 모았어요',
        onTap: () {
          ref.read(analyticsProvider).logEvent('wrapped_entry_tap', {'period': w.periodLabel});
          context.pushNamed(AppRoutes.wrappedName);
        },
      ),
    );
  }

  /// 별자리(사유의 커넥톰) 진입: 메모가 어느 정도 쌓여 연결이 생길 때 노출.
  /// 메모탭 앱바에도 진입점이 있지만 홈에서도 바로 들어가게.
  Widget _constellationSection() {
    final memos = ref.watch(profileStatsProvider).asData?.value.memos;
    if (memos == null || memos < 3) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: BannerBar(
        icon: Icons.hub_outlined,
        tint: const Color(0xFF6FD0C4),
        title: '내 생각들이 이어지고 있어요',
        subtitle: '메모 사이에 생긴 별자리를 살펴봐요',
        onTap: () {
          ref.read(analyticsProvider).logEvent('constellation_entry_tap');
          context.pushNamed(AppRoutes.constellationName);
        },
      ),
    );
  }

  /// 홈 하단 기록 = 이번 주 스트립. 메모 있는 날에 점, 탭하면 캘린더로.
  /// 이번 주 나의 기록(익명 백분위 + 성장). 로딩/실패 시 조용히 숨김(에러는 모니터링됨).
  Widget _rankingCard() {
    final async = ref.watch(myRankingProvider);
    return async.maybeWhen(
      data: (stats) => Padding(
        padding: const EdgeInsets.only(bottom: 34),
        child: RankingCard(stats: stats),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _recordStrip() {
    final memos = ref.watch(allMemosProvider).asData?.value ?? const <Memo>[];
    final counts = countByDay<Memo>(memos, (m) => m.createdAt);
    final today = dayKey(DateTime.now());
    // 월요일 시작 (weekday: Mon=1..Sun=7 -> 월요일까지 뒤로)
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return GestureDetector(
      onTap: _openCalendar,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text('내 기록', style: AppTypography.title),
                const Spacer(),
                Text('전체 보기',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary)),
                const Icon(Icons.chevron_right,
                    size: 16, color: AppColors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: _dayCell(
                      labels[i],
                      DateTime(weekStart.year, weekStart.month,
                          weekStart.day + i),
                      today,
                      counts,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayCell(
      String label, DateTime day, DateTime today, Map<DateTime, int> counts) {
    final isToday = dayKey(day) == today;
    final has = (counts[dayKey(day)] ?? 0) > 0;
    return Column(
      children: [
        Text(label,
            style: AppTypography.caption.copyWith(
                color: label == '일'
                    ? const Color(0xFFA05252)
                    : AppColors.textTertiary,
                fontSize: 11)),
        const SizedBox(height: 8),
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isToday ? Colors.white : null,
          ),
          child: Text('${day.day}',
              style: AppTypography.caption.copyWith(
                fontSize: 13,
                color: isToday ? Colors.black : AppColors.textPrimary,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              )),
        ),
        const SizedBox(height: 5),
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: has ? AppColors.accentGreen : Colors.transparent,
          ),
        ),
      ],
    );
  }

  static String _rel(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return '방금';
    if (d.inMinutes < 60) return '${d.inMinutes}분 전';
    if (d.inHours < 24) return '${d.inHours}시간 전';
    if (d.inDays < 7) return '${d.inDays}일 전';
    return '${dt.month}.${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(homeBooksProvider);
    final books = booksAsync.asData?.value ?? const <Book>[];

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      // 타이틀 없는 화면(CASE C): 상태바 영역만 순수 블러(StatusBarBlur). 콘텐츠는 상태바
      // 아래에서 시작하고, 상태바 뒤로 스크롤될 때만 노치 영역에서 흐려진다.
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.accentGreen,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              ref.invalidate(homeBooksProvider);
              ref.invalidate(booksSavedByOthersProvider);
            },
            child: ListView(
              padding: EdgeInsets.only(top: statusBarTop(context), bottom: 210),
              children: [
              _header(),
              if (_showLangPill) _langPill(),
              const SizedBox(height: 6),
              _stories(),
              if (books.isEmpty) _emptyWelcome(),
              _lyraHighlight(books),
              const SizedBox(height: 34),
              _discoverySection(books),
              const SizedBox(height: 34),
              _recentMemos(),
              const SizedBox(height: 34),
              _recentMemoBooks(),
              const SizedBox(height: 28),
              _readPrompt(),
              const SizedBox(height: 14),
              _orbSection(),
              const SizedBox(height: 14),
              _wrappedSection(),
              const SizedBox(height: 14),
              _constellationSection(),
              const SizedBox(height: 34),
              _rankingCard(),
              _recordStrip(),
            ],
          ),
        ),
          const Positioned(
              top: 0, left: 0, right: 0, child: StatusBarBlur()),
        ],
      ),
    );
  }

  Widget _header() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Text(
        'milkyway',
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 21,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: Colors.white,
        ),
      ),
    );
  }

  /// 담은 책이 없을 때(콜드 스타트) 환영 + 담기 유도.
  Widget _emptyWelcome() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('마음이 가는 책 한 권부터', style: AppTypography.heading),
          const SizedBox(height: 8),
          Text('담으면 Lyra가 물음을 건네요\n아래 사람들이 담은 책도 둘러보세요',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _openSearch,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search, size: 16, color: AppColors.accentGreen),
                const SizedBox(width: 6),
                Text('책 담으러 가기',
                    style: AppTypography.bodySmall.copyWith(
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stories() {
    final stories =
        ref.watch(homeStoriesProvider).asData?.value ?? const <HomeStory>[];
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          StoryCircle(
            label: '담기',
            ring: StoryRing.add,
            onTap: _openSearch,
          ),
          for (final s in stories) ...[
            const SizedBox(width: 14),
            StoryCircle(
              label: s.book.title,
              coverUrl: s.book.coverUrl,
              ring: s.ring,
              onTap: () => _openBook(s.book.id),
            ),
          ],
        ],
      ),
    );
  }

  /// 내가 아직 답 안 한 다음 Lyra 물음(책 물음 우선, 없으면 일반). 없으면 섹션 숨김.
  /// 답하면 다음 물음으로 넘어간다.
  Widget _lyraHighlight(List<Book> books) {
    final promptAsync = ref.watch(lyraPromptProvider);
    return promptAsync.maybeWhen(
      data: (p) {
        if (p == null) return const SizedBox.shrink();
        // 책 물음이면 홈 책들에서 표지 찾기(있으면 카드에 미니 표지 노출)
        String? cover;
        if (p.isBook && p.bookId != null) {
          final match = books.where((b) => b.id == p.bookId);
          if (match.isNotEmpty) cover = match.first.coverUrl;
        }
        if (!_lyraShownLogged) {
          _lyraShownLogged = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(analyticsProvider).logEvent(
                'view_lyra_question_in_home', {'source': p.source});
          });
        }
        return Padding(
          padding: const EdgeInsets.only(top: 22),
          child: LyraQuestionCard(
            question: p.question,
            bookTitle: p.bookTitle,
            bookCoverUrl: cover,
            bookStatusLabel: p.isBook ? '읽는 중' : null,
            onAnswer: () => _answerPrompt(p),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _discoverySection(List<Book> myBooks) {
    final async = ref.watch(booksSavedByOthersProvider);
    return async.maybeWhen(
      data: (all) {
        final myIds = myBooks.map((b) => b.id).toSet();
        final books = all.where((b) => !myIds.contains(b.id)).toList();
        if (books.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('다른 사람이 담은 책', style: AppTypography.title),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 192,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: books.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => DiscoveryCover(
                  title: books[i].title,
                  author: books[i].author,
                  coverUrl: books[i].coverUrl,
                  meta: books[i].proofLabel,
                  onTap: () => _openBook(books[i].id),
                ),
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
