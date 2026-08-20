import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/providers/analytics_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/error_handler.dart';

class BookIntroScreen extends ConsumerStatefulWidget {
  const BookIntroScreen({super.key});

  @override
  ConsumerState<BookIntroScreen> createState() => _BookIntroScreenState();
}

class _BookIntroScreenState extends ConsumerState<BookIntroScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).logScreenView('book_intro_screen');
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
            '시작하기',
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
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // 스크롤 가능한 컨텐츠 영역
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  
                  // 우주 이미지
                  _buildUniverseImage(),
                  
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
                // 책 검색하고 시작하기 버튼
                _buildStartButton(),
                const SizedBox(height: 8),
                
                // 다음에 하기 버튼
                _buildSkipButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUniverseImage() {
    return Center(
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return RadialGradient(
            center: Alignment.center,
            radius: 0.5,
            colors: [
              Colors.white,
              Colors.white.withAlpha(0),
            ],
            stops: const [0.7, 1.0],
          ).createShader(bounds);
        },
        child: Image.asset(
          'assets/images/stars_bg.png',
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.width * 0.8,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return const Center(
      child: Text(
        '이제 책을 읽으며\n떠오른 반짝이는 생각을\n메모하고 저장해요 ✨',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Pretendard',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 33.6 / 24,
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFDEDEDE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleStart,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(
                    color: Color(0xFFECECEC),
                    strokeWidth: 2,
                  )
                : MediaQuery(
                    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
                    child: const Text(
                      '책 검색하고 시작하기',
                      style: TextStyle(
                        color: Colors.black,
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

  Widget _buildSkipButton() {
    return Center(
      child: TextButton(
        onPressed: _isLoading ? null : _handleSkip,
        child: const Text(
          '다음에 하기',
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

  Future<void> _handleStart() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(analyticsProvider)
          .logEvent('click_start_in_book_intro');

      // 온보딩 완료 처리
      await ref.read(authProvider.notifier).updateOnboardingStatus(true);

      // 세션 동기화를 위해 사용자 정보 다시 가져오기
      await ref.read(authProvider.notifier).getCurrentUser();

      // 온보딩 완료 이벤트
      await ref.read(analyticsProvider).logEvent('click_complete_in_onboarding');

      // 책 검색 페이지로 이동 (온보딩 플래그 포함)
      if (mounted) {
        context.goNamed(
          AppRoutes.bookSearchName,
          queryParameters: {'isFromOnboarding': 'true'},
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ErrorHandler.showError(context, e, operation: '온보딩 완료');
      }
    }
  }

  Future<void> _handleSkip() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 온보딩 완료 처리
      await ref.read(authProvider.notifier).updateOnboardingStatus(true);

      // 온보딩 완료 이벤트
      await ref.read(analyticsProvider).logEvent('click_complete_in_onboarding');

      // 홈 화면으로 이동
      if (mounted) {
        context.goNamed(AppRoutes.homeName);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
