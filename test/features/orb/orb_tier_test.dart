import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/orb/domain/orb_tier.dart';

// 티어 결정/게이트/다음단계 계약 잠금. 임계값 변경 시 이 테스트가 알려준다.
// 포인트 = 메모*3 + 책 (메모 주동력).
void main() {
  test('포인트 = 메모*3 + 책', () {
    expect(orbPoints(0, 0), 0);
    expect(orbPoints(14, 62), 200); // 62*3 + 14
    expect(orbPoints(2, 7), 23);
  });

  test('메모가 책보다 티어에 더 크게 기여', () {
    // 쓰는 사람(메모 40) > 모으는 사람(메모 20), 책이 적어도.
    final writer = orbPoints(5, 40); // 125
    final collector = orbPoints(20, 20); // 80
    expect(writer > collector, isTrue);
  });

  test('경계값에서 티어가 정확히 갈린다', () {
    expect(resolveOrbTier(0, 0).tier, OrbTier.t1);
    expect(resolveOrbTier(0, 9).tier, OrbTier.t1); // 27
    expect(resolveOrbTier(0, 10).tier, OrbTier.t2); // 30
    expect(resolveOrbTier(0, 30).tier, OrbTier.t3); // 90
    expect(resolveOrbTier(14, 62).tier, OrbTier.t4); // 200
    expect(resolveOrbTier(0, 167).tier, OrbTier.t5); // 501
    expect(resolveOrbTier(58, 340).tier, OrbTier.t6); // 1078
    expect(resolveOrbTier(0, 400).tier, OrbTier.t6); // 1200 상한 안전
  });

  test('다음 단계까지 남은 포인트, 최고 티어는 null', () {
    expect(pointsToNextTier(0, 9), 3); // 27 -> 30까지 3
    expect(pointsToNextTier(0, 10), 60); // 30 -> 90까지 60
    expect(pointsToNextTier(58, 340), isNull); // t6
  });

  test('오브 게이트: 메모 7 이상', () {
    expect(isOrbUnlocked(6), isFalse);
    expect(isOrbUnlocked(7), isTrue);
    expect(orbGateMemos, 7);
  });

  test('자산 경로가 티어 키와 일치', () {
    expect(orbCoreAsset(OrbTier.t4), 'assets/images/orb/orb_t4_core.webp');
    expect(orbGlassAsset(OrbTier.t4), 'assets/images/orb/orb_t4_glass.webp');
  });
}
