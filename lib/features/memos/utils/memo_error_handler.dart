import 'package:flutter/material.dart';

import '../../../core/presentation/widgets/design/app_snackbar.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../../l10n/app_localizations.dart';

/// 메모 관련 에러를 처리하고 사용자에게 표시하는 유틸리티 클래스
class MemoErrorHandler {
  /// 에러를 분석하여 사용자 친화적인 메시지를 반환
  static String getErrorMessage(AppL10n l, dynamic error) {
    if (error is PlatformException) {
      switch (error.code) {
        case 'camera_access_denied':
          return l.memoErrorCameraPermission;
        case 'camera_unavailable':
          return l.memoErrorCameraUnavailable;
        case 'photo_access_denied':
          return l.memoErrorPhotoPermission;
        default:
          return l.memoErrorImagePick;
      }
    }
    
    if (error is SocketException) {
      return l.memoErrorNetwork;
    }
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return l.memoErrorNetwork;
    }
    
    if (errorString.contains('permission') || errorString.contains('권한')) {
      return l.memoErrorPermission;
    }
    
    if (errorString.contains('upload') || errorString.contains('업로드')) {
      return l.memoImageUploadFailed;
    }
    
    if (errorString.contains('save') || errorString.contains('저장')) {
      return l.memoErrorSave;
    }
    
    return l.memoErrorGeneric;
  }

  /// 에러를 회색 스낵바로 표시
  static void showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    
    showAppSnackBar(context, message);
  }

  /// 에러를 분석하여 회색 스낵바로 표시
  static void showError(BuildContext context, dynamic error) {
    final message = getErrorMessage(AppL10n.of(context), error);
    showErrorSnackBar(context, message);
  }
}

