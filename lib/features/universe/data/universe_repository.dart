import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/universe_math.dart';

/// 나의 우주에 필요한 최소 데이터: 내 서재의 책 + 책별 메모 수.
///
/// 은하 배치는 book.id 해시로 결정되므로 id를 반드시 그대로 들고 온다.
/// 메모 수는 별의 크기와 밝기가 된다.
class UniverseRepository {
  final SupabaseClient _client;
  UniverseRepository(this._client);

  String? get _uid => _client.auth.currentUser?.id;

  /// 내 서재 전체를 은하 입력으로. 책이 없으면 빈 목록.
  Future<List<UniverseBook>> fetchBooks() async {
    final uid = _uid;
    if (uid == null) return const [];

    // 내가 담은 책(books 조인). 은하는 서재 전체를 보여주므로 상태 필터는 안 건다.
    final rows = await _client
        .from('user_books')
        .select('book_id, books(id, title, author)')
        .eq('user_id', uid);

    if (rows.isEmpty) return const [];

    // 책별 내 메모 수. 메모가 많은 책이 밝은 별이 된다.
    final memoRows = await _client
        .from('memos')
        .select('book_id')
        .eq('user_id', uid)
        .not('book_id', 'is', null);

    final counts = <String, int>{};
    for (final m in memoRows) {
      final id = m['book_id'] as String?;
      if (id != null) counts[id] = (counts[id] ?? 0) + 1;
    }

    final out = <UniverseBook>[];
    for (final r in rows) {
      final b = r['books'] as Map<String, dynamic>?;
      final id = (b?['id'] ?? r['book_id']) as String?;
      if (id == null) continue;
      out.add(UniverseBook(
        id: id,
        title: (b?['title'] as String?)?.trim() ?? '',
        author: (b?['author'] as String?)?.trim() ?? '',
        notes: counts[id] ?? 0,
      ));
    }
    return out;
  }
}
