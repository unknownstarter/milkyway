import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/design/cached_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/book.dart';
import '../providers/selected_book_provider.dart';
import '../../../../core/router/app_routes.dart';

/// 읽고 있는 책 섹션 (확장된 형태)
class ReadingBooksSection extends ConsumerWidget {
  final List<Book> books;
  final PageController pageController;
  final ScrollController scrollController;
  final ValueNotifier<bool> isHorizontalDraggingNotifier;
  final bool hasResetPageController;
  final VoidCallback onPageControllerReset;

  const ReadingBooksSection({
    super.key,
    required this.books,
    required this.pageController,
    required this.scrollController,
    required this.isHorizontalDraggingNotifier,
    required this.hasResetPageController,
    required this.onPageControllerReset,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (books.isEmpty) {
      return const SizedBox.shrink();
    }

    // 선택된 책 ID watch (변경 시 자동 동기화)
    final selectedBookId = ref.watch(selectedBookIdProvider);

    // 선택된 책 ID 설정 (빌드 완료 후)
    if (books.length == 1) {
      if (selectedBookId != books[0].id) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(selectedBookIdProvider.notifier).state = books[0].id;
        });
      }
    }

    // expanded 상태일 때 항상 PageController 동기화
    // 축소→확장 전환 시 선택된 책으로 바로 표시
    if (scrollController.hasClients && pageController.hasClients) {
      final scrollPosition = scrollController.position.pixels;
      final isExpanded = scrollPosition < 10; // expanded 상태 체크 (맨 위)
      
      if (isExpanded && selectedBookId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (pageController.hasClients) {
            final selectedIndex = books.indexWhere(
              (book) => book.id == selectedBookId,
            );
            if (selectedIndex != -1) {
              final currentPage = pageController.page?.round() ?? 0;
              if (currentPage != selectedIndex) {
                pageController.jumpToPage(selectedIndex);
              }
            }
          }
        });
      }
    }

    // 정확한 높이 계산: 제목(28px) + 간격(16px) + 책 높이(191px) = 235px
    const double titleHeight = 28.0;
    const double spacing = 16.0;
    const double bookHeight = 191.0;

    return ClipRect(
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "읽고 있는 책" 제목 (정확히 28px)
          SizedBox(
            height: titleHeight,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '읽고 있는 책',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: spacing),
          // 책 스와이프 (정확히 191px)
          SizedBox(
            height: bookHeight,
            child: books.length == 1
                ? _SingleBookView(book: books[0])
                : _BookSwipeView(
                    books: books,
                    pageController: pageController,
                    scrollController: scrollController,
                    isHorizontalDraggingNotifier: isHorizontalDraggingNotifier,
                    hasResetPageController: hasResetPageController,
                    onPageControllerReset: onPageControllerReset,
                  ),
          ),
        ],
      ),
    );
  }
}

/// 축소된 형태: 작은 카드
class CollapsedReadingBooksSection extends ConsumerWidget {
  final List<Book> books;

  const CollapsedReadingBooksSection({
    super.key,
    required this.books,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (books.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedBookId = ref.watch(selectedBookIdProvider);
    // 안전한 책 선택: selectedBookId가 있으면 해당 책, 없으면 첫 번째 책
    final selectedBook = selectedBookId != null
        ? books.firstWhere(
            (book) => book.id == selectedBookId,
            orElse: () => books.isNotEmpty
                ? books[0]
                : throw StateError('No books available'),
          )
        : (books.isNotEmpty
            ? books[0]
            : throw StateError('No books available'));

    const double cardHeight = 108.0;

    return ClipRect(
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        height: cardHeight,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: () {
              // 선택된 책 ID 업데이트
              ref.read(selectedBookIdProvider.notifier).state =
                  selectedBook.id;
              context.pushNamed(
                AppRoutes.bookDetailName,
                pathParameters: {'id': selectedBook.id},
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: cardHeight,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 작은 책 표지 (54x76)
                    SizedBox(
                      width: 54,
                      height: 76,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: selectedBook.coverUrl != null &&
                                selectedBook.coverUrl!.isNotEmpty
                            ? CachedImage(
                                url: selectedBook.coverUrl,
                                width: 54,
                                height: 76,
                                fit: BoxFit.cover,
                                cacheWidth: 162,
                                fallback: _SmallBookPlaceholder(),
                              )
                            : _SmallBookPlaceholder(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 책 정보 - 좌측 정렬
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selectedBook.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Pretendard',
                              height: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.left,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  selectedBook.author,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w300,
                                    fontFamily: 'Pretendard',
                                    height: 1.0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (selectedBook.publisher != null &&
                                  selectedBook.publisher!.isNotEmpty) ...[
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    selectedBook.publisher!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w300,
                                      fontFamily: 'Pretendard',
                                      height: 1.0,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 단일 책 표시
class _SingleBookView extends ConsumerWidget {
  final Book book;

  const _SingleBookView({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 책이 하나일 때도 여러 책일 때와 동일한 확대 효과 적용 (scale 1.3)
    return Center(
      child: Transform.scale(
        scale: 1.3,
        child: GestureDetector(
          onTap: () {
            // 선택된 책 ID 업데이트
            ref.read(selectedBookIdProvider.notifier).state = book.id;
            context.pushNamed(
              AppRoutes.bookDetailName,
              pathParameters: {'id': book.id},
            );
          },
          child: _BookCover(
            book: book,
            width: 104,
            height: 147,
            opacity: 1.0,
          ),
        ),
      ),
    );
  }
}

/// 여러 책 스와이프 뷰
class _BookSwipeView extends ConsumerStatefulWidget {
  final List<Book> books;
  final PageController pageController;
  final ScrollController scrollController;
  final ValueNotifier<bool> isHorizontalDraggingNotifier;
  final bool hasResetPageController;
  final VoidCallback onPageControllerReset;

  const _BookSwipeView({
    required this.books,
    required this.pageController,
    required this.scrollController,
    required this.isHorizontalDraggingNotifier,
    required this.hasResetPageController,
    required this.onPageControllerReset,
  });

  @override
  ConsumerState<_BookSwipeView> createState() => _BookSwipeViewState();
}

class _BookSwipeViewState extends ConsumerState<_BookSwipeView> {
  String? _lastSyncedBookId;

  @override
  void initState() {
    super.initState();
    // PageController 초기화: 선택된 책의 인덱스로 즉시 설정
    // 뷰를 그릴 때 무조건 선택한 책 ID로 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.pageController.hasClients) return;
      
      // 선택된 책 ID 읽기 (nullable 처리)
      final selectedBookId = ref.read(selectedBookIdProvider);
      int targetIndex = 0; // 기본값: 첫 번째 책 (신규 회원 고려)
      
      if (selectedBookId != null) {
        final selectedIndex = widget.books.indexWhere(
          (book) => book.id == selectedBookId,
        );
        if (selectedIndex != -1) {
          targetIndex = selectedIndex;
        }
      }
      
      // PageController를 선택된 책 인덱스로 즉시 설정
      final currentPage = widget.pageController.page?.round();
      if (currentPage == null || currentPage != targetIndex) {
        widget.pageController.jumpToPage(targetIndex);
      }
      
      _lastSyncedBookId = selectedBookId;
      
      if (!widget.hasResetPageController && mounted) {
        widget.onPageControllerReset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // selectedBookIdProvider 변경 감지: 실제 변경 시에만 동기화
    // GoRouter가 페이지를 캐싱하므로 뒤로가기 후에는 상태가 유지되고 동기화 불필요
    ref.listen<String?>(selectedBookIdProvider, (previous, next) {
      // 이전 값과 다르고, 실제로 변경이 필요할 때만 동기화
      if (next != null && 
          next != _lastSyncedBookId &&
          widget.pageController.hasClients) {
            final selectedIndex = widget.books.indexWhere(
          (book) => book.id == next,
            );
            if (selectedIndex != -1) {
              final currentPage = widget.pageController.page?.round() ?? 0;
              if (currentPage != selectedIndex) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && widget.pageController.hasClients) {
                widget.pageController.jumpToPage(selectedIndex);
                _lastSyncedBookId = next;
              }
            });
          } else {
            _lastSyncedBookId = next;
          }
        }
      }
    });

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          if (!widget.isHorizontalDraggingNotifier.value &&
              widget.scrollController.hasClients) {
            widget.isHorizontalDraggingNotifier.value = true;
            widget.scrollController.position.jumpTo(
              widget.scrollController.position.pixels,
            );
          }
        } else if (notification is ScrollUpdateNotification) {
          if (notification.scrollDelta != null &&
              notification.scrollDelta!.abs() > 0) {
            if (!widget.isHorizontalDraggingNotifier.value &&
                widget.scrollController.hasClients) {
              widget.isHorizontalDraggingNotifier.value = true;
            }
          }
        } else if (notification is ScrollEndNotification) {
          if (widget.isHorizontalDraggingNotifier.value) {
            widget.isHorizontalDraggingNotifier.value = false;
          }
        }
        return true;
      },
      child: PageView.builder(
        controller: widget.pageController,
        physics: const PageScrollPhysics(),
        scrollDirection: Axis.horizontal,
        allowImplicitScrolling: false,
        onPageChanged: (index) {
          ref.read(selectedBookIdProvider.notifier).state =
              widget.books[index].id;
        },
        itemCount: widget.books.length,
        itemBuilder: (context, index) {
          return _AnimatedBookItem(
            books: widget.books,
            index: index,
            pageController: widget.pageController,
          );
        },
      ),
    );
  }
}

/// 애니메이션이 적용된 책 아이템
class _AnimatedBookItem extends ConsumerWidget {
  final List<Book> books;
  final int index;
  final PageController pageController;

  const _AnimatedBookItem({
    required this.books,
    required this.index,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedBuilder(
      animation: pageController,
      builder: (context, child) {
        double value = 0.0;
        if (pageController.position.haveDimensions) {
          value = index.toDouble() - (pageController.page ?? 0.0);
          value = (value * 0.4).clamp(-1.0, 1.0);
        } else {
          value = index == 0 ? 0.0 : (index.toDouble() * 0.4).clamp(0.0, 1.0);
        }

        final distance = value.abs().clamp(0.0, 1.0);
        final scale = 1.3 - (distance * 0.66);
        final opacity = 1.0 - (distance * 0.7);

        return Transform.scale(
          scale: scale,
          child: Center(
            child: GestureDetector(
              onTap: () {
                // 선택된 책 ID 업데이트
                ref.read(selectedBookIdProvider.notifier).state =
                    books[index].id;
                context.pushNamed(
                  AppRoutes.bookDetailName,
                  pathParameters: {'id': books[index].id},
                );
              },
              child: _BookCover(
                book: books[index],
                width: 104,
                height: 147,
                opacity: opacity.clamp(0.3, 1.0),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 책 표지 위젯
class _BookCover extends StatelessWidget {
  final Book book;
  final double width;
  final double height;
  final double opacity;

  const _BookCover({
    required this.book,
    required this.width,
    required this.height,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: opacity,
          child: book.coverUrl != null && book.coverUrl!.isNotEmpty
              ? CachedImage(
                  url: book.coverUrl,
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  cacheWidth: 700,
                  fallback: _BookPlaceholder(width: width, height: height),
                )
              : _BookPlaceholder(width: width, height: height),
        ),
      ),
    );
  }
}

class _BookPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;

  const _BookPlaceholder({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF1A1A1A),
      child: const Center(
        child: Icon(
          Icons.book,
          color: Colors.grey,
          size: 48,
        ),
      ),
    );
  }
}

class _SmallBookPlaceholder extends StatelessWidget {
  const _SmallBookPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 76,
      color: Colors.grey.shade900,
      child: const Icon(
        Icons.book,
        color: Colors.grey,
        size: 24,
      ),
    );
  }
}

