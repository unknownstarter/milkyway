import 'memo_visibility.dart';

class Memo {
  final String id;
  final String userId;
  final String bookId;
  final String content;
  final int? page;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final MemoVisibility visibility;
  final String bookTitle;
  final Map<String, dynamic> books;
  final String? imageUrl;
  final String? userNickname;
  final String? userAvatarUrl;

  Memo({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.content,
    this.page,
    required this.createdAt,
    this.updatedAt,
    required this.visibility,
    required this.bookTitle,
    required this.books,
    this.imageUrl,
    this.userNickname,
    this.userAvatarUrl,
  });

  /// 실제로 수정된 메모인지. createMemo가 created_at/updated_at을 각각 now()로
  /// 세팅해 새 메모도 updated_at이 created_at보다 수 ms 늦을 수 있어(실측: 151개 중
  /// 39개가 1초 미만 차이), 단순 isAfter로는 새 메모가 '수정됨'으로 오검출된다.
  /// 실제 편집은 항상 수 초 이상 뒤라 임계값으로 분리한다.
  bool get isEdited {
    final u = updatedAt;
    if (u == null) return false;
    return u.difference(createdAt) > const Duration(seconds: 1);
  }

  factory Memo.fromJson(Map<String, dynamic> json) {
    // Supabase 조인 결과 처리: users는 객체 또는 배열일 수 있음
    Map<String, dynamic>? users;
    final usersData = json['users'];
    if (usersData != null) {
      if (usersData is List && usersData.isNotEmpty) {
        // 배열인 경우 첫 번째 요소 사용
        users = usersData[0] as Map<String, dynamic>?;
      } else if (usersData is Map<String, dynamic>) {
        // 객체인 경우 그대로 사용
        users = usersData;
      }
    }

    return Memo(
      id: json['id'],
      userId: json['user_id'],
      bookId: json['book_id'],
      content: json['content'],
      page: json['page'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      visibility: MemoVisibility.fromString(json['visibility']),
      bookTitle: json['books']['title'],
      books: json['books'] as Map<String, dynamic>,
      imageUrl: json['image_url'],
      userNickname: users?['nickname'],
      userAvatarUrl: users?['picture_url'],
    );
  }
}
