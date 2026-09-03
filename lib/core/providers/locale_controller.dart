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
