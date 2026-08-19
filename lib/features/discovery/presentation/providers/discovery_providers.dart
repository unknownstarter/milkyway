import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/recommended_book.dart';
import '../../data/repositories/discovery_repository.dart';

final discoveryRepositoryProvider = Provider<DiscoveryRepository>(
  (ref) => DiscoveryRepository(Supabase.instance.client),
);

/// 추천 책(공개 메모 기준). 발견/온보딩 공용.
final recommendedBooksProvider = FutureProvider<List<RecommendedBook>>(
  (ref) => ref.watch(discoveryRepositoryProvider).getRecommendedBooks(),
);

/// 온보딩 책 담기 선택 상태(복수 선택).
class BookSelection extends StateNotifier<Set<String>> {
  BookSelection() : super(const <String>{});

  void toggle(String bookId) {
    final next = {...state};
    if (!next.remove(bookId)) next.add(bookId);
    state = next;
  }

  void clear() => state = const <String>{};
}

final bookSelectionProvider =
    StateNotifierProvider<BookSelection, Set<String>>(
  (ref) => BookSelection(),
);
