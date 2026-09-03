import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/ranking/domain/models/ranking_stats.dart';
import 'package:whatif_milkyway_app/features/ranking/presentation/widgets/ranking_card.dart';
import 'package:whatif_milkyway_app/l10n/app_localizations.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: Scaffold(body: child),
      );

  testWidgets('순위 있으면 상위 %/성장/이번주 수/연속 노출', (tester) async {
    await tester.pumpWidget(wrap(const RankingCard(
      stats: RankingStats(
        thisWeekMemos: 3,
        lastWeekMemos: 1,
        delta: 2,
        topPercent: 15,
        activeUsers: 20,
        streakDays: 4,
      ),
    )));
    expect(find.text('이번 주 나의 기록'), findsOneWidget);
    expect(find.text('상위 15%'), findsOneWidget);
    expect(find.text('지난주보다 2개 늘었어'), findsOneWidget);
    expect(find.text('이번 주 3개'), findsOneWidget);
    expect(find.text('4일 연속 읽는 중'), findsOneWidget);
  });

  testWidgets('이번 주 기록 없으면 시작 유도 + 지난주 안내', (tester) async {
    await tester.pumpWidget(wrap(const RankingCard(
      stats: RankingStats(
        thisWeekMemos: 0,
        lastWeekMemos: 5,
        delta: -5,
        topPercent: null,
        activeUsers: 10,
        streakDays: 0,
      ),
    )));
    expect(find.text('이번 주 첫 기록을 남겨봐'), findsOneWidget);
    expect(find.text('지난주엔 5개 남겼어'), findsOneWidget);
    expect(find.text('상위 15%'), findsNothing);
  });
}
