import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/widgets/design/buttons.dart';
import '../../../../core/presentation/widgets/design/cached_image.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../orb/domain/orb_tier.dart';
import '../../../orb/presentation/orb_tier_l10n.dart';
import '../../../orb/presentation/widgets/orb_palette.dart';
import '../providers/shared_card_provider.dart';
import '../widgets/connection_block.dart';

/// 공유 카드 랜딩(딥링크 도착지). 설치+로그인+온보딩 완료 유저가 공유 링크를
/// 눌렀을 때 그 카드를 보여준다. 뒤로가기는 항상 홈으로.
class SharedCardScreen extends ConsumerWidget {
  final String code;
  const SharedCardScreen({super.key, required this.code});

  void _goHome(BuildContext context) => context.goNamed(AppRoutes.homeName);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sharedCardProvider(code));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF08080E),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('milkyway',
              style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                  fontSize: 16)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
            onPressed: () => _goHome(context),
          ),
        ),
        body: SafeArea(
          child: async.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: AppColors.accentGreen)),
            error: (_, __) => _error(context),
            data: (card) => _content(context, card),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, SharedCard card) {
    final tier = OrbTier.values.firstWhere(
      (t) => t.name == card.tier,
      orElse: () => OrbTier.t1,
    );
    final accent = orbAccentOf(tier);
    // 문장이 실려 있으면 그게 주인공이다. 오브는 옆으로 물러난다.
    // 오브만 덩그러니 있으면 모르는 사람이 반응할 이유가 없다.
    final connection = ConnectionBlock.fromPayload(card.payload, accent);

    return Column(
      children: [
        Expanded(
          child: connection == null
              ? Center(
                  child: SizedBox(
                    // 회고=책 표지(3:4), 오브=정사각.
                    width: card.isWrapped ? 300 : 320,
                    height: card.isWrapped ? 400 : 320,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.modal),
                      child: CachedImage(url: card.imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                )
              : LayoutBuilder(builder: (context, c) {
                  // 짧은 내용이 위에 붙고 아래가 텅 비는 걸 막는다.
                  // 화면보다 짧으면 가운데로, 길면 그냥 스크롤.
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm,
                        AppSpacing.lg, AppSpacing.md),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: c.maxHeight - AppSpacing.md),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.modal),
                              child:
                                  CachedImage(url: card.imageUrl, fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _tierBadge(context, tier, accent),
                          const SizedBox(height: AppSpacing.lg),
                          connection,
                        ],
                      ),
                    ),
                  );
                }),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg,
              AppSpacing.md + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppL10n.of(context).shareLandingCta,
                  style: AppTypography.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              PrimaryButton(
                  label: AppL10n.of(context).shareLandingCtaButton,
                  onPressed: () => _goHome(context)),
            ],
          ),
        ),
      ],
    );
  }

  /// 어느 단계의 우주인지. 오브만으로는 모른다.
  Widget _tierBadge(BuildContext context, OrbTier tier, Color accent) {
    final name = orbTierName(AppL10n.of(context), tier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(AppL10n.of(context).orbTierBadge(name),
            style: AppTypography.label
                .copyWith(color: accent, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _error(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppL10n.of(context).shareLandingErrorTitle,
                  style: AppTypography.subtitle, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(AppL10n.of(context).shareLandingErrorBody,
                  style: AppTypography.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                  label: AppL10n.of(context).shareLandingGoHome,
                  onPressed: () => _goHome(context)),
            ],
          ),
        ),
      );
}
