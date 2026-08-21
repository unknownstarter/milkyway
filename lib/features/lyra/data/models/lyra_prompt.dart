/// get_lyra_prompt() RPC 결과 1행. 홈에서 노출할 '다음 Lyra 물음'.
/// source=book이면 bookId/bookTitle이 채워지고, general이면 null.
class LyraPrompt {
  final String source; // 'book' | 'general'
  final String? questionId;
  final String question;
  final String? bookId;
  final String? bookTitle;

  const LyraPrompt({
    required this.source,
    required this.question,
    this.questionId,
    this.bookId,
    this.bookTitle,
  });

  bool get isBook => source == 'book';

  static LyraPrompt fromRow(Map<String, dynamic> row) {
    return LyraPrompt(
      source: row['source'] as String,
      questionId: row['question_id'] as String?,
      question: (row['question'] as String).trim(),
      bookId: row['book_id'] as String?,
      bookTitle: row['book_title'] as String?,
    );
  }
}
