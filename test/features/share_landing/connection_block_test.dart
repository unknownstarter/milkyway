import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/share_landing/presentation/widgets/connection_block.dart';
import 'package:whatif_milkyway_app/l10n/app_localizations.dart';

// 공유 링크를 받은 사람이 보는 '그때 -> 지금'.
// payload 에 문장이 없으면 아무것도 안 그려야 한다(오브만 보이는 기존 화면으로 폴백).
void main() {
  const accent = Color(0xFFC48CFF);

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ko'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ));
    await tester.pump();
  }

  group('fromPayload - 없는 건 없는 대로', () {
    test('payload 가 없으면 null', () {
      expect(ConnectionBlock.fromPayload(null, accent), isNull);
    });

    test('connection 키가 없으면 null', () {
      expect(ConnectionBlock.fromPayload({'kind': 'orb'}, accent), isNull);
    });

    test('문장이 비어 있으면 null - 빈 블록을 그리면 더 이상하다', () {
      expect(
        ConnectionBlock.fromPayload({
          'connection': {'past': '  ', 'now': '지금 문장'}
        }, accent),
        isNull,
      );
      expect(
        ConnectionBlock.fromPayload({
          'connection': {'past': '그때 문장', 'now': ''}
        }, accent),
        isNull,
      );
    });

    test('문장 두 개가 있으면 만든다', () {
      final b = ConnectionBlock.fromPayload({
        'connection': {'past': '그때 문장', 'now': '지금 문장'}
      }, accent);
      expect(b, isNotNull);
      expect(b!.past, '그때 문장');
      expect(b.now, '지금 문장');
    });

    test('망가진 날짜는 무시하고 문장은 살린다', () {
      final b = ConnectionBlock.fromPayload({
        'connection': {
          'past': '그때',
          'now': '지금',
          'past_date': '날짜아님',
          'now_date': 12345,
        }
      }, accent);
      expect(b, isNotNull);
      expect(b!.pastDate, isNull);
      expect(b.nowDate, isNull);
    });
  });

  testWidgets('두 문장과 Lyra 근거를 보여준다', (tester) async {
    await pump(
      tester,
      ConnectionBlock(
        past: '불안한 건 아직 고르지 않았기 때문이라고 썼다',
        now: '고르고 나니 방향이 생겼다',
        pastDate: DateTime(2026, 3, 11),
        nowDate: DateTime(2026, 9, 2),
        rationale: '같은 감정을 두고 여섯 달 만에 정반대 결론에 닿았어요',
        accent: accent,
      ),
    );
    expect(find.text('그때'), findsOneWidget);
    expect(find.text('지금'), findsOneWidget);
    expect(find.text('2026.03.11'), findsOneWidget);
    expect(find.text('2026.09.02'), findsOneWidget);
    expect(find.text('불안한 건 아직 고르지 않았기 때문이라고 썼다'), findsOneWidget);
    expect(find.text('같은 감정을 두고 여섯 달 만에 정반대 결론에 닿았어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('근거가 없어도 두 문장은 그린다', (tester) async {
    await pump(
      tester,
      const ConnectionBlock(past: '그때 문장', now: '지금 문장', accent: accent),
    );
    expect(find.text('그때 문장'), findsOneWidget);
    expect(find.text('지금 문장'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('긴 문장도 오버플로 없이 잘린다', (tester) async {
    final long = '문장 ' * 200;
    await pump(
      tester,
      ConnectionBlock(past: long, now: long, rationale: long, accent: accent),
    );
    expect(tester.takeException(), isNull);
  });
}
