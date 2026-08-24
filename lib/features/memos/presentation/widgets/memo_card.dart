import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/design/cached_image.dart';
import '../../domain/models/memo.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';

class MemoCard extends StatelessWidget {
  final Memo memo;

  const MemoCard({
    super.key,
    required this.memo,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          AppRoutes.memoDetailName,
          pathParameters: {'id': memo.id},
        );
      },
      child: Card(
        elevation: 0,
        color: const Color(0xFF181818),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade800),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 책 정보 섹션
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 책 표지
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 40,
                      height: 56,
                      child: CachedImage(
                        url: memo.books['cover_url'] as String?,
                        fit: BoxFit.cover,
                        cacheWidth: 168,
                        fallback: Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.book, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 책 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MediaQuery(
                          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
                          child: Text(
                            memo.bookTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                memo.books['author'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (memo.page != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'P.${memo.page}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
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
            // 메모 이미지 섹션
            if (memo.imageUrl != null && memo.imageUrl!.isNotEmpty)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade800),
                    bottom: BorderSide(color: Colors.grey.shade800),
                  ),
                ),
                child: CachedImage(
                  url: memo.imageUrl,
                  fit: BoxFit.cover,
                  cacheWidth: 700,
                  fallback: const SizedBox(),
                ),
              ),
            // 메모 내용 섹션
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memo.content,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.white,
                    ),
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatDate(memo.updatedAt ?? memo.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
