import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/analytics_provider.dart';
import '../../../../core/presentation/widgets/design/glass_app_bar.dart';
import '../../../../core/presentation/widgets/design/memo_card.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/memo.dart';
import '../memo_l10n.dart';
import '../providers/memo_search_provider.dart';

/// 내 메모 키워드 검색. 무료 기능(PRD v2 §8 Free).
///
/// 의미 검색(Milkyway+)은 이 화면 위에 얹는다. 지금은 부분일치만 한다.
class MemoSearchScreen extends ConsumerStatefulWidget {
  const MemoSearchScreen({super.key});

  @override
  ConsumerState<MemoSearchScreen> createState() => _MemoSearchScreenState();
}

class _MemoSearchScreenState extends ConsumerState<MemoSearchScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).logScreenView('memo_search');
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      ref.read(memoSearchProvider.notifier).loadMore();
    }
  }

  void _openDetail(Memo memo) => context.pushNamed(
        AppRoutes.memoDetailName,
        pathParameters: {'id': memo.id},
        extra: memo,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final state = ref.watch(memoSearchProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      extendBodyBehindAppBar: true,
      appBar: glassAppBar(
        leading: const BackButton(color: AppColors.textSecondary),
        title: _field(l10n),
        actions: [
          if (state.query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close,
                  size: 20, color: AppColors.textSecondary),
              onPressed: () {
                _controller.clear();
                ref.read(memoSearchProvider.notifier).clear();
              },
            ),
        ],
      ),
      body: _body(l10n, state, glassTopPadding(context)),
    );
  }

  Widget _field(AppL10n l10n) {
    return TextField(
      controller: _controller,
      autofocus: true,
      style: AppTypography.body.copyWith(color: AppColors.textPrimary),
      cursorColor: AppColors.accentGreen,
      textInputAction: TextInputAction.search,
      onChanged: ref.read(memoSearchProvider.notifier).onQueryChanged,
      onSubmitted: ref.read(memoSearchProvider.notifier).search,
      decoration: InputDecoration(
        isDense: true,
        border: InputBorder.none,
        hintText: l10n.memoSearchHint,
        hintStyle:
            AppTypography.body.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _body(AppL10n l10n, MemoSearchState state, double topPadding) {
    if (state.isIdle) return _message(l10n.memoSearchPrompt, topPadding);

    return state.results.when(
      skipLoadingOnReload: true,
      loading: () => Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: const Center(
          child: CircularProgressIndicator(
              color: AppColors.textSecondary, strokeWidth: 2),
        ),
      ),
      error: (_, __) => _message(l10n.memoSearchFailed, topPadding),
      data: (memos) {
        if (memos.isEmpty) return _message(l10n.memoSearchEmpty, topPadding);
        return ListView.separated(
          controller: _scroll,
          padding: EdgeInsets.fromLTRB(
              AppSpacing.lg, topPadding, AppSpacing.lg, 110),
          itemCount: memos.length + (state.hasMore ? 1 : 0),
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
            return _card(l10n, memos[i]);
          },
        );
      },
    );
  }

  Widget _card(AppL10n l10n, Memo memo) {
    final edited = memo.isEdited;
    final date = edited ? memo.updatedAt! : memo.createdAt;
    return MemoCard(
      content: memo.content,
      authorName: memo.userNickname ?? l10n.memoAuthorFallback,
      authorImageUrl: memo.userAvatarUrl,
      dateText: memoRelativeDate(l10n, date),
      edited: edited,
      bookTitle: memo.bookTitle,
      page: memo.page,
      imageUrl: memo.imageUrl,
      commentCount: memo.commentCount,
      lyraQuestion: memo.lyraQuestion,
      onTap: () => _openDetail(memo),
    );
  }

  Widget _message(String text, double topPadding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, topPadding + AppSpacing.xl, AppSpacing.lg, 0),
      child: Align(
        alignment: Alignment.topCenter,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall
              .copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
