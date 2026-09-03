import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/orb/domain/orb_tier.dart';
import 'package:whatif_milkyway_app/features/orb/domain/share_payload.dart';
import 'package:whatif_milkyway_app/features/orb/presentation/providers/orb_providers.dart';
import 'package:whatif_milkyway_app/features/orb/presentation/screens/my_orb_screen.dart';
import 'package:whatif_milkyway_app/features/orb/presentation/widgets/orb_gate_banner.dart';
import 'package:whatif_milkyway_app/features/wrapped/domain/wrapped_data.dart';
import 'package:whatif_milkyway_app/features/wrapped/presentation/providers/wrapped_providers.dart';
import 'package:whatif_milkyway_app/features/wrapped/presentation/screens/wrapped_screen.dart';
import 'package:whatif_milkyway_app/l10n/app_localizations.dart';

import '../../support/test_fonts.dart';

/// 오버플로 예외는 안 나지만 말줄임(...)으로 **잘리는** 경우를 잡는다.
/// 판정 기준: 한국어에서는 안 잘리는데 다른 언어에서만 잘리는 텍스트.
/// (책 제목/메모 미리보기처럼 의도적으로 maxLines를 건 콘텐츠는 한국어에서도
///  잘리므로 자동으로 제외된다.)
void main() {
  setUpAll(loadAppFonts);

  const locales = ['en', 'ja', 'zh'];
  const size = Size(320, 568); // 가장 좁은 지원 단말

  const orbData = OrbShareData(
    books: 14,
    memos: 62,
    topPercent: 23,
    streakDays: 9,
    tier: OrbTier.t4, // 등급명이 가장 긴 티어
    pointsToNext: 138,
    connection: null,
  );

  const wrappedData = WrappedData(
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

  /// 화면에서 잘린(말줄임 처리된) 텍스트 목록.
  Set<String> truncatedTexts(WidgetTester tester) {
    final out = <String>{};
    void walk(RenderObject node) {
      if (node is RenderParagraph && node.didExceedMaxLines) {
        out.add(node.text.toPlainText());
      }
      node.visitChildren(walk);
    }

    walk(tester.binding.renderViewElement!.renderObject!);
    return out;
  }

  Future<Set<String>> renderAndCollect(
    WidgetTester tester,
    List<Override> overrides,
    Widget screen,
    String lang,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: Locale(lang),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        debugShowCheckedModeBanner: false,
        home: screen,
      ),
    ));
    await tester.pump();
    return truncatedTexts(tester);
  }

  Future<void> checkNoExtraTruncation(
    WidgetTester tester,
    List<Override> overrides,
    Widget screen,
    String label,
  ) async {
    final ko = await renderAndCollect(tester, overrides, screen, 'ko');
    for (final lang in locales) {
      final other = await renderAndCollect(tester, overrides, screen, lang);
      // 한국어 대비 '추가로' 잘린 게 있으면 번역문이 길어 UI가 깨진 것.
      expect(other.length, lessThanOrEqualTo(ko.length),
          reason: '$label [$lang] 한국어보다 많은 텍스트가 잘림: $other (ko: $ko)');
    }
  }

  testWidgets('내 우주 - 번역문 때문에 잘리는 라벨 없음', (tester) async {
    await checkNoExtraTruncation(
      tester,
      [orbShareDataProvider.overrideWith((ref) => orbData)],
      const MyOrbScreen(),
      '내 우주',
    );
  });

  testWidgets('은하 회고 - 번역문 때문에 잘리는 라벨 없음', (tester) async {
    await checkNoExtraTruncation(
      tester,
      [wrappedProvider.overrideWith((ref) => wrappedData)],
      const WrappedScreen(),
      '회고',
    );
  });

  testWidgets('오브 게이트 배너 - 번역문 때문에 잘리는 라벨 없음', (tester) async {
    await checkNoExtraTruncation(
      tester,
      const [],
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Align(
            alignment: Alignment.topCenter,
            child: OrbGateBanner(memos: 3, onTap: () {}),
          ),
        ),
      ),
      '게이트 배너',
    );
  });
}
