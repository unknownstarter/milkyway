import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/analytics_provider.dart';
import '../../data/repositories/memo_repository.dart';
import '../../domain/models/memo.dart';

/// 메모 검색 상태. 키워드(무료)와 의미(PRD v2 §10)를 한 화면에 함께 담는다.
///
/// [query]가 비어 있으면 아직 아무것도 안 친 상태(idle)다. 결과 0건과 구분해야
/// 화면이 "검색어를 입력하세요"와 "찾는 메모가 없어요"를 다르게 보여줄 수 있다.
class MemoSearchState {
  final String query;
  final AsyncValue<List<Memo>> results;
  final bool hasMore;

  /// 의미 검색 원본. 키워드 결과와 겹치는 메모가 그대로 들어 있다.
  /// 화면에 뿌릴 땐 [semanticOnly]를 쓴다.
  final AsyncValue<List<Memo>> semanticResults;

  const MemoSearchState({
    this.query = '',
    this.results = const AsyncValue.data(<Memo>[]),
    this.hasMore = false,
    this.semanticResults = const AsyncValue.data(<Memo>[]),
  });

  bool get isIdle => query.trim().isEmpty;

  /// 키워드로 이미 잡힌 메모를 뺀 의미 검색 결과.
  ///
  /// 뺀 결과를 저장하지 않고 매번 계산한다. 저장하면 '더 불러오기'로 키워드 결과가
  /// 늘어난 뒤 같은 메모가 위아래에 두 번 뜬다.
  AsyncValue<List<Memo>> get semanticOnly => semanticResults.whenData((list) {
        final shown = (results.value ?? const <Memo>[]).map((m) => m.id).toSet();
        return list.where((m) => !shown.contains(m.id)).toList();
      });

  MemoSearchState copyWith({
    String? query,
    AsyncValue<List<Memo>>? results,
    bool? hasMore,
    AsyncValue<List<Memo>>? semanticResults,
  }) =>
      MemoSearchState(
        query: query ?? this.query,
        results: results ?? this.results,
        hasMore: hasMore ?? this.hasMore,
        semanticResults: semanticResults ?? this.semanticResults,
      );
}

/// 내 메모 검색. 키워드는 무료(PRD v2 §8), 의미 검색은 그 위에 얹는다(§10).
///
/// 디바운스를 화면이 아니라 여기서 처리한다. 화면은 입력만 흘려보내면 되고,
/// 테스트에서 타이머를 직접 돌려볼 수 있다.
class MemoSearchNotifier extends StateNotifier<MemoSearchState> {
  MemoSearchNotifier({
    required MemoRepository repository,
    required this.onSearched,
    this.onSemanticSearched,
    this.debounce = const Duration(milliseconds: 350),
  })  : _repository = repository,
        super(const MemoSearchState());

  final MemoRepository _repository;

  /// 검색이 실제로 실행된 뒤 호출. Analytics(`keyword_search`)를 붙인다.
  final void Function(String query, int resultCount) onSearched;

  /// 의미 검색이 끝난 뒤 호출. Analytics(`semantic_search`).
  final void Function(String query, int resultCount)? onSemanticSearched;

  final Duration debounce;

  static const int _limit = 20;
  static const int _semanticLimit = 20;

  /// 한 글자로는 뜻을 잡을 수 없다. 임베딩 왕복만 낭비한다.
  static const int _minSemanticChars = 2;

  Timer? _timer;
  int _offset = 0;
  bool _loadingMore = false;

  /// 검색 세대. 늦게 도착한 이전 검색의 응답이 최신 결과를 덮는 것을 막는다.
  /// 키워드와 의미 검색이 속도가 달라 이게 없으면 순서가 섞인다.
  int _seq = 0;

  /// 입력이 바뀔 때마다 호출. 디바운스 후 실제 검색한다.
  void onQueryChanged(String value) {
    _timer?.cancel();
    state = state.copyWith(query: value);

    if (value.trim().isEmpty) {
      _reset();
      return;
    }

    _timer = Timer(debounce, () => search(value));
  }

  /// 디바운스 없이 즉시 검색(키보드의 검색 키 등).
  Future<void> search(String value) async {
    _timer?.cancel();
    final q = value.trim();
    if (q.isEmpty) {
      _reset();
      return;
    }

    final seq = ++_seq;
    state = state.copyWith(
      query: value,
      results: const AsyncValue.loading(),
      semanticResults: const AsyncValue.loading(),
    );
    _offset = 0;

    try {
      final memos = await _repository.searchMyMemos(
        query: q,
        limit: _limit,
        offset: 0,
      );
      if (!mounted || seq != _seq) return;
      _offset = memos.length;
      state = state.copyWith(
        results: AsyncValue.data(memos),
        hasMore: memos.length == _limit,
      );
      onSearched(q, memos.length);
    } catch (e, st) {
      if (!mounted || seq != _seq) return;
      state = state.copyWith(results: AsyncValue.error(e, st), hasMore: false);
    }

    // 키워드 결과를 먼저 띄우고 의미 검색을 뒤따라 채운다. 둘을 한꺼번에 기다리면
    // 공짜로 빠른 키워드 결과가 느린 임베딩 왕복에 묶인다.
    await _searchSemantic(q, seq);
  }

  Future<void> _searchSemantic(String q, int seq) async {
    if (q.length < _minSemanticChars) {
      if (mounted && seq == _seq) {
        state = state.copyWith(semanticResults: const AsyncValue.data(<Memo>[]));
      }
      return;
    }

    try {
      final memos = await _repository.searchMyMemosSemantic(
        query: q,
        limit: _semanticLimit,
      );
      if (!mounted || seq != _seq) return;
      state = state.copyWith(semanticResults: AsyncValue.data(memos));
      onSemanticSearched?.call(q, state.semanticOnly.value?.length ?? 0);
    } catch (e, st) {
      if (!mounted || seq != _seq) return;
      state = state.copyWith(semanticResults: AsyncValue.error(e, st));
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || !state.hasMore) return;
    final q = state.query.trim();
    if (q.isEmpty) return;

    _loadingMore = true;
    try {
      final more = await _repository.searchMyMemos(
        query: q,
        limit: _limit,
        offset: _offset,
      );
      if (!mounted) return;
      _offset += more.length;
      final current = state.results.value ?? const <Memo>[];
      state = state.copyWith(
        results: AsyncValue.data([...current, ...more]),
        hasMore: more.length == _limit,
      );
    } catch (_) {
      // 더 불러오기 실패는 조용히 멈춘다. 이미 보고 있는 결과는 지키는 게 낫다.
      if (mounted) state = state.copyWith(hasMore: false);
    } finally {
      _loadingMore = false;
    }
  }

  void clear() {
    _timer?.cancel();
    _reset();
  }

  /// idle 로 되돌린다. 세대를 올려 진행 중인 응답이 빈 화면에 뒤늦게 꽂히지 않게 한다.
  void _reset() {
    _seq++;
    _offset = 0;
    state = const MemoSearchState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final memoSearchProvider =
    StateNotifierProvider.autoDispose<MemoSearchNotifier, MemoSearchState>(
  (ref) => MemoSearchNotifier(
    repository: ref.watch(memoRepositoryProvider),
    onSearched: (query, count) => ref.read(analyticsProvider).logEvent(
      'keyword_search',
      {'query_length': query.length, 'result_count': count},
    ),
    onSemanticSearched: (query, count) => ref.read(analyticsProvider).logEvent(
      'semantic_search',
      {'query_length': query.length, 'result_count': count},
    ),
  ),
);
