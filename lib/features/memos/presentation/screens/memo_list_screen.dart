import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/presentation/widgets/design/segment_filter.dart';
import '../../../../core/presentation/widgets/design/glass_app_bar.dart';
import '../../../../core/presentation/widgets/design/memo_card.dart';
import '../../domain/models/memo.dart';
import '../providers/memo_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// 메모 탭 = 피드. 내 메모 / 공개(타 유저 포함) 세그먼트 + 쓰기 진입.
/// 컴포넌트(SegmentFilter · ComposePrompt · MemoCard)를 조합.
class MemoListScreen extends ConsumerStatefulWidget {
  const MemoListScreen({super.key});

  @override
  ConsumerState<MemoListScreen> createState() => _MemoListScreenState();
}

class _MemoListScreenState extends ConsumerState<MemoListScreen> {
  int _segment = 0; // 0 = 내 메모, 1 = 공개
  final _scroll = ScrollController();
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).logScreenView('memo_tab');
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// 바닥 근처에서 다음 페이지 로드(무한 스크롤). 동시 호출 방지.
  Future<void> _onScroll() async {
    if (_loadingMore || !_scroll.hasClients) return;
    if (_scroll.position.pixels < _scroll.position.maxScrollExtent - 320) {
      return;
    }
    final bool more = _segment == 0
        ? ref.read(paginatedMemosProvider(null).notifier).hasMore
        : ref.read(paginatedPublicFeedProvider.notifier).hasMore;
    if (!more) return;
    _loadingMore = true;
    if (_segment == 0) {
      await ref.read(paginatedMemosProvider(null).notifier).loadMoreMemos();
    } else {
      await ref.read(paginatedPublicFeedProvider.notifier).loadMore();
    }
    _loadingMore = false;
  }

  void _openDetail(Memo memo) => context.pushNamed(
        AppRoutes.memoDetailName,
        pathParameters: {'id': memo.id},
        extra: memo, // 즉시 렌더용(엣지펑션 대기 없이)
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      // 본문이 글래스 앱바 뒤로 확장돼 블러됨(넓어 보임)
      extendBodyBehindAppBar: true,
      appBar: glassAppBar(
        title: const Text('Memos', style: AppTypography.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.hub_outlined,
                size: 20, color: AppColors.textSecondary),
            tooltip: l10n.memoConstellationTooltip,
            onPressed: () => context.pushNamed(AppRoutes.constellationName),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined,
                size: 20, color: AppColors.textSecondary),
            onPressed: () => context.pushNamed(
              AppRoutes.calendarName,
              queryParameters: {'segment': '0'},
            ),
          ),
        ],
        // 세그먼트를 앱바 하단 스티키로(표준 filterBar - 책탭과 동일 높이/여백)
        bottom: filterBar(
          SegmentFilter(
            segments: [l10n.memoSegmentMine, l10n.memoVisibilityPublic],
            selectedIndex: _segment,
            onChanged: (i) => setState(() => _segment = i),
          ),
        ),
      ),
      body: _feed(
          topPadding: glassTopPadding(context, bottomHeight: kFilterBarHeight)),
    );
  }

  Widget _feed({double topPadding = 0}) {
    // 두 세그먼트 모두 페이지네이션(무한 스크롤). 둘 다 미리 구독 -> 전환 즉시.
    final mine = ref.watch(paginatedMemosProvider(null));
    final public = ref.watch(paginatedPublicFeedProvider);
    final async = _segment == 0 ? mine : public;
    final hasMore = _segment == 0
        ? ref.read(paginatedMemosProvider(null).notifier).hasMore
        : ref.read(paginatedPublicFeedProvider.notifier).hasMore;
    return async.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => const Center(
        child: CircularProgressIndicator(
            color: AppColors.textSecondary, strokeWidth: 2),
      ),
      error: (_, __) => _message(AppL10n.of(context).memoFeedLoadFailed),
      data: (memos) {
        if (memos.isEmpty) {
          return _message(_segment == 0
              ? AppL10n.of(context).memoEmptyMine
              : AppL10n.of(context).memoEmptyPublic);
        }
        return RefreshIndicator(
          color: AppColors.accentGreen,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            if (_segment == 0) {
              await ref
                  .read(paginatedMemosProvider(null).notifier)
                  .loadInitialMemos();
            } else {
              await ref
                  .read(paginatedPublicFeedProvider.notifier)
                  .loadInitial();
            }
          },
          child: ListView.separated(
            controller: _scroll,
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, topPadding, AppSpacing.lg, 110),
            itemCount: memos.length + (hasMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              if (i >= memos.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.textSecondary),
                    ),
                  ),
                );
              }
              return _card(memos[i]);
            },
          ),
        );
      },
    );
  }

  Widget _card(Memo memo) {
    final l10n = AppL10n.of(context);
    final edited = memo.isEdited;
    final date = edited ? memo.updatedAt! : memo.createdAt;
    return MemoCard(
      content: memo.content,
      authorName: memo.userNickname ?? l10n.memoAuthorFallback,
      authorImageUrl: memo.userAvatarUrl,
      dateText: _relativeDate(l10n, date),
      edited: edited,
      showMineTag: _segment == 1 && memo.userId == Supabase.instance.client.auth.currentUser?.id,
      bookTitle: memo.bookTitle,
      page: memo.page,
      imageUrl: memo.imageUrl,
      commentCount: memo.commentCount,
      lyraQuestion: memo.lyraQuestion,
      onTap: () => _openDetail(memo),
    );
  }

  Widget _message(String text) {
    return Center(
      child: Text(text,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
    );
  }

  static String _relativeDate(AppL10n l, DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return l.memoTimeJustNow;
    if (diff.inMinutes < 60) return l.memoTimeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l.memoTimeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l.memoTimeDaysAgo(diff.inDays);
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}.$m.$d';
  }
}
