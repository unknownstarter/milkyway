import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// 지원 언어. 서버(Lyra 물음 번역)와 동일한 집합.
const supportedLangCodes = {'ko', 'en', 'ja', 'zh'};

/// 서버에 넘길 현재 언어 코드. 사용자가 고른 값이 있으면 그것,
/// 없으면 기기 언어(지원 목록에 있을 때). 그 외에는 정본인 'ko'.
/// 서버는 번역이 없으면 한국어로 폴백하므로 이 값이 틀려도 화면은 비지 않는다.
final effectiveLangProvider = Provider<String>((ref) {
  final override = ref.watch(localeControllerProvider)?.languageCode;
  if (override != null && supportedLangCodes.contains(override)) return override;
  for (final l in WidgetsBinding.instance.platformDispatcher.locales) {
    if (supportedLangCodes.contains(l.languageCode)) return l.languageCode;
  }
  return 'ko';
});
