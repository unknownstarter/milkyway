import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'repositories/notification_preferences_repository.dart';

/// 기기 시간대 (IANA 이름) 와 앱 언어를 notification_preferences 에 맞춰 둔다.
/// 서버가 "밤 10시~아침 7시" 를 시간대로 판정하고, 푸시 문구 언어를 language 로 고른다.
/// 같은 사용자에게 같은 (시간대, 언어) 를 이미 보냈으면 건너뛴다 (메모리 캐시, 저장소도 DB 값과 비교).
class TimeZoneSync {
  TimeZoneSync({
    required this.getTimeZone,
    required this.currentUserId,
    required this.getLanguage,
    required this.save,
  });

  /// 실제 의존을 주입한 기본 구성.
  factory TimeZoneSync.live({required String Function() getLanguage}) {
    return TimeZoneSync(
      getTimeZone: () async =>
          (await FlutterTimezone.getLocalTimezone()).identifier,
      currentUserId: () => Supabase.instance.client.auth.currentUser?.id,
      getLanguage: getLanguage,
      save: (zone, language) => NotificationPreferencesRepository(
        Supabase.instance.client,
      ).syncTimeZone(zone, language),
    );
  }

  final Future<String> Function() getTimeZone;
  final String? Function() currentUserId;
  final String Function() getLanguage;
  final Future<bool> Function(String timeZone, String language) save;

  String? _syncedUserId;
  String? _syncedZone;
  String? _syncedLanguage;
  bool _syncing = false;
  bool _rerun = false;

  /// 로그인 상태일 때만 동작. 실패는 삼킨다 (다음 앱 복귀 때 다시 시도).
  /// 진행 중에 또 불리면 (언어 변경 등) 끝난 뒤 한 번 더 돈다.
  Future<void> sync() async {
    if (_syncing) {
      _rerun = true;
      return;
    }
    _syncing = true;
    try {
      do {
        _rerun = false;
        await _syncOnce();
      } while (_rerun);
    } finally {
      _syncing = false;
    }
  }

  Future<void> _syncOnce() async {
    try {
      final uid = currentUserId();
      if (uid == null) return;
      final zone = await getTimeZone();
      if (zone.isEmpty) return;
      final language = getLanguage();
      if (uid == _syncedUserId &&
          zone == _syncedZone &&
          language == _syncedLanguage) {
        return;
      }
      await save(zone, language);
      _syncedUserId = uid;
      _syncedZone = zone;
      _syncedLanguage = language;
    } catch (_) {
      // 시간대/언어 동기화는 부가 기능. 앱 흐름을 막지 않는다.
    }
  }
}
