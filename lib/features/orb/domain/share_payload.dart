import 'orb_tier.dart';
import '../../constellation/data/models/constellation.dart' show RelType;

/// 공유 카드 연결 블록(그때 -> 지금 + Lyra 근거). constellation 최강 엣지에서 도출.
class OrbConnection {
  final String pastPreview;
  final String nowPreview;
  final DateTime pastDate;
  final DateTime nowDate;
  final RelType? relType; // 표시 문구는 로케일에 따라 presentation에서 결정
  final String? rationale;

  const OrbConnection({
    required this.pastPreview,
    required this.nowPreview,
    required this.pastDate,
    required this.nowDate,
    this.relType,
    this.rationale,
  });
}

/// 공유 카드에 필요한 전체 스냅샷. 기존 provider들에서 조합(신규 쿼리 최소).
class OrbShareData {
  final int books;
  final int memos;
  final int? topPercent;
  final int streakDays;
  final OrbTier tier;
  final int? pointsToNext; // 다음 단계까지 남은 포인트(최고 티어면 null)
  final OrbConnection? connection; // 없으면 스탯형 폴백

  const OrbShareData({
    required this.books,
    required this.memos,
    required this.topPercent,
    required this.streakDays,
    required this.tier,
    required this.pointsToNext,
    this.connection,
  });

  bool get unlocked => isOrbUnlocked(memos);
}
