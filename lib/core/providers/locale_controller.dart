import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';

const _kLocaleKey = 'app_locale';

/// 앱 언어. null = 기기 설정을 따름(첫 실행 기본). 사용자가 프로필에서 고르면
/// 그 언어를 영구 저장(같은 기기에서 잊지 않음). '기기 설정'을 다시 고르면 null로.
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    _load(); // 저장된 override를 비동기로 로드해 반영
    return null; // 초기값 = 기기 설정
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final code = p.getString(_kLocaleKey);
    if (code != null && code.isNotEmpty) state = Locale(code);
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final p = await SharedPreferences.getInstance();
    if (locale == null) {
      await p.remove(_kLocaleKey);
    } else {
      await p.setString(_kLocaleKey, locale.languageCode);
    }
  }
}

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);

/// 지원 언어. 서버(Lyra 물음 번역, 푸시 문구)와 동일한 집합.
const supportedLangCodes = {'ko', 'en', 'ja', 'zh'};

/// 앱이 실제로 보여주는 언어 코드.
/// override 가 지원 언어면 그것. 아니면 MaterialApp 이 기기 언어에 하는 것과 같은
/// 규칙 (Flutter 기본 [basicLocaleListResolution] + [AppL10n.supportedLocales]) 으로 맞춘다.
/// 지원 밖 기기 언어 (fr 등) 는 supportedLocales 첫째인 en 으로 떨어진다.
String resolveAppLanguage(Locale? override, List<Locale> deviceLocales) {
  final o = override?.languageCode;
  if (o != null && supportedLangCodes.contains(o)) return o;
  return basicLocaleListResolution(deviceLocales, AppL10n.supportedLocales)
      .languageCode;
}

/// 서버에 넘길 현재 언어 코드 (Lyra 물음, 푸시 문구 언어 동기화).
final effectiveLangProvider = Provider<String>((ref) {
  return resolveAppLanguage(
    ref.watch(localeControllerProvider),
    WidgetsBinding.instance.platformDispatcher.locales,
  );
});
