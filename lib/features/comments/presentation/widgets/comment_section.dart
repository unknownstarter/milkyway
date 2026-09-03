import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/presentation/widgets/design/app_dialog.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../core/utils/response_cache.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/providers/book_provider.dart';
import '../../../books/presentation/providers/user_books_provider.dart';
import '../../../memos/presentation/providers/memo_provider.dart';
import '../../../../l10n/app_localizations.dart';
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
  // 스크롤 상단 패딩(글래스 앱바 뒤로 콘텐츠가 가려지지 않게). CASE B: glassTopPadding(context).
  final double topPadding;

  const CommentSection({
    super.key,
    required this.memoId,
    required this.bookId,
    required this.header,
    this.topPadding = 8,
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
    // 카드 댓글 수(comment_count computed column) 갱신 - 홈/메모탭/책상세 전부.
    // invalidateMemoProviders(Ref 전용)와 '동일 세트'를 유지해야 카운트 누락이 없다.
    ref.invalidate(memoProvider(widget.memoId));
    ref.invalidate(publicMemoFeedProvider); // 메모탭 공개(구)
    ref.invalidate(homePublicMemoFeedProvider); // 홈 '다른 별들이' (누락됐던 것)
    ref.invalidate(paginatedPublicFeedProvider); // 메모탭 공개 세그먼트 (누락됐던 것)
    ref.invalidate(allMemosProvider);
    ref.invalidate(recentMemosProvider);
    ref.invalidate(homeRecentMemosProvider);
    ref.invalidate(bookMemosProvider(widget.bookId));
    ref.invalidate(publicBookMemosProvider(widget.bookId));
    ref.invalidate(paginatedMemosProvider(widget.bookId));
    ref.invalidate(paginatedMemosProvider(null));
    ref.invalidate(paginatedPublicBookMemosProvider(widget.bookId));
    // 책상세 공개 메모는 edge function 응답 캐시 경유 - 캐시도 무효화해야 갱신됨.
    ResponseCache().invalidate('get-public-book-memos', bookId: widget.bookId);
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
      if (mounted) _toast(AppL10n.of(context).commentSendError);
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
    final l10n = AppL10n.of(context);
    final ok = await showAppConfirm(
      context,
      title: l10n.commentDeleteTitle,
      message: l10n.commentDeleteMessage,
      confirmText: l10n.commentDeleteConfirm,
      tone: ConfirmTone.danger,
    );
    if (!ok) return;
    try {
      await ref.read(commentRepositoryProvider).deleteComment(c.id);
      if (!mounted) return;
      if (_editing?.id == c.id) _cancelEdit();
      _refresh();
    } catch (_) {
      if (mounted) _toast(l10n.commentDeleteError);
    }
  }

  Future<void> _hide(Comment c) async {
    try {
      await ref.read(commentRepositoryProvider).hideComment(c.id);
      _refresh();
    } catch (_) {
      if (mounted) _toast(AppL10n.of(context).commentHideError);
    }
  }

  Future<void> _report(Comment c) async {
    final l10n = AppL10n.of(context);
    final reasons = <String, String>{
      'spam': l10n.commentReportSpam,
      'inappropriate': l10n.commentReportInappropriate,
      'harassment': l10n.commentReportHarassment,
      'sexual': l10n.commentReportSexual,
      'other': l10n.commentReportOther,
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
            Text(l10n.commentReportReasonTitle, style: AppTypography.label),
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
      if (mounted) _toast(l10n.commentReportDone);
      _refresh();
    } catch (_) {
      if (mounted) _toast(l10n.commentReportError);
    }
  }

  /// 책 미저장 시: 담기 팝업 → 담고 게이트 해제.
  Future<void> _saveBookPrompt() async {
    final l10n = AppL10n.of(context);
    final repo = ref.read(bookRepositoryProvider);
    final userId = repo.getCurrentUserId();
    final save = await showAppConfirm(
      context,
      title: l10n.commentSaveBookTitle,
      message: l10n.commentSaveBookMessage,
      confirmText: l10n.commentSaveBookConfirm,
    );
    if (!save) return;
    try {
      await repo.createUserBookConnection(widget.bookId, userId);
      ref.read(analyticsProvider)
          .logEvent('click_save_book_in_comment', {'book_id': widget.bookId});
      ref.invalidate(isBookSavedProvider(widget.bookId));
      ref.invalidate(homeBooksProvider);
      ref.invalidate(userBooksProvider);
    } catch (_) {
      if (mounted) _toast(l10n.commentSaveBookError);
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
            // 스크롤을 아래로 끌면 키보드가 내려간다(채팅 표준 동작).
            // 댓글이 적어도 드래그가 먹히도록 항상 스크롤 가능하게.
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, widget.topPadding, 20, 24),
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
                  error: (_, __) =>
                      _empty(AppL10n.of(context).commentLoadError),
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
    final l10n = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          comments.isEmpty
              ? l10n.commentSectionTitle
              : l10n.commentSectionTitleCount(comments.length),
          style: AppTypography.label.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (comments.isEmpty)
          _empty(l10n.commentEmpty)
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
