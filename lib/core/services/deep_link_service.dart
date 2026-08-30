import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../router/app_router.dart';
import '../router/app_routes.dart';

/// 딥링크(커스텀 스킴 `milkyway://card/{code}`) 수신 + 게이트 라우팅.
///   - 콜드스타트: 초기 링크는 pending 저장만(스플래시가 소비 -> 이중 네비 방지).
///   - 웜스타트: 실행 중 스트림 이벤트는 즉시 게이트 라우팅.
/// 미로그인/온보딩 중이면 pending code를 유지, 로그인/온보딩 완료 지점이 소비한다.
/// 상세: docs/design/07-DEEP_LINK.md
class DeepLinkService {
  DeepLinkService(this._ref);

  final WidgetRef _ref;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  static const _key = 'pending_share_code';

  Future<void> init() async {
    // 콜드스타트: 앱이 링크로 켜졌으면 초기 링크 -> pending 저장(스플래시가 소비).
    try {
      final code = _codeOf(await _appLinks.getInitialLink());
      if (code != null) await savePending(code);
    } catch (_) {/* noop */}

    // 웜스타트: 실행 중 수신 -> 즉시 라우팅.
    _sub = _appLinks.uriLinkStream.listen(
      (uri) {
        final code = _codeOf(uri);
        if (code != null) _routeWarm(code);
      },
      onError: (_) {/* noop */},
    );
  }

  void dispose() => _sub?.cancel();

  /// `milkyway://card/{code}` -> code. 그 외 스킴/호스트면 null.
  static String? _codeOf(Uri? uri) {
    if (uri == null || uri.scheme != 'milkyway' || uri.host != 'card') return null;
    final segs = uri.pathSegments;
    if (segs.isEmpty || segs.first.isEmpty) return null;
    return segs.first;
  }

  static Future<void> savePending(String code) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, code);
  }

  static Future<String?> readPending() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_key);
  }

  static Future<void> clearPending() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }

  /// 홈 진입 자격이 된 지점(스플래시/로그인/온보딩 완료)에서 호출.
  /// pending code가 있으면 소비하고 카드로 이동, true 반환. 없으면 false.
  static Future<bool> consumePending() async {
    final code = await readPending();
    if (code == null || code.isEmpty) return false;
    await clearPending();
    router.goNamed(AppRoutes.sharedCardName, pathParameters: {'code': code});
    return true;
  }

  /// 웜스타트 수신: 현재 인증 상태로 게이트 분기.
  Future<void> _routeWarm(String code) async {
    await savePending(code);
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null || session.isExpired) {
      router.goNamed(AppRoutes.loginName); // pending 유지 -> 로그인 후 소비
      return;
    }
    final user = await _ref.read(authProvider.notifier).getCurrentUser();
    if (user == null) {
      router.goNamed(AppRoutes.loginName);
      return;
    }
    if (!user.onboardingCompleted) {
      router.goNamed(AppRoutes.onboardingNicknameName); // pending 유지 -> 온보딩 후 소비
      return;
    }
    await clearPending();
    router.goNamed(AppRoutes.sharedCardName, pathParameters: {'code': code});
  }
}
