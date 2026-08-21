import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/memo_repository.dart';
import '../../domain/models/memo.dart';
import '../../domain/memo_exceptions.dart';
import 'dart:io';
import 'dart:developer';
import '../../../../core/providers/supabase_client_provider.dart';
import '../../../../core/utils/response_cache.dart';
import '../../../home/presentation/providers/book_provider.dart';

final memoRepositoryProvider = Provider((ref) {
  return MemoRepository(Supabase.instance.client);
});

/// 메모 변경 후 관련 provider들 무효화 (중앙화된 함수)
/// 
/// 메모 생성/수정/삭제 후 일관된 캐시 무효화를 보장합니다.
/// 
/// [ref] Riverpod Ref
/// [bookId] 책 ID
/// [memoId] 메모 ID (updateMemo, deleteMemo에서만 필요)
/// [isPublic] 공개 메모인지 여부 (공개 메모 provider 무효화 여부 결정)
void invalidateMemoProviders(
  Ref ref,
  String bookId, {
  String? memoId,
  bool isPublic = false,
}) {
  // 공개 메모인 경우에만 책별 공개 메모 provider 무효화
  if (isPublic) {
    ResponseCache().invalidate('get-public-book-memos', bookId: bookId);
    ref.invalidate(paginatedPublicBookMemosProvider(bookId));
    ref.invalidate(publicBookMemosProvider(bookId));
  }

  // 항상 무효화해야 하는 provider들
  // publicMemoFeedProvider: 홈 '다른 별들이 남긴 생각들' + 메모탭 공개 세그먼트.
  // 공개->비공개 전환·삭제도 피드에 반영돼야 하므로 항상 무효화.
  ref.invalidate(publicMemoFeedProvider);
  ref.invalidate(bookMemosProvider(bookId));
  ref.invalidate(recentMemosProvider);
  ref.invalidate(homeRecentMemosProvider);
  ref.invalidate(allMemosProvider);
  ref.invalidate(paginatedMemosProvider(bookId));
  ref.invalidate(paginatedMemosProvider(null));
  // 홈 책 정렬은 최근 메모 작성 시점 기반이므로 메모 CRUD마다 재정렬 필요
  ref.invalidate(homeBooksProvider);

  // 메모 상세 화면 갱신 (updateMemo, deleteMemo에서만 필요)
  if (memoId != null) {
    ref.invalidate(memoProvider(memoId));
  }
}

final memoProvider = FutureProvider.family<Memo?, String>((ref, memoId) async {
  try {
    log('memoProvider 호출: $memoId');
    final repository = ref.watch(memoRepositoryProvider);
    final memo = await repository.getMemoById(memoId);
    log('memoProvider 성공: userNickname=${memo.userNickname}, userAvatarUrl=${memo.userAvatarUrl}');
    return memo;
  } on MemoRestrictedException {
    // 남의 비공개 메모: 화면이 책 상세로 유도하도록 그대로 전파.
    rethrow;
  } catch (e, stackTrace) {
    // 메모가 삭제되었거나 존재하지 않는 경우 null 반환
    log('메모 조회 실패 (삭제되었을 수 있음): $e');
    log('스택 트레이스: $stackTrace');
    return null;
  }
});

final bookMemosProvider =
    FutureProvider.family<List<Memo>, String>((ref, bookId) async {
  if (bookId.isEmpty) return [];
  final repository = ref.watch(memoRepositoryProvider);
  try {
    return await repository.getBookMemos(bookId);
  } catch (e) {
    log('Error in bookMemosProvider: $e');
    return []; // 에러가 발생해도 빈 리스트를 반환
  }
});

/// 해당 책의 모든 공개 메모 가져오기 (다른 유저의 공개 메모 포함)
/// @deprecated 페이지네이션을 위해 paginatedPublicBookMemosProvider 사용 권장
final publicBookMemosProvider =
    FutureProvider.family<List<Memo>, String>((ref, bookId) async {
  if (bookId.isEmpty) return [];
  final repository = ref.watch(memoRepositoryProvider);
  try {
    return await repository.getPublicBookMemos(bookId);
  } catch (e) {
    log('Error in publicBookMemosProvider: $e');
    return []; // 에러가 발생해도 빈 리스트를 반환
  }
});

/// 해당 책의 공개 메모를 페이지네이션으로 가져오기 (다른 유저의 공개 메모 포함)
class PaginatedPublicBookMemosNotifier extends StateNotifier<AsyncValue<List<Memo>>> {
  final MemoRepository _repository;
  final String bookId;
  int _page = 0;
  static const int _limit = 10;
  bool _hasMore = true;
  bool _isLoading = false; // 중복 요청 방지 플래그

  PaginatedPublicBookMemosNotifier({
    required MemoRepository repository,
    required this.bookId,
  })  : _repository = repository,
        super(const AsyncValue.loading()) {
    loadInitialMemos();
  }

  Future<void> loadInitialMemos() async {
    if (!mounted || _isLoading) return;
    state = const AsyncValue.loading();
    _page = 0;
    _hasMore = true;
    _isLoading = true;
    try {
      await _loadMemos();
    } finally {
      if (mounted) {
        _isLoading = false;
      }
    }
  }

  Future<void> loadMoreMemos() async {
    // 이미 로딩 중이거나 더 이상 불러올 데이터가 없으면 중단
    if (_isLoading || !_hasMore || !mounted) return;
    
    _isLoading = true;
    _page++;
    try {
      await _loadMemos();
    } finally {
      if (mounted) {
        _isLoading = false;
      }
    }
  }

  Future<void> _loadMemos() async {
    try {
      final memos = await _repository.getPaginatedPublicBookMemos(
        bookId: bookId,
        limit: _limit,
        offset: _page * _limit,
      );

      // dispose된 후에는 state를 업데이트하지 않음
      if (!mounted) return;

      _hasMore = memos.length == _limit;

      if (_page == 0) {
        state = AsyncValue.data(memos);
      } else {
        final currentMemos = state.value ?? [];
        state = AsyncValue.data([...currentMemos, ...memos]);
      }
    } catch (e, st) {
      // dispose된 후에는 state를 업데이트하지 않음
      if (!mounted) return;
      
      // 에러 발생 시 이전 페이지로 롤백
      if (_page > 0) {
        _page--;
      }
      
      state = AsyncValue.error(e, st);
    }
  }

  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
}

final paginatedPublicBookMemosProvider = StateNotifierProvider.family<
    PaginatedPublicBookMemosNotifier, AsyncValue<List<Memo>>, String>(
  (ref, bookId) => PaginatedPublicBookMemosNotifier(
    repository: ref.watch(memoRepositoryProvider),
    bookId: bookId,
  ),
);

final recentMemosProvider = FutureProvider<List<Memo>>((ref) async {
  final repository = ref.watch(memoRepositoryProvider);
  return repository.getRecentMemos();
});

/// 전역 공개 메모 피드(메모 탭 '공개' 세그먼트).
final publicMemoFeedProvider = FutureProvider<List<Memo>>((ref) async {
  final repository = ref.watch(memoRepositoryProvider);
  return repository.getPublicFeed();
});

final createMemoProvider =
    FutureProvider.family<void, ({String bookId, String content, int? page})>(
  (ref, params) async {
    final repository = ref.watch(memoRepositoryProvider);
    await repository.createMemo(
      bookId: params.bookId,
      content: params.content,
      page: params.page,
    );

    // 중앙화된 무효화 함수 사용 (private 메모로 가정)
    invalidateMemoProviders(ref, params.bookId, isPublic: false);
  },
);

final updateMemoProvider = FutureProvider.family<
    void,
    ({
      String memoId,
      String content,
      String bookId,
      int? page,
      String? imageUrl,
    })>((ref, params) async {
  final repository = ref.read(memoRepositoryProvider);
  final supabase = ref.read(supabaseClientProvider);

  // 기존 메모의 이미지가 있다면 삭제
  if (params.imageUrl == null) {
    try {
      final oldMemo = await supabase
          .from('memos')
          .select('image_url')
          .eq('id', params.memoId)
          .single();

      if (oldMemo['image_url'] != null) {
        final userId = supabase.auth.currentUser!.id;
        final oldFileName = '${userId}/${oldMemo['image_url'].split('/').last}';
        await supabase.storage.from('memo_images').remove([oldFileName]);
      }
    } catch (e) {
      log('기존 이미지 삭제 실패: $e');
    }
  }

  await repository.updateMemo(
    memoId: params.memoId,
    content: params.content,
    page: params.page,
    imageUrl: params.imageUrl,
  );

  // updateMemoProvider는 visibility 정보가 없으므로 안전하게 모두 무효화
  // (공개 메모일 수 있으므로 isPublic: true로 설정)
  invalidateMemoProviders(
    ref,
    params.bookId,
    memoId: params.memoId,
    isPublic: true, // 안전을 위해 공개 메모로 가정
  );
});

final deleteMemoProvider =
    FutureProvider.family<void, ({String memoId, String bookId})>(
  (ref, params) async {
    final repository = ref.watch(memoRepositoryProvider);
    await repository.deleteMemo(params.memoId);

    // deleteMemoProvider는 삭제된 메모가 공개였을 수 있으므로 모두 무효화
    invalidateMemoProviders(
      ref,
      params.bookId,
      memoId: params.memoId,
      isPublic: true, // 안전을 위해 공개 메모로 가정
    );
  },
);

final allMemosProvider = FutureProvider<List<Memo>>((ref) async {
  final repository = ref.watch(memoRepositoryProvider);
  return repository.getAllMemos();
});

final homeRecentMemosProvider = FutureProvider<List<Memo>>((ref) async {
  final repository = ref.watch(memoRepositoryProvider);
  return repository.getRecentMemos();
});

class PaginatedMemosNotifier extends StateNotifier<AsyncValue<List<Memo>>> {
  final MemoRepository _repository;
  final String? bookId;
  int _page = 0;
  static const int _limit = 10;
  bool _hasMore = true;

  PaginatedMemosNotifier({
    required MemoRepository repository,
    this.bookId,
  })  : _repository = repository,
        super(const AsyncValue.loading()) {
    // 생성자에서 즉시 로딩 시작
    // StateNotifier는 생성 시점에 mounted가 true이므로 안전함
    loadInitialMemos();
  }

  Future<void> loadInitialMemos() async {
    // mounted 체크 제거: StateNotifier는 생성 시점부터 mounted가 true
    state = const AsyncValue.loading();
    _page = 0;
    _hasMore = true;
    await _loadMemos();
  }

  Future<void> loadMoreMemos() async {
    if (!_hasMore || !mounted) return;
    _page++;
    await _loadMemos();
  }

  Future<void> _loadMemos() async {
    try {
      final memos = await _repository.getPaginatedMemos(
        limit: _limit,
        offset: _page * _limit,
        bookId: bookId,
      );

      // dispose된 후에는 state를 업데이트하지 않음
      if (!mounted) return;

      _hasMore = memos.length == _limit;

      if (_page == 0) {
        state = AsyncValue.data(memos);
      } else {
        state = AsyncValue.data([
          ...state.value ?? [],
          ...memos,
        ]);
      }
    } catch (e, st) {
      // dispose된 후에는 state를 업데이트하지 않음
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  bool get hasMore => _hasMore;
}

final paginatedMemosProvider = StateNotifierProvider.family<
    PaginatedMemosNotifier, AsyncValue<List<Memo>>, String?>(
  (ref, bookId) => PaginatedMemosNotifier(
    repository: ref.watch(memoRepositoryProvider),
    bookId: bookId,
  ),
);

Future<String?> _uploadMemoImage(String filePath) async {
  try {
    final userId = Supabase.instance.client.auth.currentUser!.id;
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File(filePath);

    await Supabase.instance.client.storage
        .from('memo_images')
        .upload(fileName, file);

    // 공개 URL(만료 없음). 서명 URL 만료로 이미지가 죽던 문제 방지.
    final imageUrl = Supabase.instance.client.storage
        .from('memo_images')
        .getPublicUrl(fileName);

    return imageUrl;
  } catch (e) {
    log('이미지 업로드 실패: $e');
    return null;
  }
}

final createMemoWithImageProvider =
    StateNotifierProvider<CreateMemoNotifier, AsyncValue<void>>((ref) {
  return CreateMemoNotifier(ref.watch(memoRepositoryProvider));
});

class CreateMemoNotifier extends StateNotifier<AsyncValue<void>> {
  final MemoRepository _repository;

  CreateMemoNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> createMemo({
    required String bookId,
    required String content,
    required String? imagePath,
    int? page,
  }) async {
    state = const AsyncValue.loading();
    try {
      String? imageUrl;
      if (imagePath != null) {
        imageUrl = await _uploadMemoImage(imagePath);
      }

      await _repository.createMemo(
        bookId: bookId,
        content: content,
        page: page,
        imageUrl: imageUrl,
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// 메모 수정 이벤트를 위한 새로운 프로바이더 추가
final memoUpdateEventProvider = StateProvider<String?>((ref) => null);
