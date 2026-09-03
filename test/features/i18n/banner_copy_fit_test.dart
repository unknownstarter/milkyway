import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/core/presentation/widgets/design/banner_bar.dart';
import 'package:whatif_milkyway_app/l10n/app_localizations.dart';

import '../../support/test_fonts.dart';

/// BannerBar는 제목/부제 모두 maxLines 1 + ellipsis라 번역문이 길면 **말없이 잘린다**.
/// 홈에 깔리는 배너 카피 전량을 4개 언어 x 가장 좁은 단말에서 렌더해 잘림을 잡는다.
void main() {
  setUpAll(loadAppFonts);

  const locales = [Locale('ko'), Locale('en'), Locale('ja'), Locale('zh')];

  /// (라벨, 제목, 부제) - 실제 홈에서 BannerBar에 넘기는 문구들.
  List<(String, String, String)> banners(AppL10n l) => [
        ('읽기 유도', l.homeReadPromptTitle, l.homeReadPromptBody),
        ('오브', l.homeOrbTitle, l.homeOrbBody),
        ('별자리', l.homeConstellationTitle, l.homeConstellationBody),
        ('회고', l.wrappedEntryTitle('8월'), l.wrappedEntryBody(34)),
        ('오브 게이트', l.orbGateBannerTitle, l.orbGateBannerBody(4)),
      ];

  testWidgets('홈 배너 카피가 4개 언어에서 잘리지 않는다', (tester) async {
    // 가장 좁은 지원 단말. 배너는 좌우 20 패딩 안에 들어간다.
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final failures = <String>[];

    for (final locale in locales) {
      // 현재 로케일의 문구를 얻기 위해 먼저 AppL10n을 로드한다.
      final l = await AppL10n.delegate.load(locale);
      for (final (label, title, subtitle) in banners(l)) {
        await tester.pumpWidget(MaterialApp(
          locale: locale,
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.topCenter,
                child: BannerBar(
                  icon: Icons.auto_awesome,
                  title: title,
                  subtitle: subtitle,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ));
        await tester.pump();

        void walk(RenderObject node) {
          if (node is RenderParagraph && node.didExceedMaxLines) {
            failures.add(
                '[${locale.languageCode}] $label: "${node.text.toPlainText()}"');
          }
          node.visitChildren(walk);
        }

        walk(tester.binding.renderViewElement!.renderObject!);
      }
    }

    expect(failures, isEmpty,
        reason: '배너 문구가 잘림(번역문 축약 필요):\n${failures.join('\n')}');
  });
}
