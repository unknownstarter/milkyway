import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/analytics_provider.dart';
import '../../data/repositories/memo_repository.dart';
import '../../domain/models/memo.dart';

/// 메모 키워드 검색 상태.
///
/// [query]가 비어 있으면 아직 아무것도 안 친 상태(idle)다. 결과 0건과 구분해야
/// 화면이 "검색어를 입력하세요"와 "찾는 메모가 없어요"를 다르게 보여줄 수 있다.
class MemoSearchState {
  final String query;
  final AsyncValue<List<Memo>> results;
  final bool hasMore;

  const MemoSearchState({
    this.query = '',
    this.results = const AsyncValue.data(<Memo>[]),
    this.hasMore = false,
  });

  bool get isIdle => query.trim().isEmpty;

  MemoSearchState copyWith({
    String? query,
    AsyncValue<List<Memo>>? results,
    bool? hasMore,
  }) =>
      MemoSearchState(
        query: query ?? this.query,
        results: results ?? this.results,
        hasMore: hasMore ?? this.hasMore,
      );
}

/// 내 메모 키워드 검색. 무료 기능(PRD v2 §8 Free). AI 비용 0.
///
/// 디바운스를 화면이 아니라 여기서 처리한다. 화면은 입력만 흘려보내면 되고,
/// 테스트에서 타이머를 직접 돌려볼 수 있다.
class MemoSearchNotifier extends StateNotifier<MemoSearchState> {
  MemoSearchNotifier({
    required MemoRepository repository,
    required this.onSearched,
    this.debounce = const Duration(milliseconds: 350),
  })  : _repository = repository,
        super(const MemoSearchState());

  final MemoRepository _repository;

  /// 검색이 실제로 실행된 뒤 호출. Analytics(`keyword_search`)를 붙인다.
  final void Function(String query, int resultCount) onSearched;

  final Duration debounce;

  static const int _limit = 20;

  Timer? _timer;
  int _offset = 0;
  bool _loadingMore = false;

  /// 입력이 바뀔 때마다 호출. 디바운스 후 실제 검색한다.
  void onQueryChanged(String value) {
    _timer?.cancel();
    state = state.copyWith(query: value);

    if (value.trim().isEmpty) {
      state = const MemoSearchState();
      return;
    }

    _timer = Timer(debounce, () => search(value));
  }

  /// 디바운스 없이 즉시 검색(키보드의 검색 키 등).
  Future<void> search(String value) async {
    _timer?.cancel();
    final q = value.trim();
    if (q.isEmpty) {
      state = const MemoSearchState();
      return;
    }

    state = state.copyWith(query: value, results: const AsyncValue.loading());
    _offset = 0;

    try {
      final memos = await _repository.searchMyMemos(
        query: q,
        limit: _limit,
        offset: 0,
      );
      if (!mounted) return;
      _offset = memos.length;
      state = state.copyWith(
        results: AsyncValue.data(memos),
        hasMore: memos.length == _limit,
      );
      onSearched(q, memos.length);
    } catch (e, st) {
      if (!mounted) return;
      state = state.copyWith(results: AsyncValue.error(e, st), hasMore: false);
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
  ),
);
