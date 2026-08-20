import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../books/presentation/providers/user_books_provider.dart';
import '../../../memos/presentation/providers/memo_provider.dart';
import '../../domain/profile_stats.dart';

/// 마이페이지 "내 기록" 요약. statistics 테이블 대신 내 서재/메모에서 집계.
final profileStatsProvider = FutureProvider<ProfileStats>((ref) async {
  final books = await ref.watch(userBooksProvider.future);
  final memos = await ref.watch(allMemosProvider.future);
  return computeProfileStats(books: books, memoCount: memos.length);
});
