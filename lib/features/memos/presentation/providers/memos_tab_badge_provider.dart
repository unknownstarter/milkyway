import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/memo_repository.dart' show memoRepositoryProvider;
import '../../../../core/providers/seen_tracker_provider.dart';
import '../../../../core/services/seen_tracker.dart';

/// 하단 네비 Memos 점 여부.
///
/// max(feed_last_at, comment_last_at) > tabLastSeen('memos') 이면 true.
/// (남의 새 공개 메모 or 내 메모에 달린 새 댓글)
/// Memos 탭 진입 시 markTabSeen('memos') → 무효화됨.
///
/// autoDispose: 탭 이동/포그라운드 복귀 시 재계산. 폴링 없음.
final memosTabHasNewProvider = FutureProvider.autoDispose<bool>((ref) async {
  final repository = ref.watch(memoRepositoryProvider);
  final badge = await repository.getMemosBadgeActivity();
  final latest = badge.latestAt;
  if (latest == null) return false;

  final tracker = ref.watch(seenTrackerProvider);
  final lastSeen = await tracker.tabLastSeen(SeenTracker.tabMemos);
  if (lastSeen == null) return true;
  return latest.isAfter(lastSeen);
});
