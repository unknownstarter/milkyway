import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/services/session_restore.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/splash_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:io';

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
      // 앱 버전 체크는 라우팅을 막지 않게 백그라운드로(현재 no-op, 강제업데이트 도입 대비).
      unawaited(ref.read(authProvider.notifier).checkAppVersion());

      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;

      if (session != null) {
        // 로컬 세션이 있으면(리프레시토큰 최대 1개월 유효) 낙관적으로 즉시 진입한다.
        // 네트워크 refreshSession/유저조회를 기다리지 않아 스플래시 체류가 없고 오프라인도
        // 동작한다(백그라운드에서 OS가 앱을 종료해 콜드스타트로 돌아와도 재개처럼).
        // 세션/유저 갱신은 authProvider가 백그라운드에서 수행한다.

        // 딥링크로 켜졌으면 그 카드가 우선.
        if (await DeepLinkService.consumePending()) return;

        // 마지막 위치가 있으면 바로 복원(스플래시->홈 점프 방지).
        final last = await SessionRestore.last();
        if (last != null) {
          if (mounted) context.go(last);
          return;
        }

        // 마지막 위치가 없으면(첫 진입 등) 네트워크로 온보딩 판단 후 홈.
        final user = await ref.read(authProvider.notifier).getCurrentUser();
        if (!mounted) return;
        if (user == null) {
          context.goNamed(AppRoutes.loginName);
          return;
        }
        if (!user.onboardingCompleted) {
          context.goNamed(AppRoutes.onboardingNicknameName);
          return;
        }
        context.goNamed(AppRoutes.homeName);
        return;
      }

      // 세션 없음 -> 로그인.
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
