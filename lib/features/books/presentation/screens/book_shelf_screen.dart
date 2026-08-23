import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../widgets/book_grid_item.dart';
import '../providers/book_shelf_provider.dart';
import '../../../../core/presentation/widgets/design/segment_filter.dart';
import '../../../../core/presentation/widgets/design/glass_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../home/domain/models/book_status.dart';

/// 필터 옵션 데이터 클래스
class _FilterOption {
  final String label;
  final BookStatus? status;

  const _FilterOption({
    required this.label,
    required this.status,
  });
}

class BookShelfScreen extends ConsumerStatefulWidget {
  const BookShelfScreen({super.key});

  @override
  ConsumerState<BookShelfScreen> createState() => _BookShelfScreenState();
}

class _BookShelfScreenState extends ConsumerState<BookShelfScreen> {
  BookStatus? _selectedFilter;

  // 필터 옵션 리스트 (코드 중복 제거)
  static final List<_FilterOption> _filterOptions = [
    const _FilterOption(label: '모든 책', status: null),
    _FilterOption(
        label: BookStatus.wantToRead.value, status: BookStatus.wantToRead),
    _FilterOption(label: BookStatus.reading.value, status: BookStatus.reading),
    _FilterOption(
        label: BookStatus.completed.value, status: BookStatus.completed),
  ];

  /// 랭킹 정렬은 provider가 처리. 여기선 상태 필터만 그 순서 위에 적용.
  List<ShelfBook> _applyStatusFilter(List<ShelfBook> books) {
    if (_selectedFilter == null) return books;
    return books.where((s) => s.book.status == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(bookShelfProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      extendBodyBehindAppBar: true,
      appBar: glassAppBar(
        title: const Text('Books', style: AppTypography.title),
        bottom: filterBar(_statusFilter()),
      ),
      body: booksAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFECECEC)),
        ),
        error: (err, stack) => Center(
          child: SelectableText.rich(
            TextSpan(
                text: '에러: $err', style: const TextStyle(color: Colors.red)),
          ),
        ),
        data: (books) {
          final filteredBooks = _applyStatusFilter(books);
          final topPad = glassTopPadding(context, bottomHeight: kFilterBarHeight);
          if (filteredBooks.isEmpty) return _emptyState();
          return _BookGrid(books: filteredBooks, topPadding: topPad);
        },
      ),
    );
  }

  /// 표준 필터바에 들어갈 상태 필터(전체/읽는중/완독 등). 메모탭과 동일한 SegmentFilter.
  Widget _statusFilter() {
    final selected =
        _filterOptions.indexWhere((o) => o.status == _selectedFilter);
    return SegmentFilter(
      segments: _filterOptions.map((o) => o.label).toList(),
      selectedIndex: selected < 0 ? 0 : selected,
      onChanged: (i) => setState(() {
        _selectedFilter = _filterOptions[i].status;
      }),
    );
  }

  Widget _emptyState() {
    return Center(
      child: GestureDetector(
        onTap: () => context.pushNamed(AppRoutes.bookSearchName),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.note_add, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            Text('새로운 책을 추가해주세요',
                style: AppTypography.body.copyWith(color: AppColors.textBright)),
          ],
        ),
      ),
    );
  }
}

class _BookGrid extends StatelessWidget {
  final List<ShelfBook> books;
  final double topPadding;
  const _BookGrid({required this.books, this.topPadding = 0});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 110),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.7,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final item = books[index];
        final book = item.book;
        return BookGridItem(
          book: book,
          showNewDot: item.showNewDot,
          onTap: () => context.pushNamed(
                AppRoutes.bookDetailName,
                pathParameters: {'id': book.id},
              ),
        );
      },
    );
  }
}
