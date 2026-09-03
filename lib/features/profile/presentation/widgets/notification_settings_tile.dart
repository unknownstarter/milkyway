import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_settings/app_settings.dart';

class NotificationSettingsTile extends ConsumerStatefulWidget {
  const NotificationSettingsTile({super.key});

  @override
  ConsumerState<NotificationSettingsTile> createState() =>
      _NotificationSettingsTileState();
}

class _NotificationSettingsTileState
    extends ConsumerState<NotificationSettingsTile> {
  bool _notificationEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('users')
          .select('notification_enabled')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _notificationEnabled = response['notification_enabled'] ?? true;
        });
      }
    } catch (e) {
      // 에러 무시
    }
  }

  Future<void> _toggleNotification(bool value) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client
          .from('users')
          .update({'notification_enabled': value})
          .eq('id', user.id);

      if (mounted) {
        setState(() {
          _notificationEnabled = value;
          _isLoading = false;
        });
      }

      // 알림을 켤 때 권한 확인 및 요청
      if (value) {
        final notificationService = NotificationService();
        final settings = await notificationService.getNotificationSettings();

        if (settings.authorizationStatus ==
            AuthorizationStatus.notDetermined) {
          // 권한이 없으면 요청
          final granted = await notificationService.requestPermission();
          if (granted) {
            await notificationService.registerToken();
          } else if (mounted) {
            // 권한 거부 시 설정 화면으로 이동 안내
            _showPermissionDeniedDialog();
          }
        } else if (settings.authorizationStatus ==
                AuthorizationStatus.authorized ||
            settings.authorizationStatus ==
                AuthorizationStatus.provisional) {
          // 권한이 있으면 토큰 등록
          await notificationService.registerToken();
        } else if (mounted) {
          // 권한이 거부된 경우 설정 화면으로 이동 안내
          _showPermissionDeniedDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppL10n.of(context).profileNotificationSaveFailed),
            backgroundColor: const Color(0xFF242424),
          ),
        );
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          AppL10n.of(context).profileNotificationPermissionTitle,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        content: Text(
          AppL10n.of(context).profileNotificationPermissionBody,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w300,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppL10n.of(context).commonCancel,
              style: const TextStyle(
                color: Color(0xFF838383),
                fontFamily: 'Pretendard',
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              AppSettings.openAppSettings();
            },
            child: Text(
              AppL10n.of(context).profileOpenSettings,
              style: const TextStyle(
                color: Color(0xFF48FF00),
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 프로필 메뉴의 _menuRow 와 동일한 구성(아이콘 20/textSecondary + body + 우측 trailing).
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.notifications_outlined,
              size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Text(AppL10n.of(context).profileMenuNotification,
              style: AppTypography.body),
          const Spacer(),
          _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.accentGreen),
                )
              : Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: _notificationEnabled,
                    onChanged: _toggleNotification,
                    activeColor: Colors.black,
                    activeTrackColor: AppColors.accentGreen,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
        ],
      ),
    );
  }
}

