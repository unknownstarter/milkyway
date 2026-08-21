import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/ranking_stats.dart';

/// 내 주간 기록 통계 조회. get_my_ranking() RPC 경유(집계값만, PII 없음).
class RankingRepository {
  final SupabaseClient _client;
  RankingRepository(this._client);

  Future<RankingStats> getMyRanking() async {
    final rows = await _client.rpc('get_my_ranking');
    if (rows is List && rows.isNotEmpty) {
      return RankingStats.fromRow(rows.first as Map<String, dynamic>);
    }
    // 신규/빈 결과는 0 통계로(카드에서 시작 유도 표시).
    return const RankingStats(
      thisWeekMemos: 0,
      lastWeekMemos: 0,
      delta: 0,
      topPercent: null,
      activeUsers: 0,
      streakDays: 0,
    );
  }
}
