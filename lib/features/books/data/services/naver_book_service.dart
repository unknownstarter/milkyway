import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/env_config.dart';
import '../../domain/models/naver_book.dart';

/// 책 검색 서비스. 백엔드는 이제 Google Books(+Open Library 폴백) - edge function
/// `search-books`가 처리하고 결과를 이 클라 형태로 정규화한다. (이름은 하위호환 위해 유지)
class NaverBookService {
  final Dio _dio;
  // 프로젝트별 URL 하드코딩 금지 - EnvConfig에서 조립.
  String get _functionUrl => '${EnvConfig.supabaseUrl}/functions/v1/search-books';

  NaverBookService() : _dio = Dio();

  Future<List<NaverBook>> searchBooks(String query) async {
    try {
      final response = await _dio.post(
        _functionUrl,
        data: {'query': query},
      );

      final List<dynamic> items = response.data['items'] ?? [];
      if (items.isEmpty) {
        return [];
      }

      return items.map((item) => NaverBook.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to search books: $e');
    }
  }
}

final naverBookServiceProvider = Provider((ref) {
  return NaverBookService();
});
