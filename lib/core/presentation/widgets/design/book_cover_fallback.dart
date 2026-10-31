import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// 표지 이미지가 없을 때(또는 불러오기 실패 시) 대신 그리는 폴백.
///
/// 기본 아이콘만 있으면 어떤 책인지 알 수 없다. 제목(최대 4줄)과 저자를 가운데에
/// 그린다. 표지를 [CachedImage] 로 그리는 모든 곳의 `fallback:` 에 이걸 쓴다.
/// 폭이 좁으면(작은 썸네일) 글자를 줄이고 저자는 생략한다.
class BookCoverFallback extends StatelessWidget {
  final String title;
  final String? author;
  final double? width;
  final double? height;

  const BookCoverFallback({
    super.key,
    required this.title,
    this.author,
    this.width,
    this.height,
  });

  /// 이 폭 미만이면 작은 썸네일로 본다.
  static const double _compactWidth = 70;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceElevated,
      child: LayoutBuilder(
        builder: (context, c) {
          final compact = c.maxWidth < _compactWidth;
          final showAuthor = !compact && (author?.trim().isNotEmpty ?? false);
          return Padding(
            padding: EdgeInsets.all(compact ? 4 : 10),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: compact ? 3 : 4,
                    overflow: TextOverflow.fade,
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textBright,
                      fontWeight: FontWeight.w700,
                      fontSize: compact ? 9 : 13,
                      height: 1.25,
                    ),
                  ),
                  if (showAuthor) ...[
                    const SizedBox(height: 6),
                    Text(
                      author!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
