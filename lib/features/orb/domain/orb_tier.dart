/// 진화 은하 오브 티어. 포인트(책권수*10 + 메모수)로 6단계 결정.
/// 자산: assets/images/orb/orb_tN.png. 상세: docs/design/05-SHARE_ORB_SPEC.md
enum OrbTier { t1, t2, t3, t4, t5, t6 }

class OrbTierInfo {
  final OrbTier tier;
  final String name; // 한국어 표시명
  final int lo; // 포인트 하한(이상)
  const OrbTierInfo(this.tier, this.name, this.lo);
}

/// 오브 생성 최소 메모 수(게이트).
const int orbGateMemos = 7;

const List<OrbTierInfo> orbTiers = [
  OrbTierInfo(OrbTier.t1, '작은 성운', 0),
  OrbTierInfo(OrbTier.t2, '별무리', 30),
  OrbTierInfo(OrbTier.t3, '별자리', 90),
  OrbTierInfo(OrbTier.t4, '성단', 200),
  OrbTierInfo(OrbTier.t5, '은하', 500),
  OrbTierInfo(OrbTier.t6, '대은하', 1000),
];

/// 메모가 주동력(책의 3배 가중). 책은 보조.
int orbPoints(int books, int memos) => memos * 3 + books;

OrbTierInfo resolveOrbTier(int books, int memos) {
  final p = orbPoints(books, memos);
  return orbTiers.lastWhere((t) => p >= t.lo);
}

OrbTierInfo orbTierInfo(OrbTier tier) =>
    orbTiers.firstWhere((t) => t.tier == tier);

/// 다음 티어까지 남은 포인트. 최고 티어면 null.
int? pointsToNextTier(int books, int memos) {
  final cur = resolveOrbTier(books, memos);
  final idx = orbTiers.indexWhere((t) => t.tier == cur.tier);
  if (idx >= orbTiers.length - 1) return null;
  return orbTiers[idx + 1].lo - orbPoints(books, memos);
}

/// 오브 생성 게이트 통과 여부.
bool isOrbUnlocked(int memos) => memos >= orbGateMemos;

/// 회전하는 은하 레이어.
String orbCoreAsset(OrbTier tier) => 'assets/images/orb/orb_${tier.name}_core.webp';

/// 고정 유리 하이라이트 레이어.
String orbGlassAsset(OrbTier tier) => 'assets/images/orb/orb_${tier.name}_glass.webp';
