import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// 제목 + (선택) 설명 + 우측 스위치. [enabled] 가 false 면 흐려지고 눌리지 않는다.
class NotificationSwitchRow extends StatelessWidget {
  final String title;
  final String? description;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const NotificationSwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.description,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.body),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(description!, style: AppTypography.caption),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeThumbColor: Colors.black,
              activeTrackColor: AppColors.accentGreen,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
