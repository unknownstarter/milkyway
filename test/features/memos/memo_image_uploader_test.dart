import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/memos/utils/memo_image_uploader.dart';

// 업로드 분기(로컬 파일 vs 이미 업로드된 URL) 판별이 정확한지.
// 표시 위젯이 이 판별로 Image.file / CachedImage(url) 를 고르므로 값 정확성이 중요.
void main() {
  group('MemoImageUploader.isLocalFile', () {
    test('http/https URL 은 로컬 파일 아님', () {
      expect(MemoImageUploader.isLocalFile('https://x.co/a.jpg'), isFalse);
      expect(MemoImageUploader.isLocalFile('http://x.co/a.jpg'), isFalse);
    });

    test('로컬 경로는 로컬 파일', () {
      expect(MemoImageUploader.isLocalFile('/data/user/0/cache/a.jpg'), isTrue);
      expect(
          MemoImageUploader.isLocalFile('/var/mobile/tmp/image_picker_1.jpg'),
          isTrue);
    });

    test('null 은 로컬 파일 아님', () {
      expect(MemoImageUploader.isLocalFile(null), isFalse);
    });
  });
}
