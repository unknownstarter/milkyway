/// 온보딩/발견 화면의 추천 책.
///
/// 사회적 증거 = 공개 메모 수(`publicMemos`). "담은 사람 수"는 user_books가
/// RLS상 본인 것만 조회되어 클라이언트 집계 불가 → 서버 RPC 확장 시 추가.
class RecommendedBook {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final int publicMemos;

  const RecommendedBook({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    this.publicMemos = 0,
  });

  factory RecommendedBook.fromBookRow(
    Map<String, dynamic> row, {
    int publicMemos = 0,
  }) {
    return RecommendedBook(
      id: row['id'] as String,
      title: (row['title'] as String?) ?? '',
      author: (row['author'] as String?) ?? '',
      coverUrl: row['cover_url'] as String?,
      publicMemos: publicMemos,
    );
  }

  /// 사회적 증거 문구(쉬운 말, 금지 기호 없음).
  String get proofLabel =>
      publicMemos > 0 ? '메모 $publicMemos개가 쌓인 책' : '방금 올라온 책';
}
