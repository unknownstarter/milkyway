import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:whatif_milkyway_app/core/presentation/widgets/design/cached_image.dart';

// "이미지를 호출해서 가져오는 곳"이 규격대로 요청하는지 위젯 레벨에서 검증.
// (모든 표시 위젯이 CachedImage를 경유하므로 여기서 프로토콜을 보장하면 전 화면이 보장됨)
void main() {
  const supabaseCover =
      'https://p.supabase.co/storage/v1/object/public/book_covers/covers/9788934985907.jpg';
  const naverCover =
      'https://bookthumb-phinf.pstatic.net/cover/1.jpg?type=m1';

  CachedNetworkImage _cni(WidgetTester t) =>
      t.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));

  testWidgets('Supabase 표지는 render 변환 URL + WebP Accept 로 요청', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: CachedImage(url: supabaseCover, cacheWidth: 156),
    ));
    final cni = _cni(tester);
    expect(cni.imageUrl, contains('/storage/v1/render/image/public/'));
    expect(cni.imageUrl, contains('width=156'));
    expect(cni.imageUrl, contains('quality=80'));
    expect(cni.httpHeaders?['Accept'], contains('webp'));
  });

  testWidgets('외부(네이버) 표지는 원본 URL 그대로 요청(변환 안 함)', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: CachedImage(url: naverCover, cacheWidth: 300),
    ));
    expect(_cni(tester).imageUrl, naverCover);
  });

  testWidgets('cacheWidth 없으면 원본 URL(풀스크린 뷰어용)', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: CachedImage(url: supabaseCover),
    ));
    expect(_cni(tester).imageUrl, supabaseCover);
  });

  testWidgets('빈/널 URL 이면 네트워크 요청 없이 fallback', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: CachedImage(url: null, fallback: Text('none')),
    ));
    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.text('none'), findsOneWidget);
  });

  // surface별 표준 cacheWidth가 실제로 그 폭으로 요청되는지(프로토콜 회귀 방지)
  testWidgets('surface별 표준 폭이 그대로 변환폭으로 전달', (tester) async {
    for (final w in [120, 156, 240, 300, 700, 1000]) {
      await tester.pumpWidget(MaterialApp(
        home: CachedImage(url: supabaseCover, cacheWidth: w),
      ));
      expect(_cni(tester).imageUrl, contains('width=$w'));
    }
  });
}
