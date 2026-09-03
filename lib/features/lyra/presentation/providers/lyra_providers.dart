import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/book_question.dart';
import '../../data/models/lyra_prompt.dart';
import '../../data/repositories/lyra_repository.dart';
import '../../../../core/providers/locale_controller.dart';

final lyraRepositoryProvider = Provider<LyraRepository>(
  (ref) => LyraRepository(Supabase.instance.client),
);

/// 책의 활성 Lyra 물음(없으면 null). 책 상세/홈 등에서 공용.
final bookQuestionProvider = FutureProvider.family<BookQuestion?, String>(
  (ref, bookId) => ref
      .watch(lyraRepositoryProvider)
      .getActiveQuestion(bookId, ref.watch(effectiveLangProvider)),
);

/// 홈에서 노출할 '다음 Lyra 물음'(내가 아직 답 안 한 것). 답하면 invalidate -> 새 물음.
final lyraPromptProvider = FutureProvider<LyraPrompt?>(
  (ref) => ref
      .watch(lyraRepositoryProvider)
      .getPrompt(ref.watch(effectiveLangProvider)),
);
