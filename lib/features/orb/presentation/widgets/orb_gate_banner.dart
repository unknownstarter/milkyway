import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/orb_tier.dart';
import 'orb_palette.dart';
import 'orb_view.dart';

/// 진행 링을 두른 '생성 중' 오브(디밍). 배너/시트 공용.
class _FormingOrb extends StatelessWidget {
  final double size;
  final double progress; // 0..1
  final bool animate;
  final Color accent;
  const _FormingOrb({
    required this.size,
    required this.progress,
    required this.accent,
    this.animate = false,
  });

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
              strokeWidth: size * 0.06,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
        ],
      ),
    );
  }
}

/// 홈 활성화 배너: 메모 [memos]개(< [orbGateMemos]) 유저에게 오브 생성 유도.
/// 탭하면 [showOrbGateSheet] 로 자전 오브 + 액션.
class OrbGateBanner extends StatelessWidget {
  final int memos;
  final VoidCallback? onTap;
  const OrbGateBanner({super.key, required this.memos, this.onTap});

  @override
  Widget build(BuildContext context) {
    final remain = (orbGateMemos - memos).clamp(0, orbGateMemos);
    final progress = (memos / orbGateMemos).clamp(0.0, 1.0);
    final accent = orbAccentOf(OrbTier.t1);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.modal),
          border: Border.all(color: accent.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('나만의 은하수',
                      style: AppTypography.caption
                          .copyWith(color: accent, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('첫 오브를 만들어보세요', style: AppTypography.subtitle),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: AppTypography.bodySmall,
                      children: [
                        const TextSpan(text: '메모 '),
                        TextSpan(
                            text: '$remain개',
                            style: TextStyle(color: accent, fontWeight: FontWeight.w800)),
                        const TextSpan(text: '만 더 남기면 오브가 생겨요'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('$memos / $orbGateMemos',
                      style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _FormingOrb(size: 84, progress: progress, accent: accent),
            const Icon(Icons.chevron_right, size: 22, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// 배너 탭 시 바텀시트: 큰 자전 오브 + 남은 개수 + 메모 작성 CTA.
Future<void> showOrbGateSheet(
  BuildContext context, {
  required int memos,
  VoidCallback? onWrite,
}) {
  final remain = (orbGateMemos - memos).clamp(0, orbGateMemos);
  final progress = (memos / orbGateMemos).clamp(0.0, 1.0);
  final accent = orbAccentOf(OrbTier.t1);

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.modal)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FormingOrb(size: 200, progress: progress, accent: accent, animate: true),
          const SizedBox(height: 12),
          Text('천천히 자전 중',
              style: AppTypography.caption.copyWith(color: accent, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTypography.heading,
              children: [
                const TextSpan(text: '오브가 '),
                TextSpan(text: '$remain개', style: TextStyle(color: accent)),
                const TextSpan(text: ' 남았어요'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('메모를 $remain개 더 남기면\n너만의 은하수 오브가 완성돼요',
              textAlign: TextAlign.center, style: AppTypography.bodySmall),
          const SizedBox(height: 12),
          Text('$memos / $orbGateMemos',
              style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                onWrite?.call();
              },
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: const Color(0xFF0C0C14),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
              child: Text('지금 메모 쓰기',
                  style: AppTypography.bodyBold.copyWith(color: const Color(0xFF0C0C14))),
            ),
          ),
        ],
      ),
    ),
  );
}
