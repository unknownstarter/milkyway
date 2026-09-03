import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book_question.dart';
import '../models/lyra_prompt.dart';

/// Lyra 물음 조회. 물음 본문은 서버 콘텐츠(한국어 정본 + 언어별 번역 캐시)라
/// 조회 시 언어를 넘긴다. 번역이 없으면 서버가 한국어 정본으로 폴백한다.
/// 쓰기는 Edge Function(service role) 전용이라 클라이언트는 읽기만 한다.
class LyraRepository {
  final SupabaseClient _client;

  LyraRepository(this._client);

  /// 책의 활성 물음 1개(현재 언어). 없으면 null(카드 미노출).
  Future<BookQuestion?> getActiveQuestion(String bookId, String lang) async {
    final rows = await _client.rpc('get_book_question', params: {
      'p_book_id': bookId,
      'p_lang': lang,
    });
    if (rows is List && rows.isNotEmpty) {
      return BookQuestion.fromRow(rows.first as Map<String, dynamic>);
    }
    return null;
  }

  /// 내가 아직 답 안 한 다음 Lyra 물음 1개(책 질문 우선, 없으면 일반). 없으면 null.
  Future<LyraPrompt?> getPrompt(String lang) async {
    final rows = await _client.rpc('get_lyra_prompt', params: {'p_lang': lang});
    if (rows is List && rows.isNotEmpty) {
      return LyraPrompt.fromRow(rows.first as Map<String, dynamic>);
    }
    return null;
  }
}
