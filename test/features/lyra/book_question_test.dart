import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/lyra/data/models/book_question.dart';

void main() {
  group('BookQuestion.fromRow', () {
    test('정상 row를 파싱하고 question 앞뒤 공백을 제거한다', () {
      final q = BookQuestion.fromRow({
        'id': 'q1',
        'book_id': 'b1',
        'question': '  요즘 나를 지탱하는 분류표가 있어?  ',
        'model': 'claude-opus-4-8',
        'created_at': '2026-08-19T03:00:00Z',
      });

      expect(q.id, 'q1');
      expect(q.bookId, 'b1');
      expect(q.question, '요즘 나를 지탱하는 분류표가 있어?');
      expect(q.model, 'claude-opus-4-8');
      expect(q.createdAt, isNotNull);
      expect(q.createdAt!.isUtc, isTrue);
    });

    test('model / created_at 이 null 이어도 안전하게 파싱한다', () {
      final q = BookQuestion.fromRow({
        'id': 'q2',
        'book_id': 'b2',
        'question': '물음',
        'model': null,
        'created_at': null,
      });

      expect(q.model, isNull);
      expect(q.createdAt, isNull);
    });
  });
}
