import 'package:shared_preferences/shared_preferences.dart';

/// 기기 로컬(SharedPreferences)에 '봤음' 시각을 기록하는 데이터 계층 서비스.
///
/// 2가지 granularity:
///  - 책별 last-viewed: 책 상세를 열면 갱신 → 홈 스토리 링 / 책탭 썸네일 빨간 점 판정
///  - 탭별 last-seen: 그 탭에 들어가면 갱신 → 하단 네비 빨간 점 판정
///
/// 모든 값은 ISO8601 문자열. presentation은 직접 접근 금지, provider 경유.
class SeenTracker {
  /// 책별 키 접두사. 기존 BookViewTracker와 동일하게 유지해 사용자 이력 보존.
  static const _bookPrefix = 'book_viewed_';
  static const _tabPrefix = 'seen_tab_';

  /// 탭 키 상수.
  static const tabBooks = 'books';
  static const tabMemos = 'memos';

  String _bookKey(String bookId) => '$_bookPrefix$bookId';
  String _tabKey(String tabKey) => '$_tabPrefix$tabKey';

  // ---- 책별 ----

  Future<void> markBookViewed(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bookKey(bookId), DateTime.now().toIso8601String());
  }

  Future<DateTime?> bookLastViewed(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_bookKey(bookId));
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<Map<String, DateTime>> allBookViewed(List<String> bookIds) async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, DateTime>{};
    for (final id in bookIds) {
      final raw = prefs.getString(_bookKey(id));
      if (raw == null) continue;
      final dt = DateTime.tryParse(raw);
      if (dt != null) result[id] = dt;
    }
    return result;
  }

  // ---- 탭별 ----

  Future<void> markTabSeen(String tabKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tabKey(tabKey), DateTime.now().toIso8601String());
  }

  Future<DateTime?> tabLastSeen(String tabKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tabKey(tabKey));
    return raw == null ? null : DateTime.tryParse(raw);
  }
}
