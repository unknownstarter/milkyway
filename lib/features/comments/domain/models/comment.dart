/// 메모에 달린 댓글. 작성자(users) 조인 포함.
class Comment {
  final String id;
  final String memoId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? authorNickname;
  final String? authorAvatarUrl;

  Comment({
    required this.id,
    required this.memoId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.authorNickname,
    this.authorAvatarUrl,
  });

  /// 실제 편집 여부. insert 시 created/updated를 같은 now로 넣으므로 수 ms 차이는
  /// 편집이 아니다(Memo.isEdited와 동일 규칙).
  bool get isEdited {
    final u = updatedAt;
    if (u == null) return false;
    return u.difference(createdAt) > const Duration(seconds: 1);
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    // Supabase 조인 결과: users는 객체 또는 배열일 수 있음(Memo.fromJson과 동일 처리)
    Map<String, dynamic>? users;
    final usersData = json['users'];
    if (usersData is List && usersData.isNotEmpty) {
      users = usersData[0] as Map<String, dynamic>?;
    } else if (usersData is Map<String, dynamic>) {
      users = usersData;
    }

    return Comment(
      id: json['id'] as String,
      memoId: json['memo_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      authorNickname: users?['nickname'] as String?,
      authorAvatarUrl: users?['picture_url'] as String?,
    );
  }
}
