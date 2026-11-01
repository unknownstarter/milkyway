import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/core/utils/time_utils.dart';

void main() {
  test('nowUtcIso 는 Z 로 끝나는 UTC ISO 문자열', () {
    final s = nowUtcIso();
    expect(s.endsWith('Z'), isTrue);
    final parsed = DateTime.parse(s);
    expect(parsed.isUtc, isTrue);
    expect(parsed.difference(DateTime.now().toUtc()).abs().inSeconds, lessThan(5));
  });
}
