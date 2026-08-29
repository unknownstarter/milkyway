import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constellation/data/models/constellation.dart';
import '../../../constellation/presentation/providers/constellation_providers.dart';
import '../../../profile/presentation/providers/profile_stats_provider.dart';
import '../../../ranking/presentation/providers/ranking_providers.dart';
import '../../domain/orb_tier.dart';
import '../../domain/share_payload.dart';

/// 오브 해금 여부(메모 7개 게이트). 홈 배너 노출 판단.
final orbUnlockedProvider = FutureProvider.autoDispose<bool>((ref) async {
  final stats = await ref.watch(profileStatsProvider.future);
  return isOrbUnlocked(stats.memos);
});

/// 공유 카드 데이터. 기존 provider 조합(스탯 재사용 + 연결은 constellation에서).
final orbShareDataProvider = FutureProvider.autoDispose<OrbShareData>((ref) async {
  final stats = await ref.watch(profileStatsProvider.future);
  final ranking = await ref.watch(myRankingProvider.future);

  // 연결은 실패해도 카드는 떠야 하므로 폴백 null.
  OrbConnection? connection;
  try {
    final con = await ref.watch(constellationProvider.future);
    connection = _pickConnection(con);
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

/// 별자리 엣지 중 '가장 드라마틱한' 연결 1개 선택.
/// 우선순위: rationale 있음 -> strength 높음 -> 관계(달라짐>확장>다시떠오름>닮음).
OrbConnection? _pickConnection(Constellation con) {
  final byId = {for (final n in con.nodes) n.id: n};
  final valid = con.edges
      .where((e) =>
          (e.rationale?.isNotEmpty ?? false) &&
          byId.containsKey(e.memoA) &&
          byId.containsKey(e.memoB))
      .toList();
  if (valid.isEmpty) return null;

  valid.sort((a, b) {
    final s = b.strength.compareTo(a.strength);
    if (s != 0) return s;
    return _relRank(a.relType).compareTo(_relRank(b.relType));
  });

  final e = valid.first;
  final a = byId[e.memoA]!;
  final b = byId[e.memoB]!;
  final past = a.createdAt.isBefore(b.createdAt) ? a : b;
  final now = a.createdAt.isBefore(b.createdAt) ? b : a;

  return OrbConnection(
    pastPreview: past.preview,
    nowPreview: now.preview,
    pastDate: past.createdAt,
    nowDate: now.createdAt,
    relLabel: _relLabel(e.relType),
    rationale: e.rationale,
  );
}

int _relRank(RelType? t) {
  switch (t) {
    case RelType.reverses:
      return 0;
    case RelType.extends_:
      return 1;
    case RelType.echo:
      return 2;
    case RelType.similar:
      return 3;
    default:
      return 4;
  }
}

String _relLabel(RelType? t) {
  switch (t) {
    case RelType.extends_:
      return '확장';
    case RelType.reverses:
      return '달라짐';
    case RelType.echo:
      return '다시 떠오름';
    case RelType.similar:
      return '닮음';
    default:
      return '연결';
  }
}
