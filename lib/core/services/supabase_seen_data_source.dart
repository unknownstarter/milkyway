import 'package:supabase_flutter/supabase_flutter.dart';

import 'seen_tracker.dart';

/// [SeenDataSource]의 Supabase 구현(전송 계층만). 캐시/판정 로직은 [ServerSeenTracker]에.
///   - loadAll: seen_state 테이블(RLS로 본인 행만) 전체 조회.
///   - mark: mark_seen RPC(upsert, 서버 now()).
class SupabaseSeenDataSource implements SeenDataSource {
  final SupabaseClient _client;
  SupabaseSeenDataSource(this._client);

  @override
  String? get currentUid => _client.auth.currentUser?.id;

  @override
  Future<Map<String, DateTime>> loadAll() async {
    final rows = await _client.from('seen_state').select('scope, key, seen_at');
    final m = <String, DateTime>{};
    for (final r in (rows as List)) {
      final row = r as Map<String, dynamic>;
      final dt = DateTime.tryParse(row['seen_at'] as String);
      if (dt != null) m['${row['scope']}:${row['key']}'] = dt;
    }
    return m;
  }

  @override
  Future<void> mark(String scope, String key) =>
      _client.rpc('mark_seen', params: {'p_scope': scope, 'p_key': key});
}
