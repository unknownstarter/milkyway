import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/orb/domain/orb_tier.dart';
import 'package:whatif_milkyway_app/features/orb/domain/share_payload.dart';
import 'package:whatif_milkyway_app/features/orb/presentation/widgets/share_card.dart';
import 'package:whatif_milkyway_app/features/orb/presentation/widgets/orb_gate_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatif_milkyway_app/features/orb/presentation/providers/orb_providers.dart';
import 'package:whatif_milkyway_app/features/orb/presentation/screens/my_orb_screen.dart';
import 'package:whatif_milkyway_app/features/orb/presentation/widgets/shader_orb.dart';
import 'package:whatif_milkyway_app/l10n/app_localizations.dart';

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
        locale: const Locale('ko'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: Scaffold(body: Center(child: ShareCard(data: d))),
      ));
      expect(tester.takeException(), isNull, reason: 'tier=$tier 오버플로');
    }
  });

  testWidgets('OrbGateBanner 오버플로 없음', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ko'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
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

  // 내 우주는 한 화면에 딱 맞아야 한다(스크롤 금지). 예전엔 오브 크기가 고정값+하한
  // 이라 작은 기기에서 넘쳐 스크롤이 생겼다. 남는 공간을 오브가 먹는 구조로 바뀐 뒤의 계약.
  testWidgets('MyOrbScreen 기기별 오버플로/스크롤 없음', (tester) async {
    const sizes = <Size>[
      Size(320, 568),   // iPhone SE 1세대(최소)
      Size(375, 667),   // iPhone SE 2/3세대
      Size(390, 844),   // iPhone 14
      Size(430, 932),   // iPhone 17 Pro Max
    ];
    const data = OrbShareData(
      books: 14, memos: 62, topPercent: 23, streakDays: 9,
      tier: OrbTier.t3, pointsToNext: 138, connection: null,
    );

    for (final size in sizes) {
      for (final lang in ['ko', 'en', 'ja', 'zh']) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(ProviderScope(
          overrides: [
            orbShareDataProvider.overrideWith((ref) async => data),
          ],
          child: MaterialApp(
            locale: Locale(lang),
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.localizationsDelegates,
            home: const MyOrbScreen(),
          ),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$size/$lang 오버플로');
        expect(find.byType(Scrollable), findsNothing,
            reason: '$size/$lang 스크롤이 생김');
        // 스크롤을 없애려고 오브를 쪼그라뜨리는 회귀 방지.
        // 320x568(SE 1세대)은 텍스트 블록만으로 화면 절반이라 예외 - 넘치지만 않으면 된다.
        if (size.height >= 640) {
          final orb = tester.widget<ShaderOrb>(find.byType(ShaderOrb));
          expect(orb.size, greaterThan(size.width * 0.5),
              reason: '$size/$lang 오브가 너무 작아짐');
        }
      }
    }
  });
}
