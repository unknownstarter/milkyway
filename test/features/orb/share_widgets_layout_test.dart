import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/orb/domain/orb_tier.dart';
import 'package:whatif_milkyway_app/features/orb/domain/share_payload.dart';
import 'package:whatif_milkyway_app/features/orb/presentation/widgets/share_card.dart';
import 'package:whatif_milkyway_app/features/orb/presentation/widgets/orb_gate_banner.dart';

// 레이아웃 계약: 포스터가 1080x1350 안에 오버플로 없이 들어가는지, 배너가 정상 렌더되는지.
// (이미지/폰트 로드 없이도 오버플로는 잡힌다 - 가장 흔한 버그 방어.)
void main() {
  testWidgets('ShareCard 포스터 오버플로 없음(전 티어)', (tester) async {
    tester.view.physicalSize = const Size(ShareCard.w, ShareCard.h);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final tier in OrbTier.values) {
      final d = OrbShareData(
        books: 14, memos: 62, topPercent: tier == OrbTier.t1 ? null : 23,
        streakDays: 9, tier: tier,
        pointsToNext: tier == OrbTier.t6 ? null : 138, connection: null,
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Center(child: ShareCard(data: d))),
      ));
      expect(tester.takeException(), isNull, reason: 'tier=$tier 오버플로');
    }
  });

  testWidgets('OrbGateBanner 오버플로 없음', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Align(
            alignment: Alignment.topCenter,
            child: OrbGateBanner(memos: 3, onTap: () {}),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
