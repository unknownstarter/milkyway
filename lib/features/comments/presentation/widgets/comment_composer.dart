import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// 조합: 하단 고정 댓글 입력창.
///  - [locked]=true(책 미저장)이면 입력 대신 탭 시 [onLockedTap] (책 담기 유도)
///  - [isEditing]이면 전송 아이콘 대신 체크(수정 확정)
class CommentComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool locked;
  final bool sending;
  final bool isEditing;
  final ValueChanged<String> onSend;
  final VoidCallback? onLockedTap;
  final VoidCallback? onCancelEdit;

  const CommentComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.locked = false,
    this.sending = false,
    this.isEditing = false,
    this.onLockedTap,
    this.onCancelEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isEditing)
                GestureDetector(
                  onTap: onCancelEdit,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8, bottom: 8),
                    child: Icon(Icons.close,
                        size: 20, color: AppColors.textTertiary),
                  ),
                ),
              Expanded(
                child: GestureDetector(
                  onTap: locked ? onLockedTap : null,
                  child: AbsorbPointer(
                    absorbing: locked,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 40),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: TextField(
                        controller: controller,
                        maxLength: 500,
                        maxLines: 4,
                        minLines: 1,
                        cursorColor: Colors.white,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          counterText: '',
                          hintText: locked
                              ? '책을 담으면 댓글을 남길 수 있어요'
                              : (isEditing ? '댓글 수정' : '댓글 남기기'),
                          hintStyle: AppTypography.bodySmall
                              .copyWith(color: AppColors.textTertiary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _sendButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sendButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: sending || locked
          ? null
          : () {
              final text = controller.text.trim();
              if (text.isNotEmpty) onSend(text);
            },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: sending
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.accentGreen),
              )
            : Icon(
                isEditing ? Icons.check_circle : Icons.arrow_upward,
                size: 26,
                color: locked ? AppColors.textTertiary : AppColors.accentGreen,
              ),
      ),
    );
  }
}
