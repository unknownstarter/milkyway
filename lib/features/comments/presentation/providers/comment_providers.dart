import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/edge_function_client.dart';
import '../../data/repositories/comment_repository.dart';
import '../../domain/models/comment.dart';
import '../../../home/presentation/providers/book_provider.dart';

/// memo_provider 스타일에 맞춘 수동 Provider 선언.
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository(Supabase.instance.client,
      edge: ref.watch(edgeFunctionClientProvider));
});

/// 특정 메모의 댓글 목록.
/// autoDispose: 메모 상세를 나가면 폐기 -> 재진입 시 항상 최신 댓글 재조회(실시간성)
/// + 방문한 메모마다 캐시가 쌓이지 않게(메모리). invalidate 갱신은 skipLoadingOnRefresh
/// 기본값 덕에 이전 리스트를 유지해 깜빡임 없음.
final commentsProvider =
    FutureProvider.autoDispose.family<List<Comment>, String>((ref, memoId) async {
  return ref.watch(commentRepositoryProvider).getComments(memoId);
});

/// 그 책을 내가 저장했는지(댓글 작성 게이트).
/// 조회 실패는 false 로 삼키지 않고 오류로 낸다(false 면 멀쩡히 담은 사용자에게
/// 책 담기 팝업이 뜬다). 화면 쪽 해석은 [isCommentComposerUnlocked].
/// autoDispose: 담기 후 최신 상태 반영 + 캐시 누적 방지.
final isBookSavedProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, bookId) async {
  final repo = ref.watch(bookRepositoryProvider);
  return repo.hasUserBookConnection(bookId, repo.getCurrentUserId());
});

/// 댓글 작성창을 열어 둘지.
/// - 저장 확인됨(true) -> 연다 / 미저장(false) -> 잠그고 책 담기를 유도
/// - 확인 중 -> 잠금 유지(기존 동작)
/// - 확인 실패 -> 연다. 저장 여부는 서버 RLS(comments_insert, user_books 조인)가
///   보내는 시점에 강제하므로, 조회 오류를 '미저장'으로 단정해 담기 팝업을
///   띄우는 것보다 안전하다. 미저장이면 보내기가 실패해 오류 토스트가 뜬다.
bool isCommentComposerUnlocked(AsyncValue<bool> saved) {
  if (saved.hasValue) return saved.value!;
  return saved.hasError;
}
