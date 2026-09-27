import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// 앱의 모든 스낵바는 이 파일을 통한다.
///
/// **`ScaffoldMessenger.showSnackBar` 를 화면에서 직접 부르지 말 것.**
/// 직접 부르면 기본값이 하단 고정(behavior: fixed)이라 하단 액션바를 가린다.
/// ScaffoldMessenger 는 앱 전역이라 스낵바가 화면 전환을 따라가므로, 띄운 화면이
/// 아니라 **도착한 화면의 하단 버튼**을 가리는 형태로 터진다.
/// (실제 사고: 책 등록 -> 책 상세 이동 시 "메모하기" 버튼을 덮었다)
///
/// 하단 여백 [_bottomGap] 은 하단 액션바("메모하기" 등)와 탭 네비를 한 번에
/// 비켜가는 값이다. 화면마다 계산하지 않는다 - 계산하기 시작하면 화면마다
/// 달라지고, 그게 어긋나면 다시 같은 사고가 난다.

/// 하단 액션바/네비를 비켜가는 여백. 안전영역 위에 얹는다.
const double _bottomGap = 80;

/// 앱 공통 스낵바. 기본값이자 대부분의 경우 쓸 것.
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
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomSafe + _bottomGap),
      duration: const Duration(seconds: 2),
    ),
  );
}

/// 알약형 짧은 토스트. 댓글처럼 조작이 잦아 스낵바가 연달아 뜨는 자리에서,
/// 기본 스낵바가 너무 크고 오래 남을 때 쓴다. 겹치면 즉시 교체된다.
///
/// 기본형([showAppSnackBar])으로 충분하면 이걸 쓰지 말 것. 변형이 늘어나는
/// 만큼 화면마다 다르게 보인다.
void showAppPillSnackBar(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  final bottomSafe = MediaQuery.of(context).padding.bottom;
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceElevated,
      shape: const StadiumBorder(),
      elevation: 0,
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
      ),
      margin: EdgeInsets.fromLTRB(44, 0, 44, bottomSafe + _bottomGap),
      duration: const Duration(milliseconds: 800),
    ),
  );
}
