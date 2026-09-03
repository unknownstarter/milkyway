import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/memo.dart';
import '../../domain/models/memo_visibility.dart';
import '../providers/memo_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/presentation/widgets/design/avatar.dart';
import '../../../../core/presentation/widgets/design/chips.dart';
import '../../../../core/presentation/widgets/design/glass_app_bar.dart';
import '../../../../core/presentation/widgets/design/cached_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../widgets/full_screen_image_viewer.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../comments/presentation/widgets/comment_section.dart';
import '../../domain/memo_exceptions.dart';
import '../../../home/presentation/providers/book_provider.dart';
import '../../../../core/presentation/widgets/design/app_dialog.dart';
import '../../../../l10n/app_localizations.dart';

/// 메모 상세 = 작성자행 + 본문 + 이미지 + 책행 + 공개표시. 목업 memo-detail 기준.
class MemoDetailScreen extends ConsumerStatefulWidget {
  final String memoId;

  /// 카드에서 넘어올 때 이미 로드된 메모. 있으면 즉시 렌더(엣지펑션 대기 없이).
  final Memo? initialMemo;

  const MemoDetailScreen({super.key, required this.memoId, this.initialMemo});

  @override
  ConsumerState<MemoDetailScreen> createState() => _MemoDetailScreenState();
}

class _MemoDetailScreenState extends ConsumerState<MemoDetailScreen> {
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      ref.read(analyticsProvider).logScreenView('memo_detail_screen');
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(memoProvider(widget.memoId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final memoAsync = ref.watch(memoProvider(widget.memoId));

    // 남의 비공개 메모: 책 상세로 유도.
    if (memoAsync.hasError && memoAsync.error is MemoRestrictedException) {
      final e = memoAsync.error as MemoRestrictedException;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _routeRestricted(e.bookId);
      });
      return const Scaffold(backgroundColor: AppColors.bgPrimary);
    }
    // 삭제됨(로드 완료 + null): 뒤로/홈.
    if (memoAsync.hasValue && memoAsync.value == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.goNamed(AppRoutes.homeName);
          }
        }
      });
      return const Scaffold(backgroundColor: AppColors.bgPrimary);
    }

    // 넘어온 메모(initialMemo)가 있으면 즉시 렌더. 서버 값이 오면 자동 갱신.
    final memo = memoAsync.value ?? widget.initialMemo;
    if (memo != null) return _content(memo);

    // 로드 실패(넘어온 것도 없음)
    if (memoAsync.hasError) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(
          child: Text(AppL10n.of(context).memoLoadFailed,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ),
      );
    }
    // 로딩 중 + 넘어온 메모 없음
    return const Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: CircularProgressIndicator(
            color: AppColors.textSecondary, strokeWidth: 2),
      ),
    );
  }

  /// 남의 비공개 메모 접근 시: 그 책을 저장했으면 책 상세로 대체 이동.
  /// 저장 안 했으면 담기 팝업 -> 담으면 책 상세로, 아니면 뒤로/홈.
  Future<void> _routeRestricted(String? bookId) async {
    if (bookId == null || bookId.isEmpty) {
      _leave();
      return;
    }
    final repo = ref.read(bookRepositoryProvider);
    final userId = repo.getCurrentUserId();
    bool saved = false;
    try {
      saved = await repo.hasUserBookConnection(bookId, userId);
    } catch (_) {}
    if (!mounted) return;
    if (saved) {
      context.pushReplacementNamed(AppRoutes.bookDetailName,
          pathParameters: {'id': bookId});
      return;
    }
    final l10n = AppL10n.of(context);
    final save = await showAppConfirm(
      context,
      title: l10n.memoSaveBookTitle,
      message: l10n.memoRestrictedBody,
      confirmText: l10n.memoSaveBookConfirm,
    );
    if (!mounted) return;
    if (!save) {
      _leave();
      return;
    }
    try {
      await repo.createUserBookConnection(bookId, userId);
      ref.read(analyticsProvider)
          .logEvent('click_save_book_in_restricted', {'book_id': bookId});
      if (!mounted) return;
      context.pushReplacementNamed(AppRoutes.bookDetailName,
          pathParameters: {'id': bookId});
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e, operation: '책 담기');
      _leave();
    }
  }

  void _leave() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.homeName);
    }
  }

  Widget _content(Memo memo) {
    final l10n = AppL10n.of(context);
    final currentUser = ref.watch(authProvider).value;
    final isOwner = currentUser?.id == memo.userId;
    final edited = memo.isEdited;
    final date = edited ? memo.updatedAt! : memo.createdAt;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      extendBodyBehindAppBar: true,
      appBar: glassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(AppRoutes.homeName);
            }
          },
        ),
        title: Text(l10n.memoTitle, style: AppTypography.subtitle),
        actions: isOwner
            ? [
                IconButton(
                  icon: const Icon(Icons.more_horiz,
                      color: AppColors.textPrimary),
                  onPressed: () => _showOptions(memo),
                ),
              ]
            : null,
      ),
      // 본문을 댓글 영역 header로 넘겨 함께 스크롤 + 하단 입력창 고정.
      // topPadding으로 스크롤이 글래스 앱바 뒤에서 시작(CASE B).
      body: CommentSection(
        memoId: widget.memoId,
        bookId: memo.bookId,
        topPadding: glassTopPadding(context),
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _authorRow(memo, isOwner, edited, date),
            if (memo.lyraQuestion != null && memo.lyraQuestion!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _lyraSnapshot(memo.lyraQuestion!),
            ],
            const SizedBox(height: 18),
            Text(memo.content,
                style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary, fontSize: 16, height: 1.65)),
            if (memo.imageUrl != null && memo.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 18),
              _image(memo.imageUrl!),
            ],
            const SizedBox(height: 22),
            _bookRow(memo),
            const SizedBox(height: 18),
            _visibility(memo.visibility),
          ],
        ),
      ),
    );
  }

  Widget _authorRow(Memo memo, bool isOwner, bool edited, DateTime date) {
    return Row(
      children: [
        Avatar(
          imageUrl: memo.userAvatarUrl,
          initial: memo.userNickname,
          size: AvatarSize.md,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                        memo.userNickname ?? AppL10n.of(context).memoAuthorFallback,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyBold
                            .copyWith(color: Colors.white, fontSize: 15)),
                  ),
                  if (isOwner) ...[
                    const SizedBox(width: 6),
                    LabelChip(text: AppL10n.of(context).memoMineTag),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Text(
                      AppL10n.of(context)
                          .memoDateMonthDay(date.month, date.day),
                      style: AppTypography.caption),
                  if (edited) ...[
                    const SizedBox(width: 6),
                    LabelChip(
                        text: AppL10n.of(context).memoEditedTag,
                        tone: ChipTone.accentSoft),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 이 메모가 답한 Lyra 물음 스냅샷(초록 딤 인용 블록).
  Widget _lyraSnapshot(String question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    color: AppColors.accentGreen, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(AppL10n.of(context).memoLyraQuestionLabel,
                  style: AppTypography.caption.copyWith(
                      color: AppColors.accentGreen,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(question,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textBright, height: 1.55)),
        ],
      ),
    );
  }

  Widget _image(String url) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FullScreenImageViewer(imageUrl: url),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 1,
          child: CachedImage(
            url: url,
            cacheWidth: 1000,
            fallback: Container(
              color: AppColors.surface,
              child: const Center(
                child: Icon(Icons.image_outlined,
                    color: AppColors.textTertiary, size: 40),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 책 행 탭: 저장한 책이면 바로 책 상세, 아니면 담기 팝업(미저장 책 바로 열면 에러).
  Future<void> _openBook(String bookId) async {
    final repo = ref.read(bookRepositoryProvider);
    final uid = repo.getCurrentUserId();
    bool saved = false;
    try {
      saved = await repo.hasUserBookConnection(bookId, uid);
    } catch (_) {}
    if (!mounted) return;
    if (saved) {
      context.pushNamed(AppRoutes.bookDetailName, pathParameters: {'id': bookId});
      return;
    }
    final l10n = AppL10n.of(context);
    final save = await showAppConfirm(
      context,
      title: l10n.memoSaveBookTitle,
      message: l10n.memoSaveBookBody,
      confirmText: l10n.memoSaveBookConfirm,
    );
    if (!mounted || !save) return;
    try {
      await repo.createUserBookConnection(bookId, uid);
      ref.read(analyticsProvider)
          .logEvent('click_save_book_in_memo_detail', {'book_id': bookId});
      if (mounted) {
        context.pushNamed(AppRoutes.bookDetailName,
            pathParameters: {'id': bookId});
      }
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e, operation: '책 담기');
    }
  }

  Widget _bookRow(Memo memo) {
    final author = memo.books['author'] as String?;
    final coverUrl = memo.books['cover_url'] as String?;
    final meta = [
      if (author != null && author.isNotEmpty) author,
      if (memo.page != null) 'p${memo.page}',
    ].join(' / ');
    return GestureDetector(
      onTap: () => _openBook(memo.bookId),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(4),
              ),
              clipBehavior: Clip.antiAlias,
              child: CachedImage(url: coverUrl, fallback: const SizedBox()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(memo.bookTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textBright,
                          fontWeight: FontWeight.w600)),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textTertiary)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 20, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _visibility(MemoVisibility v) {
    final pub = v == MemoVisibility.public;
    return Row(
      children: [
        Icon(pub ? Icons.visibility_outlined : Icons.lock_outline,
            size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 6),
        Text(pub
            ? AppL10n.of(context).memoPublicLabel
            : AppL10n.of(context).memoPrivateLabel,
            style: AppTypography.caption.copyWith(color: AppColors.textTertiary)),
      ],
    );
  }

  void _showOptions(Memo memo) {
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
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.white),
              title: Text(AppL10n.of(context).memoEditAction,
                  style: AppTypography.body),
              onTap: () {
                Navigator.pop(context);
                _editMemo(memo);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Color(0xFFE05252)),
              title: Text(AppL10n.of(context).memoDeleteAction,
                  style: AppTypography.body
                      .copyWith(color: const Color(0xFFE05252))),
              onTap: () {
                Navigator.pop(context);
                _deleteMemo(memo);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _editMemo(Memo memo) {
    context.pushNamed(AppRoutes.memoEditName, pathParameters: {'id': memo.id});
  }

  Future<void> _deleteMemo(Memo memo) async {
    final l10n = AppL10n.of(context);
    final shouldDelete = await showAppConfirm(
      context,
      title: l10n.memoDeleteTitle,
      message: l10n.memoDeleteAsk,
      confirmText: l10n.memoDelete,
      tone: ConfirmTone.danger,
    );

    if (shouldDelete) {
      try {
        await ref
            .read(deleteMemoProvider((memoId: memo.id, bookId: memo.bookId))
                .future);
        if (context.mounted) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.goNamed(AppRoutes.homeName);
          }
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showError(context, e, operation: '메모 삭제');
        }
      }
    }
  }
}
