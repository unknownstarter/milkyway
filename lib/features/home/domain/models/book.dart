import 'book_status.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final String? description;
  final String? publisher;
  final String? pubdate;
  final BookStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String isbn;

  /// 내가 이 책에 남긴 마지막 메모 시각 (없으면 null). 홈 랭킹 RPC 전용.
  final DateTime? myLastMemoAt;

  /// 타 유저의 마지막 공개 메모 시각 (없으면 null). 홈 랭킹 RPC 전용.
  final DateTime? othersLastPublicMemoAt;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    this.description,
    this.publisher,
    this.pubdate,
    this.status = BookStatus.wantToRead,
    required this.createdAt,
    required this.updatedAt,
    required this.isbn,
    this.myLastMemoAt,
    this.othersLastPublicMemoAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      coverUrl: json['cover_url'],
      description: json['description'],
      publisher: json['publisher'],
      pubdate: json['pubdate'],
      status: BookStatus.fromString(json['status']),
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
      isbn: json['isbn'] ?? '',
    );
  }

  /// 홈 랭킹 RPC(`get_home_books_ranked`) 결과 전용 파서.
  /// fromJson과 동일 매핑 + my_last_memo_at / others_last_public_memo_at 추가.
  factory Book.fromHomeRanked(Map<String, dynamic> json) {
    DateTime? tryParse(dynamic v) =>
        v == null ? null : DateTime.tryParse(v as String);
    return Book(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      coverUrl: json['cover_url'],
      description: json['description'],
      publisher: json['publisher'],
      pubdate: json['pubdate'],
      status: BookStatus.fromString(json['status']),
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
      isbn: json['isbn'] ?? '',
      myLastMemoAt: tryParse(json['my_last_memo_at']),
      othersLastPublicMemoAt: tryParse(json['others_last_public_memo_at']),
    );
  }
}
