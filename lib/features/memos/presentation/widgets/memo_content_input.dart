import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

/// 메모 내용 입력 위젯
class MemoContentInput extends StatelessWidget {
  final TextEditingController controller;
  final int maxLength;

  const MemoContentInput({
    super.key,
    required this.controller,
    this.maxLength = 200,
  });

  @override
  Widget build(BuildContext context) {
    final textLength = controller.text.length;
    final l10n = AppL10n.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.memoContentLabel,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
            height: 28 / 20,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            TextField(
              controller: controller,
              maxLines: 8,
              maxLength: maxLength,
              enableInteractiveSelection: true,
              enableSuggestions: Theme.of(context).platform != TargetPlatform.android, // 안드로이드에서는 false
              cursorColor: Colors.white,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Pretendard',
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: l10n.memoContentHintMax(maxLength),
                hintStyle: const TextStyle(
                  color: Color(0xFF838383),
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                ),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF646464)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF646464)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                contentPadding: const EdgeInsets.all(18),
                counterText: '', // 기본 카운터 숨기기
              ),
            ),
            Positioned(
              right: 18,
              bottom: 18,
              child: Text(
                '$textLength/$maxLength',
                style: const TextStyle(
                  color: Color(0xFF838383),
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

