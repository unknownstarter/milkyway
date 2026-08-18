import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Milkyway 디자인 토큰: 타이포그래피.
///
/// **폰트는 무조건 Pretendard 하나로 통일**(세리프 등 혼용 금지). 위계는 폰트
/// 종류가 아니라 크기·굵기·자간·행간으로만 만든다.
///
/// 자간(letterSpacing)·행간(height)은 한글 가독 관용값 기반:
///   - 제목일수록 자간을 좁힌다(-0.02~-0.03em), 본문은 0에 가깝게(-0.01em), 캡션 0.
///   - 본문 행간은 넉넉히(1.6), 제목은 조여(1.25~1.4) 덩어리로 읽히게.
/// 정본 문서: docs/design/02-TYPOGRAPHY.md
///
/// 사용 예: Text('내 메모', style: AppTypography.title)
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Pretendard';

  /// 28 / Bold. 최상위 화면 타이틀.
  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.8,
    height: 1.25,
  );

  /// 24 / w600. 화면 메인 헤더.
  static const TextStyle heading = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.6,
    height: 1.3,
  );

  /// 20 / w600. 섹션 헤딩("읽고 있는 책", "내 메모"). 가장 흔한 헤딩.
  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
    height: 1.35,
  );

  /// 18 / w600. 카드 내부 강조, 다이얼로그 제목.
  static const TextStyle subtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.35,
    height: 1.4,
  );

  /// 16 / w400. 본문 기본(메모 본문 등). 가장 자주 쓰임.
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.6,
  );

  /// 16 / w600. 본문 강조(버튼 라벨 등).
  static const TextStyle bodyBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.6,
  );

  /// 14 / w400. 작은 본문, 보조 설명.
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: -0.15,
    height: 1.55,
  );

  /// 12 / w400. 캡션, 메타정보(timestamp, 페이지번호).
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: 0,
    height: 1.4,
  );

  /// 12 / w600. 라벨(배지, 태그).
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0,
    height: 1.3,
  );
}
