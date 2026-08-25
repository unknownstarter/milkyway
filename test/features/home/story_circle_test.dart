import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:whatif_milkyway_app/core/presentation/widgets/design/story_circle.dart';

// 홈 상단 스토리 원(이미지를 호출해서 가져오는 대표 지점)이 규격대로 동작하는지.
void main() {
  Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('라벨 노출 + 탭 콜백', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(StoryCircle(
      label: '데미안',
      ring: StoryRing.seen,
      onTap: () => tapped = true,
    )));
    expect(find.text('데미안'), findsOneWidget);
    await tester.tap(find.byType(StoryCircle));
    expect(tapped, isTrue);
  });

  testWidgets('add 링은 + 아이콘, 네트워크 요청 없음', (tester) async {
    await tester.pumpWidget(_wrap(StoryCircle(
      label: '추가',
      ring: StoryRing.add,
      onTap: () {},
    )));
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  testWidgets('표지 없으면(널) 네트워크 요청 없이 렌더', (tester) async {
    await tester.pumpWidget(_wrap(StoryCircle(
      label: '표지없음',
      coverUrl: null,
      ring: StoryRing.active,
      onTap: () {},
    )));
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  testWidgets('Supabase 표지는 홈 상단에서 156px render 변환 URL로 요청', (tester) async {
    const cover =
        'https://p.supabase.co/storage/v1/object/public/book_covers/covers/1.jpg';
    await tester.pumpWidget(_wrap(StoryCircle(
      label: '변환',
      coverUrl: cover,
      ring: StoryRing.active,
      onTap: () {},
    )));
    final cni =
        tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
    expect(cni.imageUrl, contains('/render/image/public/'));
    expect(cni.imageUrl, contains('width=156'));
  });
}
