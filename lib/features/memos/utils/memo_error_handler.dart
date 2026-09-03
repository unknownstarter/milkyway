import 'package:flutter/material.dart';
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
    
    // 하단 네비게이션 바 높이 계산
    final bottomNavigationBarHeight = _calculateBottomNavigationBarHeight(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Pretendard',
            fontSize: 14,
          ),
        ),
        backgroundColor: const Color(0xFF838383),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        elevation: 1000, // 최상위 레이어에 표시되도록 높은 elevation 설정
        margin: EdgeInsets.only(
          bottom: bottomNavigationBarHeight + 20, // 네비게이션 바 높이 + 여유 공간
          left: 20,
          right: 20,
        ),
      ),
    );
  }

  /// 하단 네비게이션 바의 높이를 계산
  /// MainShell의 bottomNavigationBar 구조를 고려하여 높이 계산
  static double _calculateBottomNavigationBarHeight(BuildContext context) {
    final scaffold = Scaffold.maybeOf(context);
    
    // 하단 네비게이션 바가 있는지 확인
    if (scaffold?.widget.bottomNavigationBar == null) {
      return 0;
    }
    
    // MainShell의 bottomNavigationBar 구조:
    // SafeArea (top: false, bottom: true) + padding(10+10) + minHeight(64) + SafeArea bottom
    final mediaQuery = MediaQuery.of(context);
    const containerPadding = 10.0 + 10.0; // top + bottom
    const containerMinHeight = 64.0;
    final safeAreaBottom = mediaQuery.padding.bottom;
    
    return containerPadding + containerMinHeight + safeAreaBottom;
  }

  /// 에러를 분석하여 회색 스낵바로 표시
  static void showError(BuildContext context, dynamic error) {
    final message = getErrorMessage(AppL10n.of(context), error);
    showErrorSnackBar(context, message);
  }
}

