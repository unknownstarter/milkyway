import 'package:flutter/material.dart';

/// Milkyway 디자인 토큰: 색상.
///
/// 값은 문서가 아니라 현재 코드베이스의 실측 사용 빈도에서 도출됨
/// (2026-05-29 시점). 토큰 도입 자체는 비파괴적 — 기존 인라인
/// `Color(0xFF...)` 호출은 그대로 두고, 새로 작성하거나 손대는 코드부터
/// 이 토큰을 사용한다.
class AppColors {
  AppColors._();

  // ──────────────────────────────────────────────────────────────────────
  // Background — 앱 전체에서 사용하는 베이스 다크 배경.
  // ──────────────────────────────────────────────────────────────────────
  /// 메인 화면 배경. 가장 빈도 높은 색 (51회).
  /// [AppTheme.scaffoldBackgroundColor] 도 이 값을 사용한다.
  static const Color bgPrimary = Color(0xFF181818);

  // ──────────────────────────────────────────────────────────────────────
  // Surface — 카드/모달/시트 표면. 배경보다 한 단계 밝다.
  // ──────────────────────────────────────────────────────────────────────
  /// 기본 카드 표면. (28회)
  static const Color surface = Color(0xFF1A1A1A);

  /// 스낵바, 작은 정보 패널 등 살짝 강조된 표면. (18회)
  static const Color surfaceMuted = Color(0xFF242424);

  /// 더 도드라진 카드 (콜랩스된 reading section 카드 등). (4회)
  static const Color surfaceElevated = Color(0xFF2C2C2C);

  // ──────────────────────────────────────────────────────────────────────
  // Text — 콘트라스트가 높은 순서대로.
  // ──────────────────────────────────────────────────────────────────────
  /// 본문/주요 텍스트. 흰색 대신 살짝 톤다운된 밝은 회색을 쓴다. (26회)
  static const Color textPrimary = Color(0xFFECECEC);

  /// 보조 텍스트(저자, 메타정보, 시간). 코드에서 가장 빈번. (41회)
  static const Color textSecondary = Color(0xFF838383);

  /// 더 흐린 텍스트 (placeholder, disabled). (13회)
  static const Color textTertiary = Color(0xFF646464);

  /// 거의 흰색에 가까운 강조 텍스트. (DEDEDE/DADADA 통합)
  static const Color textBright = Color(0xFFDEDEDE);

  // ──────────────────────────────────────────────────────────────────────
  // Accent — 사용자 액션과 시각적 강조.
  // ──────────────────────────────────────────────────────────────────────
  /// 브랜드 액센트 (형광 초록). 토글, 강조 라인, 주요 액션. (17회)
  static const Color accentGreen = Color(0xFF48FF00);

  /// 메모 추가 모달 한정 보조 액센트 (보라). 의도된 격리 사용.
  /// 새 컴포넌트에선 가급적 [accentGreen] 사용을 권장. (4회, add_action_modal.dart 전용)
  static const Color accentPurple = Color(0xFF4117EB);

  /// 파괴적 액션(삭제/신고) 위험색. 삭제 버튼/다이얼로그 등에서 공유.
  static const Color danger = Color(0xFFE05252);

  // ──────────────────────────────────────────────────────────────────────
  // Divider / Outline.
  // ──────────────────────────────────────────────────────────────────────
  /// 구분선, 비활성 외곽선. (4회)
  static const Color divider = Color(0xFF313131);
}
