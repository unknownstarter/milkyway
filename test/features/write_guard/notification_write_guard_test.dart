import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/notification_settings/data/push_permission_gateway.dart';
import 'package:whatif_milkyway_app/features/notification_settings/data/repositories/notification_preferences_repository.dart';
import 'package:whatif_milkyway_app/features/notification_settings/domain/notification_preferences.dart';
import 'package:whatif_milkyway_app/features/notification_settings/presentation/providers/notification_settings_providers.dart';
import 'package:whatif_milkyway_app/features/notification_settings/presentation/screens/notification_settings_screen.dart';
import 'package:whatif_milkyway_app/l10n/app_localizations.dart';

/// G6/G8: 알림 스위치는 저장 중 다시 눌려도 1번만 저장하고, 실패하면 되돌린다.
class _Repo extends Fake implements NotificationPreferencesRepository {
  bool fail = false;
  Completer<void>? gate;
  int saveCalls = 0;

  @override
  Future<bool> getEnabled() async => true;

  @override
  Future<NotificationPreferences> getPreferences() async =>
      NotificationPreferences.defaults;

  @override
  Future<void> savePreferences(NotificationPreferences p) async {
    saveCalls++;
    await gate?.future;
    if (fail) throw Exception('network down');
  }
}

class _Gateway extends PushPermissionGateway {
  @override
  Future<PushPermission> status() async => PushPermission.granted;

  @override
  Future<bool> ensureGrantedAndRegister() async => true;
}

Widget _app(_Repo repo) => ProviderScope(
      overrides: [
        notificationPreferencesRepositoryProvider.overrideWithValue(repo),
        pushPermissionGatewayProvider.overrideWithValue(_Gateway()),
      ],
      child: const MaterialApp(
        locale: Locale('ko'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: NotificationSettingsScreen(),
      ),
    );

bool _on(WidgetTester tester, int i) =>
    tester.widgetList<Switch>(find.byType(Switch)).elementAt(i).value;

void main() {
  final l = lookupAppL10n(const Locale('ko'));

  testWidgets('저장 실패 -> 스위치를 되돌리고 오류 토스트', (tester) async {
    final repo = _Repo()..fail = true;
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();
    expect(_on(tester, 1), isTrue);

    await tester.tap(find.byType(Switch).at(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repo.saveCalls, 1);
    expect(_on(tester, 1), isTrue);
    expect(find.text(l.profileNotificationSaveFailed), findsOneWidget);
  });

  testWidgets('저장 중 같은 스위치 연타 -> savePreferences 1번', (tester) async {
    final gate = Completer<void>();
    final repo = _Repo()..gate = gate;
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byType(Switch).at(1));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(repo.saveCalls, 1);

    gate.complete();
    await tester.pumpAndSettle();
    expect(repo.saveCalls, 1);
  });
}
