import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/core/presentation/widgets/design/keyboard_aware_sheet.dart';
import 'package:whatif_milkyway_app/features/comments/presentation/widgets/comment_composer.dart';
import 'package:whatif_milkyway_app/l10n/app_localizations.dart';

const _kb = 300.0;
const _screen = Size(360, 700);

void _setScreen(WidgetTester t) {
  t.view.physicalSize = _screen;
  t.view.devicePixelRatio = 1;
  t.view.viewInsets = const FakeViewPadding(bottom: _kb);
  addTearDown(t.view.reset);
}

Widget _app(Widget home) => MaterialApp(
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: home,
    );

void main() {
  testWidgets('댓글 작성기: 키보드가 열려도 입력칸이 키보드 위에 있다', (t) async {
    _setScreen(t);
    final focus = FocusNode();
    final ctrl = TextEditingController();
    await t.pumpWidget(_app(Scaffold(
      body: Column(children: [
        const Expanded(child: SizedBox()),
        CommentComposer(controller: ctrl, focusNode: focus, onSend: (_) {}),
      ]),
    )));
    await t.tap(find.byType(TextField));
    await t.pumpAndSettle();
    expect(focus.hasFocus, isTrue);
    expect(t.getBottomLeft(find.byType(TextField)).dy,
        lessThanOrEqualTo(_screen.height - _kb));
  });

  testWidgets('키보드 대응 시트(고정 높이): 입력칸이 키보드 위에 있다', (t) async {
    _setScreen(t);
    final focus = FocusNode();
    await t.pumpWidget(_app(Scaffold(
      resizeToAvoidBottomInset: false,
      body: KeyboardAwareSheet(
        heightFactor: 0.5,
        fixedHeight: true,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const Text('title'),
            Expanded(
                child: TextField(
                    focusNode: focus, maxLines: null, expands: true)),
          ]),
        ),
      ),
    )));
    await t.tap(find.byType(TextField));
    await t.pumpAndSettle();
    expect(t.getBottomLeft(find.byType(TextField)).dy,
        lessThanOrEqualTo(_screen.height - _kb));
    expect(t.getTopLeft(find.byType(TextField)).dy, greaterThan(0));
  });

  testWidgets('키보드 대응 시트(내용 높이): 입력칸이 키보드 위에 있다', (t) async {
    _setScreen(t);
    await t.pumpWidget(_app(const Scaffold(
      resizeToAvoidBottomInset: false,
      body: KeyboardAwareSheet(
        heightFactor: 0.6,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(height: 200),
            TextField(maxLines: 3),
          ]),
        ),
      ),
    )));
    await t.tap(find.byType(TextField));
    await t.pumpAndSettle();
    expect(t.getBottomLeft(find.byType(TextField)).dy,
        lessThanOrEqualTo(_screen.height - _kb));
  });
}
