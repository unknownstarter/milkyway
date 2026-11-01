import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/notification_preferences.dart';

/// 알림 설정 읽기/쓰기. presentation 은 반드시 이 repository 를 경유한다.
/// 전체 스위치는 users.notification_enabled, 종류별 설정은 notification_preferences.
class NotificationPreferencesRepository {
  final SupabaseClient _client;
  NotificationPreferencesRepository(this._client);

  String? get _uid => _client.auth.currentUser?.id;

  Future<bool> getEnabled() async {
    final uid = _uid;
    if (uid == null) return true;
    final row = await _client
        .from('users')
        .select('notification_enabled')
        .eq('id', uid)
        .single();
    return row['notification_enabled'] as bool? ?? true;
  }

  Future<void> setEnabled(bool value) async {
    final uid = _uid;
    if (uid == null) return;
    await _client
        .from('users')
        .update({'notification_enabled': value})
        .eq('id', uid);
  }

  /// 행이 없으면 기본값 (모두 켜짐).
  Future<NotificationPreferences> getPreferences() async {
    final uid = _uid;
    if (uid == null) return NotificationPreferences.defaults;
    final row = await _client
        .from('notification_preferences')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    if (row == null) return NotificationPreferences.defaults;
    return NotificationPreferences.fromRow(row);
  }

  /// 스위치를 처음 바꿀 때 행이 생긴다 (upsert).
  /// 시간대 칼럼은 건드리지 않는다 ([syncTimeZone] 이 맡는다).
  Future<void> savePreferences(NotificationPreferences p) async {
    final uid = _uid;
    if (uid == null) return;
    await _client.from('notification_preferences').upsert({
      'user_id': uid,
      'book_memos': p.bookMemos,
      'comments': p.comments,
      'quiet_hours': p.quietHours,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// 기기 시간대 (IANA 이름) 를 저장한다. 서버가 밤 10시~아침 7시를 이 시간대로 판정한다.
  /// 이미 같은 값이면 쓰지 않는다. 반환: 실제로 썼는지.
  Future<bool> syncTimeZone(String timeZone) async {
    final uid = _uid;
    if (uid == null) return false;
    final row = await _client
        .from('notification_preferences')
        .select('time_zone')
        .eq('user_id', uid)
        .maybeSingle();
    if (row != null && row['time_zone'] == timeZone) return false;
    await _client.from('notification_preferences').upsert({
      'user_id': uid,
      'time_zone': timeZone,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    return true;
  }
}
