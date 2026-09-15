import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/memos/domain/models/memo.dart';
import 'package:whatif_milkyway_app/features/memos/domain/models/memo_visibility.dart';
import 'package:whatif_milkyway_app/features/universe/presentation/widgets/universe_memo_card.dart';
import 'package:whatif_milkyway_app/l10n/app_localizations.dart';

// 별을 눌렀을 때 올라오는 카드. 메모가 있을 때와 없을 때(흐린 별)가 다르게 나와야 한다.
void main() {
  Memo memo({int? page, String content = '멈춘 자리에 남긴 문장'}) => Memo(
        id: 'm1',
        userId: 'u1',
        bookId: 'b1',
        content: content,
        page: page,
        createdAt: DateTime(2026, 3, 11),
        visibility: MemoVisibility.private,
        bookTitle: '데미안',
        books: const {},
      );

  Future<void> pump(WidgetTester tester, List<Memo> memos) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ko'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: Scaffold(
        body: UniverseMemoCard(
          title: '데미안',
          author: '헤르만 헤세',
          notes: memos.length,
          colorIndex: 1,
          memos: memos,
          onClose: () {},
          onOpenMemo: (_) {},
          onWrite: () {},
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('메모가 있으면 본문과 페이지/날짜를 보여준다', (tester) async {
    await pump(tester, [memo(page: 94)]);
    expect(find.text('데미안'), findsOneWidget);
    expect(find.text('헤르만 헤세'), findsOneWidget);
    expect(find.text('멈춘 자리에 남긴 문장'), findsOneWidget);
    expect(find.text('NOTE / P.94'), findsOneWidget);
    expect(find.text('2026.03.11'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('페이지가 없으면 NOTE 만', (tester) async {
    await pump(tester, [memo()]);
    expect(find.text('NOTE'), findsOneWidget);
  });

  testWidgets('메모가 없는 별은 왜 흐린지 말해주고 쓰게 한다', (tester) async {
    await pump(tester, const []);
    // 빈 상태 문구와 CTA 가 나온다(은하 화면의 유도와 같은 문구를 쓴다).
    expect(find.text('메모를 남기면 그 책의 별이 밝아져요'), findsOneWidget);
    expect(find.text('메모 남기기'), findsOneWidget);
  });

  testWidgets('메모가 여럿이면 나머지 개수를 표시한다', (tester) async {
    await pump(tester, [memo(), memo(), memo()]);
    expect(find.text('+2'), findsOneWidget);
  });

  testWidgets('닫기 버튼이 있다', (tester) async {
    await pump(tester, [memo()]);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}
