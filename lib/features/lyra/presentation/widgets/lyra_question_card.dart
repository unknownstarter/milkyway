import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

/// 책 상세에 노출되는 Lyra 물음 카드.
/// 순수 표현 위젯 - 계측/이동은 상위(책 상세)가 담당한다.
class LyraQuestionCard extends StatelessWidget {
  final String question;
  final VoidCallback onAnswer;

  const LyraQuestionCard({
    super.key,
    required this.question,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(
          color: AppColors.accentGreen.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.accentGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Lyra의 물음',
                style: AppTypography.caption.copyWith(
                  color: AppColors.accentGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            question,
            style: AppTypography.body.copyWith(
              color: AppColors.textBright,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: onAnswer,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit_outlined,
                    size: 16, color: AppColors.accentGreen),
                const SizedBox(width: 6),
                Text(
                  '이 물음에 메모 남기기',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
