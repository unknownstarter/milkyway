import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/design/cached_image.dart';
import '../../../../core/presentation/widgets/design/app_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../memos/presentation/providers/memo_provider.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nicknameController = TextEditingController();
  bool _isLoading = false;
  String? _selectedImagePath;
  bool _isImageRemoved = false;
  bool _isCheckingNickname = false;
  String? _nicknameError;
  String? _lastCheckedNickname;
  bool _lastCheckResult = true; // 마지막 체크 결과 (true: 사용 가능, false: 중복)
  String? _originalNickname; // 원본 닉네임 저장 (중복 체크 시 제외)
  Timer? _debounceTimer;
  bool _initialized = false; // 최초 1회만 컨트롤러 초기화(키보드 닫힘 등 재빌드 시 입력 유지)

  @override
  void initState() {
    super.initState();
    // initState에서는 ref를 사용할 수 없으므로 didChangeDependencies에서 처리
    _nicknameController.addListener(_validateInput);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면 재진입 시 최신 사용자 정보 로드 (예: 프로필 수정 후 돌아올 때)
    _loadUserData();
    // Analytics는 빌드 후에 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(analyticsProvider).logScreenView('profile_edit_screen');
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nicknameController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    // didChangeDependencies는 키보드 표시/숨김(MediaQuery 변화)에도 호출된다.
    // 매번 컨트롤러를 user.nickname으로 되돌리면 입력 중인 값이 날아가므로(엔터 시 리셋 버그)
    // 화면 진입 시 최초 1회만 초기화한다. 화면 재진입은 새 State라 다시 1회 로드된다.
    if (_initialized) return;
    final user = ref.read(authProvider).value;
    if (user == null) return;
    _nicknameController.text = user.nickname;
    _originalNickname = user.nickname;
    _lastCheckedNickname = user.nickname;
    _lastCheckResult = true;
    _nicknameError = null;
    _initialized = true;
  }

  void _validateInput() {
    // 즉시 기본 유효성 체크만 수행
    final nickname = _nicknameController.text.trim();
    final hasSpecialCharacters = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(nickname);

    // 원본 닉네임과 동일하면 중복 체크 불필요
    if (nickname == _originalNickname) {
      setState(() {
        _nicknameError = null;
        _isCheckingNickname = false;
        _lastCheckedNickname = nickname;
        _lastCheckResult = true; // 원본 닉네임은 항상 사용 가능
      });
      return;
    }

    // 기본 유효성 체크 및 에러 메시지 설정
    final l10n = AppL10n.of(context);
    String? formatError;
    if (nickname.isEmpty) {
      formatError = null; // 입력 전에는 에러 메시지 표시 안 함
    } else if (nickname.length < 2) {
      formatError = l10n.profileEditNicknameTooShort;
    } else if (nickname.length > 20) {
      formatError = l10n.profileEditNicknameTooLong;
    } else if (hasSpecialCharacters) {
      formatError = l10n.profileEditNicknameNoSpecial;
    }

    final isValidFormat = nickname.length >= 2 &&
        nickname.length <= 20 &&
        !hasSpecialCharacters;

    if (!isValidFormat) {
      setState(() {
        _nicknameError = formatError;
        _lastCheckedNickname = null;
        _lastCheckResult = true; // 형식 오류 시 초기화
        _isCheckingNickname = false;
      });
      return;
    }

    // 형식이 유효하면 중복 체크 전에 에러 메시지 초기화
    setState(() {
      _nicknameError = null;
    });

    // debounce: 500ms 후에 중복 체크 수행
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _checkNicknameAvailability(nickname);
    });
  }

  Future<void> _checkNicknameAvailability(String nickname) async {
    // 원본 닉네임과 동일하면 중복 체크 불필요
    if (nickname == _originalNickname) {
      setState(() {
        _nicknameError = null;
        _isCheckingNickname = false;
        _lastCheckedNickname = nickname;
        _lastCheckResult = true; // 원본 닉네임은 항상 사용 가능
      });
      return;
    }

    // 동일한 닉네임을 이미 체크했다면 이전 결과 사용
    if (_lastCheckedNickname == nickname) {
      setState(() {
        _isCheckingNickname = false;
        if (!_lastCheckResult) {
          _nicknameError = AppL10n.of(context).profileEditNicknameTaken;
        } else {
          _nicknameError = null;
        }
      });
      return;
    }

    // 닉네임 중복 체크
    setState(() {
      _isCheckingNickname = true;
      _nicknameError = null;
    });

    try {
      final isAvailable = await ref
          .read(authProvider.notifier)
          .checkNicknameAvailability(nickname);

      if (mounted) {
        setState(() {
          _isCheckingNickname = false;
          _lastCheckedNickname = nickname;
          _lastCheckResult = isAvailable; // 체크 결과 저장
          if (!isAvailable) {
            _nicknameError = AppL10n.of(context).profileEditNicknameTaken;
          } else {
            _nicknameError = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingNickname = false;
          _lastCheckResult = false; // 에러 발생 시 안전하게 false로 설정
          _nicknameError = AppL10n.of(context).profileEditNicknameCheckError;
        });
        // 에러 핸들러로도 표시
        ErrorHandler.showError(context, e, operation: '닉네임 중복 체크');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181818),
        title: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: Text(
            AppL10n.of(context).profileEditTitle,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: (_isLoading || _isCheckingNickname || _nicknameError != null) 
                ? null 
                : _saveProfile,
            child: Text(
              AppL10n.of(context).commonSave,
              style: TextStyle(
                color: (_isLoading || _isCheckingNickname || _nicknameError != null) 
                    ? Colors.grey 
                    : Colors.white,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 프로필 이미지
            _buildProfileImage(user?.pictureUrl),
            const SizedBox(height: 32),
            
            // 닉네임 입력
            _buildNicknameInput(),
            const SizedBox(height: 32),
            
            // 이메일 (읽기 전용)
            _buildEmailField(user?.email),
            const SizedBox(height: 40),
            
            // 로그아웃 버튼
            _buildLogoutButton(),
            const SizedBox(height: 16),
            
            // 계정 삭제 버튼
            _buildDeleteAccountButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(String? currentImageUrl) {
    return Column(
      children: [
        GestureDetector(
          onTap: _selectImage,
          child: Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: _getProfileImage(currentImageUrl),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _selectImage,
          icon: const Icon(Icons.camera_alt, color: Colors.white),
          label: Text(
            AppL10n.of(context).profileEditChangePhoto,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
        if (_selectedImagePath != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _removeImage,
            icon: const Icon(Icons.delete, color: Colors.red),
            label: Text(
              AppL10n.of(context).profileEditRemovePhoto,
              style: const TextStyle(
                color: Colors.red,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _getProfileImage(String? imageUrl) {
    if (_selectedImagePath != null) {
      return Image.file(
        File(_selectedImagePath!),
        fit: BoxFit.cover,
        width: 120,
        height: 120,
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedImage(
        url: imageUrl,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        cacheWidth: 360,
        fallback: _buildDefaultAvatar(),
      );
    } else {
      return _buildDefaultAvatar();
    }
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 120,
      height: 120,
      color: const Color(0xFF1A1A1A),
      child: const Icon(
        Icons.person,
        color: Colors.grey,
        size: 60,
      ),
    );
  }

  Widget _buildNicknameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppL10n.of(context).profileEditNicknameLabel,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nicknameController,
          enableInteractiveSelection: true,
          enableSuggestions: Theme.of(context).platform != TargetPlatform.android, // 안드로이드에서는 false
          cursorColor: Colors.white,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Pretendard',
            fontSize: 16,
            height: 22.4 / 16,
          ),
          decoration: InputDecoration(
            hintText: AppL10n.of(context).profileEditNicknameHint,
            hintStyle: const TextStyle(
              color: Color(0xFF838383),
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 22.4 / 16,
            ),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF646464)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF646464)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF646464)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (_isCheckingNickname) ...[
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF838383),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                AppL10n.of(context).profileEditChecking,
                style: const TextStyle(
                  color: Color(0xFF838383),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Pretendard',
                  height: 16.8 / 12,
                ),
              ),
            ] else if (_nicknameError != null) ...[
              const Icon(
                Icons.error_outline,
                size: 12,
                color: Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                _nicknameError!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Pretendard',
                  height: 16.8 / 12,
                ),
              ),
            ] else ...[
              Text(
                AppL10n.of(context).profileEditNicknameRule,
                style: const TextStyle(
                  color: Color(0xFF838383),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Pretendard',
                  height: 16.8 / 12,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildEmailField(String? email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppL10n.of(context).profileEditEmailLabel,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: Text(
            email ?? AppL10n.of(context).profileEditNoEmail,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppL10n.of(context).profileEditEmailFixed,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
            fontFamily: 'Pretendard',
          ),
        ),
      ],
    );
  }

  Future<void> _selectImage() async {
    try {
      final picker = ImagePicker();
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(AppL10n.of(context).profileEditPickImage,
              style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: Text(AppL10n.of(context).profileEditFromGallery,
                    style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: Text(AppL10n.of(context).profileEditFromCamera,
                    style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        // 원본 대신 리사이즈/압축해 업로드(화질 유지, 용량↓). 프로필은 소형 표시라 1024면 충분.
        final image = await picker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1024,
          maxHeight: 1024,
        );
        if (image != null && mounted) {
          setState(() {
            _selectedImagePath = image.path;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppL10n.of(context).profileEditPickImageError('$e'),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF242424),
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImagePath = null;
      _isImageRemoved = true;
    });
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: _logout,
        style: TextButton.styleFrom(
          backgroundColor: Colors.red.shade900.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.red.shade700, width: 1),
          ),
        ),
        child: Text(
          AppL10n.of(context).profileEditLogout,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          AppL10n.of(context).profileEditLogout,
          style: const TextStyle(color: Colors.white, fontFamily: 'Pretendard'),
        ),
        content: Text(
          AppL10n.of(context).profileEditLogoutConfirm,
          style: const TextStyle(color: Colors.white, fontFamily: 'Pretendard'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppL10n.of(context).commonCancel,
              style: const TextStyle(color: Colors.grey, fontFamily: 'Pretendard'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppL10n.of(context).profileEditLogout,
              style: const TextStyle(color: Colors.red, fontFamily: 'Pretendard'),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      await ref.read(authProvider.notifier).signOut();
      if (mounted) {
        context.goNamed(AppRoutes.loginName);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, operation: '로그아웃');
      }
    }
  }

  Widget _buildDeleteAccountButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: _deleteAccount,
        style: TextButton.styleFrom(
          backgroundColor: Colors.grey.shade800,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade700, width: 1),
          ),
        ),
        child: Text(
          AppL10n.of(context).profileEditDeleteAccount,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    // 30일 소프트딜리트 안내(기존 컨펌 모달 디자인 재사용).
    final l10n = AppL10n.of(context);
    final shouldDelete = await showAppConfirm(
      context,
      title: l10n.profileEditDeleteAccount,
      message: l10n.profileEditDeleteAccountMessage,
      confirmText: l10n.profileEditDelete,
      tone: ConfirmTone.danger,
    );

    if (!shouldDelete) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authProvider.notifier).deleteAccount();
      if (mounted) {
        context.goNamed(AppRoutes.loginName);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, operation: '계정 삭제');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final nickname = _nicknameController.text.trim();
    final l10n = AppL10n.of(context);

    // 유효성 검사
    if (nickname.isEmpty) {
      ErrorHandler.showSuccess(
        context,
        l10n.profileEditNicknameRequired,
      );
      return;
    }

    // 원본 닉네임과 다르면 중복 체크가 완료되었는지 확인
    if (nickname != _originalNickname) {
      // 중복 체크 중이면 저장 불가
      if (_isCheckingNickname) {
        ErrorHandler.showSuccess(
          context,
          l10n.profileEditNicknameChecking,
        );
        return;
      }

      // 아직 체크하지 않은 닉네임이면 체크 수행
      if (_lastCheckedNickname != nickname) {
        await _checkNicknameAvailability(nickname);
        // 체크 후에도 에러가 있으면 저장 불가
        if (_nicknameError != null) {
          return;
        }
      } else if (_nicknameError != null) {
        // 이미 체크했는데 에러가 있으면 저장 불가
        return;
      }
    }

    // 원본 닉네임과 동일하고 이미지도 변경되지 않았으면 저장 불필요
    if (nickname == _originalNickname && 
        _selectedImagePath == null && 
        !_isImageRemoved) {
      ErrorHandler.showSuccess(
        context,
        l10n.profileEditNoChanges,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 프로필 이미지 처리
      String? uploadedImageUrl;
      if (_isImageRemoved) {
        // 이미지 제거 요청
        uploadedImageUrl = '';
      } else if (_selectedImagePath != null) {
        // 새 이미지 업로드
        uploadedImageUrl = await _uploadProfileImage(_selectedImagePath!);
        if (uploadedImageUrl == null) {
          if (mounted) {
            ErrorHandler.showErrorSnackBar(
              context,
              message: l10n.profileEditImageUploadFailed,
            );
          }
          return;
        }
      }
      // _selectedImagePath가 null이고 _isImageRemoved가 false면 기존 이미지 유지 (uploadedImageUrl = null)

      await ref.read(authProvider.notifier).updateProfile(
        nickname: nickname,
        pictureUrl: uploadedImageUrl,
      );

      // 내 메모/댓글 카드에 박힌 닉네임·아바타가 바뀐 값으로 갱신되게 목록/피드 무효화.
      // (메모/댓글 상세는 재진입 시 재조회되므로 목록·피드만 갱신하면 충분)
      ref.invalidate(allMemosProvider);
      ref.invalidate(paginatedMemosProvider(null));
      ref.invalidate(recentMemosProvider);
      ref.invalidate(homeRecentMemosProvider);
      ref.invalidate(publicMemoFeedProvider);
      ref.invalidate(homePublicMemoFeedProvider);
      ref.invalidate(paginatedPublicFeedProvider);

      if (mounted) {
        ErrorHandler.showSuccess(
          context,
          l10n.profileEditSaved,
        );
        // 원본 닉네임 업데이트
        _originalNickname = nickname;
        _lastCheckedNickname = nickname;
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, operation: '프로필 수정');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 프로필 이미지를 Supabase Storage에 업로드하고 signed URL을 반환
  Future<String?> _uploadProfileImage(String filePath) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        return null;
      }

      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(filePath);

      // 파일 존재 여부 확인
      if (!await file.exists()) {
        return null;
      }

      // Supabase Storage에 업로드
      await supabase.storage.from('profile_images').upload(fileName, file);

      // 공개 URL(만료 없음). 서명 URL 만료로 아바타가 죽던 문제 방지.
      final imageUrl =
          supabase.storage.from('profile_images').getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      return null;
    }
  }
}