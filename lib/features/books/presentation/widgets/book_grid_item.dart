import 'package:flutter/material.dart';
import '../../../home/domain/models/book.dart';
import '../../../../core/presentation/widgets/design/cached_image.dart';

class BookGridItem extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  /// 표지 우상단 빨간 점: '안 본 남의 새 공개 메모'가 있으면 true.
  final bool showNewDot;

  const BookGridItem({
    super.key,
    required this.book,
    required this.onTap,
    this.showNewDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: CachedImage(
                url: book.coverUrl,
                fit: BoxFit.cover,
                cacheWidth: 300,
                fallback: Container(
                  color: Colors.grey.shade900,
                  child: const Icon(
                    Icons.book,
                    color: Colors.grey,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          if (showNewDot)
            const Positioned(
              top: 6,
              right: 6,
              child: _NewDot(),
            ),
        ],
      ),
    );
  }
}

/// 표지 위 빨간 점(테두리 없이 순수 점).
class _NewDot extends StatelessWidget {
  const _NewDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: const BoxDecoration(
        color: Color(0xFFFF3B30),
        shape: BoxShape.circle,
      ),
    );
  }
}
