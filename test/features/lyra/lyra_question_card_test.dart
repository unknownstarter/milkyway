import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/lyra/presentation/widgets/lyra_question_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('물음 텍스트와 라벨을 노출한다', (tester) async {
    await tester.pumpWidget(wrap(
      LyraQuestionCard(question: '요즘 무너뜨리기 싫은 칸은 뭐야?', onAnswer: () {}),
    ));

    expect(find.text('Lyra의 물음'), findsOneWidget);
    expect(find.text('요즘 무너뜨리기 싫은 칸은 뭐야?'), findsOneWidget);
    expect(find.text('이 물음에 메모 남기기'), findsOneWidget);
  });

  testWidgets('메모 남기기를 누르면 onAnswer 가 호출된다', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(
      LyraQuestionCard(
        question: '물음',
        onAnswer: () => tapped = true,
      ),
    ));

    await tester.tap(find.text('이 물음에 메모 남기기'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
