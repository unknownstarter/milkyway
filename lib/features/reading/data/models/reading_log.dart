/// 읽음 기록 1건(책 + 읽은 날짜). 캘린더 '책' 세그먼트/스트립의 소스.
class ReadingLog {
  final String bookId;
  final String bookTitle;
  final String? coverUrl;
  final DateTime readOn;

  const ReadingLog({
    required this.bookId,
    required this.bookTitle,
    this.coverUrl,
    required this.readOn,
  });

  static ReadingLog fromRow(Map<String, dynamic> row) {
    final book = (row['books'] as Map<String, dynamic>?) ?? const {};
    return ReadingLog(
      bookId: row['book_id'] as String,
      bookTitle: (book['title'] as String?) ?? '',
      coverUrl: book['cover_url'] as String?,
      readOn: DateTime.parse(row['read_on'].toString()),
    );
  }
}
