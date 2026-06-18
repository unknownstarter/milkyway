import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../books/presentation/providers/user_books_provider.dart';
import '../../../memos/presentation/providers/memo_provider.dart';
import '../providers/book_provider.dart';
import '../providers/selected_book_provider.dart';
import 'package:flutter/foundation.dart';

final homeLoaderProvider = AsyncNotifierProvider<HomeLoaderNotifier, void>(HomeLoaderNotifier.new);

class HomeLoaderNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    await load();
  }

  Future<void> load() async {
    try {
      final user = await ref.read(authProvider.notifier).getCurrentUser();
      if (user == null) {
        // 인증 실패시 모든 캐시 초기화
        ref.invalidate(userBooksProvider);
        ref.invalidate(recentBooksProvider);
        ref.invalidate(homeBooksProvider);
        ref.invalidate(recentMemosProvider);
        if (onAuthFailed != null) onAuthFailed!();
        return;
      }
      // 데이터 리프레시
      ref.invalidate(recentBooksProvider);
      ref.invalidate(homeBooksProvider);
      ref.invalidate(recentMemosProvider);
      // 인증된 유저만 데이터 로드
      final books = await ref.read(homeBooksProvider.future);
      if (books.isNotEmpty) {
        ref.read(selectedBookIdProvider.notifier).state = books.first.id;
      }
    } catch (e) {
      if (onAuthFailed != null) onAuthFailed!();
    }
  }

  VoidCallback? onAuthFailed;
} 