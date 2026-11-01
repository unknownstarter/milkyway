import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/widgets/design/app_dialog.dart';
import '../../../../core/presentation/widgets/design/app_snackbar.dart';
import '../../../../core/presentation/widgets/design/async_view.dart';
import '../../../../core/presentation/widgets/design/glass_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/push_permission_gateway.dart';
import '../../domain/notification_preferences.dart';
import '../providers/notification_settings_providers.dart';
import '../widgets/notification_switch_row.dart';

/// 프로필 > 알림. 맨 위 전체 스위치(users.notification_enabled) 아래에
/// 책 메모 / 댓글 / 방해 금지 시간 스위치 셋. 전체를 끄면 셋은 비활성.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 휴대폰 설정에서 돌아오면 권한 안내를 다시 판정한다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(pushPermissionProvider);
    }
  }

  void _toast(String msg) {
    if (mounted) showAppSnackBar(context, msg);
  }

  Future<void> _toggleAll(bool value) async {
    final notifier = ref.read(notificationSettingsProvider.notifier);
    final l10n = AppL10n.of(context);
    final ok = await notifier.setEnabled(value);
    if (!ok) return _toast(l10n.profileNotificationSaveFailed);
    if (value && !await notifier.ensurePermission() && mounted) {
      final open = await showAppConfirm(
        context,
        title: l10n.profileNotificationPermissionTitle,
        message: l10n.profileNotificationPermissionBody,
        confirmText: l10n.profileOpenSettings,
      );
      if (open) AppSettings.openAppSettings();
    }
  }

  Future<void> _toggle(NotificationSwitch which, bool value) async {
    final msg = AppL10n.of(context).profileNotificationSaveFailed;
    final ok = await ref
        .read(notificationSettingsProvider.notifier)
        .setSwitch(which, value);
    if (!ok) _toast(msg);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final settings = ref.watch(notificationSettingsProvider);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      extendBodyBehindAppBar: true,
      appBar: glassAppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.notifSettingsTitle, style: AppTypography.subtitle),
      ),
      body: ListView(
        padding: EdgeInsets.only(top: glassTopPadding(context), bottom: 32),
        children: [
          AsyncView<NotificationSettingsState>(
            value: settings,
            loadingHeight: 240,
            onRetry: () => ref.invalidate(notificationSettingsProvider),
            builder: _buildBody,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(NotificationSettingsState s) {
    final l10n = AppL10n.of(context);
    final p = s.preferences;
    final denied =
        ref.watch(pushPermissionProvider).valueOrNull == PushPermission.denied;
    return Column(
      children: [
        if (denied) _permissionNotice(l10n),
        _card([
          NotificationSwitchRow(
            title: l10n.notifSettingsAll,
            value: s.enabled,
            onChanged: _toggleAll,
          ),
        ]),
        _card([
          NotificationSwitchRow(
            title: l10n.notifSettingsBookMemos,
            description: l10n.notifSettingsBookMemosDesc,
            value: p.bookMemos,
            enabled: s.enabled,
            onChanged: (v) => _toggle(NotificationSwitch.bookMemos, v),
          ),
          const Divider(color: AppColors.divider, height: 1),
          NotificationSwitchRow(
            title: l10n.notifSettingsComments,
            value: p.comments,
            enabled: s.enabled,
            onChanged: (v) => _toggle(NotificationSwitch.comments, v),
          ),
          const Divider(color: AppColors.divider, height: 1),
          NotificationSwitchRow(
            title: l10n.notifSettingsQuiet,
            description: l10n.notifSettingsQuietDesc,
            value: p.quietHours,
            enabled: s.enabled,
            onChanged: (v) => _toggle(NotificationSwitch.quietHours, v),
          ),
        ]),
      ],
    );
  }

  Widget _permissionNotice(AppL10n l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.notifSettingsPermissionOff,
              style: AppTypography.body,
            ),
          ),
          TextButton(
            onPressed: AppSettings.openAppSettings,
            child: Text(
              l10n.notifSettingsOpenPhoneSettings,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.accentGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
