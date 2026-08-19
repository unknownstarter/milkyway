import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../home/domain/models/book_status.dart';
import '../models/recommended_book.dart';

/// 발견/온보딩 추천 책 조회 + 담기(user_books insert).
///
/// 저장 포인트: [saveBooks]가 `user_books`에 raw row를 INSERT한다.
/// `user_books`엔 트리거가 없어 부수효과(통계 자동갱신 등)는 없다.
/// INSERT는 RLS `auth.uid() = user_id`로 보호되어 본인 것만 저장 가능.
class DiscoveryRepository {
  final SupabaseClient _client;

  DiscoveryRepository(this._client);

  /// 공개 메모가 쌓인 책을 추천으로 반환(사회적 증거 = 공개 메모 수).
  ///
  /// `user_books`는 RLS상 본인 것만 조회되어 "담은 사람 수"는 클라이언트에서
  /// 셀 수 없다(서버 RPC로 확장 예정). 공개 메모(`memos.visibility='public'`)는
  /// 전역 조회가 허용되므로 이를 기준으로 삼는다.
  Future<List<RecommendedBook>> getRecommendedBooks({int limit = 12}) async {
    // 1. 공개 메모의 book_id 수집
    final memoRows = await _client
        .from('memos')
        .select('book_id')
        .eq('visibility', 'public');

    final counts = countPublicMemosByBook(
      (memoRows as List).cast<Map<String, dynamic>>(),
    );
    if (counts.isEmpty) return const [];

    // 2. 공개 메모 많은 순 상위 책 id
    final topIds = topBookIds(counts, limit);

    // 3. 책 메타 조회 (books SELECT는 전역 허용)
    final bookRows = await _client
        .from('books')
        .select('id, title, author, cover_url')
        .inFilter('id', topIds);

    final byId = <String, Map<String, dynamic>>{
      for (final b in (bookRows as List).cast<Map<String, dynamic>>())
        b['id'] as String: b,
    };

    // 4. counts 순서 유지하며 매핑
    return [
      for (final id in topIds)
        if (byId[id] != null)
          RecommendedBook.fromBookRow(byId[id]!, publicMemos: counts[id]!),
    ];
  }

  /// 사람들이 많이 담은 책(사회적 증거 = savers). get_recommended_books RPC 경유.
  /// RLS상 클라이언트가 못 세는 savers 집계를 SECURITY DEFINER 함수로 받는다.
  Future<List<RecommendedBook>> getBooksSavedByOthers({int limit = 12}) async {
    final rows = await _client.rpc(
      'get_recommended_books',
      params: {'p_limit': limit},
    );
    return [
      for (final r in (rows as List).cast<Map<String, dynamic>>())
        RecommendedBook.fromRpcRow(r),
    ];
  }

  /// 선택한 책들을 서재에 담는다(user_books 배치 INSERT).
  Future<void> saveBooks(List<String> bookIds) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || bookIds.isEmpty) return;
    final rows = [
      for (final id in bookIds)
        {
          'book_id': id,
          'user_id': userId,
          'status': BookStatus.wantToRead.value,
        },
    ];
    await _client.from('user_books').insert(rows);
  }

  // ─────────── 순수 로직 (단위 테스트 대상) ───────────

  /// 공개 메모 rows를 book_id별 개수로 집계.
  static Map<String, int> countPublicMemosByBook(
    List<Map<String, dynamic>> rows,
  ) {
    final result = <String, int>{};
    for (final r in rows) {
      final id = r['book_id'] as String?;
      if (id == null) continue;
      result[id] = (result[id] ?? 0) + 1;
    }
    return result;
  }

  /// 개수 내림차순 상위 limit개 book_id.
  static List<String> topBookIds(Map<String, int> counts, int limit) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in entries.take(limit)) e.key];
  }
}
