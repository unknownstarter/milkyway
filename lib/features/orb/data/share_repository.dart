import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';
import '../domain/orb_tier.dart';

/// 공유 카드 발행: 캡처 이미지 -> JPG q85 -> Supabase public 버킷 -> share_cards row -> 숏튼 링크.
class ShareRepository {
  final SupabaseClient _client;
  ShareRepository(this._client);

  static const _bucket = 'share_cards';

  /// 캡처된 ui.Image -> JPG q85 bytes. image 패키지(순수 Dart, 네이티브 설정 0).
  Future<Uint8List> encodeJpg(ui.Image image) async {
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final decoded = img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: rgba!.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
    return img.encodeJpg(decoded, quality: 85);
  }

  /// JPG 업로드 + row upsert + 링크 반환. 실패 시 예외 전파.
  Future<String> publish({
    required OrbTier tier,
    required Uint8List jpg,
    Map<String, dynamic>? payload,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('로그인이 필요합니다');
    }
    final code = _genCode();
    final path = '$uid/$code.jpg';

    await _client.storage.from(_bucket).uploadBinary(
          path,
          jpg,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    await _client.from('share_cards').upsert({
      'code': code,
      'user_id': uid,
      'tier': tier.name,
      'image_path': path,
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
