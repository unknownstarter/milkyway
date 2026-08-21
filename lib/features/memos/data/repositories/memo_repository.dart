import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/memo.dart';
import '../../domain/models/memo_visibility.dart';
import 'dart:developer';
import '../../../../core/utils/retry_helper.dart';
import '../../../../core/utils/response_cache.dart';

class MemoRepository {
  final SupabaseClient _client;

  MemoRepository(this._client);

  Future<List<Memo>> getRecentMemos() async {
    final response = await _client
        .from('memos')
        .select('''
          *,
          comment_count,
          lyra_question,
          books (
            id,
            title,
            author,
            cover_url
          ),
          users!user_id (
            nickname,
            picture_url
          )
        ''')
        .eq('user_id', _client.auth.currentUser!.id)
        .order('created_at', ascending: false)
        .limit(2);

    return response.map((json) => Memo.fromJson(json)).toList();
  }

  /// 전역 공개 메모 피드(메모 탭 '공개'/홈). RLS상 타 유저 조인 불가라 Edge Function 경유.
  Future<List<Memo>> getPublicFeed({int limit = 20, int offset = 0}) async {
    try {
      final response = await _client.functions.invoke(
        'get-public-memo-feed',
        body: {'limit': limit, 'offset': offset},
      );
      if (response.status != 200) {
        log('공개 피드 조회 실패: ${response.data ?? '알 수 없는 오류'}');
        return [];
      }
      final result = response.data as Map<String, dynamic>;
      final memosData = result['memos'] as List<dynamic>?;
      if (memosData == null) return [];
      return memosData
          .map((json) => Memo.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('공개 피드 조회 중 오류: $e');
      return [];
    }
  }

  Future<List<Memo>> getBookMemos(String bookId) async {
    final response = await _client.from('memos').select('''
          *,
          comment_count,
          lyra_question,
          books (
            id,
            title,
            author,
            cover_url
          ),
          users!user_id (
            nickname,
            picture_url
          )
        ''').eq('book_id', bookId)
        .eq('user_id', _client.auth.currentUser!.id) // 현재 사용자의 메모만 가져오기
        .order('created_at', ascending: false);

    return response.map((json) => Memo.fromJson(json)).toList();
  }

  /// 해당 책의 모든 공개 메모 가져오기 (다른 유저의 공개 메모 포함)
  /// RLS 정책으로 인해 users 조인 시 다른 유저 정보를 가져올 수 없으므로 Edge Function 사용
  /// @deprecated 페이지네이션을 위해 getPaginatedPublicBookMemos 사용 권장
  Future<List<Memo>> getPublicBookMemos(String bookId) async {
    try {
      final response = await _client.functions.invoke(
        'get-public-book-memos',
        body: {'book_id': bookId},
      );

      if (response.status != 200) {
        final errorData = response.data;
        log('공개 메모 조회 실패: ${errorData ?? '알 수 없는 오류'}');
        return [];
      }

      final result = response.data as Map<String, dynamic>;
      final memosData = result['memos'] as List<dynamic>?;

      if (memosData == null) {
        return [];
      }

      return memosData
          .map((json) => Memo.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('공개 메모 조회 중 오류 발생: $e');
      return [];
    }
  }

  /// 해당 책의 공개 메모를 페이지네이션으로 가져오기 (다른 유저의 공개 메모 포함)
  /// RLS 정책으로 인해 users 조인 시 다른 유저 정보를 가져올 수 없으므로 Edge Function 사용
  /// 네트워크 에러 시 자동 재시도 (exponential backoff)
  /// 응답 캐싱으로 동일한 요청 시 네트워크 호출 감소
  Future<List<Memo>> getPaginatedPublicBookMemos({
    required String bookId,
    required int limit,
    required int offset,
  }) async {
    final cache = ResponseCache();
    final requestBody = {
      'book_id': bookId,
      'limit': limit,
      'offset': offset,
    };

    // 캐시에서 먼저 확인 (offset이 0이 아닌 경우는 캐시하지 않음 - 실시간성 중요)
    if (offset == 0) {
      final cached = cache.get<Map<String, dynamic>>(
        'get-public-book-memos',
        requestBody,
      );
      
      if (cached != null) {
        final memosData = cached['memos'] as List<dynamic>?;
        if (memosData != null) {
          log('캐시에서 공개 메모 조회: $bookId');
          return memosData
              .map((json) => Memo.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
    }

    // 첫 페이지는 재시도 없이 빠르게 실패 처리 (사용자 경험 개선)
    // 다음 페이지는 재시도 적용
    if (offset == 0) {
      try {
        final response = await _client.functions.invoke(
          'get-public-book-memos',
          body: requestBody,
        );

        if (response.status != 200) {
          final errorData = response.data;
          log('공개 메모 조회 실패: ${errorData ?? '알 수 없는 오류'}');
          throw Exception('공개 메모 조회 실패: ${errorData ?? '알 수 없는 오류'}');
        }

        final result = response.data as Map<String, dynamic>;
        final memosData = result['memos'] as List<dynamic>?;

        if (memosData == null) {
          return [];
        }

        final memos = memosData
            .map((json) => Memo.fromJson(json as Map<String, dynamic>))
            .toList();

        // 첫 페이지 캐싱
        cache.set(
          'get-public-book-memos',
          requestBody,
          result,
          ttl: const Duration(minutes: 2),
        );

        return memos;
      } catch (e) {
        // 네트워크 에러만 재시도
        if (RetryHelper.isNetworkError(e)) {
          return await RetryHelper.retryWithBackoff<List<Memo>>(
            operation: () async {
              final response = await _client.functions.invoke(
                'get-public-book-memos',
                body: requestBody,
              );

              if (response.status != 200) {
                final errorData = response.data;
                log('공개 메모 조회 실패: ${errorData ?? '알 수 없는 오류'}');
                throw Exception('공개 메모 조회 실패: ${errorData ?? '알 수 없는 오류'}');
              }

              final result = response.data as Map<String, dynamic>;
              final memosData = result['memos'] as List<dynamic>?;

              if (memosData == null) {
                return [];
              }

              return memosData
                  .map((json) => Memo.fromJson(json as Map<String, dynamic>))
                  .toList();
            },
            maxRetries: 2, // 재시도 횟수 감소
            initialDelay: const Duration(milliseconds: 500), // 초기 지연 시간 감소
          );
        }
        rethrow;
      }
    } else {
      // 다음 페이지는 재시도 적용
      return await RetryHelper.retryWithBackoff<List<Memo>>(
        operation: () async {
          final response = await _client.functions.invoke(
            'get-public-book-memos',
            body: requestBody,
          );

          if (response.status != 200) {
            final errorData = response.data;
            log('공개 메모 조회 실패: ${errorData ?? '알 수 없는 오류'}');
            throw Exception('공개 메모 조회 실패: ${errorData ?? '알 수 없는 오류'}');
          }

          final result = response.data as Map<String, dynamic>;
          final memosData = result['memos'] as List<dynamic>?;

          if (memosData == null) {
            return [];
          }

          return memosData
              .map((json) => Memo.fromJson(json as Map<String, dynamic>))
              .toList();
        },
        maxRetries: 2,
        initialDelay: const Duration(milliseconds: 500),
      );
    }
  }

  Future<void> createMemo({
    required String bookId,
    required String content,
    int? page,
    String? imageUrl,
    MemoVisibility visibility = MemoVisibility.private,
    String? lyraQuestionId,
    String? lyraQuestionText,
    String? lyraSource,
  }) async {
    log('Creating memo with imageUrl: $imageUrl, visibility: ${visibility.value}');
    // created_at/updated_at은 동일 타임스탬프로. (따로 now()를 두 번 부르면 새 메모도
    // updated_at이 미세하게 늦어 '수정됨'으로 오검출됨)
    final now = DateTime.now().toIso8601String();
    final response = await _client.from('memos').insert({
      'book_id': bookId,
      'user_id': _client.auth.currentUser!.id,
      'content': content,
      'page': page,
      'image_url': imageUrl,
      'visibility': visibility.value,
      'created_at': now,
      'updated_at': now,
    }).select('id').single();

    final memoId = response['id'] as String;
    final currentUserId = _client.auth.currentUser!.id;

    // Lyra 물음에 답한 메모면 질문 스냅샷 저장(원본 바뀌어도 유지). 실패는 무시.
    if (lyraQuestionText != null && lyraQuestionText.isNotEmpty) {
      try {
        await _client.from('memo_question_context').insert({
          'memo_id': memoId,
          'source': lyraSource ?? 'book',
          'question_id': lyraQuestionId,
          'question_text': lyraQuestionText,
        });
      } catch (e) {
        log('Lyra 스냅샷 저장 실패(무시): $e');
      }
    }

    // 공개 메모인 경우 알림 전송
    if (visibility == MemoVisibility.public) {
      try {
        // 메모 작성자의 닉네임 조회
        final userResponse = await _client
            .from('users')
            .select('nickname')
            .eq('id', currentUserId)
            .single();
        final memoAuthorNickname = userResponse['nickname'] as String? ?? '사용자';

        await _client.functions.invoke(
          'notify-new-public-memo',
          body: {
            'book_id': bookId,
            'memo_id': memoId,
            'memo_content': content,
            'memo_author_nickname': memoAuthorNickname,
            'memo_author_id': currentUserId,
          },
        );
        log('공개 메모 알림 전송 요청 완료');
      } catch (e) {
        log('알림 전송 실패 (무시): $e');
        // 알림 실패해도 메모 생성은 성공
      }
    }
  }

  Future<void> updateMemo({
    required String memoId,
    required String content,
    int? page,
    String? imageUrl,
    MemoVisibility? visibility,
  }) async {
    final updateData = <String, dynamic>{
      'content': content,
      'page': page,
      'image_url': imageUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    if (visibility != null) {
      updateData['visibility'] = visibility.value;
    }
    
    await _client.from('memos').update(updateData).eq('id', memoId);
  }

  Future<void> deleteMemo(String memoId) async {
    await _client.from('memos').delete().eq('id', memoId);
  }

  /// 메모 ID로 조회 (공개/비공개 모두 조회 가능, 다른 유저의 메모도 조회 가능)
  /// RLS 정책으로 인해 users 조인 시 다른 유저 정보를 가져올 수 없으므로 Edge Function 사용
  Future<Memo> getMemoById(String memoId) async {
    try {
      log('get-memo-by-id 호출 시작: $memoId');
      final response = await _client.functions.invoke(
        'get-memo-by-id',
        body: {'memo_id': memoId},
      );

      log('get-memo-by-id 응답 상태: ${response.status}');
      log('get-memo-by-id 응답 데이터: ${response.data}');

      if (response.status != 200) {
        final errorData = response.data;
        log('메모 조회 실패: ${errorData ?? '알 수 없는 오류'}');
        throw Exception('메모 조회 실패: ${errorData ?? '알 수 없는 오류'}');
      }

      final result = response.data as Map<String, dynamic>;
      final memoData = result['memo'] as Map<String, dynamic>?;

      if (memoData == null) {
        log('메모 데이터가 null입니다. result: $result');
        throw Exception('메모를 찾을 수 없습니다.');
      }

      log('메모 데이터 파싱 전: users=${memoData['users']}, nickname=${memoData['users']?['nickname']}');
      final memo = Memo.fromJson(memoData);
      log('메모 파싱 후: userNickname=${memo.userNickname}, userAvatarUrl=${memo.userAvatarUrl}');
      return memo;
    } catch (e, stackTrace) {
      log('메모 조회 중 오류 발생: $e');
      log('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  Future<List<Memo>> getAllMemos() async {
    final response = await _client
        .from('memos')
        .select('''
          *,
          comment_count,
          lyra_question,
          books (
            id,
            title,
            author,
            cover_url
          ),
          users!user_id (
            nickname,
            picture_url
          )
        ''')
        .eq('user_id', _client.auth.currentUser!.id)
        .order('created_at', ascending: false);

    return response.map((json) => Memo.fromJson(json)).toList();
  }

  Future<List<Memo>> getPaginatedMemos({
    required int limit,
    required int offset,
    String? bookId,
  }) async {
    var query = _client.from('memos').select('''
      *,
      comment_count,
      lyra_question,
      books (
        id,
        title,
        author,
        cover_url
      ),
      users!user_id (
        nickname,
        picture_url
      )
    ''').eq('user_id', _client.auth.currentUser!.id);

    if (bookId != null && bookId.isNotEmpty) {
      query = query.eq('book_id', bookId);
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit)
        .range(offset, offset + limit - 1);

    return response.map((json) => Memo.fromJson(json)).toList();
  }
}

final memoRepositoryProvider = Provider((ref) {
  return MemoRepository(Supabase.instance.client);
});
