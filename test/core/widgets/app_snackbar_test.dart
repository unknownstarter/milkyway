import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/core/presentation/widgets/design/app_snackbar.dart';

Future<BuildContext> _pump(WidgetTester tester) async {
  late BuildContext ctx;
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(
        size: Size(400, 800),
        padding: EdgeInsets.only(bottom: 34),
        viewPadding: EdgeInsets.only(bottom: 34),
      ),
      child: MaterialApp(
        home: Scaffold(
          body: Builder(builder: (c) {
            ctx = c;
            return const SizedBox();
          }),
        ),
      ),
    ),
  );
  return ctx;
}

void main() {
  testWidgets('bottomOffset 을 주면 margin 이 그만큼이고 안전영역을 더하지 않는다',
      (tester) async {
    final ctx = await _pump(tester);
    expect(snackBarBottomMargin(73), 73);
    showAppSnackBar(ctx, '확인', bottomOffset: 73);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final bar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect((bar.margin! as EdgeInsets).bottom, 73);
  });

  testWidgets('bottomOffset 이 없으면 안전영역을 더하지 않은 기본 여백', (tester) async {
    final ctx = await _pump(tester);
    expect(snackBarBottomMargin(null), 80);
    showAppPillSnackBar(ctx, '확인');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final bar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect((bar.margin! as EdgeInsets).bottom, 80);
  });
}
