import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import 'cached_image.dart';

/// 조합: "다른 사람이 담은 책" 표지 카드(가로 레일). 표지 92x136 + 제목 + 메타.
class DiscoveryCover extends StatelessWidget {
  final String title;
  final String author;
  final String? coverUrl;
  final String meta;
  final VoidCallback onTap;

  const DiscoveryCover({
    super.key,
    required this.title,
    required this.author,
    this.coverUrl,
    required this.meta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 92,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 92,
              height: 136,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.cover),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x80000000),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: CachedImage(url: coverUrl, fallback: _placeholder()),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: AppColors.textBright,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textTertiary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.textBright,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
          const Spacer(),
          Text(
            author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption
                .copyWith(color: AppColors.textTertiary, fontSize: 9.5),
          ),
        ],
      ),
    );
  }
}
