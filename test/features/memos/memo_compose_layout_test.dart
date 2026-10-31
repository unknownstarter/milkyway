import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/memos/presentation/widgets/memo_compose_layout.dart';

const _question = '이 책을 읽으면서 가장 오래 머문 문장은 무엇이었고 왜 그 문장에서 멈추게 되었나요 '
    '그리고 그 문장이 지금 내 하루와 어떻게 이어지는지 천천히 적어 봐도 좋아요';

/// 실기기처럼 창이 키보드만큼 줄고(adjustResize) viewInsets 도 함께 들어오는 상황.
Widget _host({required double keyboard}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          viewInsets: EdgeInsets.only(bottom: keyboard),
        ),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Padding(
            padding: EdgeInsets.only(bottom: keyboard),
            child: MemoComposeLayout(
              bookChipBuilder: (compact) =>
                  SizedBox(height: compact ? 28 : 36),
              lyraQuestion: _question,
              lyraLabel: 'Lyra',
              editor: const TextField(maxLines: null, minLines: 5),
              bottomBars: const [SizedBox(height: 56), SizedBox(height: 64)],
            ),
          ),
        ),
      ),
    ),
  );
}

void _setScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('키보드가 닫혀 있으면 물음이 펼쳐진다', (tester) async {
    _setScreen(tester);
    await tester.pumpWidget(_host(keyboard: 0));
    expect(tester.widget<Text>(find.text(_question)).maxLines, isNull);
  });

  testWidgets('키보드가 열리면 물음이 한 줄로 접히고 입력창이 최소 높이 이상이다', (tester) async {
    _setScreen(tester);
    await tester.pumpWidget(_host(keyboard: 300));
    final text = tester.widget<Text>(find.text(_question));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.fade);

    final h = tester.getSize(find.byKey(MemoComposeLayout.editorKey)).height;
    expect(h, greaterThanOrEqualTo(MemoComposeLayout.minEditorHeight));
  });

  testWidgets('접힌 물음을 누르면 펼쳐진다', (tester) async {
    _setScreen(tester);
    await tester.pumpWidget(_host(keyboard: 300));
    await tester.tap(find.text(_question));
    await tester.pump();
    expect(tester.widget<Text>(find.text(_question)).maxLines, isNull);
  });
}
