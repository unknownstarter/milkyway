import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// 조합: 토스 스타일 넛지 배너. 모서리 둥근 바 + 이모지/아이콘 + 제목/부제 + chevron.
/// 전체가 탭 영역. 은은한 강조가 필요한 유도 문구에 사용.
class BannerBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? emoji;
  final IconData? icon;
  final VoidCallback onTap;
  final bool accent; // true면 accent 소프트 배경(형광). 홈 넛지 배너는 tint 사용 권장.
  final Color? tint; // 컨테이너는 중립 유지, 아이콘 칩만 은은히 틴트(섹션 구분용)

  const BannerBar({
    super.key,
    required this.title,
    this.subtitle,
    this.emoji,
    this.icon,
    required this.onTap,
    this.accent = false,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: accent
              ? AppColors.accentGreen.withValues(alpha: 0.10)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accent
                ? AppColors.accentGreen.withValues(alpha: 0.30)
                : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            _leading(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyBold.copyWith(
                          color: AppColors.textBright, fontSize: 15)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right,
                size: 20,
                color: accent ? AppColors.accentGreen : AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _leading() {
    if (emoji != null) {
      return Text(emoji!, style: const TextStyle(fontSize: 22));
    }
    // 틴트가 있으면 은은한 아이콘 칩(컨테이너는 중립 유지, 섹션은 아이콘색으로만 구분).
    if (tint != null) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: tint!.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(icon ?? Icons.menu_book_outlined, size: 19, color: tint),
      );
    }
    return Icon(icon ?? Icons.menu_book_outlined,
        size: 22,
        color: accent ? AppColors.accentGreen : AppColors.textSecondary);
  }
}
