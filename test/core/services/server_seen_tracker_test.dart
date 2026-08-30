import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/core/services/seen_tracker.dart';

/// 전송을 대체하는 인메모리 데이터소스. ServerSeenTracker의 캐시/판정 로직만 검증.
class _FakeDs implements SeenDataSource {
  String? uid;
  Map<String, DateTime> stored;
  int loadCount = 0;
  final List<String> marks = [];

  _FakeDs({this.uid = 'u1', Map<String, DateTime>? stored})
      : stored = stored ?? {};

  @override
  String? get currentUid => uid;

  @override
  Future<Map<String, DateTime>> loadAll() async {
    loadCount++;
    return Map.of(stored);
  }

  @override
  Future<void> mark(String scope, String key) async => marks.add('$scope:$key');
}

class _ThrowingDs extends _FakeDs {
  @override
  Future<void> mark(String scope, String key) async => throw Exception('network');
}

void main() {
  test('세션당 1회만 로드하고 캐시로 판정', () async {
    final ds = _FakeDs(stored: {'tab:books': DateTime.utc(2026, 8, 1)});
    final t = ServerSeenTracker(ds);

    expect(await t.tabLastSeen('books'), DateTime.utc(2026, 8, 1));
    await t.tabLastSeen('memos');
    await t.allBookViewed(['b1']);
    expect(ds.loadCount, 1); // 여러 판정에도 서버 로드는 1회
  });

  test('책/탭 키 분리(접두사) - 같은 문자열이라도 안 샌다', () async {
    final ds = _FakeDs();
    final t = ServerSeenTracker(ds);

    await t.markBookViewed('books'); // 탭 키와 동일 문자열
    expect(await t.tabLastSeen('books'), isNull);
    expect(await t.bookLastViewed('books'), isNotNull);

    await t.markTabSeen('some-book-id');
    expect(await t.bookLastViewed('some-book-id'), isNull);
  });

  test('allBookViewed는 기록된 책만 포함', () async {
    final ds = _FakeDs();
    final t = ServerSeenTracker(ds);

    await t.markBookViewed('a');
    await t.markBookViewed('c');
    final map = await t.allBookViewed(['a', 'b', 'c']);
    expect(map.keys.toSet(), {'a', 'c'});
  });

  test('mark는 낙관적 갱신(즉시 반영) + 전송 위임', () async {
    final ds = _FakeDs();
    final t = ServerSeenTracker(ds);

    expect(await t.tabLastSeen('memos'), isNull);
    await t.markTabSeen('memos');
    expect(await t.tabLastSeen('memos'), isNotNull); // 서버 응답 대기 없이 즉시
    expect(ds.marks, ['tab:memos']); // 전송 계층에 위임됨
  });

  test('유저 전환 시 캐시 무효화 후 재로드', () async {
    final ds = _FakeDs(uid: 'u1', stored: {'tab:books': DateTime.utc(2026, 1, 1)});
    final t = ServerSeenTracker(ds);

    expect(await t.tabLastSeen('books'), DateTime.utc(2026, 1, 1));
    expect(ds.loadCount, 1);

    ds.uid = 'u2';
    ds.stored = {'tab:books': DateTime.utc(2026, 9, 9)};
    expect(await t.tabLastSeen('books'), DateTime.utc(2026, 9, 9)); // u2로 재로드
    expect(ds.loadCount, 2);
  });

  test('미로그인(uid null)이면 빈 판정 + 크래시/전송 없음', () async {
    final ds = _FakeDs(uid: null);
    final t = ServerSeenTracker(ds);

    expect(await t.tabLastSeen('books'), isNull);
    expect(await t.allBookViewed(['b1']), isEmpty);
    await t.markTabSeen('books'); // no-op
    expect(ds.marks, isEmpty);
    expect(ds.loadCount, 0);
  });

  test('전송(upsert) 실패해도 낙관적 캐시는 유지된다', () async {
    final ds = _ThrowingDs();
    final t = ServerSeenTracker(ds);

    await t.markTabSeen('books'); // datasource.mark가 throw해도
    expect(await t.tabLastSeen('books'), isNotNull); // 캐시는 갱신됨(자가치유)
  });
}
