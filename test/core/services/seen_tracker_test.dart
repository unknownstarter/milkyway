import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whatif_milkyway_app/core/services/seen_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SeenTracker 책별', () {
    test('mark → read 왕복', () async {
      final tracker = SeenTracker();
      final before = DateTime.now();
      await tracker.markBookViewed('book-1');
      final read = await tracker.bookLastViewed('book-1');

      expect(read, isNotNull);
      // 기록 시각이 mark 직전 이후여야 함(오차 허용).
      expect(read!.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
    });

    test('없는 책 키는 null', () async {
      final tracker = SeenTracker();
      expect(await tracker.bookLastViewed('unknown'), isNull);
    });

    test('allBookViewed는 기록된 책만 포함', () async {
      final tracker = SeenTracker();
      await tracker.markBookViewed('a');
      await tracker.markBookViewed('c');

      final map = await tracker.allBookViewed(['a', 'b', 'c']);
      expect(map.keys.toSet(), {'a', 'c'});
      expect(map.containsKey('b'), isFalse);
    });
  });

  group('SeenTracker 탭별', () {
    test('mark → read 왕복', () async {
      final tracker = SeenTracker();
      await tracker.markTabSeen(SeenTracker.tabMemos);
      expect(await tracker.tabLastSeen(SeenTracker.tabMemos), isNotNull);
    });

    test('안 본 탭은 null', () async {
      final tracker = SeenTracker();
      expect(await tracker.tabLastSeen(SeenTracker.tabBooks), isNull);
    });
  });

  group('책/탭 키 분리', () {
    test('책 mark가 탭 값에 새지 않음', () async {
      final tracker = SeenTracker();
      await tracker.markBookViewed('books'); // 탭 키와 같은 문자열이지만 접두사 다름
      expect(await tracker.tabLastSeen('books'), isNull);
    });

    test('탭 mark가 책 값에 새지 않음', () async {
      final tracker = SeenTracker();
      await tracker.markTabSeen('some-book-id');
      expect(await tracker.bookLastViewed('some-book-id'), isNull);
    });
  });
}
