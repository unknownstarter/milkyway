import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/discovery/data/models/recommended_book.dart';
import 'package:whatif_milkyway_app/features/discovery/data/repositories/discovery_repository.dart';

void main() {
  group('countPublicMemosByBook', () {
    test('book_id별 개수 집계', () {
      final rows = [
        {'book_id': 'a'},
        {'book_id': 'b'},
        {'book_id': 'a'},
        {'book_id': 'a'},
      ];
      final counts = DiscoveryRepository.countPublicMemosByBook(rows);
      expect(counts['a'], 3);
      expect(counts['b'], 1);
    });

    test('null book_id는 무시', () {
      final rows = [
        {'book_id': null},
        {'book_id': 'a'},
      ];
      final counts = DiscoveryRepository.countPublicMemosByBook(rows);
      expect(counts.length, 1);
      expect(counts['a'], 1);
    });

    test('빈 입력이면 빈 맵', () {
      expect(DiscoveryRepository.countPublicMemosByBook([]), isEmpty);
    });
  });

  group('topBookIds', () {
    test('개수 내림차순 상위 N', () {
      final counts = {'a': 3, 'b': 1, 'c': 5};
      expect(DiscoveryRepository.topBookIds(counts, 2), ['c', 'a']);
    });

    test('limit을 넘지 않음', () {
      expect(DiscoveryRepository.topBookIds({'a': 1}, 5).length, 1);
    });
  });

  group('RecommendedBook.fromBookRow', () {
    // books SELECT가 실제로 반환하는 shape (Supabase 실측 기준)
    final row = {
      'id': 'e7bf4525-70b5-42b5-b73b-e9b65f193701',
      'title': '코스모스',
      'author': '칼 세이건',
      'cover_url': 'https://example.com/cosmos.jpg',
    };

    test('행을 모델로 매핑하고 공개 메모 수를 주입', () {
      final b = RecommendedBook.fromBookRow(row, publicMemos: 1);
      expect(b.id, 'e7bf4525-70b5-42b5-b73b-e9b65f193701');
      expect(b.title, '코스모스');
      expect(b.author, '칼 세이건');
      expect(b.coverUrl, 'https://example.com/cosmos.jpg');
      expect(b.publicMemos, 1);
    });

    test('proofLabel은 메모가 있으면 개수, 없으면 방금 올라온 책', () {
      expect(RecommendedBook.fromBookRow(row, publicMemos: 3).proofLabel,
          '메모 3개가 쌓인 책');
      expect(RecommendedBook.fromBookRow(row, publicMemos: 0).proofLabel,
          '방금 올라온 책');
    });

    test('title/author 누락 시 빈 문자열, cover 없으면 null', () {
      final b = RecommendedBook.fromBookRow({'id': 'x'});
      expect(b.title, '');
      expect(b.author, '');
      expect(b.coverUrl, isNull);
    });
  });
}
