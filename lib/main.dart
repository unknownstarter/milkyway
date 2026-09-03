import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/env_config.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/session_restore.dart';
import 'core/router/app_routes.dart';
import 'package:inspire_blur/inspire_blur.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 인메모리 이미지 캐시 상한을 낮춰 백그라운드 메모리 압박(jetsam) 완화.
  // 기본 100MB/1000장 -> 45MB/300장. 디스크 캐시(cached_network_image)는 그대로라
  // 재다운로드 없음. 표시측은 이미 memCacheWidth로 표시폭 기준 축소 디코드함.
  PaintingBinding.instance.imageCache
    ..maximumSizeBytes = 45 << 20
    ..maximumSize = 300;

  // 오버플로우 에러를 상세 로그로 추적 (화면에는 표시됨)
  FlutterError.onError = (FlutterErrorDetails details) {
    final exceptionString = details.exception.toString().toLowerCase();
    final stackString = details.stack?.toString().toLowerCase() ?? '';
    
    // 오버플로우 관련 에러 감지 및 상세 로그 출력
    if (exceptionString.contains('overflowed') ||
        exceptionString.contains('renderflex') ||
        exceptionString.contains('renderbox') ||
        exceptionString.contains('size') ||
        exceptionString.contains('constraints') ||
        stackString.contains('overflowed') ||
        stackString.contains('renderflex') ||
        stackString.contains('renderbox') ||
        stackString.contains('size') ||
        stackString.contains('constraints')) {
      // 오버플로우 에러 상세 로그 출력 (print로도 출력하여 확실히 보이도록)
      print('\n');
      print('═══════════════════════════════════════════════════════════');
      print('🚨 OVERFLOW ERROR DETECTED 🚨');
      print('═══════════════════════════════════════════════════════════');
      print('Exception: ${details.exception}');
      print('Library: ${details.library}');
      print('Context: ${details.context}');
      
      developer.log(
        '═══════════════════════════════════════════════════════════',
        name: 'OverflowError',
      );
      developer.log(
        '🚨 OVERFLOW ERROR DETECTED 🚨',
        name: 'OverflowError',
      );
      developer.log(
        'Exception: ${details.exception}',
        name: 'OverflowError',
      );
      developer.log(
        'Library: ${details.library}',
        name: 'OverflowError',
      );
      developer.log(
        'Context: ${details.context}',
        name: 'OverflowError',
      );
      
      // 스택 트레이스에서 발생 위치 파악
      if (details.stack != null) {
        final stackLines = details.stack.toString().split('\n');
        print('\nStack Trace (first 50 lines):');
        developer.log(
          'Stack Trace (first 50 lines):',
          name: 'OverflowError',
        );
        // 모든 스택 라인 출력 (필터링 없이)
        for (int i = 0; i < stackLines.length && i < 50; i++) {
          final line = stackLines[i].trim();
          if (line.isNotEmpty) {
            print('  [$i] $line');
            developer.log(
              '  [$i] $line',
              name: 'OverflowError',
            );
          }
        }
        
        // home_screen.dart 관련 스택 찾기
        final homeScreenStack = stackLines.where((line) => 
          line.contains('home_screen.dart') || 
          line.contains('HomeScreen') ||
          line.contains('home_screen') ||
          line.contains('_build') ||
          line.contains('build')
        ).toList();
        if (homeScreenStack.isNotEmpty) {
          print('\n📍 Home Screen Related Stack:');
          developer.log(
            '📍 Home Screen Related Stack:',
            name: 'OverflowError',
          );
          for (final line in homeScreenStack) {
            print('  $line');
            developer.log(
              '  $line',
              name: 'OverflowError',
            );
          }
        }
      } else {
        print('\n⚠️ Stack trace is null');
        developer.log(
          '⚠️ Stack trace is null',
          name: 'OverflowError',
        );
      }
      
      print('═══════════════════════════════════════════════════════════');
      print('\n');
      developer.log(
        '═══════════════════════════════════════════════════════════',
        name: 'OverflowError',
      );
    }
    
    // 모든 에러는 기본 처리 (화면에 표시됨)
    FlutterError.presentError(details);
  };

  // ErrorWidget.builder에도 오버플로우 로그 추가
  ErrorWidget.builder = (FlutterErrorDetails details) {
    final exceptionString = details.exception.toString().toLowerCase();
    final stackString = details.stack?.toString().toLowerCase() ?? '';
    
    // 오버플로우 관련 에러 감지 및 로그 출력
    if (exceptionString.contains('overflowed') ||
        exceptionString.contains('renderflex') ||
        exceptionString.contains('renderbox') ||
        exceptionString.contains('size') ||
        exceptionString.contains('constraints') ||
        stackString.contains('overflowed') ||
        stackString.contains('renderflex') ||
        stackString.contains('renderbox') ||
        stackString.contains('size') ||
        stackString.contains('constraints')) {
      // ErrorWidget.builder에서도 로그 출력
      print('\n');
      print('═══════════════════════════════════════════════════════════');
      print('🚨 OVERFLOW ERROR (ErrorWidget.builder) 🚨');
      print('═══════════════════════════════════════════════════════════');
      print('Exception: ${details.exception}');
      print('Library: ${details.library}');
      print('Context: ${details.context}');
      
      if (details.stack != null) {
        final stackLines = details.stack.toString().split('\n');
        print('\nStack Trace (first 30 lines):');
        for (int i = 0; i < stackLines.length && i < 30; i++) {
          final line = stackLines[i];
          if (line.contains('.dart:')) {
            print('  [$i] $line');
          }
        }
        
        final homeScreenStack = stackLines.where((line) => 
          line.contains('home_screen.dart') || 
          line.contains('HomeScreen') ||
          line.contains('home_screen')
        ).toList();
        if (homeScreenStack.isNotEmpty) {
          print('\n📍 Home Screen Related Stack:');
          for (final line in homeScreenStack) {
            print('  $line');
          }
        }
      }
      
      print('═══════════════════════════════════════════════════════════');
      print('\n');
    }
    
    // 기본 에러 위젯 반환
    return Container(
      color: const Color(0xFF181818),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                '레이아웃 오류가 발생했습니다',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                details.exception.toString(),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontFamily: 'Pretendard',
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  };

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env 파일이 없어도 계속 진행 (환경 변수는 빈 값으로 설정됨)
    print(
        'Warning: .env file not found. Please create .env file from .env.example');
    print('Error details: $e');
  }

  timeago.setLocaleMessages('ko', timeago.KoMessages());

  final supabaseUrl = EnvConfig.supabaseUrl;
  final supabaseAnonKey = EnvConfig.supabaseAnonKey;

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    print(
        'Error: Supabase credentials are missing. Please check your .env file.');
    // 앱을 계속 실행하되, Supabase 초기화는 건너뜀
    // 실제로는 여기서 에러를 표시하거나 종료해야 할 수도 있습니다
  } else {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  await FirebaseService.initialize();

  // 글래스 앱바 progressive blur 셰이더 프리로드(첫 렌더 깜빡임 방지)
  await Inspire.warmUp();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  DeepLinkService? _deepLink;

  @override
  void initState() {
    super.initState();
    // 알림 탭 라우팅.
    NotificationService().onNotificationTapped = (data) {
      // memo_id가 있으면 메모 상세 화면으로 이동
      if (data.containsKey('memo_id')) {
        router.pushNamed(
          AppRoutes.memoDetailName,
          pathParameters: {'id': data['memo_id'] as String},
        );
      }
    };
    // 딥링크 수신 시작(콜드=pending 저장 후 스플래시가 소비, 웜=즉시 라우팅).
    _deepLink = DeepLinkService(ref)..init();
    // 라우트 변경마다 마지막 위치 저장(콜드스타트 시 스플래시가 복원 -> 재개처럼).
    router.routerDelegate.addListener(_saveLocation);
  }

  void _saveLocation() {
    SessionRestore.save(router.routerDelegate.currentConfiguration.uri.toString());
  }

  @override
  void dispose() {
    router.routerDelegate.removeListener(_saveLocation);
    _deepLink?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'milkyway',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(
                  minScaleFactor: 0.8,
                  maxScaleFactor: 1.2,
                ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
