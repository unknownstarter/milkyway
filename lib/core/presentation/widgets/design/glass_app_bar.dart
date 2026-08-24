import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:inspire_blur/inspire_blur.dart';
import '../../../theme/app_spacing.dart';

// ════════════════════════════════════════════════════════════════════════
// 글래스 앱바 디자인 시스템 (전역 표준) — 상세 배경/레슨런: handoff/glass-appbar.md
//
// 핵심: 모든 상단 유리는 `GlassBackground`(GPU 셰이더 progressive blur + 배경색 틴트)
// 하나로 통일. 화면 유형(케이스)별로 아래 3가지만 골라 쓴다. 새 스크린도 이 중 하나.
//
// ┌ CASE A ─ 타이틀 + 필터칩 (예: 책탭, 메모탭) ───────────────────────────
// │ Scaffold(extendBodyBehindAppBar: true,
// │   appBar: glassAppBar(title: Text('Books'), bottom: filterBar(SegmentFilter(...))),
// │   body: <Scroll>(padding: top = glassTopPadding(context, bottomHeight: kFilterBarHeight)))
// │
// ├ CASE B ─ 타이틀만 / 상세 (예: 책상세, 메모상세, 캘린더, 검색) ──────────
// │ Scaffold(extendBodyBehindAppBar: true,
// │   appBar: glassAppBar(title: Text('...'), leading: BackButton(...)),
// │   body: <Scroll>(padding: top = glassTopPadding(context)))   // bottomHeight 없음
// │
// └ CASE C ─ 타이틀 없음 (예: 홈, 프로필) = 상태바만 순수 블러(글래스 아님) ──────
//   Scaffold(  // extendBodyBehindAppBar 불필요(appBar 없음)
//     body: Stack(children: [
//       <Scroll>(padding: top = statusBarTop(context)),        // SafeArea top 쓰지 말 것
//       const Positioned(top:0,left:0,right:0, child: StatusBarBlur()),
//     ]))
//
// 하단 네비(BottomNav)는 별개(momo 화이트 프로스트) — 이 파일과 무관, 건드리지 말 것.
// ════════════════════════════════════════════════════════════════════════

/// 표준 필터/세그먼트 바 높이(칩 32 + 하단 여백). 탭마다 다르지 않게 고정.
const double kFilterBarHeight = 44;

/// [CASE A/B] 타이틀 있는 화면의 표준 글래스 앱바.
/// flexibleSpace = [GlassBackground](셰이더 progressive blur). `extendBodyBehindAppBar: true` 필수.
/// [bottom]에 [filterBar]를 주면 CASE A(필터칩), 안 주면 CASE B(타이틀/상세).
/// 본문 top 패딩은 [glassTopPadding](CASE A는 bottomHeight: kFilterBarHeight).
PreferredSizeWidget glassAppBar({
  Widget? title,
  List<Widget>? actions,
  Widget? leading,
  PreferredSizeWidget? bottom,
  bool centerTitle = true,
  double? toolbarHeight,
}) {
  return AppBar(
    toolbarHeight: toolbarHeight,
    // 유리 효과는 flexibleSpace(GlassBackground)가 전담. AppBar 자체는 완전 투명.
    // 배경/서피스틴트/그림자 0 = 유리 위에 텍스트·칩만 뜸.
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: centerTitle,
    title: title,
    leading: leading,
    actions: actions,
    bottom: bottom,
    flexibleSpace: const GlassBackground(),
  );
}

/// 디자인 시스템 표준 글래스 배경(progressive blur + 배경색 그라데이션 틴트).
/// glassAppBar의 flexibleSpace, 타이틀 없는 화면의 GlassStatusBar가 공용으로 쓴다.
/// 정지 땐 배경색(#181818)이라 안 보이고, 스크롤 땐 위=진한 틴트로 색 haze를 눌러
/// 아래로 갈수록 블러·틴트가 0 -> 콘텐츠와 경계선("층") 없이 이어짐.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key});
  @override
  Widget build(BuildContext context) {
    // 진짜 progressive blur = GPU 셰이더(inspire_blur). 위=진하게 -> 아래=0으로 자연스럽게,
    // 상태바까지 이어짐. sliced 방식(밴딩) 대신 단일 셰이더라 "두두둑" 없음.
    // 위에 옅은 배경색 틴트(위 진하게->0)로 상태바/타이틀 가독성 + 반투명 유지.
    return Stack(
      fit: StackFit.expand,
      children: [
        Inspire.backdropBlur(
          config: InspireBlurConfig.topToBottom(
            sigma: 20,
            extent: 1.0,
            fadeCurve: Curves.easeInSine,
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF181818).withValues(alpha: 0.4),
                const Color(0xFF181818).withValues(alpha: 0.0),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

/// 타이틀 없는 화면(홈/프로필)용 상단 상태바 글래스 스트립.
/// body를 Stack으로 감싸 최상단에 얹고, 본문은 상태바 뒤까지 확장(SafeArea top 제거) +
/// top 패딩 = 상태바 높이(+[extra]). 스크롤 시 콘텐츠가 상태바 뒤로 들어가도 유리 처리로 일관.
/// [CASE C] 타이틀 없는 화면(홈/프로필)용 = **정확히 상태바(노치) 높이만 순수 블러**.
/// 글래스 아님(틴트/셰이더 없음). 상태바 뒤로 들어간 콘텐츠만 흐려지고, 상태바 아래는
/// 절대 안 흐려짐(높이 = MediaQuery.padding.top 딱 그만큼, 그 아래로 안 내려감).
/// 얇은 스트립이라 inspire 셰이더는 좌우 비대칭 버그 -> 균일 BackdropFilter.
/// body를 Stack으로: 스크롤(top 패딩 [statusBarTop]) + `Positioned(top:0, child: StatusBarBlur())`.
class StatusBarBlur extends StatelessWidget {
  const StatusBarBlur({super.key});
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).padding.top, // 딱 상태바 높이만
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: const SizedBox.expand(), // 순수 블러 - 틴트/배경색 없음
          ),
        ),
      ),
    );
  }
}

/// 타이틀 없는 화면 본문 top 패딩(상태바 + 숨쉴 여백).
/// StatusBarBlur를 쓰는 화면 본문 top 패딩 = 상태바 + 여백(콘텐츠가 상태바 아래에서 시작).
double statusBarTop(BuildContext context) =>
    MediaQuery.of(context).padding.top + AppSpacing.md;

/// glassAppBar를 쓰는 스크롤 본문의 상단 패딩(상태바 + 툴바 + bottom 높이 + 숨쉴 여백).
/// [gap] = 바 바닥과 첫 콘텐츠 사이 여백. 표지처럼 여백 없는 콘텐츠가 바에 씹히지 않게 기본 12.
double glassTopPadding(BuildContext context,
    {double bottomHeight = 0, double gap = AppSpacing.xs}) {
  return MediaQuery.of(context).padding.top + kToolbarHeight + bottomHeight + gap;
}

/// 앱바 하단 스티키 필터/세그먼트 바(표준). 탭마다 높이·정렬·여백을 동일하게 강제.
/// glassAppBar(bottom: filterBar(...))로 쓰고, 본문 top 패딩은
/// glassTopPadding(context, bottomHeight: kFilterBarHeight).
PreferredSizeWidget filterBar(Widget child) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(kFilterBarHeight),
    // 칩 뒤 배경 없음(투명) - 칩이 progressive 블러 위에 그냥 뜸. 솔리드 띠 금지.
    child: Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 6),
      child: Align(alignment: Alignment.centerLeft, child: child),
    ),
  );
}
