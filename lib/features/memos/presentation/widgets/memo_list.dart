import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/memo_provider.dart';
import '../../domain/models/memo.dart';
import '../../domain/models/memo_visibility_filter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'book_detail_memo_card.dart';
import '../../../../core/presentation/widgets/pill_filter_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../memo_l10n.dart';

class MemoList extends ConsumerStatefulWidget {
  final String? bookId;

  const MemoList({
    super.key,
    this.bookId,
  });

  @override
  ConsumerState<MemoList> createState() => _MemoListState();
}

class _MemoListState extends ConsumerState<MemoList> {
  final _scrollController = ScrollController();
  MemoVisibilityFilter _selectedFilter = MemoVisibilityFilter.all;

  // 필터링 결과 메모이제이션
  // GoRouter가 페이지를 캐싱하므로 뒤로가기 후에도 상태가 유지됨
  List<Memo>? _cachedFilteredMemos;
  MemoVisibilityFilter? _cachedFilter;
  int? _cachedMemosLength;
  String? _cachedUserId;
  Set<String>? _cachedMemoIds; // 메모 ID 집합으로 실제 변경 여부 확인
  String? _cachedMemoVisibilityHash; // 메모 visibility 해시 (visibility 변경 감지용)

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final notifier = ref.read(paginatedMemosProvider(widget.bookId).notifier);
      if (notifier.hasMore) {
        notifier.loadMoreMemos();
      }
    }
  }

  /// 필터링된 메모 반환 (메모이제이션 적용)
  List<Memo> _getFilteredMemos(List<Memo> memos, String? currentUserId) {
    // 메모 ID와 visibility 해시 계산 (visibility 변경 감지용)
    final currentMemoIds = memos.map((m) => m.id).toSet();
    final currentMemoVisibilityHash = memos
        .map((m) => '${m.id}:${m.visibility.value}')
        .toList()
      ..sort();
    final visibilityHashString = currentMemoVisibilityHash.join(',');

    // 캐시가 유효한지 확인 (리스트 길이, ID 집합, visibility 해시로 비교)
    if (_cachedFilteredMemos != null &&
        _cachedFilter == _selectedFilter &&
        _cachedMemosLength == memos.length &&
        _cachedUserId == currentUserId &&
        _cachedMemoIds != null &&
        _cachedMemoVisibilityHash != null) {
      // 메모 ID 집합과 visibility 해시로 실제 변경 여부 확인
      if (_cachedMemoIds == currentMemoIds &&
          _cachedMemoVisibilityHash == visibilityHashString) {
        return _cachedFilteredMemos!;
      }
    }

    // 필터링 실행
    final filtered = _selectedFilter.filterMemos(memos, currentUserId);

    // 캐시 업데이트
    _cachedFilteredMemos = filtered;
    _cachedFilter = _selectedFilter;
    _cachedMemosLength = memos.length;
    _cachedUserId = currentUserId;
    _cachedMemoIds = currentMemoIds;
    _cachedMemoVisibilityHash = visibilityHashString;

    return filtered;
  }

  /// 필터 변경 및 캐시 무효화
  void _updateFilter(MemoVisibilityFilter filter) {
    setState(() {
      _selectedFilter = filter;
      // 필터 변경 시 캐시 무효화
      _cachedFilteredMemos = null;
      _cachedFilter = null;
      _cachedMemosLength = null;
      _cachedUserId = null;
      _cachedMemoIds = null;
      _cachedMemoVisibilityHash = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final memosAsync = ref.watch(paginatedMemosProvider(widget.bookId));
    final currentUserId = ref.watch(authProvider).value?.id;

    return memosAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFFECECEC)),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SelectableText.rich(
            TextSpan(
              text: '${l10n.memoLoadErrorTitle}: ',
              style: const TextStyle(
                color: Colors.red,
                fontFamily: 'Pretendard',
                fontSize: 16,
              ),
              children: [
                TextSpan(
                  text: err.toString(),
                  style: const TextStyle(
                    color: Colors.red,
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (memos) {
        // 필터링된 메모 (메모이제이션 적용)
        final filteredMemos = _getFilteredMemos(memos, currentUserId);

        return LayoutBuilder(
          builder: (context, constraints) {
            // 반응형: 화면 너비에서 양쪽 20px씩 제외한 카드 너비
            final cardWidth = constraints.maxWidth - 40;

            return Column(
              children: [
                // 필터 버튼 (항상 표시)
                _buildVisibilityFilter(),
                // 메모 리스트 또는 빈 상태
                if (filteredMemos.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.note_add,
                            color: Colors.grey,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.memoEmptyTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.memoEmptyBody,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredMemos.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 40),
                      itemBuilder: (context, index) {
                        if (index == filteredMemos.length) {
                          // 필터링된 메모가 실제 로드된 메모보다 적으면
                          // 필터링으로 인해 일부 메모가 제외된 것이므로 더 이상 로드할 메모가 없을 수 있음
                          // 하지만 필터링된 메모가 실제 로드된 메모와 같을 때는 더 로드할 수 있음
                          final notifier = ref
                              .read(paginatedMemosProvider(widget.bookId)
                                  .notifier);
                          final hasMore = notifier.hasMore;
                          
                          // 필터링된 메모가 실제 로드된 메모보다 적으면 로딩 스피너를 표시하지 않음
                          // (필터링으로 인해 일부 메모가 제외되었을 가능성이 높음)
                          final shouldShowLoading = hasMore &&
                              filteredMemos.length == memos.length;
                          
                          return shouldShowLoading
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFECECEC),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink();
                        }
                        return BookDetailMemoCard(
                          memo: filteredMemos[index],
                          cardWidth: cardWidth,
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  /// MemoVisibility 필터 버튼 (모든 메모, 공개, 비공개)
  Widget _buildVisibilityFilter() {
    final l10n = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          PillFilterButton(
            label: memoVisibilityFilterLabel(l10n, MemoVisibilityFilter.all),
            isActive: _selectedFilter == MemoVisibilityFilter.all,
            onTap: () => _updateFilter(MemoVisibilityFilter.all),
            width: 77,
            fontSize: 12,
            activeFontWeight: FontWeight.w700,
            inactiveFontWeight: FontWeight.w400,
          ),
          const SizedBox(width: 12),
          PillFilterButton(
            label:
                memoVisibilityFilterLabel(l10n, MemoVisibilityFilter.public),
            isActive: _selectedFilter == MemoVisibilityFilter.public,
            onTap: () => _updateFilter(MemoVisibilityFilter.public),
            width: 53,
            fontSize: 12,
            activeFontWeight: FontWeight.w700,
            inactiveFontWeight: FontWeight.w400,
          ),
          const SizedBox(width: 12),
          PillFilterButton(
            label:
                memoVisibilityFilterLabel(l10n, MemoVisibilityFilter.private),
            isActive: _selectedFilter == MemoVisibilityFilter.private,
            onTap: () => _updateFilter(MemoVisibilityFilter.private),
            width: 64,
            fontSize: 12,
            activeFontWeight: FontWeight.w700,
            inactiveFontWeight: FontWeight.w400,
          ),
        ],
      ),
    );
  }
}
