import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/comment_repository.dart';
import '../../domain/models/comment.dart';
import '../../../home/presentation/providers/book_provider.dart';

/// memo_provider 스타일에 맞춘 수동 Provider 선언.
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository(Supabase.instance.client);
});

/// 특정 메모의 댓글 목록.
final commentsProvider =
    FutureProvider.family<List<Comment>, String>((ref, memoId) async {
  return ref.watch(commentRepositoryProvider).getComments(memoId);
});

/// 그 책을 내가 저장했는지(댓글 작성 게이트). 실패 시 false.
final isBookSavedProvider =
    FutureProvider.family<bool, String>((ref, bookId) async {
  final repo = ref.watch(bookRepositoryProvider);
  try {
    return await repo.hasUserBookConnection(bookId, repo.getCurrentUserId());
  } catch (_) {
    return false;
  }
});
