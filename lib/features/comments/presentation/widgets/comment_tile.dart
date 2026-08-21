import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/presentation/widgets/design/avatar.dart';
import '../../../../core/presentation/widgets/design/chips.dart';
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
                        comment.authorNickname ?? '밀키웨이',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label
                            .copyWith(color: AppColors.textBright),
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 6),
                      const LabelChip(text: '나'),
                    ],
                    const SizedBox(width: 6),
                    Text(_relative(comment.isEdited
                        ? comment.updatedAt!
                        : comment.createdAt),
                        style: AppTypography.caption),
                    if (comment.isEdited) ...[
                      const SizedBox(width: 4),
                      Text('수정됨', style: AppTypography.caption),
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
            child: const Padding(
              padding: EdgeInsets.only(left: 6, top: 2),
              child: Icon(Icons.more_horiz,
                  size: 18, color: AppColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  void _openMenu(BuildContext context) {
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
              _item(context, Icons.edit_outlined, '수정하기', onEdit),
              _item(context, Icons.delete_outline, '삭제하기', onDelete,
                  danger: true),
            ] else ...[
              _item(context, Icons.visibility_off_outlined, '이 댓글 숨기기',
                  onHide),
              _item(context, Icons.flag_outlined, '신고하기', onReport,
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
    final color = danger ? const Color(0xFFE05252) : Colors.white;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: AppTypography.body.copyWith(color: color)),
      onTap: () {
        Navigator.pop(context);
        onTap?.call();
      },
    );
  }

  static String _relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}.$m.$d';
  }
}
