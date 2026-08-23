/// Memos 탭 하단 네비 빨간 점용 활동 시각.
///
/// RPC `get_memos_badge_activity` 결과.
///  - [feedLastAt]    타 유저의 마지막 공개 메모 시각
///  - [commentLastAt] 내 메모에 달린 타 유저의 마지막 댓글 시각
/// 둘 다 nullable. 클라이언트가 max(둘) > tabLastSeen('memos') 이면 점 표시.
class MemoBadgeActivity {
  final DateTime? feedLastAt;
  final DateTime? commentLastAt;

  const MemoBadgeActivity({this.feedLastAt, this.commentLastAt});

  factory MemoBadgeActivity.fromJson(Map<String, dynamic> json) {
    DateTime? tryParse(dynamic v) =>
        v == null ? null : DateTime.tryParse(v as String);
    return MemoBadgeActivity(
      feedLastAt: tryParse(json['feed_last_at']),
      commentLastAt: tryParse(json['comment_last_at']),
    );
  }

  /// 두 활동 중 가장 최근 시각(둘 다 null이면 null).
  DateTime? get latestAt {
    final f = feedLastAt;
    final c = commentLastAt;
    if (f == null) return c;
    if (c == null) return f;
    return f.isAfter(c) ? f : c;
  }
}
