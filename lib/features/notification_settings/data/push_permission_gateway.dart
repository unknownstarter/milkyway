import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/services/notification_service.dart';

enum PushPermission { granted, denied, notDetermined }

/// 휴대폰 알림 권한 확인/요청. NotificationService 를 감싸 화면이 직접 FCM 을 만지지 않게 한다.
class PushPermissionGateway {
  Future<PushPermission> status() async {
    try {
      final s = await NotificationService().getNotificationSettings();
      switch (s.authorizationStatus) {
        case AuthorizationStatus.authorized:
        case AuthorizationStatus.provisional:
          return PushPermission.granted;
        case AuthorizationStatus.notDetermined:
          return PushPermission.notDetermined;
        case AuthorizationStatus.denied:
          return PushPermission.denied;
      }
    } catch (_) {
      return PushPermission.granted; // 확인 불가면 안내를 띄우지 않는다
    }
  }

  /// 알림을 켠 직후 호출. 권한이 있으면 토큰을 등록하고 true, 끝내 없으면 false.
  Future<bool> ensureGrantedAndRegister() async {
    final service = NotificationService();
    var current = await status();
    if (current == PushPermission.notDetermined) {
      final granted = await service.requestPermission();
      current = granted ? PushPermission.granted : PushPermission.denied;
    }
    if (current == PushPermission.granted) {
      await service.registerToken();
      return true;
    }
    return false;
  }
}
