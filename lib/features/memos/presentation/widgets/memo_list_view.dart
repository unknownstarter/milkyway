import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/memo_provider.dart';
import '../providers/memo_report_provider.dart';
import '../../domain/models/memo_filter.dart';
import 'book_detail_memo_card.dart';
import '../../../../core/presentation/widgets/pill_filter_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../memo_l10n.dart';

/// 책 상세 화면에서 사용하는 메모 리스트 뷰
/// 
/// - [bookId]가 제공되면: 특정 책의 메모만 표시 (book_detail_screen용)
/// - 필터링, 로딩, 에러, 빈 상태 처리 포함
/// - 필터링 결과 메모이제이션으로 성능 최적화
class MemoListView extends ConsumerStatefulWidget {
  final String bookId;
  final bool showFilterButtons;

  const MemoListView({
    super.key,
    required this.bookId,
    this.showFilterButtons = true,
  });

  @override
  ConsumerState<MemoListView> createState() => _MemoListViewState();
}

class _MemoListViewState extends ConsumerState<MemoListView> {
  MemoFilter _selectedFilter = MemoFilter.myMemos;
  DateTime? _lastScrollTime; // 스크롤 throttle을 위한 마지막 스크롤 시간

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    // 필터에 따라 다른 provider 사용
    // "내가 쓴": 현재 사용자의 메모만
    // "모든 메모": 해당 책의 모든 공개 메모 (다른 유저의 것도 포함, 페이지네이션 지원)
    final memosAsyncValue = _selectedFilter == MemoFilter.myMemos
        ? ref.watch(bookMemosProvider(widget.bookId))
        : ref.watch(paginatedPublicBookMemosProvider(widget.bookId));

    // "모든 메모" 필터의 경우 페이지네이션 상태 확인
    final paginatedNotifier = _selectedFilter == MemoFilter.all
        ? ref.read(paginatedPublicBookMemosProvider(widget.bookId).notifier)
        : null;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // 스크롤이 하단에 가까워지면 더 많은 메모 로드
        if (notification is ScrollUpdateNotification) {
          final metrics = notification.metrics;
          
          // Throttle: 마지막 스크롤로부터 300ms 이내면 무시
          final now = DateTime.now();
          if (_lastScrollTime != null &&
              now.difference(_lastScrollTime!).inMilliseconds < 300) {
            return false;
          }
          
          if (metrics.pixels >= metrics.maxScrollExtent - 200) {
            if (_selectedFilter == MemoFilter.all &&
                paginatedNotifier != null &&
                paginatedNotifier.hasMore &&
                !paginatedNotifier.isLoading) {
              _lastScrollTime = now;
              paginatedNotifier.loadMoreMemos();
            }
          }
        }
        return false;
      },
      child: LayoutBuilder(
      builder: (context, constraints) {
        // 반응형: 화면 너비에서 양쪽 20px씩 제외한 카드 너비
        final cardWidth = constraints.maxWidth - 40;
        
        // 신고한 메모 ID 목록 조회 (공개 메모 필터에서만 사용)
        final hiddenMemoIdsAsync = _selectedFilter == MemoFilter.all
            ? ref.watch(hiddenMemoIdsProvider)
            : const AsyncValue.data(<String>{});

        return memosAsyncValue.when(
          data: (memos) {
            // 신고한 메모 필터링
            final hiddenMemoIds = hiddenMemoIdsAsync.value ?? <String>{};
            final filteredMemos = memos
                .where((memo) => !hiddenMemoIds.contains(memo.id))
                .toList();

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 필터 버튼 (showFilterButtons가 true일 때만 표시, 항상 표시)
                if (widget.showFilterButtons) ...[
                  _buildMemoFilter(),
                  const SizedBox(height: 32),
                ],
                // 메모 리스트 또는 빈 상태
                if (filteredMemos.isEmpty)
                  _buildEmptyMemos()
                else
                  // Column으로 변경하여 오버플로우 방지
                  // ListView.builder는 itemExtent 고정으로 인한 오버플로우 발생
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 8, // 메모하기 버튼과 겹치지 않도록 최소 여백만 유지
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...filteredMemos
                            .map((memo) => BookDetailMemoCard(
                                  memo: memo,
                                  cardWidth: cardWidth,
                                ))
                            .toList(),
                        // 페이지네이션 로딩 인디케이터
                        if (_selectedFilter == MemoFilter.all)
                          _buildPaginationLoader(),
                      ],
                    ),
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFECECEC),
              ),
            ),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${l10n.memoLoadErrorTitle}: $error',
              style: const TextStyle(
                color: Colors.red,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        );
      },
      ),
    );
  }

  /// 필터 변경
  void _updateFilter(MemoFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });
    // 필터 변경 시 provider 무효화하여 새로운 데이터 가져오기
    if (filter == MemoFilter.myMemos) {
      ref.invalidate(bookMemosProvider(widget.bookId));
    } else {
      // 페이지네이션 provider 초기화
      ref.read(paginatedPublicBookMemosProvider(widget.bookId).notifier)
          .loadInitialMemos();
    }
  }

  Widget _buildPaginationLoader() {
    final notifier = ref.read(
      paginatedPublicBookMemosProvider(widget.bookId).notifier,
    );
    
    // 로딩 중이고 더 불러올 데이터가 있을 때만 표시
    if (!notifier.hasMore || !notifier.isLoading) {
      return const SizedBox.shrink();
    }

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFECECEC),
        ),
      ),
    );
  }

  Widget _buildMemoFilter() {
    final l10n = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          PillFilterButton(
            label: memoFilterLabel(l10n, MemoFilter.myMemos),
            isActive: _selectedFilter == MemoFilter.myMemos,
            onTap: () => _updateFilter(MemoFilter.myMemos),
            width: 90,
            fontSize: 16,
            activeFontWeight: FontWeight.w400,
            inactiveFontWeight: FontWeight.w400,
          ),
          const SizedBox(width: 12),
          PillFilterButton(
            label: memoFilterLabel(l10n, MemoFilter.all),
            isActive: _selectedFilter == MemoFilter.all,
            onTap: () => _updateFilter(MemoFilter.all),
            width: 104,
            fontSize: 16,
            activeFontWeight: FontWeight.w400,
            inactiveFontWeight: FontWeight.w400,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMemos() {
    final l10n = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 120, // 메모하기 버튼(41px) + 상하 padding(40px) + 여유 공간(39px)
      ),
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
    );
  }
}

