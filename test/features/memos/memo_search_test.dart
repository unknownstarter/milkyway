import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/memos/data/repositories/memo_repository.dart';
import 'package:whatif_milkyway_app/features/memos/domain/models/memo.dart';
import 'package:whatif_milkyway_app/features/memos/domain/models/memo_visibility.dart';
import 'package:whatif_milkyway_app/features/memos/presentation/providers/memo_search_provider.dart';

// 메모 키워드 검색(무료). 두 가지가 중요하다.
// 1) ILIKE 메타문자를 안 막으면 '%' 한 글자로 남의 전체 메모가 아니라
//    내 전체 메모가 쏟아진다. 검색이 아니라 사고다.
// 2) 디바운스/페이지네이션이 어긋나면 같은 메모가 두 번 붙거나 검색이 안 끝난다.

Memo _memo(String id, String content) => Memo(
      id: id,
      userId: 'u',
      bookId: 'b',
      content: content,
      createdAt: DateTime(2026, 9, 20),
      visibility: MemoVisibility.private,
      bookTitle: 't',
      books: const {},
    );

class _FakeMemoRepository implements MemoRepository {
  _FakeMemoRepository(this.pages);

  /// offset -> 그 offset에서 돌려줄 메모들
  final Map<int, List<Memo>> pages;

  final List<String> receivedQueries = [];
  int callCount = 0;

  @override
  Future<List<Memo>> searchMyMemos({
    required String query,
    required int limit,
    required int offset,
  }) async {
    callCount++;
    receivedQueries.add(query);
    return pages[offset] ?? const <Memo>[];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  group('escapeIlikePattern', () {
    test('퍼센트는 리터럴로 막는다', () {
      expect(escapeIlikePattern('100%'), r'100\%');
    });

    test('언더스코어도 막는다 - 한 글자 와일드카드였다', () {
      expect(escapeIlikePattern('a_b'), r'a\_b');
    });

    test('백슬래시를 먼저 늘린다 - 순서가 틀리면 이스케이프가 깨진다', () {
      expect(escapeIlikePattern(r'a\%'), r'a\\\%');
    });

    test('평범한 한글은 그대로 둔다', () {
      expect(escapeIlikePattern('리더십'), '리더십');
    });

    test('메타문자만 친 검색어도 전체 매칭으로 새지 않는다', () {
      expect(escapeIlikePattern('%'), r'\%');
    });
  });

  group('MemoSearchNotifier', () {
    late List<({String query, int count})> logged;

    MemoSearchNotifier build(_FakeMemoRepository repo) {
      logged = [];
      return MemoSearchNotifier(
        repository: repo,
        onSearched: (q, c) => logged.add((query: q, count: c)),
        debounce: const Duration(milliseconds: 10),
      );
    }

    test('처음엔 idle - 결과 0건과 구분돼야 안내 문구가 갈린다', () {
      final n = build(_FakeMemoRepository({}));
      expect(n.state.isIdle, isTrue);
      expect(n.state.results.value, isEmpty);
      n.dispose();
    });

    test('공백만 입력하면 검색하지 않는다', () async {
      final repo = _FakeMemoRepository({});
      final n = build(repo);
      n.onQueryChanged('   ');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(repo.callCount, 0);
      expect(n.state.isIdle, isTrue);
      n.dispose();
    });

    test('디바운스 - 연속 입력은 마지막 한 번만 쏜다', () async {
      final repo = _FakeMemoRepository({
        0: [_memo('1', '리더십에 대하여')],
      });
      final n = build(repo);
      n.onQueryChanged('리');
      n.onQueryChanged('리더');
      n.onQueryChanged('리더십');
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(repo.callCount, 1);
      expect(repo.receivedQueries.single, '리더십');
      expect(n.state.results.value, hasLength(1));
      n.dispose();
    });

    test('검색 성공하면 analytics 콜백에 결과 수가 실린다', () async {
      final repo = _FakeMemoRepository({
        0: [_memo('1', 'a'), _memo('2', 'b')],
      });
      final n = build(repo);
      await n.search('전략');

      expect(logged.single.query, '전략');
      expect(logged.single.count, 2);
      n.dispose();
    });

    test('결과가 limit 미만이면 hasMore 는 false', () async {
      final repo = _FakeMemoRepository({
        0: [_memo('1', 'a')],
      });
      final n = build(repo);
      await n.search('전략');

      expect(n.state.hasMore, isFalse);
      n.dispose();
    });

    test('limit 만큼 꽉 차면 더 불러오고 뒤에 붙인다', () async {
      final full = List.generate(20, (i) => _memo('p1-$i', 'a'));
      final repo = _FakeMemoRepository({
        0: full,
        20: [_memo('p2-0', 'b')],
      });
      final n = build(repo);
      await n.search('전략');
      expect(n.state.hasMore, isTrue);

      await n.loadMore();
      expect(n.state.results.value, hasLength(21));
      expect(n.state.results.value!.last.id, 'p2-0');
      expect(n.state.hasMore, isFalse);
      n.dispose();
    });

    test('입력을 지우면 idle 로 돌아간다', () async {
      final repo = _FakeMemoRepository({
        0: [_memo('1', 'a')],
      });
      final n = build(repo);
      await n.search('전략');
      expect(n.state.isIdle, isFalse);

      n.onQueryChanged('');
      expect(n.state.isIdle, isTrue);
      expect(n.state.results.value, isEmpty);
      n.dispose();
    });

    test('검색 실패는 error 로 드러낸다 - 조용히 빈 결과로 위장하지 않는다', () async {
      final repo = _ThrowingRepository();
      final n = MemoSearchNotifier(
        repository: repo,
        onSearched: (_, __) {},
        debounce: const Duration(milliseconds: 10),
      );
      await n.search('전략');

      expect(n.state.results, isA<AsyncError<List<Memo>>>());
      n.dispose();
    });
  });
}

class _ThrowingRepository implements MemoRepository {
  @override
  Future<List<Memo>> searchMyMemos({
    required String query,
    required int limit,
    required int offset,
  }) async =>
      throw Exception('network down');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
