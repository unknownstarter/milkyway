import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import 'avatar.dart';
import 'chips.dart';
import 'cached_image.dart';

/// [text] 에서 [query] 와 겹치는 부분만 [match] 스타일로 바꾼 스팬을 만든다.
///
/// 검색 결과에서 "왜 이게 걸렸는지"를 보여주려고 쓴다. 책 제목으로 걸린 메모는
/// 본문에 검색어가 없어서, 하이라이트가 없으면 왜 나왔는지 알 수가 없다.
///
/// 대소문자는 무시한다. [query] 가 비면 통짜 하나를 돌려주므로 호출부가
/// 분기할 필요 없다.
List<TextSpan> highlightSpans(
  String text,
  String? query, {
  required TextStyle base,
  required TextStyle match,
}) {
  final needle = (query ?? '').trim().toLowerCase();
  if (needle.isEmpty) return [TextSpan(text: text, style: base)];

  final haystack = text.toLowerCase();
  final spans = <TextSpan>[];
  var cursor = 0;

  while (true) {
    final hit = haystack.indexOf(needle, cursor);
    if (hit < 0) break;
    if (hit > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, hit), style: base));
    }
    spans.add(TextSpan(
        text: text.substring(hit, hit + needle.length), style: match));
    cursor = hit + needle.length;
  }

  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: base));
  }
  return spans;
}

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

  /// 본문 최대 줄 수. 홈처럼 요약 노출 시 지정하면 초과분은 ...로 자른다.
  final int? maxLines;

  /// 메모 첨부 이미지(있으면 카드 안에 썸네일 노출).
  final String? imageUrl;

  /// 댓글 수(> 0이면 말풍선 아이콘 + 숫자 노출).
  final int commentCount;

  /// 이 메모가 답한 Lyra 물음 스냅샷(있으면 본문 위에 인용 라인).
  final String? lyraQuestion;

  /// 검색어. 주면 본문과 책 제목에서 겹치는 부분을 강조한다.
  /// 검색 화면 전용이라 기본값은 null 이고, 다른 화면은 아무것도 안 바뀐다.
  final String? highlight;

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
    this.maxLines,
    this.imageUrl,
    this.commentCount = 0,
    this.lyraQuestion,
    this.highlight,
  });

  /// [highlight] 가 있으면 강조한 Text.rich, 없으면 그냥 Text.
  /// 없을 때 굳이 Text.rich 로 안 가는 건, 이 카드를 쓰는 다른 화면들의
  /// 렌더 경로를 건드리지 않기 위해서다.
  Widget _text(
    String value,
    TextStyle style, {
    int? maxLines,
    TextOverflow? overflow,
  }) {
    final needle = (highlight ?? '').trim();
    if (needle.isEmpty) {
      return Text(value,
          maxLines: maxLines, overflow: overflow, style: style);
    }
    return Text.rich(
      TextSpan(
        children: highlightSpans(
          value,
          needle,
          base: style,
          match: style.copyWith(color: AppColors.accentGreen),
        ),
      ),
      maxLines: maxLines,
      overflow: overflow,
    );
  }

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
              _authorRow(context),
              const SizedBox(height: 12),
            ],
            if (lyraQuestion != null && lyraQuestion!.isNotEmpty) ...[
              _lyraLine(),
              const SizedBox(height: 8),
            ],
            _text(
              content,
              AppTypography.body.copyWith(color: AppColors.textPrimary),
              maxLines: maxLines,
              overflow: maxLines != null ? TextOverflow.ellipsis : null,
            ),
            if (imageUrl != null && imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.cover),
                child: CachedImage(
                  url: imageUrl,
                  width: double.infinity,
                  height: 180,
                  cacheWidth: 700,
                  fallback: Container(
                    height: 180,
                    color: AppColors.surfaceElevated,
                  ),
                ),
              ),
            ],
            if (bookTitle != null || page != null || commentCount > 0) ...[
              const SizedBox(height: 12),
              _metaRow(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _authorRow(BuildContext context) {
    final l10n = AppL10n.of(context);
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
                    LabelChip(text: l10n.commonMyMemo),
                  ],
                  if (edited) ...[
                    const SizedBox(width: 6),
                    LabelChip(
                        text: l10n.commonEdited, tone: ChipTone.accentSoft),
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

  /// 답한 Lyra 물음 인용 라인(초록 라벨 + 물음 요약).
  Widget _lyraLine() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 3, right: 6),
          child: Icon(Icons.auto_awesome, size: 12, color: AppColors.accentGreen),
        ),
        Expanded(
          child: Text(
            lyraQuestion!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            // 사유가 먼저 - 인용문은 보조 톤으로 죽이고 강조는 아이콘(초록)에만.
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _metaRow(BuildContext context) {
    final parts = <String>[
      if (bookTitle != null) bookTitle!,
      if (page != null) AppL10n.of(context).commonPageLabel(page!),
    ];
    return Row(
      children: [
        Expanded(
          child: _text(
            parts.join('  /  '),
            AppTypography.caption.copyWith(color: AppColors.textTertiary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (commentCount > 0) ...[
          const SizedBox(width: 8),
          const Icon(Icons.chat_bubble_outline,
              size: 13, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Text('$commentCount',
              style: AppTypography.caption
                  .copyWith(color: AppColors.textTertiary)),
        ],
      ],
    );
  }
}
