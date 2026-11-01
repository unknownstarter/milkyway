import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, FlutterAuthClientOptions, EmptyLocalStorage;
import 'package:whatif_milkyway_app/core/router/app_routes.dart';
import 'package:whatif_milkyway_app/features/auth/domain/entities/user.dart';
import 'package:whatif_milkyway_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:whatif_milkyway_app/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:whatif_milkyway_app/l10n/app_localizations.dart';

/// G8: 저장이 실패하면 "저장됐어요" 토스트도 pop 도 없다. 쓰기 버튼은 연타해도 1번만.
class _FakeAuth extends Auth {
  int signOutCalls = 0;
  int updateProfileCalls = 0;
  final signOutGate = Completer<void>();

  @override
  Future<User?> build() async => User(
        id: 'u1',
        email: 'a@b.c',
        nickname: 'neo',
        createdAt: DateTime(2026, 11, 1),
        updatedAt: DateTime(2026, 11, 1),
        onboardingCompleted: true,
      );

  @override
  Future<bool> checkNicknameAvailability(String nickname) async => true;

  @override
  Future<void> updateProfile({String? nickname, String? pictureUrl}) async {
    updateProfileCalls++;
    throw Exception('server down');
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    await signOutGate.future;
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'anon',
      authOptions: FlutterAuthClientOptions(
        localStorage: const EmptyLocalStorage(),
        autoRefreshToken: false,
      ),
    );
  });

  late _FakeAuth auth;

  Future<void> open(WidgetTester tester) async {
    auth = _FakeAuth();
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
            path: '/home',
            builder: (_, __) => const Scaffold(body: Text('HOME'))),
        GoRoute(
            path: '/edit', builder: (_, __) => const ProfileEditScreen()),
        GoRoute(
            path: '/login',
            name: AppRoutes.loginName,
            builder: (_, __) => const Scaffold(body: Text('LOGIN'))),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [authProvider.overrideWith(() => auth)],
      child: MaterialApp.router(
        locale: const Locale('ko'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        routerConfig: router,
      ),
    ));
    await tester.pump();
    router.push('/edit');
    await tester.pumpAndSettle();
  }

  testWidgets('updateProfile 실패 -> 성공 토스트 없고 화면 유지', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField).first, 'newname');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(auth.updateProfileCalls, 1);
    expect(find.text('프로필이 수정되었습니다'), findsNothing);
    expect(find.byType(ProfileEditScreen), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
  });

  testWidgets('로그아웃 진행 중 다시 눌러도 signOut 은 1번', (tester) async {
    await open(tester);
    await tester.ensureVisible(find.text('로그아웃'));
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    // 확인 모달의 로그아웃 버튼(마지막 것)
    await tester.tap(find.text('로그아웃').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(auth.signOutCalls, 1);

    // signOut 이 끝나기 전에 화면의 버튼을 또 누른다
    await tester.tap(find.text('로그아웃'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
    expect(auth.signOutCalls, 1);
    expect(find.text('정말 로그아웃 하시겠습니까?'), findsNothing);

    auth.signOutGate.complete();
    await tester.pumpAndSettle();
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
