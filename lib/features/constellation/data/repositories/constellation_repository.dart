import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/constellation.dart';

/// 별자리(커넥톰) 조회. get_constellation RPC 경유(본인 노드+엣지).
class ConstellationRepository {
  final SupabaseClient _client;
  ConstellationRepository(this._client);

  Future<Constellation> getConstellation() async {
    final res = await _client.rpc('get_constellation');
    if (res is Map<String, dynamic>) return Constellation.fromJson(res);
    if (res is Map) return Constellation.fromJson(Map<String, dynamic>.from(res));
    return Constellation(nodes: const [], edges: const []);
  }
}
