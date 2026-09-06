import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whatif_milkyway_app/core/presentation/widgets/design/dismissible_pill.dart';
import 'package:whatif_milkyway_app/core/presentation/widgets/design/floating_pill.dart';
import 'package:whatif_milkyway_app/core/services/pill_policy.dart';

// 알약 계약 두 가지.
//  1) 노출 정책 - X 한 번이면 빈도와 무관하게 끝. 나머지는 빈도가 결정.
//  2) 레이아웃 - 항상 한 줄. 좁아지면 줄바꿈이 아니라 말줄임.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('PillPolicy', () {
    test('X를 누르면 어떤 빈도든 다시 안 뜬다', () async {
      for (final f in PillFrequency.values) {
        SharedPreferences.setMockInitialValues({});
        expect(await PillPolicy.shouldShow('p', f), isTrue);
        await PillPolicy.dismissForever('p');
        expect(await PillPolicy.shouldShow('p', f), isFalse, reason: '$f');
      }
    });

    test('untilDismissed - 닫기 전까지 몇 번이든 뜬다', () async {
      for (var i = 0; i < 3; i++) {
        expect(
            await PillPolicy.shouldShow('p', PillFrequency.untilDismissed),
            isTrue);
        await PillPolicy.markShown('p');
      }
    });

    test('once - 한 번 뜨면 소진', () async {
      expect(await PillPolicy.shouldShow('p', PillFrequency.once), isTrue);
      await PillPolicy.markShown('p');
      expect(await PillPolicy.shouldShow('p', PillFrequency.once), isFalse);
    });

    test('daily - 같은 날은 한 번, 날이 바뀌면 다시', () async {
      final day1 = DateTime(2026, 9, 6, 9);
      final day2 = DateTime(2026, 9, 7, 1);
      expect(
          await PillPolicy.shouldShow('p', PillFrequency.daily, now: day1),
          isTrue);
      await PillPolicy.markShown('p', now: day1);
      expect(
          await PillPolicy.shouldShow('p', PillFrequency.daily, now: day1),
          isFalse);
      expect(
          await PillPolicy.shouldShow('p', PillFrequency.daily, now: day2),
          isTrue);
    });

    test('구버전 플래그로 이미 닫은 사용자에게 되살아나지 않는다', () async {
      SharedPreferences.setMockInitialValues({'home_lang_pill_seen': true});
      expect(
        await PillPolicy.shouldShow('home_lang', PillFrequency.untilDismissed,
            legacyDismissedKey: 'home_lang_pill_seen'),
        isFalse,
      );
    });
  });

  group('DismissiblePill 레이아웃', () {
    // 4개 언어 라벨 + 일부러 긴 문자열.
    const labels = [
      '언어 변경',
      'Change language',
      '言語を変更',
      '更改语言',
      'Change the app language for every screen right now',
    ];

    testWidgets('좁은 폭에서도 한 줄 - 줄바꿈 대신 말줄임', (tester) async {
      for (final label in labels) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200, // 일부러 좁게
                child: Center(
                  child: DismissiblePill(
                    icon: Icons.language_outlined,
                    label: label,
                    onClose: () {},
                  ),
                ),
              ),
            ),
          ),
        ));
        expect(tester.takeException(), isNull, reason: label);

        final text = tester.widget<Text>(find.text(label));
        expect(text.maxLines, 1, reason: label);
        expect(text.overflow, TextOverflow.ellipsis, reason: label);

        // 한 줄 높이(패딩 8+8 + 라벨 1줄)를 넘지 않는다.
        expect(tester.getSize(find.byType(DismissiblePill)).height, lessThan(48),
            reason: '$label 이 두 줄이 됐다');
      }
    });

    testWidgets('내용이 길수록 가로로 늘어난다', (tester) async {
      double widthOf(String label) =>
          tester.getSize(find.byType(DismissiblePill)).width;

      Future<double> render(String label) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Center(
              child: DismissiblePill(label: label, onClose: () {}),
            ),
          ),
        ));
        return widthOf(label);
      }

      final short = await render('언어');
      final long = await render('언어 변경하기 아주 길게');
      expect(long, greaterThan(short));
    });
  });

  group('FloatingPill', () {
    testWidgets('정책이 막으면 아무것도 안 그린다', (tester) async {
      SharedPreferences.setMockInitialValues({'pill.x.dismissed': true});
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Stack(children: [
            FloatingPill(
              top: 10,
              spec: FloatingPillSpec(
                id: 'x',
                label: '언어 변경',
                frequency: PillFrequency.untilDismissed,
              ),
            ),
          ]),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(DismissiblePill), findsNothing);
    });

    testWidgets('X를 누르면 사라지고 정책에 영구 기록된다', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Stack(children: [
            FloatingPill(
              top: 10,
              spec: FloatingPillSpec(
                id: 'x',
                label: '언어 변경',
                frequency: PillFrequency.untilDismissed,
              ),
            ),
          ]),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(DismissiblePill), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(DismissiblePill), findsNothing);
      expect(
          await PillPolicy.shouldShow('x', PillFrequency.untilDismissed),
          isFalse);
    });
  });
}
