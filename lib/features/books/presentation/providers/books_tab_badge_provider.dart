import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/domain/book_activity.dart';
import '../../../home/presentation/providers/book_provider.dart'
    show homeBooksProvider;
import '../../../../core/providers/seen_tracker_provider.dart';
import '../../../../core/services/seen_tracker.dart';

/// 하단 네비 Books 점 여부.
///
/// 저장책 중 '안 본 남의 새 공개 메모'(others > tabLastSeen('books'))가
/// 하나라도 있으면 true. Books 탭 진입 시 markTabSeen('books') → 무효화됨.
///
/// autoDispose: 탭 이동/포그라운드 복귀 시 자연스럽게 재계산. 폴링 없음.
final booksTabHasNewProvider = FutureProvider.autoDispose<bool>((ref) async {
  final books = await ref.watch(homeBooksProvider.future);
  if (books.isEmpty) return false;

  final tracker = ref.watch(seenTrackerProvider);
  final lastSeen = await tracker.tabLastSeen(SeenTracker.tabBooks);

  for (final b in books) {
    if (hasNewOthers(b.othersLastPublicMemoAt, lastSeen)) return true;
  }
  return false;
});
