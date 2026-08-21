import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/comment.dart';

/// 댓글 CRUD + 신고/숨김. presentation은 반드시 이 repository를 경유한다.
///
/// 정책(RLS로도 강제됨):
///  - 조회: 볼 수 있는 메모(내것/공개)의 댓글, 내가 숨긴 것 제외
///  - 작성: 그 메모의 책을 내가 저장한 경우만 (DB단 차단)
///  - 수정/삭제: 본인 댓글만
///  - 신고/숨김: 누구나 (신고 즉시 내게만 숨김)
class CommentRepository {
  final SupabaseClient _client;
  CommentRepository(this._client);

  static const _withAuthor = '*, users!user_id(nickname, picture_url)';

  String get _uid => _client.auth.currentUser!.id;

  /// 메모의 댓글 목록(오래된 순). 내가 숨긴 댓글은 제외.
  Future<List<Comment>> getComments(String memoId) async {
    final hidden = await _client
        .from('user_hidden_comments')
        .select('comment_id')
        .eq('user_id', _uid);
    final hiddenIds =
        (hidden as List).map((e) => e['comment_id'] as String).toSet();

    final res = await _client
        .from('comments')
        .select(_withAuthor)
        .eq('memo_id', memoId)
        .order('created_at', ascending: true);

    return (res as List)
        .map((j) => Comment.fromJson(j as Map<String, dynamic>))
        .where((c) => !hiddenIds.contains(c.id))
        .toList();
  }

  /// 댓글 작성. 책 미저장 등 정책 위반 시 RLS가 예외를 던진다.
  Future<Comment> addComment(String memoId, String content) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final res = await _client
        .from('comments')
        .insert({
          'memo_id': memoId,
          'user_id': _uid,
          'content': content,
          'created_at': now,
          'updated_at': now,
        })
        .select(_withAuthor)
        .single();
    return Comment.fromJson(res);
  }

  /// 본인 댓글 수정.
  Future<Comment> updateComment(String commentId, String content) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final res = await _client
        .from('comments')
        .update({'content': content, 'updated_at': now})
        .eq('id', commentId)
        .select(_withAuthor)
        .single();
    return Comment.fromJson(res);
  }

  /// 본인 댓글 삭제.
  Future<void> deleteComment(String commentId) async {
    await _client.from('comments').delete().eq('id', commentId);
  }

  /// 신고 = 신고 기록 + 즉시 내 화면에서 숨김.
  Future<void> reportComment(
    String commentId,
    String reason, {
    String? description,
  }) async {
    await _client.from('comment_reports').upsert({
      'comment_id': commentId,
      'reporter_id': _uid,
      'reason': reason,
      'description': description,
    }, onConflict: 'comment_id,reporter_id');
    await hideComment(commentId);
  }

  /// 내 화면에서만 숨김.
  Future<void> hideComment(String commentId) async {
    await _client.from('user_hidden_comments').upsert({
      'user_id': _uid,
      'comment_id': commentId,
    }, onConflict: 'user_id,comment_id');
  }
}
