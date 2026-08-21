import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/providers/book_provider.dart';
import '../../../books/presentation/providers/user_books_provider.dart';
import '../../../memos/presentation/providers/memo_provider.dart';
import '../../domain/models/comment.dart';
import '../providers/comment_providers.dart';
import 'comment_tile.dart';
import 'comment_composer.dart';

/// 조합: 메모 상세의 댓글 영역 전체.
/// [header](메모 본문)를 스크롤 상단에 함께 넣고, 하단에 입력창을 고정한다.
/// 편집/삭제/신고/숨김/책담기 게이트를 한 곳에서 관리(상태 분산 방지).
class CommentSection extends ConsumerStatefulWidget {
  final String memoId;
  final String bookId;
  final Widget header;

  const CommentSection({
    super.key,
    required this.memoId,
    required this.bookId,
    required this.header,
  });

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final _controller = TextEditingController();
  Comment? _editing;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return; // async 이후 언마운트 시 ref 사용 방지
    ref.invalidate(commentsProvider(widget.memoId));
    // 카드 댓글 수(comment_count computed column)도 갱신. invalidateMemoProviders는
    // Ref 전용이라 WidgetRef에선 직접 호출하되, '동일 세트'를 유지해 카운트 누락을 막는다.
    ref.invalidate(memoProvider(widget.memoId));
    ref.invalidate(publicMemoFeedProvider);
    ref.invalidate(allMemosProvider);
    ref.invalidate(recentMemosProvider);
    ref.invalidate(homeRecentMemosProvider);
    ref.invalidate(bookMemosProvider(widget.bookId));
    ref.invalidate(publicBookMemosProvider(widget.bookId));
    ref.invalidate(paginatedMemosProvider(widget.bookId));
    ref.invalidate(paginatedMemosProvider(null));
    ref.invalidate(paginatedPublicBookMemosProvider(widget.bookId));
  }

  Future<void> _send(String text) async {
    setState(() => _sending = true);
    final repo = ref.read(commentRepositoryProvider);
    try {
      if (_editing != null) {
        await repo.updateComment(_editing!.id, text);
      } else {
        await repo.addComment(widget.memoId, text);
        ref.read(analyticsProvider).logEvent(
            'click_add_comment', {'memo_id': widget.memoId});
      }
      if (!mounted) return; // await 후 언마운트면 disposed controller 접근 금지
      _controller.clear();
      _editing = null;
      _refresh();
    } catch (_) {
      if (mounted) _toast('댓글을 못 남겼어');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _startEdit(Comment c) {
    setState(() {
      _editing = c;
      _controller.text = c.content;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editing = null;
      _controller.clear();
    });
  }

  Future<void> _delete(Comment c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('댓글 삭제',
            style: AppTypography.subtitle.copyWith(color: AppColors.textBright)),
        content: Text('이 댓글을 지울까',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('취소',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('삭제',
                style: AppTypography.bodySmall.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(commentRepositoryProvider).deleteComment(c.id);
      if (!mounted) return;
      if (_editing?.id == c.id) _cancelEdit();
      _refresh();
    } catch (_) {
      if (mounted) _toast('못 지웠어');
    }
  }

  Future<void> _hide(Comment c) async {
    try {
      await ref.read(commentRepositoryProvider).hideComment(c.id);
      _refresh();
    } catch (_) {
      if (mounted) _toast('못 숨겼어');
    }
  }

  Future<void> _report(Comment c) async {
    const reasons = <String, String>{
      'spam': '스팸/도배',
      'inappropriate': '부적절한 내용',
      'harassment': '괴롭힘/혐오',
      'sexual': '선정적',
      'other': '기타',
    };
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('신고 사유', style: AppTypography.label),
            const SizedBox(height: 4),
            for (final e in reasons.entries)
              ListTile(
                title: Text(e.value, style: AppTypography.body),
                onTap: () => Navigator.pop(context, e.key),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (reason == null) return;
    try {
      await ref.read(commentRepositoryProvider).reportComment(c.id, reason);
      if (mounted) _toast('신고했어. 이 댓글은 이제 안 보여');
      _refresh();
    } catch (_) {
      if (mounted) _toast('신고하지 못했어');
    }
  }

  /// 책 미저장 시: 담기 팝업 → 담고 게이트 해제.
  Future<void> _saveBookPrompt() async {
    final repo = ref.read(bookRepositoryProvider);
    final userId = repo.getCurrentUserId();
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceMuted,
        title: Text('책 담기',
            style: AppTypography.subtitle.copyWith(color: AppColors.textBright)),
        content: Text('이 책을 담아야 댓글을 남길 수 있어. 담을까',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('취소',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('담기',
                style: AppTypography.bodySmall.copyWith(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (save != true) return;
    try {
      await repo.createUserBookConnection(widget.bookId, userId);
      ref.read(analyticsProvider)
          .logEvent('click_save_book_in_comment', {'book_id': widget.bookId});
      ref.invalidate(isBookSavedProvider(widget.bookId));
      ref.invalidate(homeBooksProvider);
      ref.invalidate(userBooksProvider);
    } catch (_) {
      if (mounted) _toast('책을 못 담았어');
    }
  }

  /// 칩 형태의 짧은 토스트(플로팅 pill, 1.4초, 겹치면 즉시 교체).
  void _toast(String msg) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(msg,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
        elevation: 0,
        duration: const Duration(milliseconds: 800),
        margin: const EdgeInsets.only(left: 44, right: 44, bottom: 90),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authProvider).value;
    final myId = me?.id;
    final commentsAsync = ref.watch(commentsProvider(widget.memoId));
    final saved = ref.watch(isBookSavedProvider(widget.bookId)).value ?? false;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.header,
                const SizedBox(height: 20),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 16),
                commentsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  error: (_, __) => _empty('댓글을 못 불러왔어'),
                  data: (comments) => _list(comments, myId),
                ),
              ],
            ),
          ),
        ),
        CommentComposer(
          controller: _controller,
          locked: !saved,
          sending: _sending,
          isEditing: _editing != null,
          avatarUrl: me?.pictureUrl,
          avatarInitial: me?.nickname,
          onSend: _send,
          onLockedTap: _saveBookPrompt,
          onCancelEdit: _cancelEdit,
        ),
      ],
    );
  }

  Widget _list(List<Comment> comments, String? myId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          comments.isEmpty ? '댓글' : '댓글 ${comments.length}',
          style: AppTypography.label.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (comments.isEmpty)
          _empty('첫 댓글을 남겨봐')
        else
          for (final c in comments)
            CommentTile(
              comment: c,
              isMine: c.userId == myId,
              onEdit: () => _startEdit(c),
              onDelete: () => _delete(c),
              onReport: () => _report(c),
              onHide: () => _hide(c),
            ),
      ],
    );
  }

  Widget _empty(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(text,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textTertiary)),
      ),
    );
  }
}
