import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../domain/entities/user.dart';

/// 세션이 서버에서 거부됐는지(refresh token 무효) 판단한다.
/// 네트워크 오류(AuthRetryableFetchException)나 429/5xx 는 거부가 아니다.
bool isSessionRejected(Object error) {
  if (error is AuthRetryableFetchException) return false;
  if (error is AuthSessionMissingException) return true;
  if (error is AuthException) {
    final status = error.statusCode;
    return status == '400' || status == '401' || status == '403';
  }
  return false;
}

/// 현재 로그인 사용자 조회.
/// - 세션 없음 / 세션 거부 / users 행 없음 -> null
/// - 그 밖의 오류(네트워크, 서버) -> 그대로 throw (null 로 삼키지 않는다)
Future<User?> lookupCurrentUser({
  required String? Function() sessionUserId,
  required Future<void> Function() refreshIfNeeded,
  required Future<Map<String, dynamic>?> Function(String userId) fetchRow,
}) async {
  try {
    await refreshIfNeeded();
  } catch (e) {
    if (isSessionRejected(e)) return null;
    // 네트워크 등 일시 오류는 삼킨다. 세션이 아직 유효하면 계속 진행.
  }

  final userId = sessionUserId();
  if (userId == null) return null;

  final row = await fetchRow(userId);
  if (row == null) return null;
  return User.fromJson(row);
}
