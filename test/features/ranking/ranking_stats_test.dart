import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/ranking/domain/models/ranking_stats.dart';
import 'package:whatif_milkyway_app/features/ranking/presentation/widgets/ranking_card.dart';
import 'package:whatif_milkyway_app/l10n/app_localizations.dart';

void main() {
  // 표시 문구 조립은 domain getter에서 presentation(RankingCard)으로 이동했다.
  // 라벨 검증은 카드를 ko 로케일로 렌더해서 확인한다.
  Widget card(RankingStats stats) => MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: Scaffold(body: RankingCard(stats: stats)),
      );

  Map<String, dynamic> row({
    int thisWeek = 3,
    int lastWeek = 1,
    int delta = 2,
    int? top = 15,
    int active = 20,
    int streak = 4,
  }) =>
      {
        'this_week_memos': thisWeek,
        'last_week_memos': lastWeek,
        'delta': delta,
        'top_percent': top,
        'active_users': active,
        'streak_days': streak,
      };

  group('fromRow', () {
    test('모든 필드 파싱', () {
      final s = RankingStats.fromRow(row());
      expect(s.thisWeekMemos, 3);
      expect(s.lastWeekMemos, 1);
      expect(s.delta, 2);
      expect(s.topPercent, 15);
      expect(s.activeUsers, 20);
      expect(s.streakDays, 4);
    });

    test('top_percent null 허용', () {
      final s = RankingStats.fromRow(row(top: null, thisWeek: 0));
      expect(s.topPercent, isNull);
    });
  });

  group('hasRank / isEmptyThisWeek', () {
    test('기록 있고 백분위 있으면 hasRank', () {
      expect(RankingStats.fromRow(row()).hasRank, isTrue);
    });
    test('이번 주 기록 0이면 순위 없음', () {
      final s = RankingStats.fromRow(row(thisWeek: 0, top: null));
      expect(s.hasRank, isFalse);
      expect(s.isEmptyThisWeek, isTrue);
    });
  });

  group('표시 라벨(카피 규칙 준수)', () {
    testWidgets('상위 백분위 라벨', (tester) async {
      await tester.pumpWidget(card(RankingStats.fromRow(row(top: 15))));
      expect(find.text('상위 15%'), findsOneWidget);

      // 백분위 없으면(이번 주 기록 0) 상위 라벨 자체가 안 나온다.
      await tester
          .pumpWidget(card(RankingStats.fromRow(row(thisWeek: 0, top: null))));
      expect(find.textContaining('상위'), findsNothing);
    });

    testWidgets('성장 라벨 증가/감소/동일', (tester) async {
      await tester.pumpWidget(card(RankingStats.fromRow(row(delta: 3))));
      expect(find.text('지난주보다 3개 늘었어'), findsOneWidget);

      await tester.pumpWidget(card(RankingStats.fromRow(row(delta: -2))));
      expect(find.text('지난주보다 2개 줄었어'), findsOneWidget);

      await tester.pumpWidget(card(RankingStats.fromRow(row(delta: 0))));
      expect(find.text('지난주와 같아'), findsOneWidget);
    });

    testWidgets('연속 읽은 날 라벨', (tester) async {
      await tester.pumpWidget(card(RankingStats.fromRow(row(streak: 4))));
      expect(find.text('4일 연속 읽는 중'), findsOneWidget);

      // 0이면 연속 라벨 숨김.
      await tester.pumpWidget(card(RankingStats.fromRow(row(streak: 0))));
      expect(find.textContaining('연속'), findsNothing);
    });

    testWidgets('라벨에 AI 금지기호/당신/느낌표 없음', (tester) async {
      final forbidden = RegExp(r'[—–·…“”‘’!]|당신');

      Future<void> check(RankingStats stats) async {
        await tester.pumpWidget(card(stats));
        final labels = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .whereType<String>()
            .where((s) => s.isNotEmpty);
        for (final l in labels) {
          expect(forbidden.hasMatch(l), isFalse, reason: '금지기호 포함: $l');
        }
      }

      await check(RankingStats.fromRow(row()));
      await check(RankingStats.fromRow(row(delta: 3)));
      await check(RankingStats.fromRow(row(delta: -1)));
      await check(RankingStats.fromRow(row(streak: 2)));
    });
  });
}
