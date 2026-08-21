import 'dart:io';
import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 메모 이미지를 Supabase Storage에 업로드하는 유틸리티 클래스
class MemoImageUploader {
  /// 로컬 파일 경로를 Supabase Storage에 업로드하고 공개 URL을 반환
  ///
  /// [filePath] 로컬 파일 경로
  ///
  /// Returns 업로드된 이미지의 public URL(만료 없음), 실패 시 null
  static Future<String?> uploadImage(String filePath) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        log('이미지 업로드 실패: 사용자 인증 정보가 없습니다');
        return null;
      }

      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(filePath);

      // 파일 존재 여부 확인
      if (!await file.exists()) {
        log('이미지 업로드 실패: 파일이 존재하지 않습니다: $filePath');
        return null;
      }

      // Supabase Storage에 업로드
      await supabase.storage.from('memo_images').upload(fileName, file);

      // 공개 URL 반환 (버킷 public, 만료 없음 - 서명 URL 만료로 이미지가 죽던 문제 해결)
      final imageUrl =
          supabase.storage.from('memo_images').getPublicUrl(fileName);

      return imageUrl;
    } catch (e, stackTrace) {
      log('이미지 업로드 실패: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// 이미지 경로가 로컬 파일인지 확인
  /// 
  /// [imagePath] 확인할 이미지 경로
  /// 
  /// Returns 로컬 파일이면 true, URL이면 false
  static bool isLocalFile(String? imagePath) {
    if (imagePath == null) return false;
    return !imagePath.startsWith('http://') && !imagePath.startsWith('https://');
  }
}

