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
import '../../../../core/presentation/widgets/design/buttons.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../home/domain/models/book.dart';
import '../../../books/presentation/providers/user_books_provider.dart';
import '../providers/memo_form_provider.dart';
import '../../domain/models/memo_visibility.dart';
import '../../utils/memo_image_uploader.dart';
import '../../utils/memo_error_handler.dart';

/// 메모 작성 = 상단바(취소/메모/저장) + 책 칩 + (Lyra 물음) + 큰 에디터 + 하단 툴바(쪽/이미지/공개).
/// 승인 목업 memo-create-plain / memo-create 기준.
class MemoCreateScreen extends ConsumerStatefulWidget {
  final String? bookId;
  final String? bookTitle;
  final String? lyraQuestion;

  const MemoCreateScreen({
    super.key,
    this.bookId,
    this.bookTitle,
    this.lyraQuestion,
  });

  @override
  ConsumerState<MemoCreateScreen> createState() => _MemoCreateScreenState();
}

class _MemoCreateScreenState extends ConsumerState<MemoCreateScreen> {
  final _contentController = TextEditingController();
  final _pageController = TextEditingController();
  String? _selectedImagePath;
  bool _isLoading = false;
  String? _selectedBookId;
  bool _isPublic = true;

  @override
  void initState() {
    super.initState();
    _selectedBookId = widget.bookId;
    _contentController.addListener(() => setState(() {}));
    ref.read(analyticsProvider).logScreenView('memo_create_screen');
  }

  @override
  void dispose() {
    _contentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _selectedBookId != null &&
      _selectedBookId!.isNotEmpty &&
      _contentController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(userBooksProvider).asData?.value ?? const <Book>[];
    Book? selected;
    for (final b in books) {
      if (b.id == _selectedBookId) {
        selected = b;
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
          onPressed: _isLoading ? null : _close,
          child: Text('취소',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary, fontSize: 15)),
        ),
        title: const Text('메모', style: AppTypography.subtitle),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            _bookChip(selected, books),
            if (widget.lyraQuestion != null) _lyraBlock(widget.lyraQuestion!),
            Expanded(child: _editor()),
            if (_selectedImagePath != null) _imagePreview(),
            _toolbar(),
            _saveBar(),
          ],
        ),
      ),
    );
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.homeName);
    }
  }

  Widget _bookChip(Book? selected, List<Book> books) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: GestureDetector(
        onTap: _isLoading ? null : () => _pickBook(books),
        behavior: HitTestBehavior.opaque,
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
                child: (selected?.coverUrl != null &&
                        selected!.coverUrl!.isNotEmpty)
                    ? Image.network(selected.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox())
                    : const SizedBox(),
              ),
              const SizedBox(width: 7),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  selected?.title ?? '책 선택',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: selected != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down,
                  size: 16, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lyraBlock(String question) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.25)),
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
              const SizedBox(width: 7),
              Text('Lyra의 물음에 답하는 중',
                  style: AppTypography.caption.copyWith(
                      color: AppColors.accentGreen, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(question,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textPrimary, height: 1.6)),
        ],
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
          hintText: '오늘 읽은 문장, 그 문장이 남긴 생각을 적어보세요',
          hintStyle: AppTypography.body.copyWith(
              fontSize: 17, color: AppColors.textTertiary, height: 1.7),
        ),
      ),
    );
  }

  Widget _imagePreview() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(_selectedImagePath!),
              width: 84,
              height: 84,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 84,
                height: 84,
                color: AppColors.surface,
              ),
            ),
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

  Widget _saveBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: PrimaryButton(
        label: '저장',
        loading: _isLoading,
        onPressed: _isFormValid ? _saveMemo : null,
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
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
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
                hintText: '쪽',
                hintStyle:
                    AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
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
          _visOpt('공개', true),
          _visOpt('나만 보기', false),
        ],
      ),
    );
  }

  Widget _visOpt(String label, bool pub) {
    final on = _isPublic == pub;
    return GestureDetector(
      onTap: () => setState(() => _isPublic = pub),
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

  void _pickBook(List<Book> books) {
    if (books.isEmpty) {
      MemoErrorHandler.showErrorSnackBar(context, '먼저 책을 담아주세요');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgPrimary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('어떤 책의 메모인가요', style: AppTypography.title),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  itemCount: books.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final b = books[i];
                    final on = b.id == _selectedBookId;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedBookId = b.id);
                        Navigator.pop(context);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: (b.coverUrl != null && b.coverUrl!.isNotEmpty)
                                ? Image.network(b.coverUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox())
                                : const SizedBox(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(b.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.body.copyWith(
                                    color: on
                                        ? AppColors.accentGreen
                                        : AppColors.textPrimary)),
                          ),
                          if (on)
                            const Icon(Icons.check,
                                size: 18, color: AppColors.accentGreen),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
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
        try {
          final image = await picker.pickImage(source: source, imageQuality: 85);
          if (image != null) {
            setState(() => _selectedImagePath = image.path);
          }
        } on PlatformException catch (e) {
          if (mounted) MemoErrorHandler.showError(context, e);
        } catch (e) {
          if (mounted) MemoErrorHandler.showError(context, e);
        }
      }
    } catch (e) {
      if (mounted) MemoErrorHandler.showError(context, e);
    }
  }

  void _removeImage() => setState(() => _selectedImagePath = null);

  Future<void> _saveMemo() async {
    if (!_isFormValid) {
      if (_selectedBookId == null || _selectedBookId!.isEmpty) {
        MemoErrorHandler.showErrorSnackBar(context, '책을 선택해주세요');
        return;
      }
      if (_contentController.text.trim().isEmpty) {
        MemoErrorHandler.showErrorSnackBar(context, '메모 내용을 입력해주세요');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
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

      await ref.read(memoFormProvider(_selectedBookId!).notifier).createMemo(
            bookId: _selectedBookId!,
            content: _contentController.text.trim(),
            page: _pageController.text.isNotEmpty
                ? int.tryParse(_pageController.text)
                : null,
            imageUrl: imageUrl,
            visibility: visibility,
          );

      // Lyra 물음에서 진입해 작성 완료 -> 전환 계측 (N3 핵심 KPI)
      if (widget.lyraQuestion != null) {
        ref
            .read(analyticsProvider)
            .logEvent('lyra_question_answered', {'book_id': _selectedBookId!});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('메모가 저장되었습니다',
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
}
