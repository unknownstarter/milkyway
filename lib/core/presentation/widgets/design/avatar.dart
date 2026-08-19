import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// 원자: 사용자 표식(원형). 이미지 있으면 이미지, 없으면 이니셜.
/// 규격은 03-COMPONENTS.md: sm 34 / md 40, bg surface, border divider.
enum AvatarSize { sm, md }

class Avatar extends StatelessWidget {
  final String? imageUrl;
  final String? initial;
  final AvatarSize size;

  const Avatar({
    super.key,
    this.imageUrl,
    this.initial,
    this.size = AvatarSize.md,
  });

  double get _d => size == AvatarSize.sm ? 34 : 40;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return Container(
      width: _d,
      height: _d,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: hasImage
          ? Image.network(
              imageUrl!,
              width: _d,
              height: _d,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initialText(),
            )
          : _initialText(),
    );
  }

  Widget _initialText() {
    final ch = (initial != null && initial!.isNotEmpty)
        ? initial!.characters.first
        : '';
    return Text(
      ch,
      style: AppTypography.label.copyWith(color: AppColors.textSecondary),
    );
  }
}
