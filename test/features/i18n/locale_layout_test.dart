import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/orb/domain/orb_tier.dart';
import 'package:whatif_milkyway_app/features/orb/domain/share_payload.dart';
import 'package:whatif_milkyway_app/features/orb/presentation/widgets/share_card.dart';
import 'package:whatif_milkyway_app/features/orb/presentation/widgets/orb_gate_banner.dart';
import 'package:whatif_milkyway_app/features/wrapped/domain/wrapped_data.dart';
import 'package:whatif_milkyway_app/features/wrapped/presentation/widgets/wrapped_card.dart';
import 'package:whatif_milkyway_app/l10n/app_localizations.dart';

/// 4개 언어에서 공유 카드/회고 카드/게이트 배너가 오버플로 없이 렌더되는지.
/// (번역문이 한국어보다 길어져 레이아웃이 깨지는 걸 잡는다.)
void main() {
  const locales = [Locale('ko'), Locale('en'), Locale('ja'), Locale('zh')];

  Widget app(Locale locale, Widget child) => MaterialApp(
        locale: locale,
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        debugShowCheckedModeBanner: false,
        home: Material(type: MaterialType.transparency, child: child),
      );

  testWidgets('ShareCard 전 언어 오버플로 없음', (tester) async {
    tester.view.physicalSize = const Size(ShareCard.w, ShareCard.h);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const d = OrbShareData(
      books: 14,
      memos: 62,
      topPercent: 23,
      streakDays: 9,
      tier: OrbTier.t4,
      pointsToNext: 138,
      connection: null,
    );
    for (final l in locales) {
      await tester.pumpWidget(app(l, const Center(child: ShareCard(data: d))));
      expect(tester.takeException(), isNull, reason: 'locale=$l');
    }
  });

  testWidgets('WrappedCard 전 언어 오버플로 없음', (tester) async {
    tester.view.physicalSize = const Size(WrappedCard.w, WrappedCard.h);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const d = WrappedData(
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
    for (final l in locales) {
      await tester.pumpWidget(app(l, WrappedCard(data: d)));
      expect(tester.takeException(), isNull, reason: 'locale=$l');
    }
  });

  testWidgets('OrbGateBanner 전 언어 오버플로 없음', (tester) async {
    for (final l in locales) {
      await tester.pumpWidget(app(
        l,
        Padding(
          padding: const EdgeInsets.all(20),
          child: Align(
            alignment: Alignment.topCenter,
            child: OrbGateBanner(memos: 3, onTap: () {}),
          ),
        ),
      ));
      expect(tester.takeException(), isNull, reason: 'locale=$l');
    }
  });
}
