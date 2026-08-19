import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/home/domain/models/book.dart';
import 'package:whatif_milkyway_app/features/home/domain/models/book_status.dart';
import 'package:whatif_milkyway_app/features/profile/domain/profile_stats.dart';

Book _book(BookStatus status) => Book(
      id: 'b-${status.value}-${status.hashCode}',
      title: 't',
      author: 'a',
      status: status,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      isbn: 'i',
    );

void main() {
  test('담은 책=전체, 완독=completed만, 메모=memoCount 그대로', () {
    final books = [
      _book(BookStatus.wantToRead),
      _book(BookStatus.reading),
      _book(BookStatus.completed),
      _book(BookStatus.completed),
    ];
    final stats = computeProfileStats(books: books, memoCount: 41);

    expect(stats.savedBooks, 4);
    expect(stats.completedBooks, 2);
    expect(stats.memos, 41);
  });

  test('빈 서재는 모두 0', () {
    final stats = computeProfileStats(books: const [], memoCount: 0);
    expect(stats.savedBooks, 0);
    expect(stats.completedBooks, 0);
    expect(stats.memos, 0);
  });
}
