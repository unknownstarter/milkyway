import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/memos/data/repositories/memo_repository.dart';
import 'package:whatif_milkyway_app/features/memos/domain/models/memo.dart';
import 'package:whatif_milkyway_app/features/memos/domain/models/memo_visibility.dart';
import 'package:whatif_milkyway_app/features/memos/presentation/providers/memo_search_provider.dart';

// 메모 검색. 세 가지가 중요하다.
// 1) 디바운스/페이지네이션이 어긋나면 같은 메모가 두 번 붙거나 검색이 안 끝난다.
// 2) 의미 검색(§10)이 키워드 결과를 망치면 안 된다. 임베딩 왕복은 느리고 실패할 수
//    있는데, 그 실패가 이미 떠 있는 공짜 키워드 결과를 지우면 손해만 남는다.
// 3) 키워드와 의미가 같은 메모를 잡으면 한 번만 보여야 한다.
//
// ILIKE 메타문자 이스케이프 테스트가 여기 있었는데 없앴다. 책 제목/저자 검색을
// 붙이면서 이스케이프가 Dart 에서 `search_my_memo_ids` RPC 안으로 옮겨갔기 때문이다.
// 한 군데서만 막는 게 맞아서 옮긴 것이고, 대신 이 가드는 flutter test 가 못 닿는
// 곳으로 갔다. 검증은 SQL 로 직접 했다('%' 0건 / '_' 0건 / '해빙' 2건).

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

  /// 의미 검색이 돌려줄 메모. [semanticError]가 있으면 그걸 던진다.
  List<Memo> semanticResults = const <Memo>[];
  Object? semanticError;
  final List<String> semanticQueries = [];

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
  Future<List<Memo>> searchMyMemosSemantic({
    required String query,
    int limit = 20,
  }) async {
    semanticQueries.add(query);
    if (semanticError != null) throw semanticError!;
    return semanticResults;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  group('MemoSearchNotifier', () {
    late List<({String query, int count})> logged;
    late List<({String query, int count})> semanticLogged;

    MemoSearchNotifier build(_FakeMemoRepository repo) {
      logged = [];
      semanticLogged = [];
      return MemoSearchNotifier(
        repository: repo,
        onSearched: (q, c) => logged.add((query: q, count: c)),
        onSemanticSearched: (q, c) => semanticLogged.add((query: q, count: c)),
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

    test('늦게 온 이전 검색 응답이 최신 결과를 덮지 않는다', () async {
      final repo = _SlowFirstRepository();
      final n = MemoSearchNotifier(
        repository: repo,
        onSearched: (_, __) {},
        debounce: const Duration(milliseconds: 10),
      );

      final stale = n.search('옛');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await n.search('새');
      expect(n.state.results.value!.single.id, 'fresh');

      await stale;
      expect(n.state.results.value!.single.id, 'fresh');
      n.dispose();
    });
  });

  group('의미 검색', () {
    late List<({String query, int count})> semanticLogged;

    MemoSearchNotifier build(_FakeMemoRepository repo) {
      semanticLogged = [];
      return MemoSearchNotifier(
        repository: repo,
        onSearched: (_, __) {},
        onSemanticSearched: (q, c) => semanticLogged.add((query: q, count: c)),
        debounce: const Duration(milliseconds: 10),
      );
    }

    test('키워드에 이미 잡힌 메모는 의미 섹션에서 빠진다', () async {
      final repo = _FakeMemoRepository({
        0: [_memo('1', '고독에 대하여')],
      })
        ..semanticResults = [_memo('1', '고독에 대하여'), _memo('2', '혼자 있는 시간')];
      final n = build(repo);
      await n.search('고독');

      expect(n.state.semanticResults.value, hasLength(2));
      expect(n.state.semanticOnly.value!.map((m) => m.id), ['2']);
      n.dispose();
    });

    test('더 불러오기로 키워드에 들어온 메모도 의미 섹션에서 사라진다', () async {
      final full = List.generate(20, (i) => _memo('p1-$i', 'a'));
      final repo = _FakeMemoRepository({
        0: full,
        20: [_memo('겹침', 'b')],
      })
        ..semanticResults = [_memo('겹침', 'b'), _memo('단독', 'c')];
      final n = build(repo);
      await n.search('전략');
      expect(n.state.semanticOnly.value!.map((m) => m.id), ['겹침', '단독']);

      await n.loadMore();
      expect(n.state.semanticOnly.value!.map((m) => m.id), ['단독']);
      n.dispose();
    });

    test('한 글자 검색어는 임베딩을 부르지 않는다 - 왕복만 낭비다', () async {
      final repo = _FakeMemoRepository({
        0: [_memo('1', 'a')],
      });
      final n = build(repo);
      await n.search('책');

      expect(repo.semanticQueries, isEmpty);
      expect(n.state.semanticResults.value, isEmpty);
      n.dispose();
    });

    test('의미 검색이 실패해도 키워드 결과는 남는다', () async {
      final repo = _FakeMemoRepository({
        0: [_memo('1', 'a')],
      })
        ..semanticError = Exception('voyage down');
      final n = build(repo);
      await n.search('전략');

      expect(n.state.results.value, hasLength(1));
      expect(n.state.semanticResults, isA<AsyncError<List<Memo>>>());
      n.dispose();
    });

    test('analytics 에는 중복 제거 후 실제로 보이는 수가 실린다', () async {
      final repo = _FakeMemoRepository({
        0: [_memo('1', 'a')],
      })
        ..semanticResults = [_memo('1', 'a'), _memo('2', 'b')];
      final n = build(repo);
      await n.search('전략');

      expect(semanticLogged.single.count, 1);
      n.dispose();
    });

    test('입력을 지우면 의미 결과도 같이 비워진다', () async {
      final repo = _FakeMemoRepository({
        0: [_memo('1', 'a')],
      })
        ..semanticResults = [_memo('2', 'b')];
      final n = build(repo);
      await n.search('전략');
      expect(n.state.semanticOnly.value, hasLength(1));

      n.clear();
      expect(n.state.semanticResults.value, isEmpty);
      expect(n.state.isIdle, isTrue);
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
  Future<List<Memo>> searchMyMemosSemantic({
    required String query,
    int limit = 20,
  }) async =>
      throw Exception('network down');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// 첫 검색만 느리게 답하는 저장소. 검색 세대 가드 확인용.
class _SlowFirstRepository implements MemoRepository {
  int calls = 0;

  @override
  Future<List<Memo>> searchMyMemos({
    required String query,
    required int limit,
    required int offset,
  }) async {
    calls++;
    if (calls == 1) {
      await Future<void>.delayed(const Duration(milliseconds: 60));
      return [_memo('stale', '옛 결과')];
    }
    return [_memo('fresh', '새 결과')];
  }

  @override
  Future<List<Memo>> searchMyMemosSemantic({
    required String query,
    int limit = 20,
  }) async =>
      const <Memo>[];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
