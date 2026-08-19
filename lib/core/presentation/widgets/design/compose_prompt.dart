import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import 'avatar.dart';

/// 조합: 메모 쓰기 진입(메모 탭 상단). Avatar + 안내 문구, 탭하면 작성 화면.
class ComposePrompt extends StatelessWidget {
  final String? avatarUrl;
  final String? initial;
  final String hint;
  final VoidCallback onTap;

  const ComposePrompt({
    super.key,
    this.avatarUrl,
    this.initial,
    this.hint = '오늘 읽은 문장을 남겨보세요',
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Avatar(imageUrl: avatarUrl, initial: initial, size: AvatarSize.sm),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hint,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
            const Icon(Icons.edit_outlined,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
