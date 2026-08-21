import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/lyra/data/models/lyra_prompt.dart';

void main() {
  group('LyraPrompt.fromRow', () {
    test('책 물음이면 isBook + 책 정보 파싱', () {
      final p = LyraPrompt.fromRow({
        'source': 'book',
        'question_id': 'q1',
        'question': '이 책에서 뭐가 남았어? ',
        'book_id': 'b1',
        'book_title': '아처',
      });
      expect(p.isBook, isTrue);
      expect(p.questionId, 'q1');
      expect(p.question, '이 책에서 뭐가 남았어?'); // trim
      expect(p.bookId, 'b1');
      expect(p.bookTitle, '아처');
    });

    test('일반 물음이면 책 정보 null + isBook false', () {
      final p = LyraPrompt.fromRow({
        'source': 'general',
        'question_id': 'g1',
        'question': '요즘 마음에 남는 문장은?',
        'book_id': null,
        'book_title': null,
      });
      expect(p.isBook, isFalse);
      expect(p.bookId, isNull);
      expect(p.bookTitle, isNull);
      expect(p.questionId, 'g1');
    });
  });
}
