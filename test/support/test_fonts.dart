import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 테스트 기본 폰트는 글자 하나를 fontSize 크기의 사각형으로 그린다.
/// 그래서 라틴 문자가 실제보다 2배 가까이 넓게 측정되고, 다국어 레이아웃 검증이
/// 거짓 실패한다. 번들 폰트를 앱 폰트 이름으로 로드해 실제에 가깝게 만든다.
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<ByteData> load(String path) async =>
      ByteData.view(Uint8List.fromList(File(path).readAsBytesSync()).buffer);
  final loader = FontLoader('Pretendard')
    ..addFont(load('assets/fonts/NotoSansKR-Regular.ttf'))
    ..addFont(load('assets/fonts/NotoSansKR-Bold.ttf'));
  await loader.load();
}
