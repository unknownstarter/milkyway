import '../router/app_routes.dart';

/// 알림이 열어야 할 화면. 이름 있는 라우트 + path 파라미터.
class NotificationTarget {
  const NotificationTarget(this.routeName, this.pathParameters);

  final String routeName;
  final Map<String, String> pathParameters;

  @override
  bool operator ==(Object other) =>
      other is NotificationTarget &&
      other.routeName == routeName &&
      other.pathParameters.length == pathParameters.length &&
      other.pathParameters.entries
          .every((e) => pathParameters[e.key] == e.value);

  @override
  int get hashCode => Object.hash(routeName, pathParameters.length);

  @override
  String toString() => 'NotificationTarget($routeName, $pathParameters)';
}

/// 푸시 data -> 이동할 화면. 콜드 스타트/백그라운드/포그라운드 로컬 탭이 모두 이 함수를 쓴다.
/// 책 메모 알림(type=book_memo)은 쌓인 메모를 보러 오는 알림이라 책 상세,
/// 그 밖에 memo_id 가 있으면 메모 상세, 없으면 null(이동 없음).
NotificationTarget? resolveNotificationTarget(Map<String, dynamic> data) {
  String? read(String key) {
    final v = data[key]?.toString();
    return (v == null || v.isEmpty) ? null : v;
  }

  final bookId = read('book_id');
  if (data['type'] == 'book_memo' && bookId != null) {
    return NotificationTarget(AppRoutes.bookDetailName, {'id': bookId});
  }
  final memoId = read('memo_id');
  if (memoId != null) {
    return NotificationTarget(AppRoutes.memoDetailName, {'id': memoId});
  }
  return null;
}
