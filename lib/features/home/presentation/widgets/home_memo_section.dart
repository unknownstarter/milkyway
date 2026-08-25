import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/design/cached_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/book.dart';
import '../../../memos/domain/models/memo.dart';
import '../../../memos/presentation/providers/memo_provider.dart';
import '../providers/selected_book_provider.dart';
import '../../../../core/router/app_routes.dart';

/// 홈 화면의 메모 섹션
class HomeMemoSection extends ConsumerStatefulWidget {
  final List<Book> books;

  const HomeMemoSection({
    super.key,
    required this.books,
  });

  @override
  ConsumerState<HomeMemoSection> createState() => _HomeMemoSectionState();
}

class _HomeMemoSectionState extends ConsumerState<HomeMemoSection> {
  @override
  Widget build(BuildContext context) {
    if (widget.books.isEmpty) {
      return const _EmptyMemoState();
    }

    final selectedBookId = ref.watch(selectedBookIdProvider);
    
    // 선택된 책이 없거나 삭제된 책이 선택되어 있으면 첫 번째 책 선택
    final selectedBook = selectedBookId != null
        ? widget.books.firstWhere(
            (book) => book.id == selectedBookId,
            orElse: () => widget.books[0],
          )
        : widget.books[0];
    
    if (selectedBookId == null || selectedBook.id != selectedBookId) {
      // 선택된 책이 없거나 삭제된 책이 선택되어 있으면 첫 번째 책 선택 (빌드 완료 후)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(selectedBookIdProvider.notifier).state = selectedBook.id;
        }
      });
      return const _EmptyMemoState();
    }

    final memosAsync = ref.watch(bookMemosProvider(selectedBookId));

    return ClipRect(
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "내 메모" 제목 - 정확히 28px로 제한
          SizedBox(
            height: 28,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '내 메모',
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
          const SizedBox(height: 16),
          memosAsync.when(
            data: (memos) => _MemosList(memos: memos),
            loading: () => const _MemosLoadingState(),
            error: (error, stack) => _MemosErrorState(error: error),
          ),
        ],
      ),
    );
  }
}

/// 메모 리스트
class _MemosList extends StatelessWidget {
  final List<Memo> memos;

  const _MemosList({required this.memos});

  @override
  Widget build(BuildContext context) {
    if (memos.isEmpty) {
      return const _EmptyMemosList();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final memo in memos) _MemoCard(memo: memo),
        ],
      ),
    );
  }
}

/// 메모 카드
class _MemoCard extends StatelessWidget {
  final Memo memo;

  const _MemoCard({required this.memo});

  @override
  Widget build(BuildContext context) {
    final hasImage = memo.imageUrl != null && memo.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => context.pushNamed(
            AppRoutes.memoDetailName,
            pathParameters: {'id': memo.id},
          ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 40),
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(12),
        ),
        child: hasImage
            ? _MemoCardWithImage(memo: memo)
            : _MemoCardTextOnly(memo: memo),
      ),
    );
  }
}

/// 텍스트만 있는 메모 카드
class _MemoCardTextOnly extends StatelessWidget {
  final Memo memo;

  const _MemoCardTextOnly({required this.memo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            memo.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              height: 24 / 16,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  memo.bookTitle,
                  style: const TextStyle(
                    color: Color(0xFF838383),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w300,
                    height: 24 / 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (memo.page != null)
                Text(
                  'p ${memo.page}',
                  style: const TextStyle(
                    color: Color(0xFF838383),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w300,
                    height: 24 / 16,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 이미지가 있는 메모 카드
class _MemoCardWithImage extends StatelessWidget {
  final Memo memo;

  const _MemoCardWithImage({required this.memo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  memo.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    height: 24 / 16,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 15),
              SizedBox(
                width: 80,
                height: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedImage(
                    url: memo.imageUrl,
                    width: 80,
                    height: 120,
                    fit: BoxFit.cover,
                    cacheWidth: 240,
                    fallback: Container(
                      width: 80,
                      height: 120,
                      color: Colors.grey.shade900,
                      child: const Icon(
                        Icons.image,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  memo.bookTitle,
                  style: const TextStyle(
                    color: Color(0xFF838383),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w300,
                    height: 24 / 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (memo.page != null)
                Text(
                  'p ${memo.page}',
                  style: const TextStyle(
                    color: Color(0xFF838383),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w300,
                    height: 24 / 16,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 빈 메모 상태
class _EmptyMemoState extends StatelessWidget {
  const _EmptyMemoState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        '메모가 없습니다',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }
}

/// 빈 메모 리스트
class _EmptyMemosList extends ConsumerWidget {
  const _EmptyMemosList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedBookId = ref.watch(selectedBookIdProvider);

    return GestureDetector(
      onTap: () {
        if (selectedBookId != null) {
          context.pushNamed(
            AppRoutes.memoCreateName,
            queryParameters: {'bookId': selectedBookId},
          );
        }
      },
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
            const Text(
              '아직 메모가 없습니다',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '첫 번째 메모를 작성해보세요',
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

/// 메모 로딩 상태
class _MemosLoadingState extends StatelessWidget {
  const _MemosLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        '메모를 불러오는 중...',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }
}

/// 메모 에러 상태
class _MemosErrorState extends StatelessWidget {
  final Object error;

  const _MemosErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SelectableText.rich(
        TextSpan(
          text: '메모를 불러오는 중 오류가 발생했습니다: $error',
          style: const TextStyle(
            color: Colors.red,
            fontSize: 14,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }
}

