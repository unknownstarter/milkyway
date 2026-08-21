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
import '../../domain/models/book.dart';
import '../../domain/models/book_status.dart';
import '../providers/book_provider.dart';
import '../../../books/presentation/providers/user_books_provider.dart';
import '../../../discovery/presentation/providers/discovery_providers.dart';
import '../../../lyra/presentation/providers/lyra_providers.dart';
import '../../../lyra/presentation/widgets/lyra_question_card.dart';
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
      context.pushNamed(AppRoutes.bookDetailName, pathParameters: {'id': bookId});
      return;
    }
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceMuted,
        title: Text('책 담기',
            style: AppTypography.subtitle.copyWith(color: Colors.white)),
        content: Text('이 책을 서재에 담을까요',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('취소',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('담기',
                style: AppTypography.bodySmall.copyWith(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (save != true || !mounted) return;
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

  void _answer(String bookId, String question) => context.pushNamed(
        AppRoutes.memoCreateName,
        queryParameters: {'bookId': bookId, 'lyraQuestion': question},
      );

  void _openBooksTab() => context.goNamed(AppRoutes.booksName);
  void _openCalendar() => context.pushNamed(AppRoutes.calendarName);

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
  Widget _recordStrip() {
    final memos = ref.watch(allMemosProvider).asData?.value ?? const <Memo>[];
    final counts = countByDay<Memo>(memos, (m) => m.createdAt);
    final today = dayKey(DateTime.now());
    final weekStart = today.subtract(Duration(days: today.weekday % 7));
    const labels = ['일', '월', '화', '수', '목', '금', '토'];
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
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accentGreen,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            ref.invalidate(homeBooksProvider);
            ref.invalidate(booksSavedByOthersProvider);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              _header(),
              const SizedBox(height: 6),
              _stories(books),
              if (books.isEmpty) _emptyWelcome(),
              _lyraHighlight(books),
              const SizedBox(height: 34),
              _discoverySection(books),
              const SizedBox(height: 34),
              _recentMemoBooks(),
              const SizedBox(height: 28),
              _readPrompt(),
              const SizedBox(height: 34),
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

  Widget _stories(List<Book> books) {
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
          for (final b in books) ...[
            const SizedBox(width: 14),
            StoryCircle(
              label: b.title,
              coverUrl: b.coverUrl,
              ring: b.status == BookStatus.reading
                  ? StoryRing.active
                  : StoryRing.seen,
              onTap: () => _openBook(b.id),
            ),
          ],
        ],
      ),
    );
  }

  /// 지금 읽는 책(없으면 첫 책)의 Lyra 물음. 물음 없으면 섹션 숨김.
  Widget _lyraHighlight(List<Book> books) {
    if (books.isEmpty) return const SizedBox.shrink();
    final reading = books.firstWhere(
      (b) => b.status == BookStatus.reading,
      orElse: () => books.first,
    );
    final questionAsync = ref.watch(bookQuestionProvider(reading.id));
    return questionAsync.maybeWhen(
      data: (q) {
        if (q == null) return const SizedBox.shrink();
        if (!_lyraShownLogged) {
          _lyraShownLogged = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(analyticsProvider).logEvent(
                'view_lyra_question_in_home', {'book_id': reading.id});
          });
        }
        return Padding(
          padding: const EdgeInsets.only(top: 22),
          child: LyraQuestionCard(
            question: q.question,
            bookTitle: reading.title,
            bookCoverUrl: reading.coverUrl,
            bookStatusLabel: reading.status.value,
            onAnswer: () => _answer(reading.id, q.question),
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
