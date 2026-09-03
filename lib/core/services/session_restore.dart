import 'package:shared_preferences/shared_preferences.dart';

/// 마지막으로 머문 화면 경로를 저장/복원.
///
/// iOS/Android는 3~6시간 백그라운드 앱을 종료한다(메모리/배터리). 다시 열면
/// 콜드스타트라 스플래시가 뜨고 홈으로 점프해 "있던 곳"을 잃는다. 마지막 위치를
/// 저장해 두면 콜드스타트여도 그 화면으로 바로 복귀시켜 재개처럼 느끼게 한다.
class SessionRestore {
  static const _key = 'last_route';

  /// 복원 대상 제외 경로(스플래시/로그인/온보딩/딥링크 카드). 여기로 복원하면 안 된다.
  static bool _restorable(String location) {
    if (location.isEmpty || location == '/') return false;
    const skip = ['/login', '/onboarding', '/card', '/splash'];
    return !skip.any((p) => location.startsWith(p));
  }

  static Future<void> save(String location) async {
    if (!_restorable(location)) return;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, location);
  }

  static Future<String?> last() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_key);
    return (v != null && _restorable(v)) ? v : null;
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
