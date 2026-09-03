// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppL10nKo extends AppL10n {
  AppL10nKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'milkyway';

  @override
  String get commonSave => '저장';

  @override
  String get commonCancel => '취소';

  @override
  String get commonNext => '다음';

  @override
  String get commonClose => '닫기';

  @override
  String get commonConfirm => '확인';

  @override
  String get commonRetry => '다시 시도';

  @override
  String get settingsLanguage => '언어';

  @override
  String get languageSystem => '기기 설정';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageChinese => '中文';
}
