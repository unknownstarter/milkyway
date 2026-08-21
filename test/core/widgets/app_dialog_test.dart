import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/core/presentation/widgets/design/app_dialog.dart';

void main() {
  Widget host(void Function(BuildContext) onTap) => MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: GestureDetector(
                onTap: () => onTap(ctx),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

  testWidgets('제목/본문/확인/취소 노출', (tester) async {
    await tester.pumpWidget(host((ctx) => showAppConfirm(ctx,
        title: '메모 삭제',
        message: '이 메모를 지울까',
        confirmText: '삭제',
        tone: ConfirmTone.danger)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('메모 삭제'), findsOneWidget);
    expect(find.text('이 메모를 지울까'), findsOneWidget);
    expect(find.text('삭제'), findsOneWidget);
    expect(find.text('취소'), findsOneWidget);
  });

  testWidgets('확인 탭하면 true', (tester) async {
    bool? captured;
    await tester.pumpWidget(host((ctx) async {
      captured = await showAppConfirm(ctx,
          title: '메모 삭제', message: '이 메모를 지울까', confirmText: '삭제');
    }));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(captured, isTrue);
  });

  testWidgets('취소 탭하면 false', (tester) async {
    bool? captured;
    await tester.pumpWidget(host((ctx) async {
      captured = await showAppConfirm(ctx,
          title: '메모 삭제', message: '이 메모를 지울까', confirmText: '삭제');
    }));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(captured, isFalse);
  });
}
