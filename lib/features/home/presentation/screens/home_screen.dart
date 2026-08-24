import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../core/presentation/widgets/design/story_circle.dart';
import '../../../../core/presentation/widgets/design/discovery_cover.dart';
import '../../../../core/presentation/widgets/design/banner_bar.dart';
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

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).logScreenView('home_screen');
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
      // 상세를 보고 돌아오면 lastViewed가 갱신됐으므로 스토리 링 재계산.
      ref.invalidate(homeStoriesProvider);
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
        ref.watch(publicMemoFeedProvider).asData?.value ?? const <Memo>[];
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
    final memos = ref.watch(publicMemoFeedProvider).asData?.value ?? const <Memo>[];
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
        emoji: '📖',
        title: '오늘은 어떤 책을 읽을까',
        subtitle: '내 서재에서 골라보세요',
        accent: true,
        onTap: () {
          ref.read(analyticsProvider).logEvent('click_read_prompt_in_home');
          _openBooksTab();
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
      // 타이틀 없는 화면 = 상태바 아래에서 콘텐츠 시작(SafeArea). 얇은 유리 스트립은
      // 실기기에서 아티팩트(비침/밴딩/띠) 반복 -> 제거. 깔끔·안정 우선.
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.accentGreen,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            ref.invalidate(homeBooksProvider);
            ref.invalidate(booksSavedByOthersProvider);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 210),
            children: [
              _header(),
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
              const SizedBox(height: 34),
              _rankingCard(),
              _recordStrip(),
            ],
          ),
        ),
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
