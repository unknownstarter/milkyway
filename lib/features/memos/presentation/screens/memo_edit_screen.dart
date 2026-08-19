import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../home/domain/models/book.dart';
import '../../../books/presentation/providers/user_books_provider.dart';
import '../providers/memo_form_provider.dart';
import '../providers/memo_provider.dart';
import '../../domain/models/memo_visibility.dart';
import '../../utils/memo_image_uploader.dart';
import '../../utils/memo_error_handler.dart';

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
          child: Text('취소',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary, fontSize: 15)),
        ),
        title: const Text('메모 편집', style: AppTypography.subtitle),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _deleteMemo,
            child: Text('삭제',
                style: AppTypography.bodySmall
                    .copyWith(color: const Color(0xFFE05252), fontSize: 14)),
          ),
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.only(right: 20, left: 4),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: AppColors.accentGreen, strokeWidth: 2),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _hasChanges ? _saveMemo : null,
                  child: Text('저장',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _hasChanges
                            ? AppColors.accentGreen
                            : AppColors.textTertiary,
                      )),
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
                  ? Image.network(book.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox())
                  : const SizedBox(),
            ),
            const SizedBox(width: 7),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: Text(
                book?.title ?? '책',
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
        cursorColor: AppColors.accentGreen,
        style: AppTypography.body
            .copyWith(fontSize: 17, color: AppColors.textPrimary, height: 1.7),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: '메모를 입력하세요',
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
                : Image.network(path,
                    width: 84, height: 84, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imgFallback()),
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

  Widget _toolbar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 14 + MediaQuery.of(context).padding.bottom),
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
              cursorColor: AppColors.accentGreen,
              style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                border: InputBorder.none,
                hintText: '쪽',
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
        children: [_visOpt('공개', true), _visOpt('나만 보기', false)],
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
          title: const Text('이미지 선택',
              style: TextStyle(color: Colors.white, fontFamily: 'Pretendard')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text('갤러리에서 선택',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.white),
                  title: const Text('카메라로 촬영',
                      style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
            ],
          ),
        ),
      );
      if (source != null) {
        final image = await picker.pickImage(source: source, imageQuality: 85);
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
      MemoErrorHandler.showErrorSnackBar(context, '메모 내용을 입력해주세요');
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
            MemoErrorHandler.showErrorSnackBar(context, '이미지 업로드에 실패했습니다');
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
          const SnackBar(
            content: Text('메모가 수정되었습니다',
                style: TextStyle(color: Colors.white)),
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
        title: const Text('변경사항이 있습니다',
            style: TextStyle(color: Colors.white)),
        content: const Text('저장하지 않고 나가시겠습니까?',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('나가기', style: TextStyle(color: Color(0xFFE05252))),
          ),
        ],
      ),
    );
    if (shouldExit == true && mounted) _close();
  }
}
