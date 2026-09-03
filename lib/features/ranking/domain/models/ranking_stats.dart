/// 내 주간 기록 통계(익명 백분위 + 성장). get_my_ranking() RPC 1행에 대응.
/// 표시 문구는 presentation(RankingCard)에서 AppL10n으로 조립한다.
class RankingStats {
  final int thisWeekMemos;
  final int lastWeekMemos;
  final int delta;
  final int? topPercent; // 상위 N% (이번 주 기록 없으면 null)
  final int activeUsers;
  final int streakDays;

  const RankingStats({
    required this.thisWeekMemos,
    required this.lastWeekMemos,
    required this.delta,
    required this.topPercent,
    required this.activeUsers,
    required this.streakDays,
  });

  /// 이번 주 순위가 매겨졌는지(기록이 있고 백분위가 있음).
  bool get hasRank => topPercent != null && thisWeekMemos > 0;

  /// 이번 주 아직 기록이 없음.
  bool get isEmptyThisWeek => thisWeekMemos == 0;

  /// 연속 읽은 날 표시 여부(0이면 숨김).
  bool get hasStreak => streakDays > 0;

  factory RankingStats.fromRow(Map<String, dynamic> row) => RankingStats(
        thisWeekMemos: (row['this_week_memos'] as num?)?.toInt() ?? 0,
        lastWeekMemos: (row['last_week_memos'] as num?)?.toInt() ?? 0,
        delta: (row['delta'] as num?)?.toInt() ?? 0,
        topPercent: (row['top_percent'] as num?)?.toInt(),
        activeUsers: (row['active_users'] as num?)?.toInt() ?? 0,
        streakDays: (row['streak_days'] as num?)?.toInt() ?? 0,
      );
}
