import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// 원자: 라벨/배지 칩(pill). `수정됨`/`내 메모`/`오늘의 물음` 등.
/// tone에 따라 accent 소프트 또는 surface. 12/600.
enum ChipTone { accentSoft, surface }

class LabelChip extends StatelessWidget {
  final String text;
  final ChipTone tone;

  const LabelChip({super.key, required this.text, this.tone = ChipTone.surface});

  @override
  Widget build(BuildContext context) {
    final accent = tone == ChipTone.accentSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent
            ? AppColors.accentGreen.withValues(alpha: 0.12)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTypography.label.copyWith(
          color: accent ? AppColors.accentGreen : AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// 원자: 읽기 상태 칩(테두리 pill, accent). "읽는 중" / "완독" / "읽고 싶은".
class StatusChip extends StatelessWidget {
  final String text;

  const StatusChip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.6)),
      ),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: AppColors.accentGreen),
      ),
    );
  }
}
