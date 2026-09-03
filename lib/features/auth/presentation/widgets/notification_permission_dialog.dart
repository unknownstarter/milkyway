import 'package:flutter/material.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../l10n/app_localizations.dart';

/// 알림 권한 요청 다이얼로그
class NotificationPermissionDialog extends StatelessWidget {
  const NotificationPermissionDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const NotificationPermissionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: Text(
        AppL10n.of(context).authNotificationPermissionTitle,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      content: Text(
        AppL10n.of(context).authNotificationPermissionBody,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w300,
          fontSize: 16,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            AppL10n.of(context).authNotificationPermissionLater,
            style: const TextStyle(
              color: Color(0xFF838383),
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            final notificationService = NotificationService();
            final granted = await notificationService.requestPermission();
            if (granted) {
              // 권한이 승인되면 FCM 토큰 등록
              await notificationService.registerToken();
            }
            if (context.mounted) {
              Navigator.of(context).pop(granted);
            }
          },
          child: Text(
            AppL10n.of(context).authNotificationPermissionAllow,
            style: const TextStyle(
              color: Color(0xFF48FF00),
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

