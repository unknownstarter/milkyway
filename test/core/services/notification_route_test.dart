import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/core/router/app_routes.dart';
import 'package:whatif_milkyway_app/core/services/notification_route.dart';

void main() {
  group('서버가 실제로 보내는 data 모양', () {
    test('book_memo -> 책 상세', () {
      final t = resolveNotificationTarget(
          {'type': 'book_memo', 'book_id': 'b1', 'memo_id': 'm1'});
      expect(t, const NotificationTarget(AppRoutes.bookDetailName, {'id': 'b1'}));
    });
    test('new_comment -> 메모 상세', () {
      final t =
          resolveNotificationTarget({'type': 'new_comment', 'memo_id': 'm1'});
      expect(t, const NotificationTarget(AppRoutes.memoDetailName, {'id': 'm1'}));
    });
    test('빈 data -> 이동 없음', () {
      expect(resolveNotificationTarget({}), isNull);
    });
    test('book_memo 인데 book_id 없으면 memo_id 로 폴백', () {
      final t = resolveNotificationTarget({'type': 'book_memo', 'memo_id': 'm1'});
      expect(t?.routeName, AppRoutes.memoDetailName);
    });
  });

  group('app_router.dart 정의와 대조', () {
    final router = File('lib/core/router/app_router.dart').readAsStringSync();
    test('책 상세 라우트 이름/파라미터 키', () {
      expect(router, contains('name: AppRoutes.bookDetailName'));
      expect(router, contains("path: '\${AppRoutes.bookDetail}/:id'"));
      expect(AppRoutes.bookDetailName, 'book-detail');
    });
    test('메모 상세 라우트 이름/파라미터 키', () {
      expect(router, contains('name: AppRoutes.memoDetailName'));
      expect(router, contains("path: '\${AppRoutes.memoDetail}/:id'"));
      expect(AppRoutes.memoDetailName, 'memo-detail');
    });
  });
}
