import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/app_spacing.dart';

/// 확인 버튼 톤. accent=초록(긍정 액션), danger=빨강(파괴 액션).
enum ConfirmTone { accent, danger }

/// 디자인 시스템 확인 다이얼로그(제목 + 본문 + 취소/확인).
/// 앱 전역 팝업을 이 조합으로 통일한다. 반환: 확인 true / 취소·바깥탭 false.
Future<bool> showAppConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmText,
  String cancelText = '취소',
  ConfirmTone tone = ConfirmTone.accent,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => _AppConfirmDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      tone: tone,
    ),
  );
  return result ?? false;
}

class _AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final ConfirmTone tone;

  const _AppConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final confirmColor =
        tone == ConfirmTone.danger ? AppColors.danger : AppColors.accentGreen;
    return Dialog(
      backgroundColor: AppColors.surface,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.modal),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: AppTypography.subtitle
                    .copyWith(color: AppColors.textBright)),
            const SizedBox(height: AppSpacing.md),
            Text(message,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _action(context, cancelText, AppColors.textSecondary,
                    value: false),
                const SizedBox(width: AppSpacing.xs),
                _action(context, confirmText, confirmColor,
                    value: true, bold: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(BuildContext context, String label, Color color,
      {required bool value, bool bold = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base, vertical: AppSpacing.sm),
        child: Text(label,
            style: AppTypography.bodySmall.copyWith(
                color: color,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
      ),
    );
  }
}
