import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 공유 카드 뷰어 데이터(코드로 조회). get_share_card RPC(SECURITY DEFINER)로
/// 타인 카드의 공개 필드만 가져온다.
class SharedCard {
  final String tier;
  final String imageUrl;
  final Map<String, dynamic>? payload;
  const SharedCard({required this.tier, required this.imageUrl, this.payload});
}

final sharedCardProvider =
    FutureProvider.autoDispose.family<SharedCard, String>((ref, code) async {
  final client = Supabase.instance.client;
  final res = await client.rpc('get_share_card', params: {'p_code': code});
  final rows = (res as List?) ?? const [];
  if (rows.isEmpty) {
    throw StateError('카드를 찾을 수 없어요');
  }
  final row = rows.first as Map<String, dynamic>;
  final path = row['image_path'] as String;
  final imageUrl = client.storage.from('share_cards').getPublicUrl(path);
  return SharedCard(
    tier: row['tier'] as String,
    imageUrl: imageUrl,
    payload: row['payload'] as Map<String, dynamic>?,
  );
});
