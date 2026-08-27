import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/domain/book_activity.dart';
import '../../../home/domain/models/book.dart';
import '../../../home/presentation/providers/book_provider.dart'
    show homeBooksProvider;
import '../../../../core/providers/seen_tracker_provider.dart';

/// 책탭 그리드 1칸: 랭킹된 책 + '안 본 남의 새 공개 메모' 여부.
typedef ShelfBook = ({Book book, bool showNewDot});

/// 책탭 전용: 홈과 같은 순서로 정렬된 저장책 + 썸네일 빨간 점 여부.
///
/// 데이터는 홈과 동일한 `get_home_books_ranked`(저장책 전체) 사용.
/// 정렬(A/B/C)과 점 판정은 홈과 동일한 순수 함수(book_activity)로 계산.
/// 상태 필터(모든 책/읽고 싶은/읽는 중/완독)는 화면에서 이 순서 위에 적용.
///
/// autoDispose: 책탭 재진입/invalidate 때 로컬 last-viewed를 다시 읽어
/// 상세를 본 책의 점이 사라지도록 한다.
final bookShelfProvider = FutureProvider.autoDispose<List<ShelfBook>>((ref) async {
  // 홈과 같은 랭킹 fetch를 재사용(homeBooksProvider). 무효화 경로 공유.
  final books = await ref.watch(homeBooksProvider.future);
  if (books.isEmpty) return const <ShelfBook>[];

  ref.watch(seenControllerProvider.select((s) => s.bookViewed)); // 책봤음 리비전만 구독
  final viewed = await ref
      .read(seenControllerProvider.notifier)
      .allBookViewed(books.map((b) => b.id).toList());

  final sorted = sortByActivity(books, viewed);

  return [
    for (final b in sorted)
      (
        book: b,
        showNewDot: hasNewOthers(b.othersLastPublicMemoAt, viewed[b.id]),
      ),
  ];
});
