import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer';
import 'dart:async';
import '../../../home/domain/models/book.dart';
import '../../../home/domain/models/book_status.dart';
import '../../../home/data/repositories/book_repository.dart';
import '../../../home/presentation/providers/book_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_books_provider.dart';

class BookDetailController extends StateNotifier<AsyncValue<Book>> {
  final String bookId;
  final BookRepository _repository;
  final Ref _ref;
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(milliseconds: 300);
  static const Duration _maxRetryDelay = Duration(seconds: 2);

  BookDetailController({
    required this.bookId,
    required BookRepository repository,
    required Ref ref,
  })  : _repository = repository,
        _ref = ref,
        super(const AsyncValue.loading()) {
    loadBook();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> loadBook({bool isRetry = false}) async {
    if (!isRetry) {
      _retryCount = 0;
      _retryTimer?.cancel();
      // 첫 시도는 항상 로딩 상태로 시작
      state = const AsyncValue.loading();
    }
    // 재시도 중에는 상태를 변경하지 않음 (이전 상태 유지)

    try {
      final book = await _repository.getBookDetail(bookId);
      _retryCount = 0; // 성공 시 재시도 카운트 리셋
      state = AsyncValue.data(book);
    } catch (e, st) {
      // PGRST116 에러 (0 rows) 또는 관련 에러인 경우 재시도
      if (_shouldRetry(e) && _retryCount < _maxRetries) {
        _retryCount++;
        // Exponential backoff: 300ms → 600ms → 1200ms (최대 2초)
        final delay = Duration(
          milliseconds: (_initialRetryDelay.inMilliseconds *
                  (1 << (_retryCount - 1)))
              .clamp(0, _maxRetryDelay.inMilliseconds),
        );
        log(
          '책 정보 조회 실패 (재시도 $_retryCount/$_maxRetries, ${delay.inMilliseconds}ms 후): $bookId',
          name: 'BookDetailController',
        );
        // 재시도 중에는 로딩 상태 유지 (사용자 경험 개선)
        // 재시도가 성공하면 자동으로 데이터 상태로 변경됨
        _retryTimer = Timer(delay, () {
          loadBook(isRetry: true);
        });
      } else {
        // 최대 재시도 횟수 초과 또는 다른 에러인 경우
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// 재시도해야 할 에러인지 확인
  /// 
  /// 타이밍 이슈로 인한 일시적 에러만 재시도 (예: user_books 연결 생성 중)
  bool _shouldRetry(dynamic error) {
    if (error is PostgrestException) {
      // 표준 에러 코드 체크
      switch (error.code) {
        case 'PGRST116': // 0 rows (결과를 단일 JSON 객체로 변환할 수 없음)
        case 'PGRST301': // Not found
          return true;
      }
      
      // 에러 메시지에 관련 키워드가 포함된 경우 (fallback)
      final errorMessage = error.message.toLowerCase();
      return errorMessage.contains('0 rows') ||
          errorMessage.contains('not found') ||
          errorMessage.contains('no rows');
    }
    return false;
  }

  Future<void> updateStatus(BookStatus status) async {
    try {
      await _repository.updateBookStatus(bookId, status);
      // Books 스크린의 userBooksProvider도 갱신
      _ref.invalidate(userBooksProvider);
      _ref.invalidate(homeBooksProvider);
      // 상태 변경 후 책 정보 새로고침 (재시도 로직 포함)
      await loadBook();
    } catch (e, st) {
      log('Error updating status: $e', error: e, stackTrace: st);
      // 상태 업데이트 실패 시에도 에러 상태로 변경하지 않음
      // (기존 데이터 유지하여 사용자 경험 개선)
      rethrow; // 호출한 곳에서 에러 처리하도록 전파
    }
  }
}

final bookDetailProvider = StateNotifierProvider.family<BookDetailController,
    AsyncValue<Book>, String>(
  (ref, bookId) => BookDetailController(
    bookId: bookId,
    repository: ref.watch(bookRepositoryProvider),
    ref: ref,
  ),
);
