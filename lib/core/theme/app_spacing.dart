import 'package:flutter/material.dart';

/// Milkyway 디자인 토큰: 간격(spacing)과 코너 반경(radius).
///
/// 코드베이스 실측 기반 (EdgeInsets / SizedBox / BorderRadius.circular):
///   - padding 값 빈도: 20(50회), 16(30), 8(13), 12(5)
///   - SizedBox 자주 쓰는 값: 8/16/20/12/4
///   - BorderRadius: 12(37회), 8(23), 20(18), 16(6)
///
/// 의미 네이밍과 함께 raw 숫자 매핑을 제공해 마이그레이션을 쉽게 한다.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;

  /// 화면의 좌우 표준 여백. 거의 모든 화면에서
  /// `EdgeInsets.symmetric(horizontal: 20)` 으로 쓰인다. (50회)
  static const double lg = 20;

  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;

  /// 화면 좌우 표준 패딩.
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: lg);
}

/// 카드/버튼/모달 코너 반경.
class AppRadius {
  AppRadius._();

  /// 책 표지 모서리. (8 — 23회)
  static const double cover = 8;

  /// 카드 기본값. 거의 모든 카드형 컴포넌트가 이 값. (12 — 37회)
  static const double card = 12;

  /// 큰 카드 (이미지 컨테이너 등). (16 — 6회)
  static const double cardLarge = 16;

  /// 알약형 필터/태그 버튼. (20 — 18회)
  static const double pill = 20;

  /// 모달 시트, 다이얼로그 상단. (24 — 5회)
  static const double modal = 24;

  static BorderRadius get coverRadius => BorderRadius.circular(cover);
  static BorderRadius get cardRadius => BorderRadius.circular(card);
  static BorderRadius get pillRadius => BorderRadius.circular(pill);
}
