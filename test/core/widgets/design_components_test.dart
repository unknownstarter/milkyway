import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/core/presentation/widgets/design/avatar.dart';
import 'package:whatif_milkyway_app/core/presentation/widgets/design/chips.dart';
import 'package:whatif_milkyway_app/core/presentation/widgets/design/segment_filter.dart';
import 'package:whatif_milkyway_app/core/presentation/widgets/design/buttons.dart';
import 'package:whatif_milkyway_app/core/presentation/widgets/design/memo_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('Avatar 이미지 없으면 이니셜 노출', (tester) async {
    await tester.pumpWidget(wrap(const Avatar(initial: '노아')));
    expect(find.text('노'), findsOneWidget);
  });

  testWidgets('LabelChip / StatusChip 텍스트 노출', (tester) async {
    await tester.pumpWidget(wrap(const Column(children: [
      LabelChip(text: '내 메모'),
      StatusChip(text: '읽는 중'),
    ])));
    expect(find.text('내 메모'), findsOneWidget);
    expect(find.text('읽는 중'), findsOneWidget);
  });

  testWidgets('SegmentFilter 탭하면 인덱스 콜백', (tester) async {
    int? tapped;
    await tester.pumpWidget(wrap(SegmentFilter(
      segments: const ['함께', '내 메모'],
      selectedIndex: 0,
      onChanged: (i) => tapped = i,
    )));
    await tester.tap(find.text('내 메모'));
    expect(tapped, 1);
  });

  testWidgets('PrimaryButton onPressed null 이면 비활성', (tester) async {
    var pressed = false;
    await tester.pumpWidget(wrap(PrimaryButton(
      label: '저장',
      onPressed: () => pressed = true,
    )));
    await tester.tap(find.text('저장'));
    expect(pressed, isTrue);
  });

  testWidgets('MemoCard 작성자/본문/수정됨/책메타 노출', (tester) async {
    await tester.pumpWidget(wrap(const MemoCard(
      content: '오늘 읽은 문장이 오래 남았다',
      authorName: '노아',
      dateText: '3일 전',
      edited: true,
      bookTitle: '아처',
      page: 42,
    )));
    expect(find.text('오늘 읽은 문장이 오래 남았다'), findsOneWidget);
    expect(find.text('노아'), findsOneWidget);
    expect(find.text('수정됨'), findsOneWidget);
    expect(find.textContaining('아처'), findsOneWidget);
  });

  testWidgets('MemoCard Lyra 물음 스냅샷 노출', (tester) async {
    await tester.pumpWidget(wrap(const MemoCard(
      content: '답을 적었다',
      authorName: '노아',
      lyraQuestion: '요즘 마음에 남는 문장은 뭐야?',
    )));
    expect(find.text('요즘 마음에 남는 문장은 뭐야?'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });
}
