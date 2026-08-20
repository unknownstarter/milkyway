import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/recommended_book.dart';
import '../providers/discovery_providers.dart';

/// 온보딩 책 담기(주인공). 공개 메모가 쌓인 책을 추천 → 여러 권 담기.
class OnboardingBookSavingScreen extends ConsumerStatefulWidget {
  const OnboardingBookSavingScreen({super.key});

  @override
  ConsumerState<OnboardingBookSavingScreen> createState() =>
      _OnboardingBookSavingScreenState();
}

class _OnboardingBookSavingScreenState
    extends ConsumerState<OnboardingBookSavingScreen> {
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).logScreenView('onboarding_book_saving');
  }

  /// 온보딩 완료 처리 후 홈으로. savedCount는 담은 책 수(0이면 건너뜀).
  /// onboarding_completed=true 를 반드시 세팅해야 재진입 루프에 안 갇힌다.
  Future<void> _complete(int savedCount) async {
    final analytics = ref.read(analyticsProvider);
    analytics.logEvent(
        'click_complete_in_onboarding', {'added_book_count': savedCount});
    if (savedCount > 0) {
      analytics.logEvent('click_save_book_in_onboarding',
          {'source': 'onboarding_discovery', 'count': savedCount});
    }
    ref.read(bookSelectionProvider.notifier).clear();
    await ref.read(authProvider.notifier).updateOnboardingStatus(true);
    if (mounted) context.goNamed(AppRoutes.homeName);
  }

  void _openSearch() {
    context.pushNamed(
      AppRoutes.bookSearchName,
      queryParameters: {'isFromOnboarding': 'true'},
    );
  }

  Future<void> _save() async {
    final selected = ref.read(bookSelectionProvider).toList();
    if (selected.isEmpty) {
      _complete(0);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(discoveryRepositoryProvider).saveBooks(selected);
      if (mounted) _complete(selected.length);
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
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(recommendedBooksProvider);
    final selected = ref.watch(bookSelectionProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text('책 담기', style: AppTypography.subtitle),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _complete(0),
            child: Text('다음에 담기',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: async.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.textSecondary, strokeWidth: 2),
              ),
              error: (e, _) => Center(
                child: Text('추천을 불러오지 못했어요',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ),
              data: (books) => _grid(books, selected),
            ),
          ),
          _cta(selected.length),
        ],
      ),
    );
  }

  Widget _grid(List<RecommendedBook> books, Set<String> selected) {
    if (books.isEmpty) {
      return Center(
        child: Text('아직 추천할 책이 없어요',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary)),
      );
    }
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('사람들이 메모를 남긴 책', style: AppTypography.heading),
                const SizedBox(height: AppSpacing.md),
                Text('마음이 가는 책을 담아보세요\n담은 책에 Lyra가 물음을 건네요',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.base),
                GestureDetector(
                  onTap: _openSearch,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search,
                          size: 16, color: AppColors.accentGreen),
                      const SizedBox(width: 6),
                      Text('찾는 책이 없다면 직접 검색',
                          style: AppTypography.bodySmall.copyWith(
                              color: AppColors.accentGreen,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 18,
              mainAxisExtent: 300,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _bookCard(books[i], selected.contains(books[i].id)),
              childCount: books.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _bookCard(RecommendedBook book, bool on) {
    return GestureDetector(
      onTap: () =>
          ref.read(bookSelectionProvider.notifier).toggle(book.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                      border: on
                          ? Border.all(color: AppColors.accentGreen, width: 2.5)
                          : null,
                      color: AppColors.surface,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                      child: (book.coverUrl != null &&
                              book.coverUrl!.isNotEmpty)
                          ? Image.network(book.coverUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox())
                          : const SizedBox(),
                    ),
                  ),
                ),
                if (on)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: AppColors.accentGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          size: 16, color: Colors.black),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyBold
                  .copyWith(fontSize: 14, color: AppColors.textBright)),
          const SizedBox(height: 3),
          Text(book.proofLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _cta(int count) {
    final label = count == 0 ? '다음에 담기' : '$count권 담고 시작하기';
    final active = count > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: Material(
          color: active ? AppColors.accentGreen : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: InkWell(
            onTap: _saving ? null : _save,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Center(
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: active ? Colors.black : AppColors.textSecondary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
