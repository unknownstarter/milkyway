import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/design/banner_bar.dart';
import '../../../../core/presentation/widgets/design/buttons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/orb_tier.dart';
import 'orb_view.dart';

/// 진행 링을 두른 '생성 중' 오브(디밍). 시트 전용 시각.
/// 링은 앱 표준 accent(형광 초록) - StoryCircle 초록 링 문법과 동일.
class _FormingOrb extends StatelessWidget {
  final double size;
  final double progress; // 0..1
  final bool animate;
  const _FormingOrb({required this.size, required this.progress, this.animate = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.5,
            child: OrbView(tier: OrbTier.t1, size: size * 0.84, animate: animate),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: size * 0.055,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: const AlwaysStoppedAnimation(AppColors.accentGreen),
            ),
          ),
        ],
      ),
    );
  }
}

/// 홈 게이트 배너: 메모 [memos]개(< [orbGateMemos]) 유저에게 오브 생성 유도.
/// 디자인 시스템 [BannerBar] 재사용(accent 넛지). 탭 -> [showOrbGateSheet].
class OrbGateBanner extends StatelessWidget {
  final int memos;
  final VoidCallback onTap;
  const OrbGateBanner({super.key, required this.memos, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final remain = (orbGateMemos - memos).clamp(1, orbGateMemos);
    final l10n = AppL10n.of(context);
    return BannerBar(
      accent: true,
      icon: Icons.auto_awesome,
      title: l10n.orbGateBannerTitle,
      subtitle: l10n.orbGateBannerBody(remain),
      onTap: onTap,
    );
  }
}

/// 로컬라이즈된 문장에서 숫자 부분만 accent로 강조. 언어별 어순이 달라도
/// 숫자 위치를 찾아 쪼개므로 문장 구조에 의존하지 않는다.
List<TextSpan> _highlightCount(String text, String count) {
  final i = text.indexOf(count);
  if (i < 0) return [TextSpan(text: text)];
  return [
    TextSpan(text: text.substring(0, i)),
    TextSpan(
        text: count, style: const TextStyle(color: AppColors.accentGreen)),
    TextSpan(text: text.substring(i + count.length)),
  ];
}

/// 배너 탭 시 바텀시트: 큰 자전 오브 + 남은 개수 + 메모 작성 CTA(PrimaryButton).
Future<void> showOrbGateSheet(
  BuildContext context, {
  required int memos,
  VoidCallback? onWrite,
}) {
  final remain = (orbGateMemos - memos).clamp(1, orbGateMemos);
  final progress = (memos / orbGateMemos).clamp(0.0, 1.0);

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.modal)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 28, AppSpacing.xl, AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FormingOrb(size: 200, progress: progress, animate: true),
          const SizedBox(height: AppSpacing.xl),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTypography.heading,
              children: _highlightCount(
                AppL10n.of(context).orbGateSheetTitle(remain),
                '$remain',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(AppL10n.of(context).orbGateSheetBody(remain),
              textAlign: TextAlign.center, style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Text('$memos / $orbGateMemos',
              style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: AppL10n.of(context).orbGateWriteCta,
            onPressed: () {
              Navigator.of(context).pop();
              onWrite?.call();
            },
          ),
        ],
      ),
    ),
  );
}
