import 'dart:developer';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/supabase_image.dart';

/// 네이버 외부 표지 URL을 우리 Supabase Storage(book_covers)로 복사(재호스팅)한다.
/// 재호스팅 후엔 다른 이미지들과 동일하게 on-the-fly 변환(표시폭 WebP)이 적용돼
/// 홈/책탭 등 어디서든 과부하 없이 표시된다.
class BookCoverUploader {
  static const String bucket = 'book_covers';

  /// [naverUrl]을 내려받아 [isbn] 기준 결정적 경로로 업로드하고 공개 URL 반환.
  /// 실패(URL/ISBN 없음·다운로드·업로드 실패) 시 **null** -> 호출부는 원본 URL로 폴백해
  /// 저장 흐름이 절대 깨지지 않게 한다. 같은 ISBN은 같은 경로라 중복 업로드 없음(upsert).
  static Future<String?> rehostFromNaver({
    required String? naverUrl,
    required String? isbn,
    Dio? dio,
  }) async {
    if (naverUrl == null || naverUrl.trim().isEmpty) return null;
    final path = bookCoverStoragePath(isbn);
    if (path == null) return null;

    try {
      final client = dio ?? Dio();
      final res = await client.get<List<int>>(
        naverUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final data = res.data;
      if (data == null || data.isEmpty) return null;

      final storage = Supabase.instance.client.storage.from(bucket);
      await storage.uploadBinary(
        path,
        Uint8List.fromList(data),
        fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
      );
      return storage.getPublicUrl(path);
    } catch (e) {
      log('책 표지 재호스팅 실패(원본 URL 폴백): $e');
      return null;
    }
  }
}
