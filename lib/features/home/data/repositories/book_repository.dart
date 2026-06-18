import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/book.dart';
import '../../domain/models/book_status.dart';
import '../../../memos/domain/models/memo.dart';
import 'dart:developer';

class BookRepository {
  final SupabaseClient _client;

  BookRepository(this._client);

  Future<List<Book>> getRecentBooks() async {
    final response = await _client
        .from('user_books')
        .select('''
          *,
          books (
            *
          )
        ''')
        .eq('user_id', _client.auth.currentUser!.id)
        .order('created_at', ascending: false)
        .limit(10);

    return response
        .map((item) => Book.fromJson({
              ...item['books'] as Map<String, dynamic>,
              'status': item['status'],
            }))
        .toList();
  }

  /// 홈 화면 전용: 최근 메모 작성 활동순으로 정렬된 사용자 책 목록.
  ///
  /// 메모가 있는 책은 가장 최근 메모 작성 시점(DESC)이 앞쪽,
  /// 메모가 없는 책은 책 등록 시점(DESC)으로 그 뒤에 배치됨.
  /// 정렬 로직은 Postgres RPC `get_home_books_by_last_activity`에서 처리.
  Future<List<Book>> getHomeBooksByLastActivity() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final response = await _client.rpc(
        'get_home_books_by_last_activity',
        params: {'p_user_id': userId},
      ) as List<dynamic>;

      return response
          .map((item) => Book.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('Error getting home books by last activity: $e');
      rethrow;
    }
  }

  Future<Book> getBookDetail(String bookId) async {
    final response = await _client
        .from('books')
        .select('''
          *,
          user_books!inner (
            status
          )
        ''')
        .eq('id', bookId)
        .eq('user_books.user_id', _client.auth.currentUser!.id)
        .single();

    return Book.fromJson({
      ...response,
      'status': response['user_books'][0]['status'],
    });
  }

  Future<List<Memo>> getBookMemos(String bookId) async {
    final response = await _client.from('memos').select('''
          *,
          book:books!book_id (
            title
          )
        ''').eq('book_id', bookId).order('created_at', ascending: false);

    return response
        .map((json) => Memo.fromJson({
              ...json,
              'book_title': json['book']['title'],
            }))
        .toList();
  }

  Future<List<Book>> getUserBooks() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final response = await _client.from('user_books').select('''
            *,
            books (
              *
            )
          ''').eq('user_id', userId).order('created_at', ascending: false);

      return response
          .map((item) => Book.fromJson({
                ...item['books'] as Map<String, dynamic>,
                'status': item['status'],
              }))
          .toList();
    } catch (e) {
      log('Error getting user books: $e');
      rethrow;
    }
  }

  Future<Book> createBook({
    required String title,
    required String author,
    required String isbn,
    required String coverUrl,
    required String description,
    required String publisher,
    required String pubdate,
  }) async {
    try {
      final response = await _client
          .from('books')
          .insert({
            'title': title,
            'author': author,
            'isbn': isbn,
            'cover_url': coverUrl,
            'description': description,
            'publisher': publisher,
            'pubdate': pubdate,
          })
          .select()
          .single();

      return Book.fromJson(response);
    } catch (e, stackTrace) {
      print('Error creating book: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Book?> findBookByIsbn(String isbn) async {
    try {
      // ISBN으로 books 테이블에서 직접 찾기 (user_id 필터링 제거)
      final response = await _client
          .from('books')
          .select()
          .eq('isbn', isbn)
          .maybeSingle();

      if (response == null) return null;

      // Book 객체로 변환 (status는 기본값 사용)
      return Book.fromJson({
        ...response,
        'status': BookStatus.wantToRead.value,
      });
    } catch (e) {
      print('Error finding book by ISBN: $e');
      rethrow;
    }
  }

  Future<void> createUserBook({
    required String bookId,
    required String userId,
    required BookStatus status,
  }) async {
    await _client.from('user_books').insert({
      'book_id': bookId,
      'user_id': userId,
      'status': status.value,
    });
  }

  Future<void> updateBookStatus(String bookId, BookStatus status) async {
    await _client
        .from('user_books')
        .update({'status': status.value})
        .eq('book_id', bookId)
        .eq('user_id', _client.auth.currentUser!.id);
  }

  Future<bool> hasUserBookConnection(String bookId, String userId) async {
    final response = await _client
        .from('user_books')
        .select()
        .eq('book_id', bookId)
        .eq('user_id', userId)
        .maybeSingle();

    return response != null;
  }

  String getCurrentUserId() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated. Please log in again.');
    }
    return user.id;
  }

  Future<void> createUserBookConnection(String bookId, String userId) async {
    await _client.from('user_books').insert({
      'book_id': bookId,
      'user_id': userId,
      'status': BookStatus.wantToRead.value,
    });
  }

  /// 사용자-책 관계 삭제 및 해당 책의 메모들도 삭제
  Future<void> deleteUserBook(String bookId) async {
    final userId = getCurrentUserId();
    
    // 1. 해당 책의 메모들 삭제 (user_id와 book_id 모두 일치하는 메모)
    await _client
        .from('memos')
        .delete()
        .eq('book_id', bookId)
        .eq('user_id', userId);
    
    // 2. user_books에서 사용자-책 관계 삭제
    await _client
        .from('user_books')
        .delete()
        .eq('book_id', bookId)
        .eq('user_id', userId);
  }

  /// 공개된 메모가 많은 순으로 책 목록 가져오기 (최대 10개)
  /// 
  /// memos 테이블에서 visibility='public'인 메모를 기준으로
  /// book_id별로 그룹화하여 개수를 세고, 많은 순으로 정렬
  Future<List<Book>> getPopularBooksByPublicMemos() async {
    try {
      // 공개된 메모가 있는 책들을 book_id별로 그룹화하여 개수 세기
      final memoCountResponse = await _client
          .from('memos')
          .select('book_id')
          .eq('visibility', 'public')
          .not('book_id', 'is', null);

      // book_id별로 카운트
      final Map<String, int> bookMemoCounts = {};
      for (final memo in memoCountResponse) {
        final bookId = memo['book_id'] as String?;
        if (bookId != null) {
          bookMemoCounts[bookId] = (bookMemoCounts[bookId] ?? 0) + 1;
        }
      }

      // 메모 개수로 정렬 (내림차순)
      final sortedBookIds = bookMemoCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // 최대 10개만 가져오기
      final topBookIds = sortedBookIds.take(10).map((e) => e.key).toList();

      if (topBookIds.isEmpty) {
        return [];
      }

      // books 테이블에서 해당 책들 가져오기
      // Supabase에서는 여러 ID를 필터링하기 위해 or 조건 사용
      if (topBookIds.isEmpty) {
        return [];
      }
      
      String orCondition = topBookIds
          .map((id) => 'id.eq.$id')
          .join(',');
      
      final booksResponse = await _client
          .from('books')
          .select()
          .or(orCondition);

      // 원래 순서 유지하기 위해 Map으로 변환
      final booksMap = <String, Map<String, dynamic>>{};
      for (final book in booksResponse) {
        booksMap[book['id'] as String] = book;
      }

      // 원래 순서대로 Book 객체 생성
      final books = topBookIds
          .map((id) => booksMap[id])
          .whereType<Map<String, dynamic>>()
          .map((json) => Book.fromJson({
                ...json,
                'status': BookStatus.wantToRead.value, // 기본 상태
              }))
          .toList();

      return books;
    } catch (e) {
      log('Error getting popular books by public memos: $e');
      return [];
    }
  }

}
