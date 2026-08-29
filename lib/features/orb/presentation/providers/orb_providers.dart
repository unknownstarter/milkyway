import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../constellation/presentation/providers/constellation_providers.dart';
import '../../../profile/presentation/providers/profile_stats_provider.dart';
import '../../../ranking/presentation/providers/ranking_providers.dart';
import '../../data/orb_share_mapper.dart';
import '../../data/share_repository.dart';
import '../../domain/orb_tier.dart';
import '../../domain/share_payload.dart';

/// 공유 카드 발행 리포지토리.
final shareRepositoryProvider =
    Provider<ShareRepository>((ref) => ShareRepository(Supabase.instance.client));

/// 오브 해금 여부(메모 7개 게이트). 홈 배너 노출 판단.
final orbUnlockedProvider = FutureProvider.autoDispose<bool>((ref) async {
  final stats = await ref.watch(profileStatsProvider.future);
  return isOrbUnlocked(stats.memos);
});

/// 공유 카드 데이터. 기존 provider 조합(스탯 재사용 + 연결은 constellation에서).
final orbShareDataProvider =
    FutureProvider.autoDispose<OrbShareData>((ref) async {
  // 병렬 로드(직렬 네트워크 방지). watch가 즉시 Future를 반환 -> 셋 다 동시에 시작.
  final statsF = ref.watch(profileStatsProvider.future);
  final rankingF = ref.watch(myRankingProvider.future);
  final conF = ref.watch(constellationProvider.future);

  final stats = await statsF;
  final ranking = await rankingF;

  // 연결은 실패해도 카드는 떠야 하므로 폴백 null.
  OrbConnection? connection;
  try {
    connection = pickOrbConnection(await conF);
  } catch (_) {
    connection = null;
  }

  return OrbShareData(
    books: stats.savedBooks,
    memos: stats.memos,
    topPercent: ranking.topPercent,
    streakDays: ranking.streakDays,
    tier: resolveOrbTier(stats.savedBooks, stats.memos).tier,
    pointsToNext: pointsToNextTier(stats.savedBooks, stats.memos),
    connection: connection,
  );
});
