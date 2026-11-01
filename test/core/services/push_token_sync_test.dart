import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/core/services/push_token_sync.dart';

void main() {
  late StreamController<String> refresh;
  late List<(String, String)> saved;
  late bool permitted;
  late String? uid;
  late String? token;
  late int apnsCalls;
  late String? apns;

  PushTokenSync build({bool ios = false}) => PushTokenSync(
        hasPermission: () async => permitted,
        getToken: () async => token,
        tokenRefreshStream: () => refresh.stream,
        currentUserId: () => uid,
        save: (u, t) async => saved.add((u, t)),
        getApnsToken: ios
            ? () async {
                apnsCalls++;
                return apns;
              }
            : null,
        apnsRetryDelay: Duration.zero,
      );

  setUp(() {
    refresh = StreamController<String>.broadcast();
    saved = [];
    permitted = true;
    uid = 'u1';
    token = 't1';
    apnsCalls = 0;
    apns = 'apns';
  });

  test('같은 토큰이면 두 번째 sync 는 저장하지 않는다', () async {
    final s = build();
    await s.sync();
    await s.sync();
    expect(saved, [('u1', 't1')]);
  });

  test('토큰이 바뀌면 다시 저장한다', () async {
    final s = build();
    await s.sync();
    token = 't2';
    await s.sync();
    expect(saved.length, 2);
  });

  test('다른 사용자로 로그인하면 같은 토큰도 다시 저장한다', () async {
    final s = build();
    await s.sync();
    uid = 'u2';
    await s.sync();
    expect(saved, [('u1', 't1'), ('u2', 't1')]);
  });

  test('권한이 없으면 저장하지 않는다', () async {
    permitted = false;
    await build().sync();
    expect(saved, isEmpty);
  });

  test('로그아웃 상태면 저장하지 않는다', () async {
    uid = null;
    await build().sync();
    expect(saved, isEmpty);
  });

  test('onTokenRefresh 리스너는 sync 를 여러 번 불러도 한 번만 붙는다', () async {
    final s = build();
    await s.sync();
    await s.sync();
    await s.sync();
    expect(refresh.hasListener, isTrue);
    refresh.add('t9');
    await Future<void>.delayed(Duration.zero);
    expect(saved.where((e) => e.$2 == 't9').length, 1);
    await s.dispose();
  });

  test('토큰 갱신은 로그아웃 상태면 건너뛴다', () async {
    final s = build();
    await s.sync();
    uid = null;
    refresh.add('t9');
    await Future<void>.delayed(Duration.zero);
    expect(saved.length, 1);
    await s.dispose();
  });

  test('iOS: APNs 토큰이 없으면 3번 재시도 후 포기한다', () async {
    apns = null;
    await build(ios: true).sync();
    expect(apnsCalls, 3);
    expect(saved, isEmpty);
  });
}
