import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/ranking_stats.dart';

/// 조합: 홈 '이번 주 나의 기록' 카드(익명 백분위 + 성장).
/// 순수 표현 위젯 - 데이터/계측은 상위가 담당. 디자인 시스템 토큰만 사용.
class RankingCard extends StatelessWidget {
  final RankingStats stats;

  const RankingCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up,
                  size: 16, color: AppColors.accentGreen),
              const SizedBox(width: 6),
              Text('이번 주 나의 기록',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (stats.hasRank) ..._ranked() else ..._empty(),
          const SizedBox(height: AppSpacing.base),
          _statsRow(),
        ],
      ),
    );
  }

  List<Widget> _ranked() {
    return [
      Text(stats.topPercentLabel!,
          style: AppTypography.title.copyWith(
              color: AppColors.accentGreen, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(stats.deltaLabel,
          style:
              AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
    ];
  }

  List<Widget> _empty() {
    return [
      Text('이번 주 첫 기록을 남겨봐',
          style: AppTypography.body.copyWith(color: AppColors.textBright)),
      if (stats.lastWeekMemos > 0) ...[
        const SizedBox(height: 4),
        Text('지난주엔 ${stats.lastWeekMemos}개 남겼어',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary)),
      ],
    ];
  }

  Widget _statsRow() {
    return Row(
      children: [
        _stat(Icons.edit_outlined, '이번 주 ${stats.thisWeekMemos}개'),
        if (stats.streakLabel != null) ...[
          const SizedBox(width: AppSpacing.base),
          _stat(Icons.local_fire_department_outlined, stats.streakLabel!),
        ],
      ],
    );
  }

  Widget _stat(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(label,
            style:
                AppTypography.caption.copyWith(color: AppColors.textTertiary)),
      ],
    );
  }
}
