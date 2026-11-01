import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/push_permission_gateway.dart';
import '../../data/repositories/notification_preferences_repository.dart';
import '../../domain/notification_preferences.dart';

final notificationPreferencesRepositoryProvider =
    Provider<NotificationPreferencesRepository>((ref) {
      return NotificationPreferencesRepository(Supabase.instance.client);
    });

final pushPermissionGatewayProvider = Provider<PushPermissionGateway>(
  (ref) => PushPermissionGateway(),
);

/// 휴대폰 알림 권한 상태. 설정 앱에서 돌아오면 invalidate 로 다시 읽는다.
final pushPermissionProvider = FutureProvider.autoDispose<PushPermission>((
  ref,
) {
  return ref.watch(pushPermissionGatewayProvider).status();
});

enum NotificationSwitch { bookMemos, comments, quietHours }

class NotificationSettingsNotifier
    extends AutoDisposeAsyncNotifier<NotificationSettingsState> {
  NotificationPreferencesRepository get _repo =>
      ref.read(notificationPreferencesRepositoryProvider);

  @override
  Future<NotificationSettingsState> build() async {
    final repo = ref.watch(notificationPreferencesRepositoryProvider);
    final enabled = await repo.getEnabled();
    final prefs = await repo.getPreferences();
    return NotificationSettingsState(enabled: enabled, preferences: prefs);
  }

  /// 전체 스위치. 실패하면 이전 상태로 되돌리고 false.
  Future<bool> setEnabled(bool value) async {
    final prev = state.valueOrNull;
    if (prev == null) return false;
    state = AsyncData(prev.copyWith(enabled: value));
    try {
      await _repo.setEnabled(value);
    } catch (_) {
      state = AsyncData(prev);
      return false;
    }
    return true;
  }

  /// 권한이 필요한 상황이면 false (화면이 안내를 띄운다).
  Future<bool> ensurePermission() async {
    final granted = await ref
        .read(pushPermissionGatewayProvider)
        .ensureGrantedAndRegister();
    ref.invalidate(pushPermissionProvider);
    return granted;
  }

  /// 종류별 스위치. 행이 없으면 이 순간 처음 upsert 된다. 실패 시 되돌린다.
  Future<bool> setSwitch(NotificationSwitch which, bool value) async {
    final prev = state.valueOrNull;
    if (prev == null) return false;
    final p = prev.preferences;
    final next = switch (which) {
      NotificationSwitch.bookMemos => p.copyWith(bookMemos: value),
      NotificationSwitch.comments => p.copyWith(comments: value),
      NotificationSwitch.quietHours => p.copyWith(quietHours: value),
    };
    state = AsyncData(prev.copyWith(preferences: next));
    try {
      await _repo.savePreferences(next);
    } catch (_) {
      state = AsyncData(prev);
      return false;
    }
    return true;
  }
}

final notificationSettingsProvider =
    AsyncNotifierProvider.autoDispose<
      NotificationSettingsNotifier,
      NotificationSettingsState
    >(NotificationSettingsNotifier.new);
