import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/memo.dart';
import '../../domain/models/memo_visibility.dart';
import '../../data/repositories/memo_repository.dart' as memo;
import '../providers/memo_provider.dart';

class MemoFormParams {
  final String bookId;
  final Memo? initialMemo;

  MemoFormParams({
    required this.bookId,
    this.initialMemo,
  });
}

class MemoFormController extends StateNotifier<AsyncValue<void>> {
  final memo.MemoRepository _repository;
  final String bookId;
  final Memo? initialMemo;
  final Ref ref;

  final pageController = TextEditingController();
  final contentController = TextEditingController();

  MemoFormController({
    required memo.MemoRepository repository,
    required this.bookId,
    required this.ref,
    this.initialMemo,
  })  : _repository = repository,
        super(const AsyncValue.data(null)) {
    if (initialMemo != null) {
      pageController.text = initialMemo!.page?.toString() ?? '';
      contentController.text = initialMemo!.content;
    }
  }

  Future<bool> saveMemo() async {
    if (contentController.text.isEmpty) return false;

    state = const AsyncValue.loading();

    try {
      final page = pageController.text.isNotEmpty
          ? int.parse(pageController.text)
          : null;

      if (initialMemo != null) {
        await _repository.updateMemo(
          memoId: initialMemo!.id,
          content: contentController.text,
          page: page,
          imageUrl: null,
        );
      } else {
        log('Creating memo with: bookId=$bookId, content=${contentController.text}, page=$page');
        await _repository.createMemo(
          bookId: bookId,
          content: contentController.text,
          page: page,
          imageUrl: null,
        );
      }

      // saveMemo는 visibility 정보가 없으므로, 기존 메모가 있으면 그 visibility 확인
      // 없으면 private로 가정 (기본값)
      final wasPublic = initialMemo != null &&
          initialMemo!.visibility == MemoVisibility.public;
      _invalidateMemoProviders(
        bookId,
        memoId: initialMemo?.id,
        isPublic: wasPublic,
      );

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      log('Error saving memo: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteMemo() async {
    if (initialMemo == null) return false;

    state = const AsyncValue.loading();

    try {
      final memoToDelete = initialMemo!;
      await _repository.deleteMemo(memoToDelete.id);

      // 삭제된 메모가 공개였을 수 있으므로 공개 메모 provider도 무효화
      final wasPublic = memoToDelete.visibility == MemoVisibility.public;
      _invalidateMemoProviders(
        bookId,
        memoId: memoToDelete.id,
        isPublic: wasPublic,
      );

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> createMemo({
    required String bookId,
    required String content,
    int? page,
    String? imageUrl,
    MemoVisibility visibility = MemoVisibility.private,
    String? lyraQuestionId,
    String? lyraQuestionText,
    String? lyraSource,
  }) async {
    if (content.isEmpty) return false;

    state = const AsyncValue.loading();

    try {
      await _repository.createMemo(
        bookId: bookId,
        content: content,
        page: page,
        imageUrl: imageUrl,
        visibility: visibility,
        lyraQuestionId: lyraQuestionId,
        lyraQuestionText: lyraQuestionText,
        lyraSource: lyraSource,
      );

      // visibility에 따라 조건부 무효화
      _invalidateMemoProviders(
        bookId,
        isPublic: visibility == MemoVisibility.public,
      );

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateMemo({
    required String memoId,
    required String content,
    int? page,
    String? imageUrl,
    MemoVisibility? visibility,
  }) async {
    if (content.isEmpty) return false;

    state = const AsyncValue.loading();

    try {
      await _repository.updateMemo(
        memoId: memoId,
        content: content,
        page: page,
        imageUrl: imageUrl,
        visibility: visibility,
      );

      // visibility 변경 여부 확인 (기존 메모의 visibility와 비교)
      // visibility가 null이면 변경되지 않은 것으로 간주
      final isPublic = visibility == MemoVisibility.public ||
          (visibility == null && initialMemo?.visibility == MemoVisibility.public);
      
      _invalidateMemoProviders(
        bookId,
        memoId: memoId,
        isPublic: isPublic,
      );

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 메모 변경 후 관련 provider들 무효화
  /// 
  /// 중앙화된 무효화 함수를 사용하여 일관성 보장
  void _invalidateMemoProviders(
    String bookId, {
    String? memoId,
    bool isPublic = false,
  }) {
    invalidateMemoProviders(ref, bookId, memoId: memoId, isPublic: isPublic);
  }

  @override
  void dispose() {
    pageController.dispose();
    contentController.dispose();
    super.dispose();
  }
}

final memoFormControllerProvider = StateNotifierProvider.family<
    MemoFormController, AsyncValue<void>, MemoFormParams>((ref, params) {
  final repository = ref.watch(memo.memoRepositoryProvider);
  return MemoFormController(
    repository: repository,
    bookId: params.bookId,
    ref: ref,
    initialMemo: params.initialMemo,
  );
});

// 편의를 위한 Provider
final memoFormProvider = StateNotifierProvider.family<
    MemoFormController, AsyncValue<void>, String>((ref, bookId) {
  final repository = ref.watch(memo.memoRepositoryProvider);
  return MemoFormController(
    repository: repository,
    bookId: bookId,
    ref: ref,
  );
});
