import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/core/services/notification_service.dart';

void main() {
  late NotificationService svc;
  late List<Map<String, dynamic>> taps;

  setUp(() {
    svc = NotificationService();
    svc.setPendingColdStart(null);
    taps = [];
    svc.onNotificationTapped = taps.add;
  });

  tearDown(() => svc.onNotificationTapped = null);

  test('pending 이 있으면 콜백 등록 뒤 이동 요청이 한 번 나간다', () {
    svc.onNotificationTapped = null;
    svc.setPendingColdStart({'memo_id': 'm1', 'type': 'new_comment'});
    expect(svc.dispatchPendingColdStart(), isFalse, reason: '콜백 없으면 보관 유지');
    expect(svc.hasPendingColdStart, isTrue);

    svc.onNotificationTapped = taps.add;
    expect(svc.dispatchPendingColdStart(), isTrue);
    expect(svc.dispatchPendingColdStart(), isFalse);
    expect(taps, [
      {'memo_id': 'm1', 'type': 'new_comment'}
    ]);
  });

  test('pending 이 없으면 아무것도 보내지 않는다', () {
    expect(svc.dispatchPendingColdStart(), isFalse);
    expect(taps, isEmpty);
  });

  test('로컬 알림 payload 는 JSON 으로 읽는다', () {
    svc.onLocalNotificationResponse(const NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
      payload: '{"memo_id":"m2","type":"new_public_memo"}',
    ));
    expect(taps.single['memo_id'], 'm2');
  });

  test('깨진 payload 는 무시한다', () {
    svc.onLocalNotificationResponse(const NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
      payload: '{memo_id: m2}',
    ));
    expect(taps, isEmpty);
  });
}
