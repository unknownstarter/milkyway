import '../../auth/domain/entities/user.dart';

enum SplashDestination { login, onboarding, home }

const splashRetryDelays = [
  Duration(milliseconds: 400),
  Duration(milliseconds: 1200),
];

/// 세션이 있는 상태에서 사용자 행을 조회해 갈 곳을 정한다.
/// - 행 없음(조회 성공 + null) -> 로그인
/// - 온보딩 미완료 -> 온보딩 / 완료 -> 홈
/// - 조회 오류 -> [retryDelays] 만큼 재시도 후에도 실패면 마지막 오류를 throw
///   (오류를 "로그아웃"으로 읽어 로그인 화면으로 보내지 않는다)
Future<SplashDestination> resolveSplashDestination({
  required Future<User?> Function() getUser,
  List<Duration> retryDelays = splashRetryDelays,
  Future<void> Function(Duration) wait = _defaultWait,
}) async {
  var attempt = 0;
  while (true) {
    try {
      final user = await getUser();
      if (user == null) return SplashDestination.login;
      return user.onboardingCompleted
          ? SplashDestination.home
          : SplashDestination.onboarding;
    } catch (_) {
      if (attempt >= retryDelays.length) rethrow;
      await wait(retryDelays[attempt]);
      attempt++;
    }
  }
}

Future<void> _defaultWait(Duration d) => Future<void>.delayed(d);
