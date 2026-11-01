import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_remote_data_source.dart';
import '../models/user_model.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/services/analytics_service.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final GoogleSignIn _googleSignIn;
  final SupabaseClient _supabase;

  AuthRemoteDataSourceImpl({
    required AnalyticsService analytics,
    GoogleSignIn? googleSignIn,
    SupabaseClient? supabase,
  })  : _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']),
        _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      print('🔵 Google 로그인 시작...');
      
      // 기존 세션 정리 (에러 무시)
      try {
        await _googleSignIn.signOut();
        print('🔵 기존 세션 정리 완료');
      } catch (e) {
        print('⚠️ 기존 세션 정리 중 에러 (무시): $e');
      }
      
      // Google 로그인
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('❌ Google 로그인 취소됨');
        throw Exception('Google sign in cancelled');
      }

      print('🔵 Google 사용자 정보 획득: ${googleUser.email}');
      
      // Google 인증 정보 획득
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.idToken == null) {
        print('❌ Google ID Token이 없습니다');
        throw Exception('Google ID token is null');
      }
      
      print('🔵 Google 인증 토큰 획득 완료');

      // Supabase 로그인
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (response.user == null) {
        print('❌ Supabase 로그인 실패: user is null');
        throw Exception('Supabase authentication failed: user is null');
      }

      print('🔵 Supabase 로그인 성공: ${response.user!.id}');

      // 사용자 정보 생성
      final userModel = UserModel(
        id: response.user!.id,
        email: response.user!.email ?? '',
        nickname: googleUser.displayName ?? '사용자',
        pictureUrl: googleUser.photoUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        onboardingCompleted: false,
      );

      print('✅ Google 로그인 완료: ${userModel.email}');
      return userModel;
    } catch (e, stackTrace) {
      print('❌ Google 로그인 실패: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<UserModel> signInWithApple() async {
    try {
      print('🍎 Apple 로그인 시작...');
      
      // Apple 로그인 요청
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.identityToken == null) {
        print('❌ Apple 로그인 취소됨 또는 identityToken이 null');
        throw Exception('Apple sign in cancelled or identityToken is null');
      }

      print('🍎 Apple 사용자 정보 획득: ${credential.userIdentifier}');
      print('🍎 Email: ${credential.email ?? '없음'}');
      
      // Supabase 로그인
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
        accessToken: credential.authorizationCode,
      );

      if (response.user == null) {
        print('❌ Supabase 로그인 실패: user is null');
        print('Response session: ${response.session}');
        throw Exception('Supabase authentication failed: user is null');
      }

      print('🍎 Supabase 로그인 성공: ${response.user!.id}');

      // 닉네임 생성 (이름이 없으면 기본값 사용)
      String nickname = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
      if (nickname.isEmpty) {
        nickname = '사용자';
      }

      // 사용자 정보 생성
      final userModel = UserModel(
        id: response.user!.id,
        email: response.user!.email ?? credential.email ?? '',
        nickname: nickname,
        pictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        onboardingCompleted: false,
      );

      print('✅ Apple 로그인 완료: ${userModel.email}');
      return userModel;
    } catch (e, stackTrace) {
      print('❌ Apple 로그인 실패: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      print('🚪 로그아웃 시작...');
      
      // Google 로그아웃
      await _googleSignIn.signOut();
      print('🔵 Google 로그아웃 완료');
      
      // Supabase 로그아웃
      await _supabase.auth.signOut();
      print('🔵 Supabase 로그아웃 완료');
      
      print('✅ 로그아웃 완료');
    } catch (e) {
      print('❌ 로그아웃 실패: $e');
      rethrow;
    }
  }

  /// 세션 없음/행 없음 -> null. 조회 오류는 throw (null 로 삼키지 않는다).
  @override
  Future<UserModel?> getCurrentUser() async {
    final session = _supabase.auth.currentSession;
    if (session?.user == null) return null;

    final response = await _supabase
        .from('users')
        .select()
        .eq('id', session!.user.id)
        .maybeSingle();

    if (response == null) return null;

    return UserModel.fromJson(response);
  }

  Future<void> updateProfile({
    String? nickname,
    String? pictureUrl,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{
        'updated_at': nowUtcIso(),
      };

      if (nickname != null) updates['nickname'] = nickname;
      if (pictureUrl != null) updates['picture_url'] = pictureUrl;

      await _supabase
          .from('users')
          .update(updates)
          .eq('id', currentUser.id);

      print('✅ 프로필 업데이트 완료');
    } catch (e) {
      print('❌ 프로필 업데이트 실패: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // 사용자 데이터 삭제
      await _supabase.from('users').delete().eq('id', currentUser.id);
      
      // 계정 삭제
      await _supabase.auth.signOut();
      
      print('✅ 계정 삭제 완료');
    } catch (e) {
      print('❌ 계정 삭제 실패: $e');
      rethrow;
    }
  }
}