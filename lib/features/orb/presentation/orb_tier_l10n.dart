import '../../../l10n/app_localizations.dart';
import '../domain/orb_tier.dart';

/// 오브 등급 표시명 로컬라이저. 도메인은 언어 중립(analytics는 tier.name 사용),
/// 표시/공유 시점에만 현재 언어로 매핑.
String orbTierName(AppL10n l, OrbTier tier) {
  switch (tier) {
    case OrbTier.t1:
      return l.orbTierNebulaSmall;
    case OrbTier.t2:
      return l.orbTierStarCluster;
    case OrbTier.t3:
      return l.orbTierConstellation;
    case OrbTier.t4:
      return l.orbTierCluster;
    case OrbTier.t5:
      return l.orbTierGalaxy;
    case OrbTier.t6:
      return l.orbTierSuperGalaxy;
  }
}
