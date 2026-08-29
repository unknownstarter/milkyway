import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/design/banner_bar.dart';
import '../../../../core/presentation/widgets/design/buttons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
    return BannerBar(
      accent: true,
      icon: Icons.auto_awesome,
      title: '첫 오브를 만들어보세요',
      subtitle: '메모 $remain개만 더 남기면 나만의 은하수가 생겨요',
      onTap: onTap,
    );
  }
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
            text: TextSpan(style: AppTypography.heading, children: [
              const TextSpan(text: '오브가 '),
              TextSpan(text: '$remain개', style: const TextStyle(color: AppColors.accentGreen)),
              const TextSpan(text: ' 남았어요'),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('메모를 $remain개 더 남기면\n나만의 은하수 오브가 완성돼요',
              textAlign: TextAlign.center, style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Text('$memos / $orbGateMemos',
              style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: '지금 메모 쓰기',
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
