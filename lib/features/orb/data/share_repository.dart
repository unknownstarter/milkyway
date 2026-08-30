import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';
import '../domain/orb_tier.dart';

/// 공유 링크 발행. **이미지는 매번 생성/업로드하지 않는다**(스토리지 낭비 방지).
/// OG 썸네일은 기존 이미지를 재사용:
///   - 오브: 티어별 정적 오브 이미지 `share_cards/orb/{tier}.jpg`(1회 호스팅).
///   - 회고: 책 표지 URL(payload.cover_url, 이미 호스팅됨).
/// share_cards row는 code -> tier/payload 매핑용(딥링크 + OG). 이미지 저장 안 함.
class ShareRepository {
  final SupabaseClient _client;
  ShareRepository(this._client);

  /// 발행: row upsert 후 숏튼 링크 반환. 실패 시 예외 전파.
  Future<String> publish({
    required OrbTier tier,
    Map<String, dynamic>? payload,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('로그인이 필요합니다');
    }
    final code = _genCode();

    await _client.from('share_cards').upsert({
      'code': code,
      'user_id': uid,
      'tier': tier.name,
      // OG 기본 이미지 = 정적 오브. 회고는 edge function이 payload.cover_url 우선 사용.
      'image_path': 'orb/${tier.name}.jpg',
      if (payload != null) 'payload': payload,
    });

    return '${EnvConfig.supabaseUrl}/functions/v1/s/$code';
  }

  /// 6자 base62 숏튼 코드.
  String _genCode() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final r = Random.secure();
    return String.fromCharCodes(
      List.generate(6, (_) => chars.codeUnitAt(r.nextInt(chars.length))),
    );
  }
}
