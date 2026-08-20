import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'cached_image.dart';

/// 조합: 홈 상단 "좋아하는 책" 스토리 원(인스타 문법).
/// ring - active(초록 conic = 새 활동) / seen(회색) / add(+).
enum StoryRing { active, seen, add }

class StoryCircle extends StatelessWidget {
  final String label;
  final String? coverUrl;
  final StoryRing ring;
  final VoidCallback onTap;

  const StoryCircle({
    super.key,
    required this.label,
    this.coverUrl,
    this.ring = StoryRing.seen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 62,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: ring == StoryRing.active
                    ? const SweepGradient(
                        colors: [
                          AppColors.accentGreen,
                          Color(0xFF00C2A8),
                          AppColors.accentGreen,
                        ],
                        transform: GradientRotation(2.35),
                      )
                    : null,
                color: ring == StoryRing.active
                    ? null
                    : (ring == StoryRing.add
                        ? AppColors.surfaceMuted
                        : AppColors.surfaceElevated),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.bgPrimary, width: 2.5),
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: ring == StoryRing.add
                    ? const Icon(Icons.add,
                        size: 24, color: AppColors.textTertiary)
                    : CachedImage(
                        url: coverUrl,
                        width: 57,
                        height: 57,
                        fallback: const SizedBox(),
                      ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: ring == StoryRing.add
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
