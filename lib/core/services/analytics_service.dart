import 'package:firebase_analytics/firebase_analytics.dart';
import '../../features/home/domain/models/book_status.dart';

class AnalyticsService {
  final FirebaseAnalytics? _analytics;

  AnalyticsService(this._analytics);

  // 로그인 이벤트
  Future<void> logLogin(String method) async {
    if (_analytics == null) return;
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      // Analytics 에러는 무시
    }
  }

  // 회원가입 완료 이벤트
  Future<void> logSignUp(String method) async {
    if (_analytics == null) return;
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (e) {
      // Analytics 에러는 무시
    }
  }

  // 온보딩 완료 이벤트
  Future<void> logOnboardingComplete() async {
    if (_analytics == null) return;
    try {
      await _analytics.logEvent(
        name: 'onboarding_complete',
      );
    } catch (e) {
      // Analytics 에러는 무시
    }
  }

  // 책 등록 이벤트
  Future<void> logBookRegistered(String bookId, String title) async {
    if (_analytics == null) return;
    try {
      await _analytics.logEvent(
        name: 'book_registered',
        parameters: {
          'book_id': bookId,
          'book_title': title,
        },
      );
    } catch (e) {
      // Analytics 에러는 무시
    }
  }

  // 메모 작성 이벤트
  Future<void> logMemoCreated(String bookId) async {
    if (_analytics == null) return;
    try {
      await _analytics.logEvent(
        name: 'memo_created',
        parameters: {
          'book_id': bookId,
        },
      );
    } catch (e) {
      // Analytics 에러는 무시
    }
  }

  // 프로필 업데이트 이벤트
  Future<void> logProfileUpdated() async {
    if (_analytics == null) return;
    try {
      await _analytics.logEvent(
        name: 'profile_updated',
      );
    } catch (e) {
      // Analytics 에러는 무시
    }
  }

  // 책 상태 변경 이벤트
  Future<void> logBookStatusChanged(String bookId, BookStatus status) async {
    if (_analytics == null) return;
    try {
      await _analytics.logEvent(
        name: 'book_status_changed',
        parameters: {
          'book_id': bookId,
          'status': status.value, // enum을 String으로 변환
        },
      );
    } catch (e) {
      // Analytics 에러는 무시
    }
  }

  // 페이지 뷰 이벤트
  Future<void> logScreenView(String screenName) async {
    if (_analytics == null) return;
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      // Analytics 에러는 무시
    }
  }

  // 클릭 이벤트
  Future<void> logButtonClick(String buttonName, String screenName) async {
    if (_analytics == null) return;
    try {
      await _analytics.logEvent(
        name: 'button_click',
        parameters: {
          'button_name': buttonName,
          'screen_name': screenName,
        },
      );
    } catch (e) {
      // Analytics 에러는 무시
    }
  }

  /// 범용 이벤트. 계측 확장용(온보딩 KPI 등).
  Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    if (_analytics == null) return;
    try {
      await _analytics.logEvent(name: name, parameters: params);
    } catch (e) {
      // Analytics 에러는 무시
    }
  }
}
