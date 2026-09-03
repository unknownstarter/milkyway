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
import '../providers/shared_card_provider.dart';

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
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SizedBox(
              // 회고=책 표지(3:4), 오브=정사각.
              width: card.isWrapped ? 300 : 320,
              height: card.isWrapped ? 400 : 320,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.modal),
                child: CachedImage(url: card.imageUrl, fit: BoxFit.cover),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg,
              AppSpacing.md + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppL10n.of(context).shareLandingCta,
                  style: AppTypography.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                  label: AppL10n.of(context).shareLandingCtaButton,
                  onPressed: () => _goHome(context)),
            ],
          ),
        ),
      ],
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
