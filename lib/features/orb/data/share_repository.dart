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

    // 공개 도메인(mymilkyway.xyz)의 /s/{code}. Cloudflare Worker가 엣지 함수로 프록시한다.
    // supabase.co를 직접 노출하면 프로젝트 ref가 새고, 그 도메인은 HTML을 못 서빙해서
    // OG 미리보기도 인앱 웹뷰도 깨진다(플랫폼이 text/plain으로 강등).
    final base = EnvConfig.shareLinkBase;
    if (base.isEmpty) {
      throw StateError('SHARE_LINK_BASE 가 설정되지 않았습니다');
    }
    // 폴백(도메인 미설정)일 때만 옛 경로. 정상 경로는 /s/{code}.
    if (base == EnvConfig.supabaseUrl) {
      return '$base/functions/v1/s/$code';
    }
    return '$base/s/$code';
  }

  /// 연결 블록을 공유 payload 에 실어도 되는지 확인한다.
  ///
  /// 별자리 RPC(get_constellation)는 **내 화면용이라 비공개 메모도 그대로 준다.**
  /// 공유 링크는 링크만 있으면 누구나 열 수 있으므로, 두 메모가 **둘 다 공개**일
  /// 때만 문장을 싣는다. 하나라도 비공개면 통째로 뺀다.
  Future<bool> bothPublic(String memoIdA, String memoIdB) async {
    final rows = await _client
        .from('memos')
        .select('id, visibility')
        .inFilter('id', [memoIdA, memoIdB]);
    if (rows.length != 2) return false;
    return rows.every((r) => r['visibility'] == 'public');
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
