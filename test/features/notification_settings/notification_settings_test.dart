import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/core/providers/locale_controller.dart';
import 'package:whatif_milkyway_app/features/notification_settings/data/push_permission_gateway.dart';
import 'package:whatif_milkyway_app/features/notification_settings/data/repositories/notification_preferences_repository.dart';
import 'package:whatif_milkyway_app/features/notification_settings/data/time_zone_sync.dart';
import 'package:whatif_milkyway_app/features/notification_settings/domain/notification_preferences.dart';
import 'package:whatif_milkyway_app/features/notification_settings/presentation/providers/notification_settings_providers.dart';
import 'package:whatif_milkyway_app/features/notification_settings/presentation/screens/notification_settings_screen.dart';
import 'package:whatif_milkyway_app/l10n/app_localizations.dart';

class _FakeRepo implements NotificationPreferencesRepository {
  _FakeRepo({this.enabled = true});

  bool enabled;
  NotificationPreferences prefs = NotificationPreferences.defaults;
  final List<NotificationPreferences> saved = [];
  final List<bool> enabledCalls = [];

  @override
  Future<bool> getEnabled() async => enabled;

  @override
  Future<void> setEnabled(bool value) async {
    enabled = value;
    enabledCalls.add(value);
  }

  @override
  Future<NotificationPreferences> getPreferences() async => prefs;

  @override
  Future<void> savePreferences(NotificationPreferences p) async {
    prefs = p;
    saved.add(p);
  }

  @override
  Future<bool> syncTimeZone(String timeZone, String language) async => true;
}

class _FakeGateway extends PushPermissionGateway {
  _FakeGateway(this.permission);
  final PushPermission permission;

  @override
  Future<PushPermission> status() async => permission;

  @override
  Future<bool> ensureGrantedAndRegister() async =>
      permission == PushPermission.granted;
}

Widget _app(
  _FakeRepo repo, {
  PushPermission permission = PushPermission.granted,
}) {
  return ProviderScope(
    overrides: [
      notificationPreferencesRepositoryProvider.overrideWithValue(repo),
      pushPermissionGatewayProvider.overrideWithValue(_FakeGateway(permission)),
    ],
    child: MaterialApp(
      locale: const Locale('ko'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: const NotificationSettingsScreen(),
    ),
  );
}

Switch _switchAt(WidgetTester tester, int i) =>
    tester.widgetList<Switch>(find.byType(Switch)).elementAt(i);

void main() {
  testWidgets('행이 없으면 기본값(모두 켜짐)으로 보인다', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    expect(find.text('알림 받기'), findsOneWidget);
    expect(find.text('책에 달린 메모'), findsOneWidget);
    expect(find.text('내 메모에 달린 댓글'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      expect(_switchAt(tester, i).value, isTrue);
      expect(_switchAt(tester, i).onChanged, isNotNull);
    }
    expect(repo.saved, isEmpty); // 보기만 해서는 행이 생기지 않는다
  });

  testWidgets('전체 끔이면 스위치 셋이 비활성', (tester) async {
    await tester.pumpWidget(_app(_FakeRepo(enabled: false)));
    await tester.pumpAndSettle();

    expect(_switchAt(tester, 0).value, isFalse);
    expect(_switchAt(tester, 0).onChanged, isNotNull);
    for (var i = 1; i < 4; i++) {
      expect(_switchAt(tester, i).onChanged, isNull);
    }
  });

  testWidgets('스위치를 바꾸면 repository 에 저장한다', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).at(1));
    await tester.pumpAndSettle();
    expect(repo.saved.single.bookMemos, isFalse);
    expect(repo.saved.single.comments, isTrue);

    await tester.tap(find.byType(Switch).at(3));
    await tester.pumpAndSettle();
    expect(repo.saved.last.quietHours, isFalse);
    expect(repo.saved.last.bookMemos, isFalse);
  });

  testWidgets('전체 스위치는 users 쪽 저장을 호출한다', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(repo.enabledCalls, [false]);
    expect(repo.saved, isEmpty);
  });

  testWidgets('휴대폰 권한이 꺼져 있으면 안내 줄이 뜬다', (tester) async {
    await tester.pumpWidget(
      _app(_FakeRepo(), permission: PushPermission.denied),
    );
    await tester.pumpAndSettle();
    expect(find.text('휴대폰 알림이 꺼져 있어요'), findsOneWidget);
    expect(find.text('휴대폰 설정에서 켜기'), findsOneWidget);
  });

  testWidgets('권한이 있으면 안내 줄이 없다', (tester) async {
    await tester.pumpWidget(_app(_FakeRepo()));
    await tester.pumpAndSettle();
    expect(find.text('휴대폰 설정에서 켜기'), findsNothing);
  });

  group('TimeZoneSync', () {
    var lang = 'ko';
    test('로그인 상태에서 한 번만 저장하고 같은 값은 건너뛴다', () async {
      final saved = <String>[];
      final sync = TimeZoneSync(
        getTimeZone: () async => 'Asia/Seoul',
        currentUserId: () => 'u1',
        getLanguage: () => lang,
        save: (z, l) async {
          saved.add(z);
          return true;
        },
      );
      await sync.sync();
      await sync.sync();
      expect(saved, ['Asia/Seoul']);
    });

    test('로그아웃 상태면 저장하지 않는다', () async {
      final saved = <String>[];
      final sync = TimeZoneSync(
        getTimeZone: () async => 'Asia/Seoul',
        currentUserId: () => null,
        getLanguage: () => lang,
        save: (z, l) async {
          saved.add(z);
          return true;
        },
      );
      await sync.sync();
      expect(saved, isEmpty);
    });

    test('시간대가 바뀌면 다시 저장하고, 저장 실패는 삼키고 재시도한다', () async {
      var zone = 'Asia/Seoul';
      var fail = true;
      final saved = <String>[];
      final sync = TimeZoneSync(
        getTimeZone: () async => zone,
        currentUserId: () => 'u1',
        getLanguage: () => lang,
        save: (z, l) async {
          if (fail) throw Exception('network');
          saved.add(z);
          return true;
        },
      );
      await sync.sync();
      expect(saved, isEmpty);
      fail = false;
      await sync.sync();
      zone = 'America/New_York';
      await sync.sync();
      expect(saved, ['Asia/Seoul', 'America/New_York']);
    });
  });

  group('푸시 언어 계약 (서버 check: ko/en/ja/zh)', () {
    const serverLangs = {'ko', 'en', 'ja', 'zh'};

    test('upsert 본문 키가 정확히 user_id/time_zone/language/updated_at', () {
      final m = NotificationPreferencesRepository.timeZoneSyncPayload(
        userId: 'u1',
        timeZone: 'Asia/Seoul',
        language: 'ko',
        now: DateTime.utc(2026, 11, 1),
      );
      expect(m.keys.toSet(),
          {'user_id', 'time_zone', 'language', 'updated_at'});
      expect(serverLangs, contains(m['language']));
    });

    test('기기 언어 -> 앱 언어', () {
      const cases = <String, Locale>{
        'ko': Locale('ko', 'KR'),
        'en': Locale('en', 'US'),
        'ja': Locale('ja', 'JP'),
        'zh': Locale.fromSubtags(
            languageCode: 'zh', scriptCode: 'Hans', countryCode: 'CN'),
        // 지원 밖 = MaterialApp 이 실제로 고르는 폴백 (supportedLocales 첫째)
        'en ': Locale('fr', 'FR'),
      };
      for (final e in cases.entries) {
        final r = resolveAppLanguage(null, [e.value]);
        expect(r, e.key.trim(), reason: e.value.toString());
        expect(serverLangs, contains(r));
      }
    });

    test('override 가 기기 언어보다 앞선다', () {
      expect(resolveAppLanguage(const Locale('ja'), [const Locale('ko', 'KR')]),
          'ja');
    });

    test('같은 (시간대, 언어) 두 번이면 쓰기 1번, 언어가 바뀌면 다시 쓴다', () async {
      var lang = 'ko';
      final saved = <String>[];
      final sync = TimeZoneSync(
        getTimeZone: () async => 'Asia/Seoul',
        currentUserId: () => 'u1',
        getLanguage: () => lang,
        save: (z, l) async {
          saved.add('$z/$l');
          return true;
        },
      );
      await sync.sync();
      await sync.sync();
      expect(saved, ['Asia/Seoul/ko']);
      lang = 'ja';
      await sync.sync();
      expect(saved, ['Asia/Seoul/ko', 'Asia/Seoul/ja']);
    });
  });
}
