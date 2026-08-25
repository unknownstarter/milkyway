import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// 앱 공통 스낵바(디자인 시스템). 항상 floating + 하단 여백이라, 하단 액션바(책상세
/// "메모하기" 등)나 네비를 가리지 않고 홈처럼 그 위에 뜬다. 스낵바를 직접 만들지 말고
/// 이 헬퍼로 통일한다.
void showAppSnackBar(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  final bottomSafe = MediaQuery.of(context).padding.bottom;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceMuted,
      content: Text(
        message,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
      ),
      // 하단 액션바/네비를 확실히 비켜가도록 여백(안전영역 + 버튼바 높이만큼).
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomSafe + 80),
      duration: const Duration(seconds: 2),
    ),
  );
}
