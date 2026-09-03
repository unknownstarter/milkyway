import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/ranking/domain/models/ranking_stats.dart';
import 'package:whatif_milkyway_app/features/ranking/presentation/widgets/ranking_card.dart';
import 'package:whatif_milkyway_app/l10n/app_localizations.dart';

/// RankingCard 카피 규칙 강제 + 빈/경계 상태.
/// 이 카드는 순수 표현 위젯이라 모든 Text 가 시스템 카피다(사용자 입력 없음).
void main() {
  Widget wrap(Widget child) => MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: Scaffold(body: child),
      );

  final banned = RegExp(r'[—–·“”‘’…]');
  final honorific = RegExp('당신');
  final bang = RegExp('!');

  List<String> texts(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data)
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .toList();

  void assertClean(WidgetTester tester) {
    for (final s in texts(tester)) {
      expect(banned.hasMatch(s), isFalse, reason: 'AI 금지 기호: "$s"');
      expect(honorific.hasMatch(s), isFalse, reason: '"당신" 호칭: "$s"');
      expect(bang.hasMatch(s), isFalse, reason: '느낌표: "$s"');
    }
  }

  const rankedStats = RankingStats(
    thisWeekMemos: 3,
    lastWeekMemos: 1,
    delta: 2,
    topPercent: 15,
    activeUsers: 20,
    streakDays: 4,
  );

  testWidgets('순위 있는 상태 카피 규칙 준수', (tester) async {
    await tester.pumpWidget(wrap(const RankingCard(stats: rankedStats)));
    assertClean(tester);
  });

  testWidgets('이번 주 기록 0 + 지난주 0(완전 빈 상태) - 지난주 안내 미노출', (tester) async {
    await tester.pumpWidget(wrap(const RankingCard(
      stats: RankingStats(
        thisWeekMemos: 0,
        lastWeekMemos: 0,
        delta: 0,
        topPercent: null,
        activeUsers: 0,
        streakDays: 0,
      ),
    )));
    expect(find.text('이번 주 첫 기록을 남겨봐'), findsOneWidget);
    expect(find.textContaining('지난주엔'), findsNothing);
    assertClean(tester);
  });

  testWidgets('delta 음수/0 성장 문구 규칙 준수', (tester) async {
    await tester.pumpWidget(wrap(const RankingCard(
      stats: RankingStats(
        thisWeekMemos: 2,
        lastWeekMemos: 5,
        delta: -3,
        topPercent: 40,
        activeUsers: 10,
        streakDays: 0,
      ),
    )));
    expect(find.text('지난주보다 3개 줄었어'), findsOneWidget);
    // streakDays 0 이면 연속 라벨 미노출
    expect(find.textContaining('연속'), findsNothing);
    assertClean(tester);
  });

  testWidgets('delta 0 이면 지난주와 같아', (tester) async {
    await tester.pumpWidget(wrap(const RankingCard(
      stats: RankingStats(
        thisWeekMemos: 4,
        lastWeekMemos: 4,
        delta: 0,
        topPercent: 30,
        activeUsers: 10,
        streakDays: 1,
      ),
    )));
    expect(find.text('지난주와 같아'), findsOneWidget);
    assertClean(tester);
  });
}
