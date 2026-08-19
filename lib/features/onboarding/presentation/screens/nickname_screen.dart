import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../../../../core/providers/analytics_provider.dart';

class NicknameScreen extends ConsumerStatefulWidget {
  const NicknameScreen({super.key});

  @override
  ConsumerState<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends ConsumerState<NicknameScreen> {
  final _nicknameController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  bool _isCheckingNickname = false;
  String? _nicknameError;
  String? _lastCheckedNickname;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_validateInput);
    ref.read(analyticsProvider).logScreenView('nickname_screen');
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nicknameController.dispose();
    super.dispose();
  }

  void _validateInput() {
    // 즉시 기본 유효성 체크만 수행
    final nickname = _nicknameController.text.trim();
    final hasSpecialCharacters = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(nickname);

    // 기본 유효성 체크 및 에러 메시지 설정
    String? formatError;
    if (nickname.isEmpty) {
      formatError = null; // 입력 전에는 에러 메시지 표시 안 함
    } else if (nickname.length < 2) {
      formatError = '닉네임은 최소 2자 이상이어야 합니다';
    } else if (nickname.length > 20) {
      formatError = '닉네임은 최대 20자까지 입력 가능합니다';
    } else if (hasSpecialCharacters) {
      formatError = '특수문자는 사용할 수 없습니다';
    }

    final isValidFormat = nickname.length >= 2 &&
        nickname.length <= 20 &&
        !hasSpecialCharacters;

    if (!isValidFormat) {
      setState(() {
        _isButtonEnabled = false;
        _nicknameError = formatError;
        _lastCheckedNickname = null;
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
    // 동일한 닉네임을 이미 체크했다면 다시 체크하지 않음
    if (_lastCheckedNickname == nickname) {
      setState(() {
        _isButtonEnabled = _nicknameError == null;
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
          if (!isAvailable) {
            _nicknameError = '이미 사용 중인 닉네임입니다';
            _isButtonEnabled = false;
          } else {
            _nicknameError = null;
            _isButtonEnabled = true;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingNickname = false;
          _nicknameError = '닉네임 확인 중 오류가 발생했습니다';
          _isButtonEnabled = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        title: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: const Text(
            '닉네임 설정',
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
        automaticallyImplyLeading: false,
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
                  
                  // 닉네임 입력
                  _buildNicknameInput(),
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
          '닉네임을 설정해주세요',
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
          '밀키웨이의 다른 유저가 볼 수 있는 이름이에요',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
            height: 16.8 / 12,
          ),
        ),
      ],
    );
  }

  Widget _buildNicknameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '닉네임',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
            height: 28 / 20,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nicknameController,
          enableInteractiveSelection: true,
          enableSuggestions: Theme.of(context).platform != TargetPlatform.android, // 안드로이드에서는 false
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Pretendard',
            fontSize: 16,
            height: 22.4 / 16,
          ),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: '닉네임을 입력하세요',
            hintStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 22.4 / 16,
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.textTertiary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.textTertiary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.textTertiary),
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
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '확인 중...',
                style: TextStyle(
                  color: AppColors.textSecondary,
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
              const Text(
                '2 - 20자, 특수문자 사용 불가',
                style: TextStyle(
                  color: AppColors.textSecondary,
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

  Widget _buildSkipButton() {
    return Center(
      child: TextButton(
        onPressed: _isLoading ? null : _handleSkip,
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
    final isEnabled = _isButtonEnabled && !_isLoading;
    
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: isEnabled ? AppColors.textBright : AppColors.textSecondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? _handleNext : null,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(
                    color: AppColors.textPrimary,
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

  Future<void> _handleSkip() async {
    // 건너뛰기는 유효성 체크 없이 바로 두번째 온보딩으로 이동
    if (mounted) {
      context.goNamed(AppRoutes.onboardingProfileImageName);
    }
  }

  Future<void> _handleNext() async {
    if (!_isButtonEnabled) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final nickname = _nicknameController.text.trim();
      await ref.read(authProvider.notifier).updateProfile(nickname: nickname);
      await ref.read(onboardingProvider.notifier).setNickname(nickname);

      if (mounted) {
        context.pushNamed(AppRoutes.onboardingProfileImageName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '닉네임 설정 중 오류가 발생했습니다: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.surfaceMuted,
          ),
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
}