import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/presentation/widgets/design/story_circle.dart';
import '../../../../core/providers/seen_tracker_provider.dart';
import '../../data/repositories/book_repository.dart';
import '../../domain/book_activity.dart';
import '../../domain/models/book.dart';

final bookRepositoryProvider = Provider((ref) {
  return BookRepository(Supabase.instance.client);
});

final recentBooksProvider = FutureProvider<List<Book>>((ref) async {
  final repository = ref.watch(bookRepositoryProvider);
  // 여기서 현재 로그인한 사용자의 ID를 기반으로 책을 조회해야 함
  return repository.getRecentBooks();
});

/// 공개된 메모가 많은 순으로 책 목록 가져오기 (최대 10개)
final popularBooksProvider = FutureProvider<List<Book>>((ref) async {
  final repository = ref.watch(bookRepositoryProvider);
  return repository.getPopularBooksByPublicMemos();
});

/// 홈 화면 전용: 랭킹 RPC(get_home_books_ranked) 결과.
///
/// 반환 타입은 List<Book>로 기존과 동일(홈 나머지 로직 유지).
/// Book에 myLastMemoAt / othersLastPublicMemoAt 가 채워진다.
/// 책 등록/삭제, 책 상태 변경, 메모 CRUD 후에는 함께 invalidate 필요.
final homeBooksProvider = FutureProvider<List<Book>>((ref) async {
  final repository = ref.watch(bookRepositoryProvider);
  return repository.getHomeBooksRanked();
});

/// 홈 스토리 원 1개의 표시 정보 (책 + 링 종류).
typedef HomeStory = ({Book book, StoryRing ring});

/// 홈 스토리 원 전용: 랭킹된 책 + 로컬 조회 이력으로 정렬/링을 계산.
///
/// 순서: [내 메모 있는 책: myLastMemoAt DESC]
///     → [안 본 남의 새 공개 메모 책: othersLastPublicMemoAt DESC]
///     → [나머지: 원래 순서].
/// 링 우선순위: active(안 본 남의 새 공개 메모) > mine(내 메모) > seen.
///
/// autoDispose: 홈 재진입/invalidate 때 로컬 lastViewed를 다시 읽어
/// 상세를 본 책의 초록 링이 사라지도록 한다.
final homeStoriesProvider = FutureProvider.autoDispose<List<HomeStory>>((ref) async {
  final books = await ref.watch(homeBooksProvider.future);
  if (books.isEmpty) return const <HomeStory>[];

  final tracker = ref.watch(seenTrackerProvider);
  final viewed = await tracker.allBookViewed(books.map((b) => b.id).toList());

  final sorted = sortByActivity(books, viewed);

  StoryRing ringFor(Book b) {
    // 링 = "안 본 남의 새 공개 메모"(초록)만. 내 메모 책은 순서(왼쪽)로만 구분(링 없음).
    // 링이 "새 것" 신호라, 안 없어지는 mine 링은 직관에 어긋나 제거(B안).
    if (hasNewOthers(b.othersLastPublicMemoAt, viewed[b.id])) {
      return StoryRing.active;
    }
    return StoryRing.seen;
  }

  return [
    for (final b in sorted) (book: b, ring: ringFor(b)),
  ];
});
