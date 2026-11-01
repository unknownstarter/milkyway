/// 남의 비공개 메모라 접근이 제한된 경우. bookId가 있으면 책 상세로 유도할 수 있다.
class MemoRestrictedException implements Exception {
  final String? bookId;
  MemoRestrictedException(this.bookId);

  @override
  String toString() => 'MemoRestrictedException(bookId: $bookId)';
}

/// 메모가 정말 없는 경우(삭제됨 등). 서버가 404 를 주거나 데이터가 비어 있을 때만 던진다.
/// 429/5xx/네트워크 오류는 이 타입이 아니라 일반 예외로 전파해야 한다.
class MemoNotFoundException implements Exception {
  const MemoNotFoundException();

  @override
  String toString() => 'MemoNotFoundException';
}
