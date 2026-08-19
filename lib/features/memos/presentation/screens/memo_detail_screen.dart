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
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/full_screen_image_viewer.dart';
import '../../../../core/utils/error_handler.dart';

/// 메모 상세 = 작성자행 + 본문 + 이미지 + 책행 + 공개표시. 목업 memo-detail 기준.
class MemoDetailScreen extends ConsumerStatefulWidget {
  final String memoId;

  const MemoDetailScreen({super.key, required this.memoId});

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
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(memoProvider(widget.memoId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final memoAsync = ref.watch(memoProvider(widget.memoId));
    return memoAsync.when(
      data: (memo) {
        if (memo == null) {
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
        return _content(memo);
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(
          child: CircularProgressIndicator(
              color: AppColors.textSecondary, strokeWidth: 2),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(
          child: Text('메모를 불러오지 못했어요',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ),
      ),
    );
  }

  Widget _content(Memo memo) {
    final currentUser = ref.watch(authProvider).value;
    final isOwner = currentUser?.id == memo.userId;
    final edited =
        memo.updatedAt != null && memo.updatedAt!.isAfter(memo.createdAt);
    final date = edited ? memo.updatedAt! : memo.createdAt;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
        title: const Text('메모', style: AppTypography.subtitle),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _authorRow(memo, isOwner, edited, date),
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
                    child: Text(memo.userNickname ?? '밀키웨이',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyBold
                            .copyWith(color: Colors.white, fontSize: 15)),
                  ),
                  if (isOwner) ...[
                    const SizedBox(width: 6),
                    const LabelChip(text: '내 메모'),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Text('${date.month}월 ${date.day}일',
                      style: AppTypography.caption),
                  if (edited) ...[
                    const SizedBox(width: 6),
                    const LabelChip(text: '수정됨', tone: ChipTone.accentSoft),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
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
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : Container(
                    color: AppColors.surface,
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.textSecondary, strokeWidth: 2),
                    ),
                  ),
            errorBuilder: (_, __, ___) => Container(
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

  Widget _bookRow(Memo memo) {
    final author = memo.books['author'] as String?;
    final coverUrl = memo.books['cover_url'] as String?;
    final meta = [
      if (author != null && author.isNotEmpty) author,
      if (memo.page != null) 'p${memo.page}',
    ].join(' / ');
    return GestureDetector(
      onTap: () => context.pushNamed(AppRoutes.bookDetailName,
          pathParameters: {'id': memo.bookId}),
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
              child: (coverUrl != null && coverUrl.isNotEmpty)
                  ? Image.network(coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox())
                  : const SizedBox(),
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
        Text(pub ? '공개 메모' : '나만 보는 메모',
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
              title: Text('수정하기', style: AppTypography.body),
              onTap: () {
                Navigator.pop(context);
                _editMemo(memo);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Color(0xFFE05252)),
              title: Text('삭제하기',
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
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('메모 삭제', style: TextStyle(color: Colors.white)),
        content: const Text('이 메모를 삭제하시겠습니까?',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Color(0xFFE05252))),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
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
