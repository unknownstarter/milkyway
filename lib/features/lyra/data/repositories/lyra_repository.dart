import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book_question.dart';
import '../models/lyra_prompt.dart';

/// Lyra 물음 조회. `book_questions`는 RLS상 인증 사용자 전체 읽기 허용,
/// 쓰기는 Edge Function(service role) 전용이라 클라이언트는 읽기만 한다.
class LyraRepository {
  final SupabaseClient _client;

  LyraRepository(this._client);

  /// 책의 활성 물음 1개. 없으면 null(카드 미노출).
  Future<BookQuestion?> getActiveQuestion(String bookId) async {
    final row = await _client
        .from('book_questions')
        .select('id, book_id, question, model, created_at')
        .eq('book_id', bookId)
        .eq('is_active', true)
        .maybeSingle();
    if (row == null) return null;
    return BookQuestion.fromRow(row);
  }

  /// 내가 아직 답 안 한 다음 Lyra 물음 1개(책 질문 우선, 없으면 일반). 없으면 null.
  Future<LyraPrompt?> getPrompt() async {
    final rows = await _client.rpc('get_lyra_prompt');
    if (rows is List && rows.isNotEmpty) {
      return LyraPrompt.fromRow(rows.first as Map<String, dynamic>);
    }
    return null;
  }
}
