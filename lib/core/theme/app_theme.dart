import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// 밀키웨이 앱 테마.
///
/// 앱은 **무조건 다크**(디자인 철학 원칙 1). light/dark 어느 쪽을 요청해도 동일한
/// 다크 테마를 돌려준다. 색·타이포는 토큰(`AppColors`/`AppTypography`)에서 온다.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _dark;
  static ThemeData get darkTheme => _dark;

  static final ThemeData _dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgPrimary,
    fontFamily: AppTypography.fontFamily,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.bgPrimary,
      onSurface: AppColors.textPrimary,
      primary: AppColors.accentGreen,
      onPrimary: Colors.black,
      outline: AppColors.divider,
    ),
    textTheme: const TextTheme(
      displayLarge: AppTypography.display,
      headlineMedium: AppTypography.heading,
      titleLarge: AppTypography.title,
      titleMedium: AppTypography.subtitle,
      bodyLarge: AppTypography.body,
      bodyMedium: AppTypography.bodySmall,
      bodySmall: AppTypography.caption,
      labelLarge: AppTypography.bodyBold,
      labelSmall: AppTypography.label,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
