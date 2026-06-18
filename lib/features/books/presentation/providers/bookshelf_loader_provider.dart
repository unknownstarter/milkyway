import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_books_provider.dart';
import '../providers/book_status_update_provider.dart';
import '../../../home/presentation/providers/book_provider.dart';

final bookshelfLoaderProvider = AsyncNotifierProvider<BookshelfLoaderNotifier, void>(BookshelfLoaderNotifier.new);

class BookshelfLoaderNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    await load();
  }

  Future<void> load() async {
    try {
      ref.invalidate(userBooksProvider);
      ref.invalidate(homeBooksProvider);
      ref.invalidate(bookStatusUpdateFlagProvider);
      await ref.read(userBooksProvider.future);
    } catch (e) {
      // 에러 무시(로딩 실패 시 화면에서 처리)
    }
  }
} 