import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/seen_tracker_provider.dart';
import '../../domain/models/memo.dart';

/// 판정에 필요한 값만 담은 키(Memo 전체를 키로 쓰면 목록 갱신마다 새 인스턴스).
typedef MemoNewCommentKey = ({
  String memoId,
  bool isMine,
  DateTime? lastCommentAt,
});

MemoNewCommentKey memoNewCommentKey(Memo memo, String? currentUserId) => (
      memoId: memo.id,
      isMine: currentUserId != null && memo.userId == currentUserId,
      lastCommentAt: memo.lastCommentAt,
    );

/// 메모 카드의 새 댓글 점 여부. 내 메모이고 last_comment_at 이 본 시각보다 늦으면 true
/// (본 적 없으면 댓글이 있기만 하면 true). 메모 상세 진입 시 markMemoViewed 가
/// memoViewed 리비전을 올려 자동 재계산 -> 돌아오면 점이 꺼져 있다.
final memoHasNewCommentProvider =
    FutureProvider.autoDispose.family<bool, MemoNewCommentKey>((ref, key) async {
  final last = key.lastCommentAt;
  if (!key.isMine || last == null) return false;
  ref.watch(seenControllerProvider.select((s) => s.memoViewed));
  final seen = await ref
      .read(seenControllerProvider.notifier)
      .memoLastViewed(key.memoId);
  return seen == null || last.isAfter(seen);
});
