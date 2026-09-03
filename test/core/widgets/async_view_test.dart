import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/core/presentation/widgets/design/async_view.dart';
import 'package:whatif_milkyway_app/l10n/app_localizations.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: Scaffold(body: child),
      );

  testWidgets('데이터면 builder 렌더', (tester) async {
    await tester.pumpWidget(wrap(AsyncView<List<String>>(
      value: const AsyncData(['a', 'b']),
      builder: (d) => Text('items ${d.length}'),
    )));
    await tester.pump();
    expect(find.text('items 2'), findsOneWidget);
  });

  testWidgets('빈 데이터면 emptyBuilder', (tester) async {
    await tester.pumpWidget(wrap(AsyncView<List<String>>(
      value: const AsyncData([]),
      isEmpty: (d) => d.isEmpty,
      emptyBuilder: () => const Text('비었어'),
      builder: (d) => Text('items ${d.length}'),
    )));
    await tester.pump();
    expect(find.text('비었어'), findsOneWidget);
  });

  testWidgets('로딩이면 고정 높이 스피너', (tester) async {
    await tester.pumpWidget(wrap(AsyncView<List<String>>(
      value: const AsyncLoading(),
      loadingHeight: 140,
      builder: (d) => const Text('data'),
    )));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final box = tester.widget<SizedBox>(find.descendant(
      of: find.byType(AsyncView<List<String>>),
      matching: find.byKey(const ValueKey('async-loading')),
    ));
    expect(box.height, 140);
  });
}
