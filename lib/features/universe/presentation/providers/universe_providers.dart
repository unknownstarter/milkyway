import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../memos/data/repositories/memo_repository.dart';
import '../../../memos/domain/models/memo.dart';
import '../../data/universe_repository.dart';
import '../../domain/universe_layout.dart';

final universeRepositoryProvider = Provider<UniverseRepository>(
  (ref) => UniverseRepository(Supabase.instance.client),
);

/// 은하 배치. 서재가 바뀔 때만 다시 계산된다(placeNamed 가 110패스 O(n^2)라
/// 화면에서 매번 만들면 안 된다).
final universeLayoutProvider = FutureProvider.autoDispose<UniverseLayout>((ref) async {
  final books = await ref.watch(universeRepositoryProvider).fetchBooks();
  return UniverseLayout.build(books);
});

/// 별(책)을 눌렀을 때 보여줄 내 메모. 최신순.
final universeBookMemosProvider =
    FutureProvider.autoDispose.family<List<Memo>, String>((ref, bookId) async {
  final memos =
      await MemoRepository(Supabase.instance.client).getBookMemos(bookId);
  memos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return memos;
});
