import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

/// 메모 공개/비공개 토글 위젯
class MemoVisibilityToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const MemoVisibilityToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.memoVisibilityLabel,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
            height: 28 / 20,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.memoVisibilityDescription,
              style: const TextStyle(
                color: Color(0xFF838383),
                fontSize: 16,
                fontFamily: 'Pretendard',
                height: 22.4 / 16,
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: const Color(0xFF48FF00),
              activeThumbColor: Colors.white,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFF2C2C2C),
            ),
          ],
        ),
      ],
    );
  }
}

