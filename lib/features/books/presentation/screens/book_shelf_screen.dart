import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../widgets/book_grid_item.dart';
import '../../../books/presentation/providers/user_books_provider.dart';
import '../../../../core/presentation/widgets/add_floating_action_button.dart';
import '../../../../core/presentation/widgets/pill_filter_button.dart';
import '../../../home/domain/models/book.dart';
import '../../../home/domain/models/book_status.dart';
import '../../../home/domain/models/book_status_extension.dart';

/// 필터 옵션 데이터 클래스
class _FilterOption {
  final String label;
  final BookStatus? status;
  final double width;

  const _FilterOption({
    required this.label,
    required this.status,
    required this.width,
  });
}

class BookShelfScreen extends ConsumerStatefulWidget {
  const BookShelfScreen({super.key});

  @override
  ConsumerState<BookShelfScreen> createState() => _BookShelfScreenState();
}

class _BookShelfScreenState extends ConsumerState<BookShelfScreen> {
  BookStatus? _selectedFilter;
  
  // 메모이제이션: 필터링 결과 캐싱
  List<Book>? _cachedFilteredBooks;
  BookStatus? _cachedFilter;
  List<Book>? _cachedAllBooks;

  // 필터 옵션 리스트 (코드 중복 제거)
  static final List<_FilterOption> _filterOptions = [
    const _FilterOption(label: '모든 책', status: null, width: 67),
    _FilterOption(
      label: BookStatus.wantToRead.value,
      status: BookStatus.wantToRead,
      width: 77,
    ),
    _FilterOption(
      label: BookStatus.reading.value,
      status: BookStatus.reading,
      width: 67,
    ),
    _FilterOption(
      label: BookStatus.completed.value,
      status: BookStatus.completed,
      width: 53,
    ),
  ];

  // 필터링된 책 목록 (extension 메서드 사용 + 메모이제이션)
  // GoRouter가 페이지를 캐싱하므로 뒤로가기 후에도 상태가 유지됨
  List<Book> _getFilteredBooks(List<Book> books) {
    // 캐시가 유효한지 확인 (리스트 길이와 필터로 비교하여 참조 비교 문제 해결)
    if (_cachedFilteredBooks != null &&
        _cachedFilter == _selectedFilter &&
        _cachedAllBooks != null &&
        _cachedAllBooks!.length == books.length) {
      // 리스트 내용이 실제로 변경되었는지 확인 (ID 기반)
      final cachedIds = _cachedAllBooks!.map((b) => b.id).toSet();
      final currentIds = books.map((b) => b.id).toSet();
      if (cachedIds == currentIds) {
      return _cachedFilteredBooks!;
      }
    }

    // extension 메서드를 사용하여 필터링
    final filtered = _selectedFilter.filterBooks(books);
    
    // 캐시 업데이트
    _cachedFilteredBooks = filtered;
    _cachedFilter = _selectedFilter;
    _cachedAllBooks = List.from(books); // 새 리스트로 복사하여 참조 비교 문제 해결
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(userBooksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181818),
        surfaceTintColor: Colors.transparent, // Material 3에서 스크롤 시 색상 변경 방지
        elevation: 0,
        title: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: const Text(
            'Books',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 20,
              height: 28 / 20,
            ),
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: booksAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFECECEC)),
        ),
        error: (err, stack) => Center(
          child: SelectableText.rich(
            TextSpan(text: '에러: $err', style: TextStyle(color: Colors.red)),
          ),
        ),
        data: (books) {
          final filteredBooks = _getFilteredBooks(books);

          if (filteredBooks.isEmpty) {
            return Column(
              children: [
                _buildFilterButtons(),
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        context.pushNamed(AppRoutes.bookSearchName);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.note_add,
                            color: Colors.grey,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                              textScaler: TextScaler.linear(1.0),
                            ),
                            child: const Text(
                              '새로운 책을 추가해주세요',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              _buildFilterButtons(),
              Expanded(
                child: _BookGrid(books: filteredBooks),
              ),
            ],
          );
        },
      ),
      floatingActionButton: const AddFloatingActionButton(),
    );
  }

  Widget _buildFilterButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: _filterOptions
            .map((option) => [
                  PillFilterButton(
                    label: option.label,
                    isActive: _selectedFilter == option.status,
                    onTap: () {
                      setState(() {
                        _selectedFilter = option.status;
                        // 필터 변경 시 캐시 무효화
                        _cachedFilteredBooks = null;
                        _cachedFilter = null;
                        _cachedAllBooks = null;
                      });
                    },
                    width: option.width,
        ),
                  if (option != _filterOptions.last)
                    const SizedBox(width: 13),
                ])
            .expand((widgets) => widgets)
            .toList(),
      ),
    );
  }
}

class _BookGrid extends StatelessWidget {
  final List<Book> books;
  const _BookGrid({required this.books});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.7,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return BookGridItem(
          book: book,
          onTap: () => context.pushNamed(
                AppRoutes.bookDetailName,
                pathParameters: {'id': book.id},
              ),
        );
      },
    );
  }
}
