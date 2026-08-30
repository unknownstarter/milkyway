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

/// seen 데이터 전송 계층(서버/로컬 무관). 캐시/판정 로직은 [ServerSeenTracker]가 씌운다.
/// 전송을 분리해 캐시 로직을 순수 단위테스트할 수 있게 한다(Supabase 목 불필요).
abstract class SeenDataSource {
  /// 현재 로그인 유저 id(없으면 null). 유저 전환 감지용.
  String? get currentUid;

  /// 현재 유저의 전체 seen 맵. key = '$scope:$key'.
  Future<Map<String, DateTime>> loadAll();

  /// 봤음 upsert(서버 now). 실패는 호출측이 흡수한다.
  Future<void> mark(String scope, String key);
}

/// 서버 기반 seen 판정. 재설치/기기변경에도 유지된다(기존 로컬 SharedPreferences는
/// 재설치마다 초기화돼 빨간점이 되살아나던 문제).
///
/// 성능/UX:
///  - **로그인 세션당 1회 로드 후 인메모리 캐시** -> 판정은 네트워크 없이 즉시.
///  - 유저 전환 시 캐시 자동 무효화(uid 가드) -> 재로드.
///  - mark는 **캐시 낙관적 갱신 + 서버 upsert 백그라운드** -> 점 즉시 사라짐.
///
/// 자가치유(문서): 낙관적 갱신은 클라 클럭 기준이라 서버와 미세 오차가 있을 수 있으나,
/// mark는 항상 기존 활동보다 뒤에 일어나므로 실사용에선 문제없고 다음 로드에서 서버값으로
/// 정정된다. mark upsert가 네트워크로 실패해도 다음 성공 시 복구된다.
class ServerSeenTracker implements SeenTracker {
  final SeenDataSource _ds;
  ServerSeenTracker(this._ds);

  Map<String, DateTime>? _cache; // key = '$scope:$key'
  String? _cacheUid;
  Future<Map<String, DateTime>>? _loading;
  String? _loadingUid;

  Future<Map<String, DateTime>> _ensure() async {
    final uid = _ds.currentUid;
    if (uid == null) return {};
    if (_cache != null && _cacheUid == uid) return _cache!;
    if (_loading != null && _loadingUid == uid) return _loading!;
    _loadingUid = uid;
    _loading = _ds.loadAll().then((m) {
      _cache = m;
      _cacheUid = uid;
      return m;
    });
    return _loading!;
  }

  Future<void> _mark(String scope, String key) async {
    if (_ds.currentUid == null) return;
    final m = await _ensure();
    m['$scope:$key'] = DateTime.now().toUtc(); // 낙관적 -> 점 즉시 사라짐
    // 서버 upsert는 응답을 기다리지 않는다(UI 즉시 반영). 실패해도 캐시는 유지.
    _ds.mark(scope, key).catchError((_) {});
  }

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

  @override
  Future<void> markTabSeen(String tabKey) => _mark('tab', tabKey);

  @override
  Future<DateTime?> tabLastSeen(String tabKey) async =>
      (await _ensure())['tab:$tabKey'];
}
