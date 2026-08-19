/// Lyra가 책 소개를 바탕으로 생성한 사유 확장 물음.
/// `book_questions` 테이블의 활성(is_active) 행 1개에 대응.
class BookQuestion {
  final String id;
  final String bookId;
  final String question;
  final String? model;
  final DateTime? createdAt;

  const BookQuestion({
    required this.id,
    required this.bookId,
    required this.question,
    this.model,
    this.createdAt,
  });

  /// `book_questions` row -> 엔티티. 순수 함수(테스트 용이).
  static BookQuestion fromRow(Map<String, dynamic> row) {
    return BookQuestion(
      id: row['id'] as String,
      bookId: row['book_id'] as String,
      question: (row['question'] as String).trim(),
      model: row['model'] as String?,
      createdAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'].toString())
          : null,
    );
  }
}
