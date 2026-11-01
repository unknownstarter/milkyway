import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/current_user_lookup.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/datasources/auth_remote_data_source_impl.dart';
import '../../../../core/network/edge_function_client.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../core/services/session_restore.dart';
import '../../../books/presentation/providers/user_books_provider.dart';
import '../../../home/presentation/providers/book_provider.dart';
import '../../../memos/presentation/providers/memo_provider.dart';
import '../../../home/presentation/providers/selected_book_provider.dart';
import '../../../home/presentation/providers/home_loader_provider.dart';
import '../../../memos/presentation/providers/memo_list_loader_provider.dart';
import '../../../books/presentation/providers/bookshelf_loader_provider.dart';
import 'dart:developer' as developer;

part 'auth_provider.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  final analytics = ref.watch(analyticsProvider);
  return AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(analytics: analytics),
  );
}

@riverpod
class Auth extends _$Auth {
  final _supabase = Supabase.instance.client;

  @override
  FutureOr<User?> build() async {
    // 초기화 시 현재 사용자 가져오기
    return await getCurrentUser();
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final result = await ref.read(authRepositoryProvider).signInWithGoogle();
      await result.fold(
        (failure) async =>
            state = AsyncValue.error(failure, StackTrace.current),
        (user) async {
          await _handleUserSignIn(user);
          // 사용자 정보를 명시적으로 새로고침 (DB 업데이트 반영)
          await Future.delayed(const Duration(milliseconds: 100));
          final currentUser = await getCurrentUser();
          if (currentUser != null) {
            state = AsyncValue.data(currentUser);
            // 로그인 완료 후 데이터 provider 강제 새로고침. 로그아웃 순간 currentUser=null로
            // 에러/빈 상태가 캐시된 provider(책탭·프로필 등)가 재로그인해도 그대로 남아
            // 데이터가 안 보이던 문제 해결(메모는 타이밍상 보였음). 데이터 유실 아님.
            _clearAllDataProviders();
          } else {
            state = const AsyncValue.data(null);
          }
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    try {
      final result = await ref.read(authRepositoryProvider).signInWithApple();
      await result.fold(
        (failure) async =>
            state = AsyncValue.error(failure, StackTrace.current),
        (user) async {
          await _handleUserSignIn(user);
          // 사용자 정보를 명시적으로 새로고침 (DB 업데이트 반영)
          await Future.delayed(const Duration(milliseconds: 100));
          final currentUser = await getCurrentUser();
          if (currentUser != null) {
            state = AsyncValue.data(currentUser);
            // 로그인 완료 후 데이터 provider 강제 새로고침. 로그아웃 순간 currentUser=null로
            // 에러/빈 상태가 캐시된 provider(책탭·프로필 등)가 재로그인해도 그대로 남아
            // 데이터가 안 보이던 문제 해결(메모는 타이밍상 보였음). 데이터 유실 아님.
            _clearAllDataProviders();
          } else {
            state = const AsyncValue.data(null);
          }
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();

      // 마지막 위치 복원 캐시 정리(로그아웃 후 콜드스타트가 앱 안으로 복원되지 않게).
      await SessionRestore.clear();

      // 모든 데이터 provider 캐시 초기화 (다른 사용자 데이터가 표시되지 않도록)
      _clearAllDataProviders();

      // authProvider 자체도 invalidate하여 완전히 초기화
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 로그아웃 시 모든 데이터 provider 캐시 초기화
  void _clearAllDataProviders() {
    // 책 관련 provider
    ref.invalidate(userBooksProvider);
    ref.invalidate(recentBooksProvider);
    ref.invalidate(homeBooksProvider);

    // 메모 관련 provider
    ref.invalidate(recentMemosProvider);
    ref.invalidate(homeRecentMemosProvider);
    ref.invalidate(allMemosProvider);

    // 선택된 책 초기화
    ref.read(selectedBookIdProvider.notifier).state = null;

    // 로더 provider들 초기화
    ref.invalidate(homeLoaderProvider);
    ref.invalidate(memoListLoaderProvider);
    ref.invalidate(bookshelfLoaderProvider);

    // Family provider들은 사용자가 접근할 때 자동으로 새로 로드됨
    // (bookDetailProvider, memoProvider, bookMemosProvider, paginatedMemosProvider 등)
  }

  /// 세션 없음/세션 거부/행 없음 -> null. 그 밖의 오류는 throw.
  Future<User?> getCurrentUser() {
    return lookupCurrentUser(
      sessionUserId: () => _supabase.auth.currentSession?.user.id,
      refreshIfNeeded: _refreshSessionIfNeeded,
      fetchRow: (userId) =>
          _supabase.from('users').select().eq('id', userId).maybeSingle(),
    );
  }

  /// 세션이 만료되기 전에 자동으로 갱신
  /// Refresh token을 사용하여 최대 1개월까지 세션 유지 가능
  /// 네트워크 오류는 삼키고(세션이 아직 유효하면 계속), 서버가 refresh token 을
  /// 거부한 경우는 [lookupCurrentUser] 가 알 수 있게 그대로 던진다.
  Future<void> _refreshSessionIfNeeded() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return;

    // 세션이 만료되기 5분 전에 갱신
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return;

    final now = DateTime.now().toUtc();
    final expiresAtDateTime = DateTime.fromMillisecondsSinceEpoch(
      expiresAt * 1000,
      isUtc: true,
    );
    final timeUntilExpiry = expiresAtDateTime.difference(now);

    // 만료되기 5분 전이면 갱신 시도
    if (timeUntilExpiry.inMinutes < 5) {
      developer.log('세션 갱신 시도 (만료까지 ${timeUntilExpiry.inMinutes}분 남음)');
      try {
        await _supabase.auth.refreshSession();
        developer.log('세션 갱신 완료');
      } catch (e) {
        developer.log('세션 갱신 실패: $e');
        if (isSessionRejected(e)) rethrow;
        // 일시 오류는 무시 (다음 요청 시 다시 시도)
      }
    }
  }

  Future<void> _handleUserSignIn(User user) async {
    try {
      // 사용자 정보가 이미 존재하는지 확인
      final existingUser = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existingUser == null) {
        // 새 사용자 등록
        // referral_code는 Supabase trigger에서 자동 생성됨
        await _supabase.from('users').insert({
          'id': user.id,
          'email': user.email,
          'nickname': user.nickname,
          'picture_url': user.pictureUrl,
          'created_at': nowUtcIso(),
          'updated_at': nowUtcIso(),
          // referral_code는 NULL로 두면 trigger가 자동 생성
        });
      } else {
        // 탈퇴 유예(소프트삭제) 중 재로그인 -> 삭제 취소(복구). 인스타/디스코드식.
        if (existingUser['deleted_at'] != null) {
          try {
            await _supabase.rpc('restore_account');
          } catch (e) {
            developer.log('계정 복구 실패: $e');
          }
        }
        // 기존 사용자 정보 업데이트
        // 중요: nickname과 picture_url은 사용자가 온보딩/프로필 편집에서 설정한 값이 있으면 덮어쓰지 않음
        final updates = <String, dynamic>{
          'email': user.email,
          'updated_at': nowUtcIso(),
        };

        // nickname이 DB에 없거나 null인 경우에만 Google/Apple에서 받은 값으로 설정
        if (existingUser['nickname'] == null ||
            existingUser['nickname'].toString().isEmpty) {
          updates['nickname'] = user.nickname;
        }

        // picture_url이 DB에 없거나 null인 경우에만 Google/Apple에서 받은 값으로 설정
        if (existingUser['picture_url'] == null ||
            existingUser['picture_url'].toString().isEmpty) {
          updates['picture_url'] = user.pictureUrl;
        }

        await _supabase.from('users').update(updates).eq('id', user.id);
      }
    } catch (e) {
      developer.log('Error handling user sign in: $e');
      rethrow;
    }
  }

  /// 닉네임 중복 체크
  ///
  /// [nickname] 체크할 닉네임
  /// Returns true if nickname is available (not duplicate), false otherwise
  ///
  /// RLS 정책으로 인해 다른 사용자의 닉네임을 직접 조회할 수 없으므로
  /// Supabase Edge Function을 사용하여 중복 체크를 수행합니다.
  ///
  /// 확인 자체가 실패하면(네트워크/서버 오류) false("중복")로 속이지 않고 throw 한다.
  Future<bool> checkNicknameAvailability(String nickname) async {
    try {
      final currentUser = await getCurrentUser();

      // 현재 사용자의 닉네임과 동일하면 사용 가능
      if (currentUser?.nickname == nickname) {
        return true;
      }

      // Edge Function을 사용하여 닉네임 중복 체크 (RLS 정책 우회)
      final response = await ref.read(edgeFunctionClientProvider).invoke(
        'check-nickname',
        body: {'nickname': nickname, 'user_id': currentUser?.id},
      );

      if (response.status != 200) {
        final errorData = response.data;
        developer.log('닉네임 중복 체크 실패: ${errorData ?? '알 수 없는 오류'}');
        throw Exception('nickname check failed: ${response.status}');
      }

      final data = response.data as Map<String, dynamic>?;
      return data?['available'] == true;
    } catch (e) {
      developer.log('닉네임 중복 체크 실패: $e');
      rethrow;
    }
  }

  Future<void> updateProfile({String? nickname, String? pictureUrl}) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) throw StateError('Not logged in');

      final updates = <String, dynamic>{
        'updated_at': nowUtcIso(),
      };

      if (nickname != null) updates['nickname'] = nickname;
      if (pictureUrl != null) {
        // 빈 문자열은 null로 처리 (이미지 제거)
        updates['picture_url'] = pictureUrl.isEmpty ? null : pictureUrl;
      }

      await _supabase.from('users').update(updates).eq('id', currentUser.id);

      // 상태 새로고침 - DB 업데이트 후 약간의 지연을 두고 최신 데이터 가져오기
      await Future.delayed(const Duration(milliseconds: 100));
      try {
        final updatedUser = await getCurrentUser();
        if (updatedUser != null) {
          state = AsyncValue.data(updatedUser);
        }
      } catch (e) {
        developer.log('프로필 새로고침 실패(저장은 성공): $e');
      }

      // 프로필 업데이트 시 메모 관련 provider들 무효화하여 최신 프로필 정보 반영
      ref.invalidate(recentMemosProvider);
      ref.invalidate(homeRecentMemosProvider);
      ref.invalidate(allMemosProvider);
      // paginatedMemosProvider는 family이므로 모든 bookId에 대해 무효화
      // null (모든 메모)과 특정 bookId들에 대해 무효화
      ref.invalidate(paginatedMemosProvider(null));
      // 다른 bookId들은 사용자가 접근할 때 자동으로 새로 로드됨
    } catch (e) {
      // 저장 실패는 호출부가 알아야 한다(성공 토스트/화면 이동 금지).
      // state 는 건드리지 않는다 - 로그인 상태가 오류로 바뀌면 로그아웃처럼 보인다.
      developer.log('프로필 저장 실패: $e');
      rethrow;
    }
  }

  /// 탈퇴 = 소프트 삭제(30일 유예). 즉시 하드삭제하지 않고 deleted_at 만 찍어
  /// 콘텐츠를 전면 숨김. 유예 내 재로그인하면 복구됨([restore_account]).
  /// 30일 지나면 스케줄러(purge_expired_deleted_accounts)가 완전 삭제.
  Future<void> deleteAccount() async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) throw StateError('Not logged in');

      await _supabase.rpc('soft_delete_account');

      // 로그아웃 + 데이터/복원 캐시 초기화
      await SessionRestore.clear();
      await _supabase.auth.signOut();
      _clearAllDataProviders();
      ref.invalidateSelf();
    } catch (e, st) {
      developer.log('계정 삭제(소프트) 실패: $e');
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  bool get isSignedIn => _supabase.auth.currentUser != null;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  Future<void> checkAppVersion() async {
    // TODO: 앱 버전 체크 로직 구현
    // 현재는 빈 구현으로 두어 에러 방지
  }

  /// 행이 있고 onboarding_completed 가 true 일 때만 true.
  /// 조회 오류는 throw (오류를 "온보딩 미완료"로 읽어 온보딩으로 보내지 않는다).
  Future<bool> checkOnboardingStatus() async {
    final user = await getCurrentUser();
    return user?.onboardingCompleted ?? false;
  }

  Future<void> updateOnboardingStatus(bool completed) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) throw StateError('Not logged in');

      await _supabase
          .from('users')
          .update({
            'onboarding_completed': completed,
            'updated_at': nowUtcIso(),
          })
          .eq('id', currentUser.id);

      // 상태 새로고침 (실패해도 저장은 끝났으니 state 를 null/오류로 바꾸지 않는다)
      try {
        final updatedUser = await getCurrentUser();
        if (updatedUser != null) state = AsyncValue.data(updatedUser);
      } catch (e) {
        developer.log('온보딩 상태 새로고침 실패(저장은 성공): $e');
      }
    } catch (e) {
      developer.log('Error updating onboarding status: $e');
      rethrow;
    }
  }
}
