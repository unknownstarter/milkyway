/// 알림 종류별 켜고 끄기 + 방해 금지 시간대 설정.
/// 행이 없는 사용자는 [defaults] (모두 켜짐) 로 본다.
class NotificationPreferences {
  final bool bookMemos;
  final bool comments;
  final bool quietHours;

  const NotificationPreferences({
    required this.bookMemos,
    required this.comments,
    required this.quietHours,
  });

  static const defaults = NotificationPreferences(
    bookMemos: true,
    comments: true,
    quietHours: true,
  );

  factory NotificationPreferences.fromRow(Map<String, dynamic> row) {
    return NotificationPreferences(
      bookMemos: row['book_memos'] as bool? ?? true,
      comments: row['comments'] as bool? ?? true,
      quietHours: row['quiet_hours'] as bool? ?? true,
    );
  }

  NotificationPreferences copyWith({
    bool? bookMemos,
    bool? comments,
    bool? quietHours,
  }) {
    return NotificationPreferences(
      bookMemos: bookMemos ?? this.bookMemos,
      comments: comments ?? this.comments,
      quietHours: quietHours ?? this.quietHours,
    );
  }
}

/// 알림 설정 화면 상태: 전체 스위치(users.notification_enabled) + 종류별 설정.
class NotificationSettingsState {
  final bool enabled;
  final NotificationPreferences preferences;

  const NotificationSettingsState({
    required this.enabled,
    required this.preferences,
  });

  NotificationSettingsState copyWith({
    bool? enabled,
    NotificationPreferences? preferences,
  }) {
    return NotificationSettingsState(
      enabled: enabled ?? this.enabled,
      preferences: preferences ?? this.preferences,
    );
  }
}
