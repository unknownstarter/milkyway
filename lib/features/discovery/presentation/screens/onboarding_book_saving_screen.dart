import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/design/cached_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/recommended_book.dart';
import '../providers/discovery_providers.dart';
import '../recommended_book_l10n.dart';

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
    if (await DeepLinkService.consumePending()) return;
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
            content: Text(AppL10n.of(context).discoverySaveError,
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
    final l = AppL10n.of(context);
    final async = ref.watch(recommendedBooksProvider);
    final selected = ref.watch(bookSelectionProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(l.discoveryTitle, style: AppTypography.subtitle),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _complete(0),
            child: Text(l.discoverySkip,
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
                child: Text(l.discoveryLoadError,
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
    final l = AppL10n.of(context);
    if (books.isEmpty) {
      return Center(
        child: Text(l.discoveryEmpty,
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
                Text(l.discoveryHeading, style: AppTypography.heading),
                const SizedBox(height: AppSpacing.md),
                Text(l.discoveryBody,
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
                      Text(l.discoverySearchCta,
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
                          ? CachedImage(
                              url: book.coverUrl,
                              fit: BoxFit.cover,
                              cacheWidth: 300,
                              fallback: const SizedBox())
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
          Text(recommendedBookProof(AppL10n.of(context), book),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _cta(int count) {
    final l = AppL10n.of(context);
    final label = count == 0 ? l.discoverySkip : l.discoveryStartCta(count);
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
