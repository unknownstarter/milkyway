import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/auth/domain/entities/user.dart';
import 'package:whatif_milkyway_app/features/splash/presentation/splash_user_check.dart';
import 'package:whatif_milkyway_app/features/splash/presentation/widgets/splash_retry_view.dart';
import 'package:whatif_milkyway_app/l10n/app_localizations.dart';

User _user({required bool onboarded}) => User(
      id: 'u1',
      email: 'a@b.c',
      nickname: 'neo',
      createdAt: DateTime(2026, 11, 1),
      updatedAt: DateTime(2026, 11, 1),
      onboardingCompleted: onboarded,
    );

Future<void> _instant(Duration _) async {}

void main() {
  group('resolveSplashDestination', () {
    test('행 없음(조회 성공 + null) -> 로그인', () async {
      final d = await resolveSplashDestination(
          getUser: () async => null, wait: _instant);
      expect(d, SplashDestination.login);
    });

    test('온보딩 미완료 -> 온보딩 / 완료 -> 홈', () async {
      expect(
          await resolveSplashDestination(
              getUser: () async => _user(onboarded: false), wait: _instant),
          SplashDestination.onboarding);
      expect(
          await resolveSplashDestination(
              getUser: () async => _user(onboarded: true), wait: _instant),
          SplashDestination.home);
    });

    test('일시 오류 후 성공하면 재시도해서 홈 (400ms, 1200ms 대기)', () async {
      final waits = <Duration>[];
      var calls = 0;
      final d = await resolveSplashDestination(
        getUser: () async {
          calls++;
          if (calls < 3) throw const SocketException('offline');
          return _user(onboarded: true);
        },
        wait: (d) async => waits.add(d),
      );
      expect(d, SplashDestination.home);
      expect(calls, 3);
      expect(waits, const [
        Duration(milliseconds: 400),
        Duration(milliseconds: 1200),
      ]);
    });

    test('계속 실패하면 로그인이 아니라 throw (3번 시도)', () async {
      var calls = 0;
      await expectLater(
        resolveSplashDestination(
          getUser: () async {
            calls++;
            throw const SocketException('offline');
          },
          wait: _instant,
        ),
        throwsA(isA<SocketException>()),
      );
      expect(calls, 3);
    });
  });

  group('SplashRetryView', () {
    Widget host(VoidCallback onRetry) => MaterialApp(
          locale: const Locale('ko'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: SplashRetryView(onRetry: onRetry),
        );

    testWidgets('다시 시도 버튼이 보이고, 누르면 재조회 콜백', (tester) async {
      var retried = 0;
      await tester.pumpWidget(host(() => retried++));
      expect(find.text('다시 시도'), findsOneWidget);
      await tester.tap(find.text('다시 시도'));
      expect(retried, 1);
    });
  });
}
