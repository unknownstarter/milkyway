import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// 디자인 시스템 표준 앱바 = 반투명 + 블러(콘텐츠가 뒤로 비쳐 넓어 보임, Claude 모바일 톤).
///
/// 반드시 `Scaffold(extendBodyBehindAppBar: true)`와 함께 쓴다(본문이 바 뒤로 확장돼 블러됨).
/// 스크롤 본문은 상단 패딩을 [heightWith]로 확보해 시작 시 바 아래에 오게 한다.
/// [bottom]에 정렬/세그먼트 칩을 넣으면 상단 스티키로 붙는다.
PreferredSizeWidget glassAppBar({
  Widget? title,
  List<Widget>? actions,
  Widget? leading,
  PreferredSizeWidget? bottom,
  bool centerTitle = true,
}) {
  return AppBar(
    backgroundColor: AppColors.bgPrimary.withValues(alpha: 0.55),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: centerTitle,
    title: title,
    leading: leading,
    actions: actions,
    bottom: bottom,
    // 바 뒤(상태바 영역 포함)를 블러 -> 반투명 유리. 콘텐츠가 은은히 비침.
    flexibleSpace: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

/// glassAppBar를 쓰는 스크롤 본문의 상단 패딩(상태바 + 툴바 + bottom 높이).
double glassTopPadding(BuildContext context, {double bottomHeight = 0}) {
  return MediaQuery.of(context).padding.top + kToolbarHeight + bottomHeight;
}
