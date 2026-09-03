import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/constellation/data/models/constellation.dart';
import 'package:whatif_milkyway_app/features/constellation/presentation/providers/constellation_providers.dart';
import 'package:whatif_milkyway_app/features/constellation/presentation/screens/constellation_screen.dart';
import 'package:whatif_milkyway_app/features/orb/domain/orb_tier.dart';
import 'package:whatif_milkyway_app/features/orb/domain/share_payload.dart';
import 'package:whatif_milkyway_app/features/orb/presentation/providers/orb_providers.dart';
import 'package:whatif_milkyway_app/features/orb/presentation/screens/my_orb_screen.dart';
import 'package:whatif_milkyway_app/features/orb/presentation/widgets/shader_orb.dart';
import 'package:whatif_milkyway_app/features/wrapped/domain/wrapped_data.dart';
import 'package:whatif_milkyway_app/features/wrapped/presentation/providers/wrapped_providers.dart';
import 'package:whatif_milkyway_app/features/wrapped/presentation/screens/wrapped_screen.dart';
import 'package:whatif_milkyway_app/l10n/app_localizations.dart';

import '../../support/test_fonts.dart';

/// 실제 앱 스크린을 4개 언어 x 좁은 단말에서 렌더해 오버플로/잘림을 잡는다.
/// (번역문이 한국어보다 3~6배 긴 라벨이 있어서 - 예: '성단' vs 'Star Cluster' -
///  스탯 패널이나 배지처럼 폭이 고정된 곳이 가장 위험하다.)
void main() {
  setUpAll(loadAppFonts);

  const locales = [Locale('ko'), Locale('en'), Locale('ja'), Locale('zh')];
  // 가장 좁은 지원 단말(iPhone SE 1세대급) + 일반 폰.
  const sizes = [Size(320, 568), Size(375, 667)];

  final orbData = const OrbShareData(
    books: 14,
    memos: 62,
    topPercent: 23,
    streakDays: 9,
    tier: OrbTier.t4, // '성단' / 'Star Cluster' - 가장 긴 등급명
    pointsToNext: 138,
    connection: null,
  );

  final wrappedData = const WrappedData(
    year: 2026,
    month: 8,
    memoCount: 34,
    readDays: 21,
    topPercent: 12,
    bookTitle: '미움받을 용기',
    bookAuthor: '기시미 이치로',
    bookCoverUrl: null,
    bookMemoCount: 9,
    quote: '무너뜨리기 싫은 칸이 있었다',
    quoteBookTitle: '미움받을 용기',
    lyra: '요즘 무너뜨리기 싫은 칸은 뭐야',
    tier: OrbTier.t4,
  );

  final constellation = Constellation(
    nodes: [
      ConNode(
          id: 'a',
          preview: '어제의 나는 확신이 있었다',
          createdAt: DateTime(2026, 6, 1)),
      ConNode(
          id: 'b',
          preview: '오늘의 나는 조금 흔들린다',
          createdAt: DateTime(2026, 8, 1)),
    ],
    edges: [
      ConEdge(
          memoA: 'a',
          memoB: 'b',
          relType: RelType.reverses,
          strength: 0.9,
          rationale: '같은 물음을 다르게 본다'),
    ],
  );

  Future<void> pumpAll(
    WidgetTester tester,
    List<Override> overrides,
    Widget screen,
    String label,
    Finder rendered,
  ) async {
    for (final size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final l in locales) {
        await tester.pumpWidget(ProviderScope(
          overrides: overrides,
          child: MaterialApp(
            locale: l,
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.localizationsDelegates,
            debugShowCheckedModeBanner: false,
            home: screen,
          ),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull,
            reason: '$label locale=$l size=$size');
        // 로딩 상태로 통과하지 않도록 실제 콘텐츠가 그려졌는지 확인.
        expect(rendered, findsWidgets, reason: '$label locale=$l 렌더 안 됨');
      }
    }
  }

  testWidgets('내 우주 스크린 - 전 언어/좁은 화면', (tester) async {
    await pumpAll(
      tester,
      [orbShareDataProvider.overrideWith((ref) => orbData)],
      const MyOrbScreen(),
      '내 우주',
      find.byType(ShaderOrb),
    );
  });

  testWidgets('은하 회고 스크린 - 전 언어/좁은 화면', (tester) async {
    await pumpAll(
      tester,
      [wrappedProvider.overrideWith((ref) => wrappedData)],
      const WrappedScreen(),
      '회고',
      find.textContaining('미움받을 용기'),
    );
  });

  testWidgets('별자리 스크린 - 전 언어/좁은 화면', (tester) async {
    await pumpAll(
      tester,
      [constellationProvider.overrideWith((ref) => constellation)],
      const ConstellationScreen(),
      '별자리',
      find.textContaining('어제의 나는'),
    );
  });
}
