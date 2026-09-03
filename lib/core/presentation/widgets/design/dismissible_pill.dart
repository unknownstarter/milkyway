import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// 원자: 닫을 수 있는 알약(pill). 선행 아이콘 + 라벨 + 우측 X.
/// 본체 탭은 [onTap], X 탭은 [onClose]. 1회성 힌트/전환 유도 등에 재사용.
/// (예: 홈 상단 언어 전환, 안내 배너의 경량 버전)
class DismissiblePill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback onClose;

  const DismissiblePill({
    super.key,
    required this.label,
    required this.onClose,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 16, color: AppColors.textBright),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: AppTypography.label
                          .copyWith(color: AppColors.textBright),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: onClose,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(4, 8, 12, 8),
                child: Icon(Icons.close, size: 15, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
