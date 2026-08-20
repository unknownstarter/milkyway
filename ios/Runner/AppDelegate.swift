import Flutter
import UIKit

// Xcode 26 scene 라이프사이클을 '되돌리지 않고' 제대로 채택한다(momo 앱과 동일 전략, 2026-08-20).
// 이렇게 하면 flutter build ipa(CLI)가 매 빌드마다 자동 마이그레이션으로 소스를
// 오염시키던 문제가 사라지고(이미 scene 상태라 바꿀 게 없음) 정상 IPA가 만들어진다.
//
// 플러그인 등록은 scene 환경의 표준 위치인 didInitializeImplicitFlutterEngine 에서 수행.
// OAuth 콜백(Google 역클라이언트ID scheme)은 Info.plist 의 FlutterSceneDelegate 가
// scene(openURLContexts:) 로 받아 Flutter 플러그인(google_sign_in) 체인으로 전달한다.
// Apple 로그인은 네이티브(ASAuthorizationController)라 URL 콜백 없이 작동.
// 아래 application(open:) 은 일부 iOS 환경에서 콜백이 AppDelegate 로 오는 경우의 이중방어.
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 푸시 알림(FCM) 을 위한 APNs 등록.
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // OAuth 콜백 이중방어: SceneDelegate 가 아닌 AppDelegate 로 openURL 이 오는
  // 일부 환경에서도 Flutter 플러그인(google_sign_in 등) 체인으로 전달되게 한다.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    return super.application(app, open: url, options: options)
  }
}
