import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

final log = Logger();

/// 백그라운드 메시지 핸들러 (최상위 함수여야 함)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log.i('백그라운드 메시지 수신: ${message.messageId}');
  log.i('제목: ${message.notification?.title}');
  log.i('내용: ${message.notification?.body}');
  log.i('데이터: ${message.data}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  late final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  
  /// 알림 탭 시 라우팅 콜백
  Function(Map<String, dynamic>)? onNotificationTapped;

  /// 앱이 꺼진 상태에서 알림을 눌러 실행됐을 때의 데이터.
  /// 이동 콜백/라우터가 준비되기 전이라 보관만 하고, 스플래시가 세션 확인 뒤 [dispatchPendingColdStart] 로 소비한다.
  Map<String, dynamic>? _pendingColdStart;

  bool get hasPendingColdStart => _pendingColdStart != null;

  @visibleForTesting
  void setPendingColdStart(Map<String, dynamic>? data) => _pendingColdStart = data;

  /// 보관된 콜드 스타트 알림을 이동 콜백으로 한 번 내보낸다. 보낸 경우 true.
  /// 콜백이 아직 없으면 보관을 유지한다.
  bool dispatchPendingColdStart() {
    final data = _pendingColdStart;
    final cb = onNotificationTapped;
    if (data == null || cb == null) return false;
    _pendingColdStart = null;
    cb(data);
    return true;
  }

  /// 알림 권한 상태 확인
  Future<NotificationSettings> getNotificationSettings() async {
    return await _messaging.getNotificationSettings();
  }

  /// 알림 권한 요청
  Future<bool> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      log.e('알림 권한 요청 실패: $e');
      return false;
    }
  }

  /// FCM 토큰 획득 및 Supabase에 저장
  Future<String?> registerToken() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        log.w('사용자가 로그인하지 않았습니다.');
        return null;
      }

      final token = await _messaging.getToken();
      if (token == null) {
        log.w('FCM 토큰을 획득할 수 없습니다.');
        return null;
      }

      log.i('FCM 토큰 획득: $token');

      // Supabase users 테이블에 토큰 저장
      await Supabase.instance.client
          .from('users')
          .update({'fcm_token': token})
          .eq('id', user.id);

      log.i('FCM 토큰 저장 완료');

      // 토큰 갱신 리스너 설정
      _messaging.onTokenRefresh.listen((newToken) async {
        log.i('FCM 토큰 갱신: $newToken');
        if (user.id.isNotEmpty) {
          await Supabase.instance.client
              .from('users')
              .update({'fcm_token': newToken})
              .eq('id', user.id);
        }
      });

      return token;
    } catch (e) {
      log.e('FCM 토큰 등록 실패: $e');
      return null;
    }
  }

  /// 알림 초기화
  Future<void> initialize() async {
    if (_isInitialized) {
      log.w('NotificationService가 이미 초기화되었습니다.');
      return;
    }

    try {
      // 로컬 알림 초기화
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: onLocalNotificationResponse,
      );

      // 백그라운드 메시지 핸들러 설정
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 포그라운드 메시지 핸들러 설정
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 알림 탭 핸들러 설정
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // 앱이 종료된 상태에서 알림 탭으로 앱 실행된 경우 처리.
      // iOS 26 시뮬레이터 등 APNS 미지원 환경에서 무한 hang 방지 위해 3s timeout.
      // 실기기는 보통 100ms 이내 응답.
      final initialMessage = await _messaging.getInitialMessage().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          log.w('getInitialMessage timeout (iOS 시뮬레이터 또는 APNS 미준비)');
          return null;
        },
      );
      if (initialMessage != null) {
        // 이 시점엔 이동 콜백/라우터가 없다(runApp 전). 보관했다가 스플래시가 소비한다.
        _pendingColdStart = Map<String, dynamic>.from(initialMessage.data);
      }

      _isInitialized = true;
      log.i('NotificationService 초기화 완료');
    } catch (e) {
      log.e('NotificationService 초기화 실패: $e');
    }
  }

  /// 포그라운드 메시지 처리
  void _handleForegroundMessage(RemoteMessage message) {
    log.i('포그라운드 메시지 수신: ${message.messageId}');
    log.i('제목: ${message.notification?.title}');
    log.i('내용: ${message.notification?.body}');
    log.i('데이터: ${message.data}');

    // 로컬 알림 표시
    if (message.notification != null) {
      _showLocalNotification(message);
    }
  }

  /// 로컬 알림 표시
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      '알림',
      channelDescription: 'milkyway 앱의 중요한 알림',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  /// 알림 탭 처리
  void _handleNotificationTap(RemoteMessage message) {
    log.i('알림 탭: ${message.data}');
    if (onNotificationTapped != null) {
      onNotificationTapped!(message.data);
    }
  }

  /// 로컬 알림 탭 처리
  @visibleForTesting
  void onLocalNotificationResponse(NotificationResponse response) {
    log.i('로컬 알림 탭: ${response.payload}');
    final payload = response.payload;
    final cb = onNotificationTapped;
    if (payload == null || cb == null) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) cb(decoded);
    } catch (e) {
      log.e('알림 payload 파싱 실패: $e');
    }
  }

  /// 알림 채널 생성 (Android)
  Future<void> createNotificationChannel() async {
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'high_importance_channel',
        '알림',
        description: 'milkyway 앱의 중요한 알림',
        importance: Importance.high,
      );

      final androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.createNotificationChannel(androidChannel);
    }
  }
}

