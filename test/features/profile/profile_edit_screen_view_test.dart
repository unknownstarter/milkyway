import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, FlutterAuthClientOptions, EmptyLocalStorage;
import 'package:whatif_milkyway_app/core/providers/analytics_provider.dart';
import 'package:whatif_milkyway_app/core/router/app_routes.dart';
import 'package:whatif_milkyway_app/core/services/analytics_service.dart';
import 'package:whatif_milkyway_app/features/auth/domain/entities/user.dart';
import 'package:whatif_milkyway_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:whatif_milkyway_app/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:whatif_milkyway_app/l10n/app_localizations.dart';

class _FakeAuth extends Auth {
  @override
  Future<User?> build() async => User(
        id: 'u1',
        email: 'a@b.c',
        nickname: 'neo',
        createdAt: DateTime(2026, 11, 1),
        updatedAt: DateTime(2026, 11, 1),
        onboardingCompleted: true,
      );
}

class _FakeAnalytics extends AnalyticsService {
  _FakeAnalytics() : super(null);
  final screens = <String>[];

  @override
  Future<void> logScreenView(String screenName) async {
    screens.add(screenName);
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

  testWidgets('키보드 프레임 30번에도 logScreenView 는 1번', (tester) async {
    final analytics = _FakeAnalytics();
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
            path: '/home',
            builder: (_, __) => const Scaffold(body: Text('HOME'))),
        GoRoute(path: '/edit', builder: (_, __) => const ProfileEditScreen()),
        GoRoute(
            path: '/login',
            name: AppRoutes.loginName,
            builder: (_, __) => const Scaffold(body: Text('LOGIN'))),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith(() => _FakeAuth()),
        analyticsProvider.overrideWithValue(analytics),
      ],
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
    expect(find.byType(ProfileEditScreen), findsOneWidget);

    addTearDown(tester.view.resetViewInsets);
    for (var i = 1; i <= 30; i++) {
      tester.view.viewInsets = FakeViewPadding(bottom: i * 10.0);
      await tester.pump();
    }

    expect(analytics.screens, ['profile_edit_screen']);
  });
}
