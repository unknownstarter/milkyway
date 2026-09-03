// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppL10nZh extends AppL10n {
  AppL10nZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'milkyway';

  @override
  String get commonSave => '保存';

  @override
  String get commonCancel => '取消';

  @override
  String get commonNext => '下一步';

  @override
  String get commonClose => '关闭';

  @override
  String get commonConfirm => '确定';

  @override
  String get commonRetry => '重试';

  @override
  String get settingsLanguage => '语言';

  @override
  String get languageSystem => '系统默认';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageChinese => '中文';
}
