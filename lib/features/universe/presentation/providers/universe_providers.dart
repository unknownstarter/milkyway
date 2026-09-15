import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
