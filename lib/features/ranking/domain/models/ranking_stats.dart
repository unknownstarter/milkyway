/// 내 주간 기록 통계(익명 백분위 + 성장). get_my_ranking() RPC 1행에 대응.
/// 표시 문구는 카피 규칙 준수(AI 금지기호 없음, '당신' 금지, 느낌표 없음).
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

  /// 상위 N% 라벨(순위 없으면 null).
  String? get topPercentLabel => hasRank ? '상위 $topPercent%' : null;

  /// 지난주 대비 성장 문구.
  String get deltaLabel {
    if (delta > 0) return '지난주보다 $delta개 늘었어';
    if (delta < 0) return '지난주보다 ${-delta}개 줄었어';
    return '지난주와 같아';
  }

  /// 연속 읽은 날 라벨(0이면 null).
  String? get streakLabel =>
      streakDays > 0 ? '$streakDays일 연속 읽는 중' : null;

  factory RankingStats.fromRow(Map<String, dynamic> row) => RankingStats(
        thisWeekMemos: (row['this_week_memos'] as num?)?.toInt() ?? 0,
        lastWeekMemos: (row['last_week_memos'] as num?)?.toInt() ?? 0,
        delta: (row['delta'] as num?)?.toInt() ?? 0,
        topPercent: (row['top_percent'] as num?)?.toInt(),
        activeUsers: (row['active_users'] as num?)?.toInt() ?? 0,
        streakDays: (row['streak_days'] as num?)?.toInt() ?? 0,
      );
}
