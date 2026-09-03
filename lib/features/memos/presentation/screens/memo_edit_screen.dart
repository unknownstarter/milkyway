import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/design/cached_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/presentation/widgets/design/buttons.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../home/domain/models/book.dart';
import '../../../books/presentation/providers/user_books_provider.dart';
import '../providers/memo_form_provider.dart';
import '../providers/memo_provider.dart';
import '../../domain/models/memo_visibility.dart';
import '../../utils/memo_image_uploader.dart';
import '../../utils/memo_error_handler.dart';
import '../../../../l10n/app_localizations.dart';

/// 메모 편집 = 작성 화면과 동일 디자인. 로드/변경감지/update/삭제 로직 보존.
class MemoEditScreen extends ConsumerStatefulWidget {
  final String memoId;

  const MemoEditScreen({super.key, required this.memoId});

  @override
  ConsumerState<MemoEditScreen> createState() => _MemoEditScreenState();
}

class _MemoEditScreenState extends ConsumerState<MemoEditScreen> {
  final _contentController = TextEditingController();
  final _pageController = TextEditingController();
  String? _selectedImagePath;
  bool _isLoading = false;
  String? _bookId;
  bool _isPublic = true;
  bool _hasChanges = false;

  String? _originalContent;
  String? _originalPage;
  String? _originalImageUrl;
  MemoVisibility? _originalVisibility;

  @override
  void initState() {
    super.initState();
    _loadMemoData();
    _contentController.addListener(() {
      setState(() {});
      _checkChanges();
    });
    _pageController.addListener(_checkChanges);
    ref.read(analyticsProvider).logScreenView('memo_edit_screen');
  }

  @override
  void dispose() {
    _contentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadMemoData() async {
    try {
      final memo = await ref.read(memoProvider(widget.memoId).future);
      if (!mounted) return;
      if (memo == null) {
        _close();
        return;
      }
      _bookId = memo.bookId;
      _contentController.text = memo.content;
      _pageController.text = memo.page?.toString() ?? '';
      _selectedImagePath = memo.imageUrl;
      _isPublic = memo.visibility == MemoVisibility.public;
      _originalContent = memo.content;
      _originalPage = memo.page?.toString();
      _originalImageUrl = memo.imageUrl;
      _originalVisibility = memo.visibility;
      _checkChanges();
    } catch (e) {
      if (mounted) MemoErrorHandler.showError(context, e);
    }
  }

  void _checkChanges() {
    if (_originalContent == null) {
      setState(() => _hasChanges = false);
      return;
    }
    final visibility =
        _isPublic ? MemoVisibility.public : MemoVisibility.private;
    setState(() {
      _hasChanges = _contentController.text.trim() != _originalContent ||
          _pageController.text.trim() != (_originalPage ?? '') ||
          _selectedImagePath != _originalImageUrl ||
          visibility != _originalVisibility;
    });
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.homeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final books = ref.watch(userBooksProvider).asData?.value ?? const <Book>[];
    Book? book;
    for (final b in books) {
      if (b.id == _bookId) {
        book = b;
        break;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leadingWidth: 72,
        leading: TextButton(
          onPressed: _isLoading
              ? null
              : (_hasChanges ? _showExitDialog : _close),
          child: Text(l10n.commonCancel,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary, fontSize: 15)),
        ),
        title: Text(l10n.memoEditTitle, style: AppTypography.subtitle),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _deleteMemo,
            child: Text(l10n.memoDelete,
                style: AppTypography.bodySmall
                    .copyWith(color: const Color(0xFFE05252), fontSize: 14)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            _bookChip(book),
            Expanded(child: _editor()),
            if (_selectedImagePath != null) _imagePreview(),
            _toolbar(),
            _saveBar(),
          ],
        ),
      ),
    );
  }

  Widget _bookChip(Book? book) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(3),
              ),
              clipBehavior: Clip.antiAlias,
              child: (book?.coverUrl != null && book!.coverUrl!.isNotEmpty)
                  ? CachedImage(
                      url: book.coverUrl,
                      fit: BoxFit.cover,
                      cacheWidth: 200,
                      fallback: const SizedBox())
                  : const SizedBox(),
            ),
            const SizedBox(width: 7),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: Text(
                book?.title ?? AppL10n.of(context).memoBookFallback,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textPrimary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editor() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: TextField(
        controller: _contentController,
        expands: true,
        maxLines: null,
        minLines: null,
        textAlignVertical: TextAlignVertical.top,
        cursorColor: Colors.white,
        style: AppTypography.body
            .copyWith(fontSize: 17, color: AppColors.textPrimary, height: 1.7),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: AppL10n.of(context).memoEditHint,
          hintStyle: AppTypography.body.copyWith(
              fontSize: 17, color: AppColors.textTertiary, height: 1.7),
        ),
      ),
    );
  }

  Widget _imagePreview() {
    final path = _selectedImagePath!;
    final isLocal = MemoImageUploader.isLocalFile(path);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: isLocal
                ? Image.file(File(path),
                    width: 84, height: 84, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imgFallback())
                : CachedImage(
                    url: path,
                    width: 84, height: 84, fit: BoxFit.cover,
                    cacheWidth: 252,
                    fallback: _imgFallback()),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: _removeImage,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgFallback() =>
      Container(width: 84, height: 84, color: AppColors.surface);

  Widget _saveBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: PrimaryButton(
        label: AppL10n.of(context).commonSave,
        loading: _isLoading,
        onPressed: _hasChanges ? _saveMemo : null,
      ),
    );
  }

  Widget _toolbar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Text('p ',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          SizedBox(
            width: 44,
            child: TextField(
              controller: _pageController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              cursorColor: Colors.white,
              style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                border: InputBorder.none,
                hintText: AppL10n.of(context).memoPageHint,
                hintStyle: AppTypography.bodySmall
                    .copyWith(color: AppColors.textTertiary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isLoading ? null : _selectImage,
            icon: const Icon(Icons.image_outlined,
                size: 22, color: AppColors.textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const Spacer(),
          _visibilityToggle(),
        ],
      ),
    );
  }

  Widget _visibilityToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _visOpt(AppL10n.of(context).memoVisibilityPublic, true),
          _visOpt(AppL10n.of(context).memoVisibilityPrivateOnlyMe, false),
        ],
      ),
    );
  }

  Widget _visOpt(String label, bool pub) {
    final on = _isPublic == pub;
    return GestureDetector(
      onTap: () {
        setState(() => _isPublic = pub);
        _checkChanges();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: on ? AppColors.accentGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: on ? Colors.black : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Future<void> _selectImage() async {
    try {
      final picker = ImagePicker();
      final source = await showDialog<ImageSource>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(AppL10n.of(context).memoImagePickTitle,
              style: const TextStyle(
                  color: Colors.white, fontFamily: 'Pretendard')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: Text(AppL10n.of(context).memoImageFromGallery,
                    style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.white),
                  title: Text(AppL10n.of(context).memoImageFromCamera,
                      style: const TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
            ],
          ),
        ),
      );
      if (source != null) {
        // 캡처 시점에 리사이즈(최대 1280px) + 압축 -> 업로드/로딩 대폭 빨라짐.
        final image = await picker.pickImage(
            source: source, imageQuality: 80, maxWidth: 1280, maxHeight: 1280);
        if (image != null) {
          setState(() => _selectedImagePath = image.path);
          _checkChanges();
        }
      }
    } catch (e) {
      if (mounted) MemoErrorHandler.showError(context, e);
    }
  }

  void _removeImage() {
    setState(() => _selectedImagePath = null);
    _checkChanges();
  }

  Future<void> _saveMemo() async {
    if (_contentController.text.trim().isEmpty) {
      MemoErrorHandler.showErrorSnackBar(
          context, AppL10n.of(context).memoContentRequired);
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_bookId == null) throw Exception('책 정보를 불러올 수 없습니다');
      final visibility =
          _isPublic ? MemoVisibility.public : MemoVisibility.private;

      String? imageUrl = _selectedImagePath;
      if (MemoImageUploader.isLocalFile(_selectedImagePath)) {
        imageUrl = await MemoImageUploader.uploadImage(_selectedImagePath!);
        if (imageUrl == null) {
          if (mounted) {
            MemoErrorHandler.showErrorSnackBar(
                context, AppL10n.of(context).memoImageUploadFailed);
          }
          return;
        }
      }

      await ref.read(memoFormProvider(_bookId!).notifier).updateMemo(
            memoId: widget.memoId,
            content: _contentController.text.trim(),
            page: _pageController.text.isNotEmpty
                ? int.tryParse(_pageController.text)
                : null,
            imageUrl: imageUrl,
            visibility: visibility,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppL10n.of(context).memoUpdated,
                style: const TextStyle(color: Colors.white)),
            backgroundColor: AppColors.surfaceMuted,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) MemoErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMemo() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(AppL10n.of(context).memoDeleteTitle,
            style: const TextStyle(color: Colors.white)),
        content: Text(AppL10n.of(context).memoDeleteConfirm,
            style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppL10n.of(context).commonCancel,
                style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppL10n.of(context).memoDelete,
                style: const TextStyle(color: Color(0xFFE05252))),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        if (_bookId == null) throw Exception('책 정보를 불러올 수 없습니다');
        await ref
            .read(deleteMemoProvider((memoId: widget.memoId, bookId: _bookId!))
                .future);
        if (!mounted) return;
        if (context.mounted) context.pop();
      } catch (e) {
        if (context.mounted) MemoErrorHandler.showError(context, e);
      }
    }
  }

  Future<void> _showExitDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(AppL10n.of(context).memoUnsavedTitle,
            style: const TextStyle(color: Colors.white)),
        content: Text(AppL10n.of(context).memoUnsavedBody,
            style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppL10n.of(context).commonCancel,
                style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppL10n.of(context).memoLeave,
                style: const TextStyle(color: Color(0xFFE05252))),
          ),
        ],
      ),
    );
    if (shouldExit == true && mounted) _close();
  }
}
