import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/edge_function_client.dart';
import '../../../memos/data/repositories/memo_repository.dart';
import '../../../memos/domain/models/memo.dart';

final memoRepositoryProvider = Provider((ref) {
  return MemoRepository(Supabase.instance.client,
      edge: ref.watch(edgeFunctionClientProvider));
});

final recentMemosProvider = FutureProvider<List<Memo>>((ref) async {
  final repository = ref.watch(memoRepositoryProvider);
  return repository.getRecentMemos();
});
