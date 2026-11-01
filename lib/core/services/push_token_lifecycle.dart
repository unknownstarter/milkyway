import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_service.dart';

/// 로그인된 상태가 확인되는 순간마다 푸시 토큰을 맞춰 둔다.
/// 앱 시작(세션 복원), 로그인/세션 이벤트, 앱 복귀(resumed).
/// [extraSyncs] (예: 시간대 동기화) 도 같은 시점에 함께 돈다.
class PushTokenLifecycle with WidgetsBindingObserver {
  PushTokenLifecycle({this.extraSyncs = const []});

  final List<Future<void> Function()> extraSyncs;
  StreamSubscription<AuthState>? _authSub;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    try {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((s) {
        if (s.session != null) _sync();
      });
    } catch (_) {
      /* Supabase 미초기화 */
    }
    _sync();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sync();
  }

  void _sync() {
    unawaited(NotificationService().registerToken());
    for (final extra in extraSyncs) {
      unawaited(extra());
    }
  }
}
