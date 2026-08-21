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
import '../../../../core/presentation/widgets/design/compose_prompt.dart';
import '../../../../core/presentation/widgets/design/memo_card.dart';
import '../../domain/models/memo.dart';
import '../providers/memo_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// 메모 탭 = 피드. 내 메모 / 공개(타 유저 포함) 세그먼트 + 쓰기 진입.
/// 컴포넌트(SegmentFilter · ComposePrompt · MemoCard)를 조합.
class MemoListScreen extends ConsumerStatefulWidget {
  const MemoListScreen({super.key});

  @override
  ConsumerState<MemoListScreen> createState() => _MemoListScreenState();
}

class _MemoListScreenState extends ConsumerState<MemoListScreen> {
  int _segment = 0; // 0 = 내 메모, 1 = 공개

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).logScreenView('memo_tab');
  }

  void _openCompose() => context.pushNamed(AppRoutes.memoCreateName);

  void _openDetail(String memoId) => context.pushNamed(
        AppRoutes.memoDetailName,
        pathParameters: {'id': memoId},
      );

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authProvider).value;
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Memos', style: AppTypography.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined,
                size: 20, color: AppColors.textSecondary),
            onPressed: () => context.pushNamed(
              AppRoutes.calendarName,
              queryParameters: {'segment': '0'},
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.base),
            child: Column(
              children: [
                ComposePrompt(
                  avatarUrl: me?.pictureUrl,
                  initial: me?.nickname ?? '나',
                  onTap: _openCompose,
                ),
                const SizedBox(height: AppSpacing.base),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SegmentFilter(
                    segments: const ['내 메모', '공개'],
                    selectedIndex: _segment,
                    onChanged: (i) => setState(() => _segment = i),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _feed()),
        ],
      ),
    );
  }

  Widget _feed() {
    final async =
        _segment == 0 ? ref.watch(allMemosProvider) : ref.watch(publicMemoFeedProvider);
    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
            color: AppColors.textSecondary, strokeWidth: 2),
      ),
      error: (_, __) => _message('피드를 불러오지 못했어요'),
      data: (memos) {
        if (memos.isEmpty) {
          return _message(
              _segment == 0 ? '아직 남긴 메모가 없어요' : '아직 공개된 메모가 없어요');
        }
        return RefreshIndicator(
          color: AppColors.accentGreen,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            ref.invalidate(_segment == 0 ? allMemosProvider : publicMemoFeedProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 110),
            itemCount: memos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _card(memos[i]),
          ),
        );
      },
    );
  }

  Widget _card(Memo memo) {
    final edited = memo.isEdited;
    final date = edited ? memo.updatedAt! : memo.createdAt;
    return MemoCard(
      content: memo.content,
      authorName: memo.userNickname ?? '밀키웨이',
      authorImageUrl: memo.userAvatarUrl,
      dateText: _relativeDate(date),
      edited: edited,
      showMineTag: _segment == 1 && memo.userId == Supabase.instance.client.auth.currentUser?.id,
      bookTitle: memo.bookTitle,
      page: memo.page,
      onTap: () => _openDetail(memo.id),
    );
  }

  Widget _message(String text) {
    return Center(
      child: Text(text,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
    );
  }

  static String _relativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}.$m.$d';
  }
}
