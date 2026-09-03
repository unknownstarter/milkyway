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
  final int savers;

  const RecommendedBook({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    this.publicMemos = 0,
    this.savers = 0,
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

  /// get_recommended_books RPC row -> 엔티티(savers 포함).
  factory RecommendedBook.fromRpcRow(Map<String, dynamic> row) {
    return RecommendedBook(
      id: row['id'] as String,
      title: (row['title'] as String?) ?? '',
      author: (row['author'] as String?) ?? '',
      coverUrl: row['cover_url'] as String?,
      publicMemos: (row['public_memo_count'] as num?)?.toInt() ?? 0,
      savers: (row['savers_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// 사회적 증거 문구(한국어 원문). UI는 이걸 쓰지 말고
  /// `presentation/recommended_book_l10n.dart`의 recommendedBookProof를 쓴다.
  String get proofLabel {
    if (savers > 0) return '$savers명이 담은 책';
    if (publicMemos > 0) return '메모 $publicMemos개가 쌓인 책';
    return '방금 올라온 책';
  }
}
