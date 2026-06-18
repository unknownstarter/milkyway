import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/book_repository.dart';
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

/// 홈 화면 전용: 최근 메모 활동순으로 정렬된 사용자 책 목록.
///
/// 메모가 있는 책 → 최신 메모 작성 시점 DESC,
/// 메모가 없는 책 → user_books.created_at DESC (뒤쪽).
/// 책 등록/삭제, 책 상태 변경, 메모 CRUD 후에는 함께 invalidate 필요.
final homeBooksProvider = FutureProvider<List<Book>>((ref) async {
  final repository = ref.watch(bookRepositoryProvider);
  return repository.getHomeBooksByLastActivity();
});
