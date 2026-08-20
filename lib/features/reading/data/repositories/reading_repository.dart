import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reading_log.dart';

/// 읽음 기록 CRUD. read_on은 사용자 로컬 날짜 기준(캘린더 표시와 일치).
class ReadingRepository {
  final SupabaseClient _client;

  ReadingRepository(this._client);

  String get _today {
    final n = DateTime.now();
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '${n.year}-$m-$d';
  }

  /// 오늘 읽음 기록(중복이면 무시). 메모 작성 시 자동 호출 + 책 상세 토글.
  Future<void> logToday(String bookId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('reading_logs').upsert(
      {'user_id': userId, 'book_id': bookId, 'read_on': _today},
      onConflict: 'user_id,book_id,read_on',
      ignoreDuplicates: true,
    );
  }

  /// 오늘 읽음 취소.
  Future<void> unlogToday(String bookId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from('reading_logs')
        .delete()
        .eq('user_id', userId)
        .eq('book_id', bookId)
        .eq('read_on', _today);
  }

  Future<bool> hasReadToday(String bookId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    final row = await _client
        .from('reading_logs')
        .select('id')
        .eq('user_id', userId)
        .eq('book_id', bookId)
        .eq('read_on', _today)
        .maybeSingle();
    return row != null;
  }

  /// 내 모든 읽음 기록(책 정보 조인). 캘린더/스트립용.
  Future<List<ReadingLog>> getMyReadingLogs() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];
    final rows = await _client
        .from('reading_logs')
        .select('book_id, read_on, books(title, cover_url)')
        .eq('user_id', userId)
        .order('read_on', ascending: false);
    return [
      for (final r in (rows as List).cast<Map<String, dynamic>>())
        ReadingLog.fromRow(r),
    ];
  }
}
