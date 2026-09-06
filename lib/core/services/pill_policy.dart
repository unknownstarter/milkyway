import 'package:shared_preferences/shared_preferences.dart';

/// 플로팅 알약의 노출 빈도.
///   once           - 평생 딱 한 번만 뜬다(한 번 뜨면 소진)
///   daily          - 하루에 한 번
///   untilDismissed - 닫기 전까지 매번(1회성 안내의 기본값)
///   always         - 조건 없이 항상
enum PillFrequency { once, daily, untilDismissed, always }

/// 플로팅 알약 노출 정책 저장소.
///
/// 규칙 하나는 빈도와 무관하게 절대적이다: **X를 한 번이라도 누르면 그 알약은 끝**.
/// 빈도는 "아직 안 닫은 사람에게 얼마나 자주 보일까"만 결정한다.
class PillPolicy {
  static String _dismissedKey(String id) => 'pill.$id.dismissed';
  static String _lastShownKey(String id) => 'pill.$id.lastShown';
  static String _shownCountKey(String id) => 'pill.$id.shownCount';

  static String _stamp(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 지금 띄워도 되는지. [legacyDismissedKey]는 이 정책 도입 전에 쓰던 플래그로,
  /// 이미 닫은 기존 사용자에게 알약이 되살아나지 않게 한다.
  static Future<bool> shouldShow(
    String id,
    PillFrequency frequency, {
    String? legacyDismissedKey,
    DateTime? now,
  }) async {
    final p = await SharedPreferences.getInstance();
    if (legacyDismissedKey != null && (p.getBool(legacyDismissedKey) ?? false)) {
      return false;
    }
    if (p.getBool(_dismissedKey(id)) ?? false) return false;

    switch (frequency) {
      case PillFrequency.always:
      case PillFrequency.untilDismissed:
        return true;
      case PillFrequency.once:
        return (p.getInt(_shownCountKey(id)) ?? 0) == 0;
      case PillFrequency.daily:
        return p.getString(_lastShownKey(id)) != _stamp(now ?? DateTime.now());
    }
  }

  /// 화면에 실제로 띄운 순간 기록(once/daily 판정의 근거).
  static Future<void> markShown(String id, {DateTime? now}) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_shownCountKey(id), (p.getInt(_shownCountKey(id)) ?? 0) + 1);
    await p.setString(_lastShownKey(id), _stamp(now ?? DateTime.now()));
  }

  /// 영구 종료(X 또는 목적 달성). 이후 어떤 빈도든 다시 뜨지 않는다.
  static Future<void> dismissForever(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_dismissedKey(id), true);
  }

  /// 테스트/디버그용 초기화.
  static Future<void> reset(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_dismissedKey(id));
    await p.remove(_lastShownKey(id));
    await p.remove(_shownCountKey(id));
  }
}
