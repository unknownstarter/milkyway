import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/discovery/presentation/providers/discovery_providers.dart';

void main() {
  group('BookSelection', () {
    test('toggle은 추가와 제거를 오간다', () {
      final s = BookSelection();
      expect(s.state, isEmpty);
      s.toggle('a');
      expect(s.state, {'a'});
      s.toggle('b');
      expect(s.state, {'a', 'b'});
      s.toggle('a');
      expect(s.state, {'b'});
    });

    test('clear는 전체 비운다', () {
      final s = BookSelection()
        ..toggle('a')
        ..toggle('b');
      s.clear();
      expect(s.state, isEmpty);
    });
  });
}
