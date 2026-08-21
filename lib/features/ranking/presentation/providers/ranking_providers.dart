import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../core/utils/error_handler.dart';
import '../../data/repositories/ranking_repository.dart';
import '../../domain/models/ranking_stats.dart';

final rankingRepositoryProvider = Provider<RankingRepository>(
  (ref) => RankingRepository(Supabase.instance.client),
);

/// 내 주간 랭킹. 실패 시 에러코드(ERR_XXXX)로 로그 + GA4 app_error 집계(모니터링).
final myRankingProvider = FutureProvider<RankingStats>((ref) async {
  try {
    return await ref.watch(rankingRepositoryProvider).getMyRanking();
  } catch (e, st) {
    final code = ErrorHandler.codeFor(e);
    ref.read(analyticsProvider).logError(code, operation: 'ranking_fetch');
    developer.log('[$code] 랭킹 조회 실패',
        name: 'Ranking', error: e, stackTrace: st);
    rethrow;
  }
});
