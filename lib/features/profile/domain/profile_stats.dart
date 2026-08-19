import '../../home/domain/models/book.dart';
import '../../home/domain/models/book_status.dart';

/// 마이페이지 "내 기록" 요약. statistics 테이블은 비어 있어(트리거 없음)
/// 내 user_books/memos에서 클라이언트가 직접 집계한다.
class ProfileStats {
  final int savedBooks;
  final int completedBooks;
  final int memos;

  const ProfileStats({
    required this.savedBooks,
    required this.completedBooks,
    required this.memos,
  });
}

/// 순수 집계(테스트 대상). books=내 서재, memoCount=내 메모 수.
ProfileStats computeProfileStats({
  required List<Book> books,
  required int memoCount,
}) {
  return ProfileStats(
    savedBooks: books.length,
    completedBooks:
        books.where((b) => b.status == BookStatus.completed).length,
    memos: memoCount,
  );
}
