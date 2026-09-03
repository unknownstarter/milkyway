// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppL10nJa extends AppL10n {
  AppL10nJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'milkyway';

  @override
  String get commonSave => '保存';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonNext => '次へ';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonConfirm => 'OK';

  @override
  String get commonRetry => '再試行';

  @override
  String get settingsLanguage => '言語';

  @override
  String get languageSystem => '端末の設定';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageChinese => '中文';
}
