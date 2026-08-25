import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileImageScreen extends ConsumerStatefulWidget {
  const ProfileImageScreen({super.key});

  @override
  ConsumerState<ProfileImageScreen> createState() => _ProfileImageScreenState();
}

class _ProfileImageScreenState extends ConsumerState<ProfileImageScreen> {
  String? _selectedImagePath;
  bool _isLoading = false;
  bool _isSelectingImage = false;

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).logScreenView('profile_image_screen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181818),
        title: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: const Text(
            '프로필 사진',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(AppRoutes.onboardingNicknameName);
            }
          },
        ),
      ),
      body: Column(
        children: [
          // 스크롤 가능한 컨텐츠 영역
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  
                  // 제목
                  _buildTitle(),
                  const SizedBox(height: 40),
                  
                  // 프로필 이미지
                  _buildProfileImage(),
                  const SizedBox(height: 40),
                  
                  // 설명 텍스트
                  _buildDescription(),
                ],
              ),
            ),
          ),
          
          // 하단 고정 버튼 영역
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 다음 버튼
                _buildNextButton(),
                const SizedBox(height: 8),
                
                // 건너뛰기 버튼
                _buildSkipButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '프로필 사진을 설정해주세요',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
            height: 33.6 / 24,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '나중에 언제든지 변경할 수 있어요',
          style: TextStyle(
            color: Color(0xFF838383),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
            height: 16.8 / 12,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: GestureDetector(
        onTap: _isSelectingImage ? null : _selectImage,
        child: Opacity(
          opacity: _isSelectingImage ? 0.5 : 1.0,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF48FF00),
                width: 4,
              ),
            ),
            child: ClipOval(
              child: _getProfileImage(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getProfileImage() {
    if (_selectedImagePath != null) {
      return Image.file(
        File(_selectedImagePath!),
        fit: BoxFit.cover,
        width: 200,
        height: 200,
      );
    } else {
      return Container(
        width: 200,
        height: 200,
        color: const Color(0xFF1A1A1A),
        child: const Icon(
          Icons.person,
          color: Colors.grey,
          size: 80,
        ),
      );
    }
  }

  Widget _buildDescription() {
    return Center(
      child: Column(
        children: [
          const Text(
            '등록된 프로필 사진은\n남겨주신 메모와 함께 보여져요',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard',
              height: 33.6 / 24,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '공개 설정한 메모만 보여지니 걱정마세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF838383),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard',
              height: 16.8 / 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkipButton() {
    return Center(
      child: TextButton(
        onPressed: _isLoading ? null : _skipImage,
        child: const Text(
          '건너뛰기',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            fontFamily: 'Pretendard',
            height: 16.8 / 12,
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final isEnabled = _selectedImagePath != null && !_isLoading;
    
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
          onTap: isEnabled ? _next : null,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(
                    color: Color(0xFFECECEC),
                    strokeWidth: 2,
                  )
                : MediaQuery(
                    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
                    child: Text(
                      '다음',
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
      ),
    );
  }

  Future<void> _selectImage() async {
    if (_isSelectingImage) return;
    
    setState(() {
      _isSelectingImage = true;
    });
    
    try {
      final picker = ImagePicker();
      // 원본 대신 리사이즈/압축해 업로드(화질 유지, 용량↓). 프로필은 소형 표시라 1024면 충분.
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (image != null && mounted) {
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        // 권한 관련 에러 처리
        if (e.code == 'photo_access_denied' || 
            e.code == 'camera_access_denied' ||
            e.code.contains('permission') ||
            e.code.contains('denied')) {
          ErrorHandler.showError(
            context,
            e,
            operation: '프로필 이미지 선택',
          );
        } else {
          ErrorHandler.showError(
            context,
            e,
            operation: '프로필 이미지 선택',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(
          context,
          e,
          operation: '프로필 이미지 선택',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSelectingImage = false;
        });
      }
    }
  }


  Future<void> _skipImage() async {
    await _next();
  }

  Future<void> _next() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 프로필 이미지 저장
      if (_selectedImagePath != null) {
        // Supabase Storage에 이미지 업로드
        final uploadedImageUrl = await _uploadProfileImage(_selectedImagePath!);
        if (uploadedImageUrl != null && mounted) {
          // 데이터베이스에 프로필 이미지 URL 저장
          await ref.read(authProvider.notifier).updateProfile(
            pictureUrl: uploadedImageUrl,
          );
        } else if (mounted) {
          ErrorHandler.showError(
            context,
            Exception('프로필 이미지 업로드에 실패했습니다'),
            operation: '프로필 이미지 업로드',
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // 다음 화면으로 이동 (장르 선택 스텝)
      if (mounted) {
        context.pushNamed(AppRoutes.onboardingGenreName);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(
          context,
          e,
          operation: '프로필 이미지 저장',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 프로필 이미지를 Supabase Storage에 업로드하고 signed URL 반환
  Future<String?> _uploadProfileImage(String filePath) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final file = File(filePath);
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePathInStorage = 'profile_images/$fileName';

      // Storage에 업로드
      await supabase.storage.from('profile_images').upload(
        filePathInStorage,
        file,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'image/jpeg',
        ),
      );

      // 공개 URL(만료 없음). 서명 URL 만료로 아바타가 죽던 문제 방지.
      final signedUrl = supabase.storage
          .from('profile_images')
          .getPublicUrl(filePathInStorage);

      return signedUrl;
    } catch (e) {
      developer.log('프로필 이미지 업로드 실패: $e');
      return null;
    }
  }
}