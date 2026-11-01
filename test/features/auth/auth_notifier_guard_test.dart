import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, FlutterAuthClientOptions, EmptyLocalStorage;
import 'package:whatif_milkyway_app/features/auth/domain/entities/user.dart';
import 'package:whatif_milkyway_app/features/auth/presentation/providers/auth_provider.dart';

/// G7/G8: 쓰기/확인 실패는 호출부가 알 수 있게 throw 하고, 로그인 상태(state)를 건드리지 않는다.
class _FakeServer {
  late HttpServer _server;
  final requests = <String>[]; // "METHOD path"
  final bodies = <String>[];
  int patchStatus = 204;
  int functionStatus = 200;
  Object functionBody = {'available': true};

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((req) async {
      final body = await utf8.decoder.bind(req).join();
      requests.add('${req.method} ${req.uri.path}');
      bodies.add(body);
      final res = req.response;
      if (req.uri.path.startsWith('/functions/v1/')) {
        res.statusCode = functionStatus;
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode(functionBody));
      } else if (req.method == 'PATCH') {
        res.statusCode = patchStatus;
        if (patchStatus >= 400) {
          res.headers.contentType = ContentType.json;
          res.write(jsonEncode({'message': 'boom', 'code': 'XX000'}));
        }
      } else {
        res.statusCode = 404;
      }
      await res.close();
    });
  }

  String get url => 'http://127.0.0.1:${_server.port}';
  Future<void> stop() => _server.close(force: true);
}

User _user({String nickname = 'neo', bool onboarded = false}) => User(
      id: 'u1',
      email: 'a@b.c',
      nickname: nickname,
      createdAt: DateTime(2026, 11, 1),
      updatedAt: DateTime(2026, 11, 1),
      onboardingCompleted: onboarded,
    );

class _TestAuth extends Auth {
  _TestAuth(this.onGet);
  Future<User?> Function() onGet;

  @override
  Future<User?> getCurrentUser() => onGet();
}

void main() {
  late _FakeServer server;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    HttpOverrides.global = null; // 테스트 바인딩의 HTTP 차단을 풀고 로컬 가짜 서버를 쓴다
    server = _FakeServer();
    await server.start();
    await Supabase.initialize(
      url: server.url,
      anonKey: 'anon',
      authOptions: FlutterAuthClientOptions(
        localStorage: const EmptyLocalStorage(),
        autoRefreshToken: false,
      ),
    );
  });

  tearDownAll(() => server.stop());

  setUp(() {
    server.requests.clear();
    server.bodies.clear();
    server.patchStatus = 204;
    server.functionStatus = 200;
    server.functionBody = {'available': true};
  });

  ({ProviderContainer c, Auth n}) make(Future<User?> Function() onGet) {
    final c = ProviderContainer(
        overrides: [authProvider.overrideWith(() => _TestAuth(onGet))]);
    addTearDown(c.dispose);
    c.listen(authProvider, (_, __) {}); // autoDispose 유지
    return (c: c, n: c.read(authProvider.notifier));
  }

  group('checkOnboardingStatus', () {
    test('조회 오류 -> throw (온보딩 미완료 false 로 읽지 않는다)', () async {
      final t = make(() async => throw const SocketException('offline'));
      await expectLater(
          t.n.checkOnboardingStatus(), throwsA(isA<SocketException>()));
    });

    test('행 있고 완료 -> true / 행 있고 미완료 -> false', () async {
      expect(await make(() async => _user(onboarded: true))
          .n
          .checkOnboardingStatus(), isTrue);
      expect(await make(() async => _user(onboarded: false))
          .n
          .checkOnboardingStatus(), isFalse);
    });
  });

  group('updateOnboardingStatus', () {
    test('저장 실패 -> rethrow, state 는 로그인 상태 유지', () async {
      server.patchStatus = 500;
      final t = make(() async => _user());
      await t.c.read(authProvider.future);
      await expectLater(
          t.n.updateOnboardingStatus(true), throwsA(anything));
      final s = t.c.read(authProvider);
      expect(s.hasError, isFalse);
      expect(s.value?.id, 'u1');
    });

    test('조회 오류로 실패해도 state 를 null/오류로 바꾸지 않는다', () async {
      var fail = false;
      final t = make(() async {
        if (fail) throw const SocketException('offline');
        return _user();
      });
      await t.c.read(authProvider.future);
      fail = true;
      await expectLater(
          t.n.updateOnboardingStatus(true), throwsA(isA<SocketException>()));
      expect(t.c.read(authProvider).value?.id, 'u1');
    });

    test('성공 -> onboarding_completed=true 로 PATCH 호출', () async {
      final t = make(() async => _user());
      await t.c.read(authProvider.future);
      await t.n.updateOnboardingStatus(true);
      expect(server.requests, contains('PATCH /rest/v1/users'));
      final body = jsonDecode(
          server.bodies[server.requests.indexOf('PATCH /rest/v1/users')]);
      expect(body['onboarding_completed'], true);
    });
  });

  group('updateProfile', () {
    test('저장 실패 -> rethrow (성공 토스트/pop 못 가게), state 유지', () async {
      server.patchStatus = 500;
      final t = make(() async => _user());
      await t.c.read(authProvider.future);
      await expectLater(
          t.n.updateProfile(nickname: 'new'), throwsA(anything));
      expect(t.c.read(authProvider).hasError, isFalse);
      expect(t.c.read(authProvider).value?.id, 'u1');
    });

    test('사용자 없음 -> 조용히 return 하지 않고 throw', () async {
      final t = make(() async => null);
      await t.c.read(authProvider.future);
      await expectLater(
          t.n.updateProfile(nickname: 'new'), throwsA(isA<StateError>()));
    });

    test('성공 -> PATCH 호출, 던지지 않음', () async {
      final t = make(() async => _user());
      await t.c.read(authProvider.future);
      await t.n.updateProfile(nickname: 'new');
      expect(server.requests, contains('PATCH /rest/v1/users'));
    });
  });

  group('checkNicknameAvailability', () {
    test('서버 오류 -> "중복(false)" 이 아니라 throw', () async {
      server.functionStatus = 500;
      server.functionBody = {'error': 'boom'};
      final t = make(() async => _user());
      await t.c.read(authProvider.future);
      await expectLater(
          t.n.checkNicknameAvailability('other'), throwsA(anything));
    });

    test('정말 중복이면 false / 사용 가능이면 true', () async {
      final t = make(() async => _user());
      await t.c.read(authProvider.future);
      server.functionBody = {'available': false};
      expect(await t.n.checkNicknameAvailability('taken'), isFalse);
      server.functionBody = {'available': true};
      expect(await t.n.checkNicknameAvailability('free'), isTrue);
    });
  });
}
