import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/session_restore.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../splash_user_check.dart';
import '../widgets/splash_layout.dart';
import '../widgets/splash_retry_view.dart';
import '../../../../l10n/app_localizations.dart';
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
  bool _loadFailed = false;

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

        // 꺼진 앱에서 알림을 눌러 켜졌으면: 홈을 깔고 그 위에 메모 상세를 올린다.
        // (SessionRestore 가 덮어쓰지 않도록 복원보다 먼저 처리)
        final notif = NotificationService();
        if (notif.hasPendingColdStart && mounted) {
          context.goNamed(AppRoutes.homeName);
          if (notif.dispatchPendingColdStart()) return;
        }

        // 마지막 위치가 있으면 바로 복원(스플래시->홈 점프 방지).
        final last = await SessionRestore.last();
        if (last != null) {
          if (mounted) context.go(last);
          return;
        }

        // 마지막 위치가 없으면(첫 진입 등) 네트워크로 온보딩 판단 후 홈.
        // 조회 오류는 재시도 후에도 실패하면 throw -> 아래 catch 가 "다시 시도"를 보인다.
        final destination = await resolveSplashDestination(
          getUser: () => ref.read(authProvider.notifier).getCurrentUser(),
        );
        if (!mounted) return;
        switch (destination) {
          case SplashDestination.login:
            context.goNamed(AppRoutes.loginName);
          case SplashDestination.onboarding:
            context.goNamed(AppRoutes.onboardingNicknameName);
          case SplashDestination.home:
            context.goNamed(AppRoutes.homeName);
        }
        return;
      }

      // 세션 없음 -> 로그인.
      if (mounted) context.goNamed(AppRoutes.loginName);
    } catch (e) {
      if (e.toString().contains('업데이트가 필요합니다')) {
        _showForceUpdateDialog();
      } else if (mounted) {
        // 세션이 살아 있으면 오류를 로그아웃으로 읽지 않는다: 다시 시도.
        final hasSession =
            Supabase.instance.client.auth.currentSession != null;
        if (hasSession) {
          setState(() => _loadFailed = true);
        } else {
          context.goNamed(AppRoutes.loginName);
        }
      }
    }
  }

  void _retry() {
    setState(() => _loadFailed = false);
    _validateSession();
  }

  void _showForceUpdateDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(AppL10n.of(context).splashUpdateTitle),
        content: Text(AppL10n.of(context).splashUpdateBody),
        actions: [
          TextButton(
            onPressed: () {
              final url = Platform.isIOS
                  ? 'your_ios_app_store_url'
                  : 'your_android_play_store_url';
              launchUrl(Uri.parse(url));
            },
            child: Text(AppL10n.of(context).splashUpdateAction),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadFailed) return SplashRetryView(onRetry: _retry);
    return const SplashLayout();
  }
}
