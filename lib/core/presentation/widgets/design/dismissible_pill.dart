import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// 원자: 닫을 수 있는 알약(pill). 선행 아이콘 + 라벨 + 우측 X.
/// 본체 탭은 [onTap], X 탭은 [onClose]. 1회성 힌트/전환 유도 등에 재사용.
/// (예: 홈 상단 언어 전환, 안내 배너의 경량 버전)
///
/// **항상 한 줄.** 내용만큼 가로로 늘어나고, 남은 폭을 넘길 때만 말줄임한다.
/// 화면 위에 띄우고 노출 정책까지 붙이려면 `FloatingPill`을 쓸 것.
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
            // Flexible: 라벨이 길어도 X가 밀려나지 않게. 줄바꿈 대신 말줄임.
            Flexible(
              child: InkWell(
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
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.label
                              .copyWith(color: AppColors.textBright),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: onClose,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(4, 8, 12, 8),
                child:
                    Icon(Icons.close, size: 15, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
