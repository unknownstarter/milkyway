import 'package:flutter/material.dart';
import '../../../home/domain/models/book.dart';

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
              child: Image.network(
                book.coverUrl ?? 'https://picsum.photos/200/300',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
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

/// 표지 위 빨간 점. 배경과 대비되도록 얇은 테두리를 둔다.
class _NewDot extends StatelessWidget {
  const _NewDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B30),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF181818), width: 1.5),
      ),
    );
  }
}
