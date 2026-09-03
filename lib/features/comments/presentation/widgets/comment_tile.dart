import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/presentation/widgets/design/avatar.dart';
import '../../../../core/presentation/widgets/design/chips.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/comment.dart';

/// 조합: 댓글 한 줄(아바타 + 이름/시간 + 본문 + 더보기).
/// [isMine]이면 더보기 = 수정/삭제, 아니면 신고/숨김.
class CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isMine;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  final VoidCallback? onHide;

  const CommentTile({
    super.key,
    required this.comment,
    required this.isMine,
    this.onEdit,
    this.onDelete,
    this.onReport,
    this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Avatar(
            imageUrl: comment.authorAvatarUrl,
            initial: comment.authorNickname,
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
                        comment.authorNickname ?? l10n.commentAnonymousAuthor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label
                            .copyWith(color: AppColors.textBright),
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 6),
                      LabelChip(text: l10n.commentMineTag),
                    ],
                    const SizedBox(width: 6),
                    Text(_relative(context, comment.isEdited
                        ? comment.updatedAt!
                        : comment.createdAt),
                        style: AppTypography.caption),
                    if (comment.isEdited) ...[
                      const SizedBox(width: 4),
                      Text(l10n.commonEdited, style: AppTypography.caption),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  comment.content,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textPrimary, height: 1.5),
                ),
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openMenu(context),
            // 터치 타깃 확보(44 권장에 맞춰 히트영역 확대)
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.more_horiz,
                  size: 18, color: AppColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  void _openMenu(BuildContext context) {
    final l10n = AppL10n.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            if (isMine) ...[
              _item(context, Icons.edit_outlined, l10n.commentEdit, onEdit),
              _item(context, Icons.delete_outline, l10n.commentDelete, onDelete,
                  danger: true),
            ] else ...[
              _item(context, Icons.visibility_off_outlined, l10n.commentHide,
                  onHide),
              _item(context, Icons.flag_outlined, l10n.commentReport, onReport,
                  danger: true),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label,
      VoidCallback? onTap,
      {bool danger = false}) {
    final color = danger ? AppColors.danger : AppColors.textBright;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: AppTypography.body.copyWith(color: color)),
      onTap: () {
        Navigator.pop(context);
        onTap?.call();
      },
    );
  }

  static String _relative(BuildContext context, DateTime dt) {
    final l10n = AppL10n.of(context);
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return l10n.commonTimeJustNow;
    if (diff.inMinutes < 60) return l10n.commonTimeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.commonTimeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.commonTimeDaysAgo(diff.inDays);
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}.$m.$d';
  }
}
