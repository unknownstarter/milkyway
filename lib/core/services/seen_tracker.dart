import 'package:supabase_flutter/supabase_flutter.dart';

/// '봤음' 시각 기록의 계약. presentation은 직접 접근 금지, provider(SeenController) 경유.
///  - 책별 last-viewed(scope='book'): 책 상세 진입 시 -> 홈 스토리 링 / 책탭 점
///  - 탭별 last-seen(scope='tab', key='books'|'memos'): 탭 진입 시 -> 하단 네비 점
abstract class SeenTracker {
  static const tabBooks = 'books';
  static const tabMemos = 'memos';

  Future<void> markBookViewed(String bookId);
  Future<DateTime?> bookLastViewed(String bookId);
  Future<Map<String, DateTime>> allBookViewed(List<String> bookIds);
  Future<void> markTabSeen(String tabKey);
  Future<DateTime?> tabLastSeen(String tabKey);
}

/// 서버(seen_state 테이블) 기반 구현. 재설치/기기변경에도 유지된다(기존 로컬
/// SharedPreferences는 재설치마다 초기화돼 빨간점이 되살아나던 문제).
/// 성능: 판정마다 네트워크 재조회하지 않도록 **로그인 세션당 1회 로드 후 인메모리
/// 캐시**. mark 시 캐시를 낙관적으로 갱신하고 서버 upsert는 백그라운드로 보낸다.
class ServerSeenTracker implements SeenTracker {
  final SupabaseClient _client;
  ServerSeenTracker(this._client);

  Map<String, DateTime>? _cache; // key = '$scope:$key'
  String? _cacheUid;
  Future<Map<String, DateTime>>? _loading;
  String? _loadingUid;

  Future<Map<String, DateTime>> _ensure() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return {};
    if (_cache != null && _cacheUid == uid) return _cache!;
    if (_loading != null && _loadingUid == uid) return _loading!;
    _loadingUid = uid;
    _loading = _load(uid);
    return _loading!;
  }

  Future<Map<String, DateTime>> _load(String uid) async {
    final rows = await _client.from('seen_state').select('scope, key, seen_at');
    final m = <String, DateTime>{};
    for (final r in (rows as List)) {
      final row = r as Map<String, dynamic>;
      final dt = DateTime.tryParse(row['seen_at'] as String);
      if (dt != null) m['${row['scope']}:${row['key']}'] = dt;
    }
    _cache = m;
    _cacheUid = uid;
    return m;
  }

  Future<void> _mark(String scope, String key) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    final m = await _ensure();
    m['$scope:$key'] = DateTime.now().toUtc(); // 낙관적 갱신 -> 점 즉시 사라짐
    // 서버 upsert는 응답을 기다리지 않는다(UI 즉시 반영). 실패해도 캐시는 유지.
    _client
        .rpc('mark_seen', params: {'p_scope': scope, 'p_key': key})
        .then((_) {})
        .catchError((_) {});
  }

  // ---- 책별 ----

  @override
  Future<void> markBookViewed(String bookId) => _mark('book', bookId);

  @override
  Future<DateTime?> bookLastViewed(String bookId) async =>
      (await _ensure())['book:$bookId'];

  @override
  Future<Map<String, DateTime>> allBookViewed(List<String> bookIds) async {
    final m = await _ensure();
    final result = <String, DateTime>{};
    for (final id in bookIds) {
      final v = m['book:$id'];
      if (v != null) result[id] = v;
    }
    return result;
  }

  // ---- 탭별 ----

  @override
  Future<void> markTabSeen(String tabKey) => _mark('tab', tabKey);

  @override
  Future<DateTime?> tabLastSeen(String tabKey) async =>
      (await _ensure())['tab:$tabKey'];
}
