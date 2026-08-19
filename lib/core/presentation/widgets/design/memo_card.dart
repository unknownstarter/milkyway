import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import 'avatar.dart';
import 'chips.dart';

/// 조합: 메모 카드(피드·책 상세 공용, 03-COMPONENTS.md ★핵심 재사용).
///
/// param 기반으로 variant를 표현한다:
///  - feed     : authorName + bookTitle + page
///  - bookDetail: authorName + page (bookTitle 생략)
///  - mine     : showMineTag=true
/// [edited]=true 면 `수정됨` 칩 노출(날짜는 caller가 수정일로 넘긴다).
class MemoCard extends StatelessWidget {
  final String content;
  final String? authorName;
  final String? authorImageUrl;
  final String? dateText;
  final bool edited;
  final bool showMineTag;
  final String? bookTitle;
  final int? page;
  final VoidCallback? onTap;

  const MemoCard({
    super.key,
    required this.content,
    this.authorName,
    this.authorImageUrl,
    this.dateText,
    this.edited = false,
    this.showMineTag = false,
    this.bookTitle,
    this.page,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (authorName != null) ...[
              _authorRow(),
              const SizedBox(height: 12),
            ],
            Text(
              content,
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
            ),
            if (bookTitle != null || page != null) ...[
              const SizedBox(height: 12),
              _metaRow(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _authorRow() {
    return Row(
      children: [
        Avatar(
          imageUrl: authorImageUrl,
          initial: authorName,
          size: AvatarSize.sm,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      authorName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label
                          .copyWith(color: AppColors.textBright),
                    ),
                  ),
                  if (showMineTag) ...[
                    const SizedBox(width: 6),
                    const LabelChip(text: '내 메모'),
                  ],
                  if (edited) ...[
                    const SizedBox(width: 6),
                    const LabelChip(text: '수정됨', tone: ChipTone.accentSoft),
                  ],
                ],
              ),
              if (dateText != null)
                Text(dateText!, style: AppTypography.caption),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metaRow() {
    final parts = <String>[
      if (bookTitle != null) bookTitle!,
      if (page != null) '$page쪽',
    ];
    return Row(
      children: [
        Expanded(
          child: Text(
            parts.join('  /  '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }
}
