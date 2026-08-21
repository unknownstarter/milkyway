import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/ranking/domain/models/ranking_stats.dart';

void main() {
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
    test('topPercentLabel', () {
      expect(RankingStats.fromRow(row(top: 15)).topPercentLabel, '상위 15%');
      expect(RankingStats.fromRow(row(thisWeek: 0, top: null)).topPercentLabel,
          isNull);
    });

    test('deltaLabel 증가/감소/동일', () {
      expect(RankingStats.fromRow(row(delta: 3)).deltaLabel, '지난주보다 3개 늘었어');
      expect(RankingStats.fromRow(row(delta: -2)).deltaLabel, '지난주보다 2개 줄었어');
      expect(RankingStats.fromRow(row(delta: 0)).deltaLabel, '지난주와 같아');
    });

    test('streakLabel', () {
      expect(RankingStats.fromRow(row(streak: 4)).streakLabel, '4일 연속 읽는 중');
      expect(RankingStats.fromRow(row(streak: 0)).streakLabel, isNull);
    });

    test('라벨에 AI 금지기호/당신/느낌표 없음', () {
      final labels = [
        RankingStats.fromRow(row()).topPercentLabel ?? '',
        RankingStats.fromRow(row(delta: 3)).deltaLabel,
        RankingStats.fromRow(row(delta: -1)).deltaLabel,
        RankingStats.fromRow(row(streak: 2)).streakLabel ?? '',
      ];
      final forbidden = RegExp(r'[—–·…“”‘’!]|당신');
      for (final l in labels) {
        expect(forbidden.hasMatch(l), isFalse, reason: '금지기호 포함: $l');
      }
    });
  });
}
