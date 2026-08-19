import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/book_question.dart';
import '../../data/repositories/lyra_repository.dart';

final lyraRepositoryProvider = Provider<LyraRepository>(
  (ref) => LyraRepository(Supabase.instance.client),
);

/// 책의 활성 Lyra 물음(없으면 null). 책 상세/홈 등에서 공용.
final bookQuestionProvider = FutureProvider.family<BookQuestion?, String>(
  (ref, bookId) => ref.watch(lyraRepositoryProvider).getActiveQuestion(bookId),
);
