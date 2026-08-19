import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/memo_form_provider.dart';
import '../../../books/presentation/providers/user_books_provider.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../domain/models/memo_visibility.dart';
import '../widgets/memo_visibility_toggle.dart';
import '../widgets/memo_content_input.dart';
import '../widgets/memo_page_input.dart';
import '../widgets/memo_image_selector.dart';
import '../../utils/memo_image_uploader.dart';
import '../../utils/memo_error_handler.dart';

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
  bool _isPublic = true; // 공개/비공개 토글 상태 (기본값: 공개)

  @override
  void initState() {
    super.initState();
    _selectedBookId = widget.bookId;
    _contentController.addListener(() => setState(() {}));
    ref.read(analyticsProvider).logScreenView('memo_create_screen');
  }

  // 필수값이 모두 채워졌는지 확인
  bool get _isFormValid {
    return _selectedBookId != null && 
           _selectedBookId!.isNotEmpty &&
           _contentController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _contentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181818),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(AppRoutes.homeName);
            }
          },
        ),
        title: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: const Text(
            '메모 작성',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 20,
              height: 28 / 20,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lyra 물음 컨텍스트 (물음에서 진입했을 때만)
            if (widget.lyraQuestion != null) ...[
              _buildLyraQuestionBanner(widget.lyraQuestion!),
              const SizedBox(height: 20),
            ],

            // 책 선택
            _buildBookSelector(),
            const SizedBox(height: 20),

                // 메모 공개 선택 (토글)
                MemoVisibilityToggle(
                  value: _isPublic,
                  onChanged: (value) {
                    setState(() {
                      _isPublic = value;
                    });
                  },
                ),
            const SizedBox(height: 20),

            // 메모 내용
                MemoContentInput(controller: _contentController),
                const SizedBox(height: 20),

                // 페이지 입력
                MemoPageInput(controller: _pageController),
            const SizedBox(height: 20),

            // 이미지 선택
                MemoImageSelector(
                  imagePath: _selectedImagePath,
                  onSelectImage: _selectImage,
                  onRemoveImage: _removeImage,
                ),
                SizedBox(
                  height: 50 + 20 + 20 + MediaQuery.of(context).padding.bottom + 20, // 버튼 높이 + 상하 패딩 + SafeArea + 여유 공간
                ),
              ],
            ),
          ),
          // 하단 고정 저장하기 버튼 (책 상세의 메모하기와 동일한 스타일)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              bottom: false, // SafeArea를 false로 하여 하단까지 확장
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 불투명 배경 (181818 색상으로 버튼 뒤와 아래 영역 모두 가리기)
                  Container(
                    color: const Color(0xFF181818),
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 20,
                      bottom: 20,
                    ),
                    child: _buildSaveButton(),
                  ),
                  // 하단 영역까지 181818로 가리기
                  Container(
                    color: const Color(0xFF181818),
                    height: MediaQuery.of(context).padding.bottom,
                  ),
          ],
        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyraQuestionBanner(String question) {
    const accent = Color(0xFF48FF00);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              SizedBox(
                width: 6,
                height: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Lyra의 물음',
                style: TextStyle(
                  color: accent,
                  fontFamily: 'Pretendard',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question,
            style: const TextStyle(
              color: Color(0xFFECECEC),
              fontFamily: 'Pretendard',
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookSelector() {
    final booksAsync = ref.watch(userBooksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '책 선택',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
            height: 28 / 20,
          ),
        ),
        const SizedBox(height: 8),
        booksAsync.when(
          data: (books) => _buildBookDropdown(books),
          loading: () =>
              const CircularProgressIndicator(color: Color(0xFFECECEC)),
          error: (error, stack) => Text(
            '책 목록을 불러올 수 없습니다: $error',
            style: const TextStyle(color: Colors.red, fontFamily: 'Pretendard'),
          ),
        ),
      ],
    );
  }

  Widget _buildBookDropdown(List<dynamic> books) {
    return Container(
      width: double.infinity,
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF646464)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBookId,
          isExpanded: true,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Pretendard',
            fontSize: 16,
          ),
          dropdownColor: const Color(0xFF1A1A1A),
          hint: _selectedBookId == null
              ? const Text(
                  '어떤 책을 읽고 있나요?',
                  style: TextStyle(
                    color: Color(0xFF838383),
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                  ),
                )
              : null,
          items: books.map((book) {
            return DropdownMenuItem<String>(
              value: book.id,
              child: Text(book.title, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedBookId = value;
            });
          },
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white,
            size: 24,
          ),
          menuMaxHeight: 400, // 드롭다운 최대 높이 설정
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final isEnabled = _isFormValid && !_isLoading;
    
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: isEnabled ? const Color(0xFFDEDEDE) : const Color(0xFF838383),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? _saveMemo : null,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: Text(
              '저장하기',
              style: TextStyle(
                color: isEnabled ? Colors.black : Colors.white,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                height: 24 / 16,
              ),
            ),
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
        barrierColor: Colors.black.withOpacity(0.5), // 어두운 딤 처리
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('이미지 선택', style: TextStyle(color: Colors.white)),
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
          final image = await picker.pickImage(
            source: source,
            imageQuality: 85,
          );
          if (image != null) {
            setState(() {
              _selectedImagePath = image.path;
            });
          }
        } on PlatformException catch (e) {
          if (mounted) {
            MemoErrorHandler.showError(context, e);
          }
        } catch (e) {
          if (mounted) {
            MemoErrorHandler.showError(context, e);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        MemoErrorHandler.showError(context, e);
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImagePath = null;
    });
  }

  Future<void> _saveMemo() async {
    // 필수값 검증 (이미 버튼에서 체크하지만 이중 체크)
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

    setState(() {
      _isLoading = true;
    });

    try {
      final visibility = _isPublic ? MemoVisibility.public : MemoVisibility.private;
      
      // 이미지가 로컬 파일 경로인 경우 Supabase Storage에 업로드
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
            content: Text(
              '메모가 저장되었습니다',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF242424),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        MemoErrorHandler.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
