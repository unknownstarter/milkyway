import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/core/presentation/widgets/design/memo_card.dart';
import 'package:whatif_milkyway_app/l10n/app_localizations.dart';

/// 소셜 확장(신규 lyraQuestion 인용 라인 + commentCount)의 표현/경계 검증.
void main() {
  Widget wrap(Widget child) => MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: Scaffold(body: child),
      );

  testWidgets('lyraQuestion 있으면 인용 라인 + 반짝임 아이콘', (tester) async {
    await tester.pumpWidget(wrap(const MemoCard(
      content: '답을 적었다',
      authorName: '노아',
      lyraQuestion: '요즘 마음에 남는 문장은 뭐야',
    )));
    expect(find.text('요즘 마음에 남는 문장은 뭐야'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });

  testWidgets('lyraQuestion 빈 문자열이면 인용 라인 미노출', (tester) async {
    await tester.pumpWidget(wrap(const MemoCard(
      content: '답을 적었다',
      authorName: '노아',
      lyraQuestion: '',
    )));
    expect(find.byIcon(Icons.auto_awesome), findsNothing);
  });

  testWidgets('lyraQuestion null이면 인용 라인 미노출', (tester) async {
    await tester.pumpWidget(wrap(const MemoCard(
      content: '답을 적었다',
      authorName: '노아',
    )));
    expect(find.byIcon(Icons.auto_awesome), findsNothing);
  });

  testWidgets('commentCount 경계: 0 미노출 / 1 이상 노출', (tester) async {
    await tester.pumpWidget(wrap(const MemoCard(
      content: '문장',
      authorName: '노아',
      commentCount: 0,
    )));
    expect(find.byIcon(Icons.chat_bubble_outline), findsNothing);

    await tester.pumpWidget(wrap(const MemoCard(
      content: '문장',
      authorName: '노아',
      commentCount: 1,
    )));
    expect(find.text('1'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
  });

  testWidgets('onTap 콜백 동작', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(MemoCard(
      content: '문장',
      authorName: '노아',
      onTap: () => tapped = true,
    )));
    await tester.tap(find.text('문장'));
    expect(tapped, isTrue);
  });
}
