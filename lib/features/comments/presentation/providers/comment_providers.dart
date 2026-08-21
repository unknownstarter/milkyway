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
/// autoDispose: 메모 상세를 나가면 폐기 -> 재진입 시 항상 최신 댓글 재조회(실시간성)
/// + 방문한 메모마다 캐시가 쌓이지 않게(메모리). invalidate 갱신은 skipLoadingOnRefresh
/// 기본값 덕에 이전 리스트를 유지해 깜빡임 없음.
final commentsProvider =
    FutureProvider.autoDispose.family<List<Comment>, String>((ref, memoId) async {
  return ref.watch(commentRepositoryProvider).getComments(memoId);
});

/// 그 책을 내가 저장했는지(댓글 작성 게이트). 실패 시 false.
/// autoDispose: 담기 후 최신 상태 반영 + 캐시 누적 방지.
final isBookSavedProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, bookId) async {
  final repo = ref.watch(bookRepositoryProvider);
  try {
    return await repo.hasUserBookConnection(bookId, repo.getCurrentUserId());
  } catch (_) {
    return false;
  }
});
