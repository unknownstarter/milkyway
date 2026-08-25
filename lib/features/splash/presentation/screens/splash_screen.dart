import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/splash_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:developer';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 인위적 지연 없음 — 콜드 스타트 시 스플래시 체감을 최소화하려 세션 검증을 즉시 시작.
    // 첫 프레임 페인트 뒤에 시작해 라우팅 컨텍스트를 안전하게 확보.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _validateSession();
    });
  }

  Future<void> _validateSession() async {
    try {
      // 네트워크 연결 체크 추가
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('인터넷 연결 없음'),
              content: const Text('인터넷 연결을 확인하고 다시 시도해주세요.'),
              actions: [
                TextButton(
                  onPressed: () {
                    _validateSession(); // 재시도
                    Navigator.pop(context);
                  },
                  child: const Text('재시도'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // 앱 버전 체크는 라우팅을 막지 않게 백그라운드로(현재 no-op, 강제업데이트 도입 대비).
      unawaited(ref.read(authProvider.notifier).checkAppVersion());

      // 세션 갱신 시도 (refresh token을 사용하여 최대 1개월까지 유지)
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;

      if (session != null && !session.isExpired) {
        // 세션이 유효하면 사용자 정보 가져오기
        final user = await ref.read(authProvider.notifier).getCurrentUser();
        if (user == null) {
          if (mounted) context.goNamed(AppRoutes.loginName);
          return;
        }

        if (!user.onboardingCompleted) {
          if (mounted) context.goNamed(AppRoutes.onboardingNicknameName);
          return;
        }

        if (mounted) context.goNamed(AppRoutes.homeName);
        return;
      }

      // 세션이 없거나 만료된 경우, refresh token으로 갱신 시도
      if (session != null) {
        try {
          log('세션 만료됨, refresh token으로 갱신 시도...');
          await supabase.auth.refreshSession();
          log('세션 갱신 성공');
          
          // 갱신 후 다시 사용자 정보 확인
          final user = await ref.read(authProvider.notifier).getCurrentUser();
          if (user != null) {
            if (!user.onboardingCompleted) {
              if (mounted) context.goNamed(AppRoutes.onboardingNicknameName);
              return;
            }
            if (mounted) context.goNamed(AppRoutes.homeName);
            return;
          }
        } catch (e) {
          log('세션 갱신 실패: $e');
        }
      }

      // 세션 갱신 실패 또는 세션이 없는 경우 로그인 화면으로
      if (mounted) context.goNamed(AppRoutes.loginName);
    } catch (e) {
      if (e.toString().contains('업데이트가 필요합니다')) {
        _showForceUpdateDialog();
      } else {
        if (mounted) context.goNamed(AppRoutes.loginName);
      }
    }
  }

  void _showForceUpdateDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('업데이트 필요'),
        content: const Text('새로운 버전이 있습니다.\n원활한 사용을 위해 업데이트를 진행해주세요.'),
        actions: [
          TextButton(
            onPressed: () {
              final url = Platform.isIOS
                  ? 'your_ios_app_store_url'
                  : 'your_android_play_store_url';
              launchUrl(Uri.parse(url));
            },
            child: const Text('업데이트'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SplashLayout();
  }
}
