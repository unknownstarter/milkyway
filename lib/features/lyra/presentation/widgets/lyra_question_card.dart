import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

/// Lyra 물음 카드. 순수 표현 위젯 - 계측/이동은 상위가 담당한다.
///
/// variant:
///  - bookDetail(기본): 라벨 + 물음 + CTA
///  - home: 책 헤더(미니 표지 + 제목 + 상태) + 라벨 + 물음 + CTA, 초록 딤 배경.
///    [bookTitle] 을 주면 home variant로 렌더된다.
class LyraQuestionCard extends StatelessWidget {
  final String question;
  final VoidCallback onAnswer;
  final String? bookTitle;
  final String? bookCoverUrl;
  final String? bookStatusLabel;

  const LyraQuestionCard({
    super.key,
    required this.question,
    required this.onAnswer,
    this.bookTitle,
    this.bookCoverUrl,
    this.bookStatusLabel,
  });

  bool get _isHome => bookTitle != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _isHome ? null : AppColors.surface,
        gradient: _isHome
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.accentGreen.withValues(alpha: 0.06),
                  AppColors.bgPrimary.withValues(alpha: 0.0),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(
          color: AppColors.accentGreen.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isHome) ...[
            _bookHeader(),
            const SizedBox(height: AppSpacing.base),
          ],
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.accentGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Lyra의 물음',
                style: AppTypography.caption.copyWith(
                  color: AppColors.accentGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            question,
            style: AppTypography.body.copyWith(
              color: AppColors.textBright,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: onAnswer,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit_outlined,
                    size: 16, color: AppColors.accentGreen),
                const SizedBox(width: 6),
                Text(
                  '이 물음에 메모 남기기',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookHeader() {
    return Row(
      children: [
        Container(
          width: 34,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(4),
          ),
          clipBehavior: Clip.antiAlias,
          child: (bookCoverUrl != null && bookCoverUrl!.isNotEmpty)
              ? Image.network(bookCoverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox())
              : const SizedBox(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bookTitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textBright,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (bookStatusLabel != null) ...[
                const SizedBox(height: 3),
                Text(bookStatusLabel!, style: AppTypography.caption),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
