import 'dart:async';

/// FCM 토큰을 users.fcm_token 에 맞춰 두는 로직. Firebase/Supabase 에 직접 의존하지 않아
/// 테스트할 수 있다. 실제 의존은 NotificationService 가 주입한다.
///
/// - 권한이 없으면 저장하지 않는다.
/// - 같은 사용자에게 같은 토큰을 이미 저장했으면 DB 쓰기를 건너뛴다(메모리 캐시).
/// - onTokenRefresh 리스너는 한 번만 붙인다.
class PushTokenSync {
  PushTokenSync({
    required this.hasPermission,
    required this.getToken,
    required this.tokenRefreshStream,
    required this.currentUserId,
    required this.save,
    this.getApnsToken,
    this.apnsRetryDelay = const Duration(seconds: 1),
    this.apnsMaxAttempts = 3,
  });

  final Future<bool> Function() hasPermission;
  final Future<String?> Function() getToken;
  final Stream<String> Function() tokenRefreshStream;
  final String? Function() currentUserId;
  final Future<void> Function(String userId, String token) save;

  /// iOS 에서만 주입. null 이면 APNs 대기를 건너뛴다.
  final Future<String?> Function()? getApnsToken;
  final Duration apnsRetryDelay;
  final int apnsMaxAttempts;

  String? _savedUserId;
  String? _savedToken;
  StreamSubscription<String>? _refreshSub;
  bool _syncing = false;

  bool get isListeningRefresh => _refreshSub != null;

  /// 로그인 상태이고 알림 권한이 있으면 현재 토큰을 저장한다. 저장했거나 이미 같은 값이면 토큰 반환.
  Future<String?> sync() async {
    if (_syncing) return null;
    _syncing = true;
    try {
      final uid = currentUserId();
      if (uid == null) return null;
      if (!await hasPermission()) return null;
      if (!await _apnsReady()) return null;

      final token = await getToken();
      if (token == null || token.isEmpty) return null;

      _ensureRefreshListener();
      if (_savedUserId == uid && _savedToken == token) return token;

      await save(uid, token);
      _savedUserId = uid;
      _savedToken = token;
      return token;
    } finally {
      _syncing = false;
    }
  }

  Future<bool> _apnsReady() async {
    final read = getApnsToken;
    if (read == null) return true;
    for (var i = 0; i < apnsMaxAttempts; i++) {
      if (await read() != null) return true;
      if (i < apnsMaxAttempts - 1) await Future<void>.delayed(apnsRetryDelay);
    }
    return false;
  }

  void _ensureRefreshListener() {
    _refreshSub ??= tokenRefreshStream().listen((newToken) async {
      final uid = currentUserId();
      if (uid == null || newToken.isEmpty) return;
      if (_savedUserId == uid && _savedToken == newToken) return;
      try {
        await save(uid, newToken);
        _savedUserId = uid;
        _savedToken = newToken;
      } catch (_) {/* 다음 sync 에서 재시도 */}
    });
  }

  Future<void> dispose() async {
    await _refreshSub?.cancel();
    _refreshSub = null;
  }
}
