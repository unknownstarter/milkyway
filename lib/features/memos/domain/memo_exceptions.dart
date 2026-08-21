/// 남의 비공개 메모라 접근이 제한된 경우. bookId가 있으면 책 상세로 유도할 수 있다.
class MemoRestrictedException implements Exception {
  final String? bookId;
  MemoRestrictedException(this.bookId);

  @override
  String toString() => 'MemoRestrictedException(bookId: $bookId)';
}
