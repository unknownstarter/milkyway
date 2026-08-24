import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/book.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/presentation/widgets/design/cached_image.dart';

class BookCard extends StatelessWidget {
  final Book? book;
  final VoidCallback onTap;

  const BookCard({
    super.key,
    this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (book == null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                '책 등록',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        if (book != null) {
          context.pushNamed(
            AppRoutes.bookDetailName,
            pathParameters: {'id': book!.id},
          );
        } else {
          onTap();
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book!.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              book!.author,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedImage(
                url: book!.coverUrl,
                width: double.infinity,
                height: 400,
                fit: BoxFit.cover,
                cacheWidth: 800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
