import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'repositories/notification_preferences_repository.dart';

/// 기기 시간대 (IANA 이름) 를 notification_preferences.time_zone 에 맞춰 둔다.
/// 서버가 "밤 10시~아침 7시" 를 이 시간대로 판정한다.
/// 같은 사용자에게 같은 값을 이미 보냈으면 건너뛴다 (메모리 캐시, 저장소도 DB 값과 비교).
class TimeZoneSync {
  TimeZoneSync({
    required this.getTimeZone,
    required this.currentUserId,
    required this.save,
  });

  /// 실제 의존을 주입한 기본 구성.
  factory TimeZoneSync.live() {
    return TimeZoneSync(
      getTimeZone: () async =>
          (await FlutterTimezone.getLocalTimezone()).identifier,
      currentUserId: () => Supabase.instance.client.auth.currentUser?.id,
      save: (zone) => NotificationPreferencesRepository(
        Supabase.instance.client,
      ).syncTimeZone(zone),
    );
  }

  final Future<String> Function() getTimeZone;
  final String? Function() currentUserId;
  final Future<bool> Function(String timeZone) save;

  String? _syncedUserId;
  String? _syncedZone;
  bool _syncing = false;

  /// 로그인 상태일 때만 동작. 실패는 삼킨다 (다음 앱 복귀 때 다시 시도).
  Future<void> sync() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final uid = currentUserId();
      if (uid == null) return;
      final zone = await getTimeZone();
      if (zone.isEmpty) return;
      if (uid == _syncedUserId && zone == _syncedZone) return;
      await save(zone);
      _syncedUserId = uid;
      _syncedZone = zone;
    } catch (_) {
      // 시간대 동기화는 부가 기능. 앱 흐름을 막지 않는다.
    } finally {
      _syncing = false;
    }
  }
}
