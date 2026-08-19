# 📚 학습 내용 및 레슨런 (Lessons Learned)

## 📋 개요

이 문서는 Milkyway 앱 개발 과정에서 배운 교훈과 실수를 기록하여 향후 유사한 문제를 방지하고, 더 나은 개발을 위한 가이드로 활용합니다.

**최종 업데이트:** 2026-07-01  
**작성자:** AI Assistant  
**검토자:** 개발팀

---

## 🚨 2026-07-01: Xcode 26 자동 마이그레이션 함정 — Google/Apple 로그인 전면 마비

### 문제 상황
- 새 Mac (Xcode 26.5 / iOS 26 시뮬레이터 / macOS Tahoe 26.4) 에서 코드 받아 빌드 후 시뮬레이터로 실행
- 1차 증상: 검은 화면에서 안 빠져나옴 (별개 이슈: `getInitialMessage()` hang — timeout 으로 해결)
- 2차 증상: 검은 화면 해결됐는데 **Google 로그인 버튼 누르면 "로그인에 실패했습니다. 다시 시도해 주세요." 토스트만 뜸**
- 라이브 앱 (App Store / Play Store, `v0.1.0+16`) 은 정상 작동 중 → 코드 회귀 아님

### 원인 분석
**Xcode 26 가 프로젝트 첫 오픈 시 자동 마이그레이션으로 iOS 26 scene-based architecture 를 적용했음.** 구체적으로:

1. `ios/Runner/Info.plist` 에 `UIApplicationSceneManifest` 추가 — `UISceneDelegateClassName = FlutterSceneDelegate` 로 scene delegate 지정
2. `ios/Runner/AppDelegate.swift` 변경 — 클래스에 `FlutterImplicitEngineDelegate` 채택, 플러그인 등록을 `didFinishLaunchingWithOptions` 에서 `didInitializeImplicitFlutterEngine` 으로 이동

**OAuth URL 콜백 흐름이 깨진 메커니즘**:
```
[before]  Google 인증 → 리다이렉트(com.googleusercontent.apps...://) 
          → iOS → AppDelegate.application(_:open:options:) 
          → google_sign_in 플러그인 처리 → 로그인 성공

[after]   Google 인증 → 리다이렉트(com.googleusercontent.apps...://) 
          → iOS (scene manifest 보고) → FlutterSceneDelegate.scene(_:openURLContexts:) 
          → google_sign_in 플러그인 후킹 안 됨 → 콜백 유실 → 로그인 실패
```

`google_sign_in` 같은 구형 Flutter 플러그인은 `AppDelegate` 의 URL 콜백에 후킹돼 있어서, scene 으로 라우팅이 바뀌면 콜백을 받지 못함. **`sign_in_with_apple` / 딥링크 / `app_links` 등 URL 콜백 의존 플러그인 전부 잠재 영향권**.

### 해결 과정
1. `AppDelegate.swift` 를 라이브와 동일한 구조로 복원:
   ```swift
   @objc class AppDelegate: FlutterAppDelegate {
     override func application(...) -> Bool {
       GeneratedPluginRegistrant.register(with: self)
       return super.application(...)
     }
   }
   ```
2. `Info.plist` 의 `UIApplicationSceneManifest` 절 완전 삭제
3. Clean Build → Run → Google 로그인 정상 복구 확인

### 교훈 (반드시 지킬 것)
1. **Xcode 가 "Modernize Project" / scene manifest 자동 추가 같은 마이그레이션 제안하면 Flutter 프로젝트에선 절대 수락하지 말 것.** Xcode 26+ 가 새 머신/새 Xcode 에서 프로젝트 첫 오픈 시 조용히 자동 적용할 수도 있으므로 `git diff ios/` 로 변경 여부 확인 필수.
2. **신규 디바이스에서 첫 빌드 후 OAuth/딥링크/푸시탭 기능을 반드시 손으로 테스트** — 빌드 통과해도 URL 콜백은 런타임 시점에만 깨짐. 자동 테스트로는 못 잡음.
3. **iOS 마이그레이션 변경은 `git diff` 로 무조건 라이브 빌드 머신과 비교 후 커밋.** 자동 변경이라도 검토 없이 통과시키면 라이브 사용자에게 회귀로 직격.
4. Flutter 가 scene-based 를 공식 지원하는 시점까지는 라이브에서 사용하지 말 것 (현재 `Flutter 3.41.7` 시점 기준 `FlutterSceneDelegate` 가 모든 플러그인의 URL 콜백을 전달하지 않음).

### 참고
- 영향 받은 파일: `ios/Runner/Info.plist`, `ios/Runner/AppDelegate.swift`
- 변경 추가된 커밋: `12771a3` (이번 세션에서 추가 커밋으로 되돌림)
- 관련 플러그인: `google_sign_in ^6.2.1`, `sign_in_with_apple ^7.0.1`, `firebase_messaging`, `app_links`

---

## 🎯 2026-01-09: 캐시 무효화 및 클린 아키텍처 개선

### 문제 상황
1. **책 재등록 시 캐시 문제**: 신규 회원이 책을 저장 → 삭제 → 재등록 시 "Cannot coerce the result to a single JSON object (PGRST116)" 에러 발생
2. **메모 작성 후 캐시 문제**: 책 상세에서 메모 작성 시 "나의 메모"에는 표시되지만 "모든 메모"에는 표시되지 않음
3. **코드 중복 및 아키텍처 문제**: 여러 provider에서 동일한 무효화 로직 반복, Presentation 레이어 간 강한 결합

### 원인 분석
1. **책 재등록 문제**:
   - 책 삭제 후 재등록 시 `bookDetailProvider`가 무효화되지 않아 이전 캐시 사용
   - `user_books` 연결 생성 전에 책 상세 조회 시도 (타이밍 이슈)
   - 고정 딜레이 재시도로 인한 비효율성

2. **메모 작성 문제**:
   - `memoFormProvider`에서 `paginatedPublicBookMemosProvider` 무효화 누락
   - `ResponseCache` 무효화 누락

3. **아키텍처 문제**:
   - 4개 메서드에서 동일한 무효화 로직 반복 (약 160줄 중복)
   - `memo_form_provider`가 다른 provider들을 직접 invalidate (강한 결합)
   - `ResponseCache`를 Presentation 레이어에서 직접 사용

### 해결 과정
1. **책 상세 Provider 개선**:
   - Exponential backoff 적용: 300ms → 600ms → 1200ms (최대 2초)
   - 에러 처리 범위 확대: PGRST116 외에도 PGRST301, "0 rows", "not found" 등
   - 책 등록 시 `bookDetailProvider` 무효화 추가

2. **메모 작성 캐시 무효화 수정**:
   - `memoFormProvider`의 모든 메서드에 `paginatedPublicBookMemosProvider` 무효화 추가
   - `ResponseCache` 무효화 추가
   - visibility에 따른 조건부 무효화 적용 (private 메모는 공개 메모 provider 무효화 불필요)

3. **코드 리팩토링 및 아키텍처 개선**:
   - 중앙화된 무효화 함수 `invalidateMemoProviders` 제공 (`memo_provider.dart`)
   - `memo_form_provider`가 중앙화된 함수 사용 (중복 제거)
   - `createMemoProvider`, `updateMemoProvider`, `deleteMemoProvider`도 중앙화된 함수 사용
   - `ResponseCache` 직접 사용 제거 (Presentation 레이어에서)

### 배운 점
1. **Exponential Backoff의 중요성**:
   - 고정 딜레이보다 exponential backoff가 더 효율적
   - 타이밍 이슈 해결에 효과적
   - 프로젝트에 `RetryHelper`가 있으면 활용 고려

2. **캐시 무효화의 완전성**:
   - 데이터 변경 시 관련된 모든 provider를 무효화해야 함
   - 특히 페이지네이션 provider (`paginatedPublicBookMemosProvider`) 무효화 누락 주의
   - `ResponseCache`와 provider 무효화를 함께 수행해야 함

3. **조건부 무효화의 효율성**:
   - Private 메모 생성 시 공개 메모 provider 무효화 불필요
   - visibility 정보를 활용한 선택적 무효화로 성능 개선

4. **중앙화된 함수의 가치**:
   - 중복 코드 제거 (160줄 → 30줄)
   - 일관성 보장 (모든 메모 변경 시 동일한 무효화 로직)
   - 유지보수성 향상 (한 곳에서 수정)
   - 클린 아키텍처 개선 (의존성 감소)

5. **클린 아키텍처 원칙**:
   - Presentation 레이어 간 직접 의존 최소화
   - Core 유틸리티는 가능한 한 한 곳에서만 사용
   - 중앙화된 함수로 결합도 감소

### 실수 및 개선 사항
1. **초기 구현 시 누락**:
   - 책 재등록 시 `bookDetailProvider` 무효화 누락
   - 메모 작성 시 `paginatedPublicBookMemosProvider` 무효화 누락
   - → **체크리스트 필요**: 데이터 변경 시 관련 provider 모두 무효화 확인

2. **코드 중복 발견 지연**:
   - 4개 메서드에서 동일한 로직 반복했으나 리팩토링 지연
   - → **코드 리뷰 시 중복 코드 체크 필수**

3. **아키텍처 개선 지연**:
   - Presentation 레이어 간 직접 의존을 초기에 발견하지 못함
   - → **의존성 분석 도구 활용 고려**

### 향후 개선 방안
1. **자동화된 무효화 패턴**:
   - 데이터 변경 시 관련 provider를 자동으로 무효화하는 패턴 고려
   - 이벤트 기반 아키텍처 도입 검토

2. **테스트 커버리지**:
   - 캐시 무효화 로직에 대한 단위 테스트 추가
   - 통합 테스트로 전체 플로우 검증

3. **모니터링**:
   - 캐시 무효화 누락을 감지하는 로깅 추가
   - 개발 환경에서 경고 표시

---

## 🎯 2026-01-02: 메모 신고 기능 구현 (Google Play Store 가족 정책 준수)

### 문제 상황
Google Play Store에서 앱이 거절되었습니다. 소셜 기능 관련 가족 정책 요구사항을 준수하지 않는다는 이유였습니다:
- 아동 사용자가 자유 형식의 미디어나 정보를 교환할 수 있도록 허용하기 전에 안전 알림 제공하지 않음
- 개인 정보 교환 시 성인 인증 요구하지 않음
- 보호자가 소셜 기능을 관리할 수 있는 수단 제공하지 않음

### 원인 분석
- 공개 메모 기능이 있으나, 부적절한 콘텐츠를 신고할 수 있는 기능이 없었음
- 사용자가 신고한 콘텐츠를 숨기는 기능이 없었음
- Google Play Store의 가족 정책 요구사항을 충족하지 못함

### 해결 과정
1. **데이터베이스 마이그레이션**:
   - `memo_reports` 테이블 생성: 신고 정보 저장 (memo_id, reporter_id, reason, description)
   - `user_hidden_memos` 테이블 생성: 신고한 사용자에게 메모 숨기기
   - `report_reason_type` enum 생성: 7가지 신고 사유 (스팸, 부적절한 콘텐츠, 혐오 발언, 성적 콘텐츠, 폭력적 콘텐츠, 저작권 침해, 기타)
   - RLS 정책 설정: 사용자는 자신이 신고한 내용만 조회 가능

2. **Repository 및 Provider 구현**:
   - `MemoReportRepository`: 신고 생성, 숨긴 메모 ID 조회
   - `hiddenMemoIdsProvider`: 사용자가 숨긴 메모 ID 목록 캐싱
   - `reportMemoProvider`: 신고 처리 및 자동 리로딩

3. **UI 구현**:
   - 공개 메모 카드 우측 상단에 케밥 메뉴 추가 (공개 메모이고 다른 유저의 메모일 때만)
   - 신고 바텀시트: 신고 사유 선택 및 제출
   - 신고 완료 후 즉시 메모 리스트 리로딩 및 필터링

4. **필터링 로직**:
   - `memo_list_view.dart`에서 `hiddenMemoIdsProvider`를 watch하여 자동 필터링
   - 신고한 메모는 해당 사용자에게만 안보이게 처리 (메모는 삭제되지 않음)

5. **패딩 구조 수정**:
   - 케밥 메뉴 추가 시 이중 패딩 문제 발생
   - `BookDetailMemoCard`의 외부 패딩 제거, 원래 구조 유지
   - 케밥 메뉴는 `Positioned`로 절대 위치 배치

### 배운 점
- **Google Play Store 정책 준수**: 소셜 기능이 있는 앱은 반드시 콘텐츠 신고 기능을 제공해야 함
- **사용자 경험**: 신고 완료 후 즉시 리로딩하여 사용자가 신고한 콘텐츠가 사라지는 것을 확인할 수 있도록 함
- **데이터 무결성**: 메모는 삭제되지 않고, 신고한 사용자에게만 숨김 처리하여 다른 사용자에게는 계속 보임
- **RLS 정책 활용**: 사용자는 자신이 신고한 내용만 조회 가능하도록 RLS 정책 설정
- **UI 일관성**: 패딩 구조를 원래대로 유지하여 기존 디자인과 일관성 유지

### 실수
- 초기에 `BookDetailMemoCard`에 패딩을 추가하여 이중 패딩 문제 발생
- `memo_list_view.dart`의 패딩과 겹쳐 총 40px 패딩이 적용됨
- 해결: 외부 패딩 제거, 원래 구조 유지

### 참고 문서
- [Google Play 가족 정책](https://support.google.com/googleplay/android-developer/answer/9888170)
- [DEVELOPER_RULES.md](./DEVELOPER_RULES.md) - Clean Architecture 규칙

---

## 🎯 2026-01-02: Push Notification 이미지 추가

### 문제 상황
Push Notification에 책 표지 이미지를 추가하여 사용자 경험을 개선하고 싶었으나, 현재 알림에는 텍스트만 표시되고 있었습니다.

### 원인 분석
- Edge Function에서 책 정보 조회 시 `title`만 조회하고 있었음
- FCM v1 API의 이미지 필드가 설정되지 않았음
- Android와 iOS에서 이미지 설정 방법이 다를 수 있음

### 해결 과정
1. **책 정보 조회 확장**:
   - `notify-new-public-memo` Edge Function에서 `books` 테이블 조회 시 `cover_url` 필드 추가
   - `select('title')` → `select('title, cover_url')`로 변경

2. **FCM v1 API 이미지 필드 추가**:
   - Android: `android.notification.image` 필드 사용
   - iOS: `apns.fcmOptions.image` 필드 사용
   - 이미지가 있을 때만 조건부로 추가하여 하위 호환성 유지

3. **하위 호환성 보장**:
   - 책 표지 이미지가 없을 경우 `null`로 처리
   - 이미지 필드가 없으면 기존과 동일한 페이로드 전송
   - 이전 버전 사용자에게 영향 없음

### 배운 점
- **FCM v1 API 이미지 지원**: Android와 iOS 모두에서 이미지를 지원하지만, 각각 다른 필드 경로를 사용해야 함
  - Android: `message.android.notification.image`
  - iOS: `message.apns.fcmOptions.image`
- **조건부 필드 추가**: 이미지가 없을 때는 필드를 추가하지 않아야 하위 호환성 유지 가능
- **Edge Function 배포**: Supabase MCP를 사용하여 Edge Function을 직접 배포할 수 있음
- **하위 호환성 중요성**: 기존 사용자에게 영향을 주지 않으면서 새 기능을 추가하는 것이 중요

### 실수
- 초기에 이미지 필드를 항상 추가하려 했으나, `null` 값이 포함되면 FCM에서 오류가 발생할 수 있음
- 조건부 추가로 해결

### 참고 문서
- [FCM v1 API 문서](https://firebase.google.com/docs/cloud-messaging/send-message)
- [Android Notification 이미지](https://firebase.google.com/docs/cloud-messaging/android/send-image)
- [iOS Notification 이미지](https://firebase.google.com/docs/cloud-messaging/ios/send-image)

---

## 🎯 2026-01-02: Google Play 정책 준수 및 Android 15 지원

### 문제 상황
1. **공개 메모 상세 화면 프로필 정보 미표시**: 다른 사람이 남긴 공개 메모의 상세 화면에서 메모 소유자의 프로필 이미지와 닉네임이 표시되지 않음 (빈 프로필 이미지 + "User"로 표시)
2. **Google Play 권한 정책 위반**: `READ_MEDIA_IMAGES` 권한 사용이 앱의 핵심 목적과 직접적인 관련이 없다는 이유로 앱 업데이트 거절
3. **Android 15 지원 중단된 API 사용**: `Window.setStatusBarColor`, `setNavigationBarColor`, `setNavigationBarDividerColor` API가 Android 15에서 지원 중단
4. **Edge-to-Edge 미지원**: SDK 35 타겟팅 앱이 Android 15 이상에서 더 넓은 화면을 표시하지 않음

### 원인 분석
1. **RLS 정책 제약**: 메모 상세 화면에서 `getMemoById`를 직접 Supabase 쿼리로 호출했지만, RLS 정책으로 인해 다른 유저의 `users` 정보를 조인할 수 없음
2. **권한 사용 불필요**: 일회성 이미지 선택에는 Android Photo Picker를 사용해야 하는데, `READ_MEDIA_IMAGES` 권한을 선언하여 Google Play 정책 위반
3. **구식 API 사용**: Flutter 엔진 내부에서 지원 중단된 Window API를 사용하여 Android 15 호환성 문제 발생
4. **Edge-to-Edge 미활성화**: MainActivity에서 Edge-to-Edge 모드를 활성화하지 않아 Android 15에서 올바르게 표시되지 않음

### 해결 과정
1. **공개 메모 상세 화면 프로필 정보 표시**:
   - `get-memo-by-id` Edge Function 생성 및 배포
   - Service Role Key를 사용하여 RLS 정책 우회
   - `MemoRepository.getMemoById`에서 Edge Function 호출로 변경
   - 디버깅 로그 추가

2. **Google Play 권한 정책 준수**:
   - `AndroidManifest.xml`에서 `READ_MEDIA_IMAGES` 권한 제거
   - `image_picker` 패키지가 Android 13+에서 자동으로 Photo Picker 사용 (코드 변경 불필요)
   - Android 12 이하는 `READ_EXTERNAL_STORAGE` 사용 (`maxSdkVersion="32"`로 제한)

3. **Android 15 지원 중단된 API 대체**:
   - `MainActivity.kt`에 Edge-to-Edge 활성화 코드 추가
   - `WindowCompat.setDecorFitsSystemWindows(window, false)` 사용
   - `androidx.core:core-ktx:1.13.1` 의존성 추가

4. **Edge-to-Edge 지원**:
   - Android 15 (API 35) 이상에서 자동으로 Edge-to-Edge 모드 활성화
   - Flutter 코드에서 이미 `SafeArea`와 `MediaQuery.padding`을 사용 중이므로 추가 작업 불필요

### 배운 점
- **RLS 정책은 조인에도 적용**: 다른 유저의 데이터를 조인할 때도 RLS 정책이 적용되므로 Edge Function 필요
- **Edge Function은 단일 책임 원칙 준수**: `get-public-book-memos`와 `get-memo-by-id`를 분리하여 각각의 책임 명확화
- **Google Play 권한 정책 엄격**: 일회성 미디어 접근에는 Photo Picker 사용 필수, 권한 선언 시 거절
- **Android Photo Picker 자동 지원**: `image_picker` 1.0.7 이상은 Android 13+에서 자동으로 Photo Picker 사용
- **Android 15 호환성**: 지원 중단된 Window API 대신 `WindowCompat` 사용 필요
- **Edge-to-Edge는 필수**: SDK 35 타겟팅 앱은 Android 15 이상에서 Edge-to-Edge 지원 필수
- **iOS는 영향 없음**: Android의 Edge-to-Edge는 iOS에 적용되지 않음 (다른 시스템)
- **SafeArea는 이미 처리됨**: Flutter 코드에서 이미 `SafeArea`를 사용 중이므로 Edge-to-Edge 모드에서도 정상 동작

### 실수
- 메모 상세 화면에서도 RLS 정책을 고려하지 않고 직접 쿼리 시도
- `get-public-book-memos`에 `memo_id` 기능을 추가하려고 시도 (단일 책임 원칙 위반)
- `READ_MEDIA_IMAGES` 권한을 선언하여 Google Play 정책 위반
- Android 15 지원 중단된 API 문제를 미리 파악하지 못함
- Edge-to-Edge 지원을 미리 준비하지 않음

### 참고 문서
- [SUPABASE_EDGE_FUNCTIONS.md](./SUPABASE_EDGE_FUNCTIONS.md) - Edge Functions 가이드
- [DEVELOPER_RULES.md](./DEVELOPER_RULES.md) - Supabase Edge Functions 규칙
- [ANDROID_DEPLOYMENT.md](./ANDROID_DEPLOYMENT.md) - 안드로이드 배포 가이드

---

## 🎯 2025-11-27: 안드로이드 빌드 설정 업그레이드 및 배포

### 문제 상황
1. **8개월 만의 안드로이드 배포**: iOS는 최근 배포했지만 안드로이드는 8개월 만에 배포를 시도
2. **빌드 설정 오래됨**: Flutter SDK, Kotlin, Gradle 버전이 오래되어 빌드 실패
3. **중복 설정 파일**: `.kts` 파일과 `.gradle` 파일이 중복 존재
4. **서명 키 문제**: 기존 키스토어 비밀번호 기억하지 못함
5. **텍스트 입력 문제**: 안드로이드에서 한글 입력 불가, 키보드 깜빡임, 앱 멈춤
6. **앱바 타이틀 정렬**: 안드로이드에서만 타이틀이 왼쪽 정렬
7. **숫자 키보드 미표시**: 페이지 입력 필드에서 숫자 키보드가 나타나지 않음

### 원인 분석
1. **Flutter SDK 버전 불일치**: `pubspec.yaml`의 SDK 버전이 설치된 Flutter 버전과 불일치
2. **패키지 호환성**: `sign_in_with_apple` 패키지가 오래된 Kotlin 버전과 호환되지 않음
3. **Java 버전**: Java 17에서 Java 21로 업그레이드 필요
4. **IME 충돌**: `autofocus: true`와 `initState`의 `requestFocus` 중복으로 IME 초기화 충돌
5. **enableSuggestions 충돌**: 안드로이드에서 `enableSuggestions: true`가 한글 IME와 충돌
6. **플랫폼별 기본값**: 안드로이드 AppBar의 `centerTitle` 기본값이 `false`
7. **TextInputType.number 한계**: 안드로이드에서 `TextInputType.number`만으로는 숫자 키보드가 항상 나타나지 않음

### 해결 과정
1. **빌드 설정 업그레이드**:
   - Flutter SDK: `^3.6.0` → `^3.10.0`
   - Android Gradle Plugin: `8.2.2` → `8.7.3`
   - Kotlin: `1.9.22` → `2.1.0`
   - Gradle: `8.2` → `8.9`
   - Java: `17` → `21`
   - `sign_in_with_apple`: `^5.0.0` → `^7.0.1`

2. **중복 파일 정리**:
   - `android/app/build.gradle.kts` 삭제
   - `android/settings.gradle.kts` 삭제
   - 중복 `MainActivity.kt` 삭제

3. **서명 키 관리**:
   - 기존 키스토어 파일 위치 확인 (`~/upload-keystore.jks`)
   - `key.properties` 파일 생성 및 비밀번호 설정
   - SHA1 지문 확인 및 Google Play Console과 일치 확인

4. **텍스트 입력 문제 해결**:
   - `autofocus: true` 제거 (중복 포커스 요청 방지)
   - `enableSuggestions: !isAndroid` (안드로이드에서만 false)
   - `enableInteractiveSelection: true` 추가
   - `MainActivity.kt` 정리 (불필요한 `onCreate` 제거)

5. **앱바 타이틀 중앙 정렬**:
   - `centerTitle: true` 명시적 설정

6. **숫자 키보드 문제 해결**:
   - `TextInputType.numberWithOptions(signed: false, decimal: false)` 사용
   - `inputFormatters: [FilteringTextInputFormatter.digitsOnly]` 추가
   - `textInputAction: TextInputAction.done` 추가

### 배운 점
- **Flutter SDK 업그레이드는 iOS에도 영향**: iOS CocoaPods 재설치 필요 (`pod install`)
- **중복 설정 파일 주의**: Groovy와 Kotlin DSL 파일이 동시에 있으면 혼란 발생
- **서명 키는 절대 분실하면 안 됨**: 분실 시 Google Play Console에서 업로드 키 재설정 필요
- **플랫폼별 기본값 차이**: iOS와 Android의 기본 동작이 다르므로 명시적 설정 필요
- **IME 충돌 주의**: `autofocus`와 `requestFocus` 중복 사용 시 IME 초기화 충돌 발생
- **안드로이드 한글 입력**: `enableSuggestions: true`가 한글 IME와 충돌할 수 있음
- **숫자 키보드**: `TextInputType.number`만으로는 부족, `numberWithOptions`와 `inputFormatters` 필요
- **버전 코드 관리**: Google Play Console 업로드 시마다 버전 코드는 반드시 증가해야 함
- **키스토어 SHA1 지문**: Google Play Console에서 요구하는 지문과 일치해야 업로드 가능

### 실수
- Flutter SDK 버전을 확인하지 않고 `^3.27.0`으로 설정하여 빌드 실패
- 기존 키스토어 비밀번호를 기억하지 못하여 새로 생성 시도 (기존 키와 불일치)
- `autofocus`와 `requestFocus`를 동시에 사용하여 IME 충돌 발생
- 안드로이드에서 `enableSuggestions: true`로 설정하여 한글 입력 불가
- `TextInputType.number`만 사용하여 숫자 키보드가 나타나지 않음
- `centerTitle`을 설정하지 않아 안드로이드에서 타이틀이 왼쪽 정렬

### 참고 문서
- [ANDROID_DEPLOYMENT.md](./ANDROID_DEPLOYMENT.md) - 안드로이드 배포 가이드
- [DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md) - 배포 체크리스트

---

## 🎯 2025-11-21: 공개 메모 페이지네이션 및 성능 최적화

### 문제 상황
1. **다른 유저의 프로필 정보 미표시**: 책 상세 화면의 "모든 메모" 필터에서 다른 유저의 공개 메모를 볼 때, 해당 유저의 닉네임과 프로필 이미지가 표시되지 않았습니다.
2. **로딩 시간 지연**: "모든 메모" 필터를 선택하면 호출 시간이 오래 걸렸습니다.
3. **오버플로우 에러**: 메모 리스트에서 "BOTTOM OVERFLOWED BY 17 PIXELS" 오버플로우 에러가 발생했습니다.

### 원인 분석
1. **RLS 정책 제약**: `users` 테이블의 RLS 정책(`user_id = auth.uid()`)으로 인해, 클라이언트에서 다른 유저의 `users` 정보를 조인할 수 없었습니다. `users!user_id` 조인을 사용해도 RLS 정책으로 인해 다른 유저의 데이터가 `null`로 반환되었습니다.
2. **전체 데이터 한 번에 로딩**: 페이지네이션이 없어 모든 공개 메모를 한 번에 불러와 로딩 시간이 길었습니다.
3. **고정 높이 문제**: `ListView.builder`의 `itemExtent: 240.0`으로 고정되어 있었는데, 실제 메모 카드는 이미지 유무에 따라 높이가 달라 240px보다 클 수 있었습니다.

### 해결 과정
1. **Edge Function으로 RLS 우회**:
   - `get-public-book-memos` Edge Function 생성
   - Service Role Key를 사용하여 RLS 정책 우회
   - 페이지네이션 지원 (`limit`, `offset` 파라미터)
   - `count` 계산을 첫 페이지에서만 수행하여 성능 최적화

2. **서버 사이드 페이지네이션 구현**:
   - `PaginatedPublicBookMemosNotifier` 생성 (즉시 로딩 시작)
   - 10개씩 페이지네이션으로 로딩
   - 스크롤 감지로 자동 다음 페이지 로드
   - `hasMore` 플래그로 더 불러올 데이터 여부 확인

3. **성능 최적화**:
   - 중복 요청 방지: `isLoading` 플래그 추가
   - 스크롤 throttle: 300ms 간격으로 요청 제한
   - 재시도 로직: 네트워크 에러만 exponential backoff로 재시도
   - 응답 캐싱: 첫 페이지만 2분간 캐싱
   - 선택적 캐시 무효화: 특정 `bookId`만 무효화

4. **오버플로우 수정**:
   - `ListView.builder`의 `itemExtent` 제거
   - `Column`으로 변경하여 실제 높이에 맞게 자동 계산

5. **호출 시간 최적화**:
   - 첫 페이지는 재시도 없이 즉시 호출
   - 네트워크 에러만 재시도 (2회, 500ms 초기 지연)

### 배운 점
- **RLS 정책과 조인**: RLS가 활성화된 테이블을 조인할 때, RLS 정책이 조인된 테이블에도 적용되어 다른 유저의 데이터를 가져올 수 없음
- **Edge Function 활용**: RLS 정책을 우회해야 하는 경우 Supabase Edge Function을 사용해야 함
- **페이지네이션 필수**: 대량 데이터는 반드시 페이지네이션으로 처리해야 함
- **즉시 로딩 시작**: `StateNotifier`는 생성 시 즉시 로딩을 시작하므로 `FutureProvider`보다 빠름
- **고정 높이 주의**: `itemExtent`를 사용할 때는 실제 높이와 일치하는지 확인해야 함
- **성능 최적화는 단계별로**: 중복 요청 방지 → 스크롤 최적화 → 캐싱 → 재시도 로직 순서로 최적화
- **첫 페이지와 다음 페이지 구분**: 첫 페이지는 사용자 경험을 위해 빠르게, 다음 페이지는 안정성을 위해 재시도 적용

### 실수
- RLS 정책을 고려하지 않고 직접 조인 시도
- 페이지네이션 없이 전체 데이터를 한 번에 로딩
- `itemExtent`를 실제 높이보다 작게 설정하여 오버플로우 발생
- 첫 페이지도 재시도 로직을 적용하여 불필요한 지연 발생

### 참고 문서
- [SUPABASE_EDGE_FUNCTIONS.md](./SUPABASE_EDGE_FUNCTIONS.md) - Edge Functions 가이드
- [DEVELOPER_RULES.md](./DEVELOPER_RULES.md) - Supabase Edge Functions 규칙

---

## 🎯 2025-11-20: 닉네임 중복 체크 및 RLS 정책 우회

### 문제 상황
프로필 수정 화면과 온보딩 화면에서 닉네임 중복 체크가 작동하지 않았습니다. 이미 존재하는 닉네임을 입력해도 통과되었습니다.

### 원인 분석
1. **RLS 정책 제약**: `users` 테이블의 RLS 정책이 `user_id = auth.uid()`로 설정되어 있어, 클라이언트에서는 다른 사용자의 닉네임을 직접 조회할 수 없음
2. **직접 쿼리 시도**: `_supabase.from('users').select('id').eq('nickname', nickname)`로 직접 조회 시도했지만, RLS 정책으로 인해 결과가 항상 null로 반환됨
3. **에러 처리 부족**: 쿼리 실패 시 에러가 제대로 처리되지 않아 사용 가능한 것으로 잘못 판단됨

### 해결 과정
1. **Supabase Edge Function 생성**: `check-nickname` Edge Function을 생성하여 Service Role Key로 RLS 정책을 우회
2. **Edge Function 로직 구현**: 
   - Service Role Key를 사용하여 모든 사용자의 닉네임 조회 가능
   - 현재 사용자의 닉네임과 동일하면 사용 가능 처리
   - 다른 사용자가 사용 중이면 사용 불가 처리
3. **클라이언트 코드 수정**: `auth_provider.dart`의 `checkNicknameAvailability` 메서드를 Edge Function 호출로 변경
4. **프로필 수정 화면 개선**: 온보딩 화면과 동일한 유효성 검사 로직 적용

### 배운 점
- **RLS 정책 이해**: RLS가 활성화된 테이블에서는 클라이언트가 다른 사용자의 데이터를 직접 조회할 수 없음
- **Edge Function 활용**: RLS 정책을 우회해야 하는 경우 Supabase Edge Function을 사용해야 함
- **Service Role Key 사용**: Edge Function에서는 Service Role Key를 사용하여 RLS 정책을 우회할 수 있음
- **보안 고려사항**: Service Role Key는 절대 클라이언트에 노출하지 않고, Edge Function에서만 사용해야 함

### 실수
- RLS 정책을 고려하지 않고 직접 쿼리 시도
- 쿼리 실패 시 에러 처리가 부족하여 잘못된 결과 반환

### 참고 문서
- [SUPABASE_EDGE_FUNCTIONS.md](./SUPABASE_EDGE_FUNCTIONS.md) - Edge Functions 가이드
- [DEVELOPER_RULES.md](./DEVELOPER_RULES.md) - Supabase Edge Functions 규칙

---

---

## 🎯 2025-11-19: 메모 프로필 정보 동기화

### 문제 상황
메모에 표시되는 프로필 이미지와 닉네임이 변경된 값으로 반영되지 않았습니다. 프로필을 업데이트해도 메모 목록에는 이전 정보가 그대로 표시되었습니다.

### 원인 분석
1. **Supabase 조인 결과 처리 미흡**: `Memo.fromJson`에서 `users` 조인 결과를 객체로만 가정하여, 배열로 반환될 경우 처리하지 못함
2. **Provider 무효화 누락**: 프로필 업데이트 시 메모 관련 provider를 무효화하지 않아 캐시된 데이터가 계속 표시됨

### 해결 과정
1. **`Memo.fromJson` 개선**: Supabase 조인 결과가 배열 또는 객체일 수 있음을 인지하고, 두 경우를 모두 처리하도록 수정
2. **Provider 무효화 추가**: `updateProfile` 메서드에서 메모 관련 provider들(`recentMemosProvider`, `homeRecentMemosProvider`, `allMemosProvider`, `paginatedMemosProvider`)을 무효화하여 최신 프로필 정보가 반영되도록 수정

### 배운 점
- **Supabase 조인 결과는 예측 불가능**: 같은 쿼리라도 상황에 따라 배열 또는 객체로 반환될 수 있으므로, 항상 두 경우를 모두 처리해야 함
- **데이터 변경 시 관련 Provider 무효화 필수**: 한 곳에서 데이터를 변경하면, 해당 데이터를 표시하는 모든 화면의 provider를 무효화해야 최신 정보가 반영됨
- **명시적 파라미터 전달**: null 값을 전달할 때도 명시적으로 전달하여 코드의 의도를 명확히 하는 것이 좋음

### 실수
- 처음에는 `users` 조인 결과를 객체로만 가정하여 타입 캐스팅 에러 발생 가능성 무시
- 프로필 업데이트 시 메모 provider 무효화를 고려하지 않음

---

## 🎯 2025-11-19: My Memo 화면 데이터 로딩

### 문제 상황
My Memo 화면에서 필터(모든/공개/비공개)를 사용했을 때 아무것도 표시되지 않았습니다.

### 원인 분석
`memo_list_screen.dart`에서 `MemoList()`를 호출할 때 `bookId`를 명시적으로 전달하지 않아, 기본값(null)에 의존하고 있었습니다. 이로 인해 `paginatedMemosProvider`가 올바르게 초기화되지 않았을 가능성이 있었습니다.

### 해결 과정
`MemoList(bookId: null)`을 명시적으로 전달하여 모든 책의 메모를 불러오도록 수정했습니다.

### 배운 점
- **명시적 파라미터 전달의 중요성**: 기본값에 의존하기보다는 명시적으로 파라미터를 전달하여 코드의 의도를 명확히 하는 것이 좋음
- **null 값도 명시적으로 전달**: null을 전달할 때도 명시적으로 전달하면 코드 가독성이 향상됨

---

## 🎯 2025-11-19: 홈 화면 단일 책 확대 효과

### 문제 상황
홈 화면에서 책이 하나만 있을 때 "읽고 있는 책" 섹션의 책이 확대되지 않았습니다. 여러 책이 있을 때는 중앙에 있는 책이 1.3배 확대되어 표시되었지만, 책이 하나만 있을 때는 확대 효과가 없었습니다.

### 원인 분석
`_SingleBookView`는 책이 하나일 때 사용되는 위젯인데, `_AnimatedBookItem`과 달리 `Transform.scale`을 사용하지 않아 확대 효과가 없었습니다.

### 해결 과정
`_SingleBookView`에도 `Transform.scale(scale: 1.3)`을 적용하여 여러 책일 때와 동일한 확대 효과를 제공하도록 수정했습니다.

### 배운 점
- **일관된 UI/UX 유지**: 조건에 따라 다른 위젯을 사용하더라도, 시각적 효과는 일관되게 유지해야 함
- **단일 케이스도 고려**: 여러 항목과 단일 항목 모두 동일한 사용자 경험을 제공해야 함

---

## 🎯 2025-11-20: Bundle ID 불일치로 인한 App Store Connect 연결 실패

### 문제 상황
Xcode에서 Archive를 생성하고 Distribute App을 시도했을 때, Xcode가 기존 App Store Connect의 "milkyway" 앱을 인식하지 못하고 새로운 앱을 만들려고 했습니다. "Runner"로 Archive가 생성되어 기존 앱과 연결되지 않았습니다.

### 원인 분석
1. **Bundle ID 불일치**: 프로젝트의 Bundle ID가 `com.whatif.milkyway.whatifMilkywayApp`로 설정되어 있었지만, App Store Connect의 실제 앱은 `com.whatif.milkyway`를 사용하고 있었습니다.
2. **Xcode 서명 설정 누락**: `CODE_SIGN_STYLE = Automatic`이 Runner 타겟에 설정되지 않아 자동 서명이 제대로 작동하지 않았습니다.

### 해결 과정
1. **Bundle ID 수정**: `project.pbxproj`에서 모든 Bundle ID를 `com.whatif.milkyway`로 변경
2. **Xcode 서명 설정 추가**: Debug, Release, Profile 빌드 설정에 `CODE_SIGN_STYLE = Automatic` 추가
3. **Scheme 이름 변경**: `Runner.xcscheme`를 `milkyway.xcscheme`로 변경하여 Archive 이름 개선

### 배운 점
- **Bundle ID는 App Store Connect와 정확히 일치해야 함**: Bundle ID가 다르면 Xcode가 다른 앱으로 인식하여 새 앱을 만들려고 시도함
- **기존 프로젝트 리팩토링 시 Bundle ID 확인 필수**: 프로젝트를 리팩토링할 때도 기존 App Store Connect의 Bundle ID를 확인하고 일치시켜야 함
- **Xcode 서명 설정 확인**: 자동 서명이 제대로 작동하려면 `CODE_SIGN_STYLE = Automatic`이 명시적으로 설정되어 있어야 함
- **Archive 이름은 Scheme 이름을 따름**: Scheme 이름을 변경하면 Archive 이름도 변경되어 App Store Connect 연결이 더 명확해짐

### 실수
- Bundle ID를 확인하지 않고 프로젝트를 진행함
- App Store Connect의 실제 Bundle ID를 확인하지 않음
- Xcode 서명 설정이 누락되어 있음을 간과함

---

## 🎯 2025-11-20: iOS Launch Screen과 Flutter 스플래시 화면의 차이

### 문제 상황
TestFlight에서 실제 디바이스로 앱을 다운로드했을 때, 스플래시 화면 대신 하얀색 화면이 나타났습니다.

### 원인 분석
1. **iOS Launch Screen은 네이티브 레벨**: iOS Launch Screen은 Flutter 엔진이 로드되기 전에 네이티브 레벨에서 표시되는 정적 화면입니다.
2. **배경색이 흰색으로 설정**: `LaunchScreen.storyboard`의 배경색이 흰색(`red="1" green="1" blue="1"`)으로 설정되어 있었습니다.
3. **Flutter 스플래시는 엔진 로드 후**: Flutter 위젯 스플래시 화면은 Flutter 엔진이 로드된 후에 표시되므로, Launch Screen이 먼저 보입니다.

### 해결 과정
1. **Launch Screen 배경색 변경**: `LaunchScreen.storyboard`의 배경색을 검은색(`red="0" green="0" blue="0"`)으로 변경
2. **Flutter 스플래시 표시 시간 보장**: Flutter 스플래시 화면이 최소 1.5초 동안 표시되도록 지연 추가
3. **애니메이션 개선**: Flutter 스플래시 화면의 페이드 인 애니메이션을 더 부드럽게 개선

### 배운 점
- **iOS Launch Screen은 정적 이미지만 가능**: Flutter 엔진이 로드되기 전에 표시되므로 애니메이션이나 동적 콘텐츠 불가능
- **두 단계 스플래시 화면**: iOS 앱은 Launch Screen(네이티브) → Flutter 스플래시(위젯) 순서로 표시됨
- **배경색 일치 중요**: Launch Screen과 Flutter 스플래시의 배경색을 일치시켜야 자연스러운 전환 가능
- **TestFlight에서 확인 필수**: 시뮬레이터와 실제 디바이스의 Launch Screen 동작이 다를 수 있으므로 TestFlight에서 반드시 확인해야 함

---

## 🎯 2025-11-20: 하단 네비게이션 바 클릭 영역 확대와 오버플로우

### 문제 상황
하단 네비게이션 바의 클릭 영역을 넓히기 위해 `Expanded`, `Material`, `InkWell`을 사용하고 padding과 아이콘 크기를 늘렸더니 "OVERFLOWED BY 12" 오버플로우 에러가 발생했습니다.

### 원인 분석
1. **Container 높이 제약**: Container의 `maxHeight: 70` 제약이 있었는데, 내부 콘텐츠(아이콘 24px + 텍스트 + padding)가 이를 초과했습니다.
2. **클릭 영역과 시각적 크기 혼동**: 클릭 영역을 넓히는 것과 시각적 콘텐츠 크기를 늘리는 것을 혼동했습니다.

### 해결 과정
1. **maxHeight 제약 제거**: Container의 `maxHeight` 제약을 제거하여 높이 제한 해제
2. **콘텐츠 크기 최적화**: 아이콘 크기를 20으로 복원, padding을 `vertical: 8`로 조정
3. **클릭 영역은 보이지 않는 영역으로 확대**: `minHeight: 48` 설정으로 터치 영역만 확대하고, 실제 콘텐츠는 적절한 크기 유지

### 배운 점
- **클릭 영역과 시각적 크기는 별개**: 클릭 영역을 넓히는 것은 보이지 않는 영역(`minHeight`, `Expanded`)으로 확대하고, 실제 콘텐츠는 적절한 크기를 유지해야 함
- **오버플로우는 제약 조건 확인**: 오버플로우가 발생하면 부모 위젯의 제약 조건(`maxHeight`, `maxWidth` 등)을 확인해야 함
- **Material과 InkWell 활용**: `Material`과 `InkWell`을 사용하면 클릭 영역을 넓히면서도 리플 효과를 제공할 수 있음

---

## 🎯 2025-11-20: 햅틱 피드백 구현

### 구현 내용
하단 네비게이션 바 탭 시 카카오톡처럼 가벼운 진동 피드백을 추가했습니다.

### 사용 방법
- **Flutter 기본 기능 사용**: `HapticFeedback.selectionClick()` 사용 (추가 패키지 불필요)
- **권한 불필요**: iOS와 Android 모두 시스템 레벨 햅틱이므로 권한 설정 불필요

### 진동 강도 옵션
- `HapticFeedback.selectionClick()` - 가장 가벼운 선택 클릭 느낌 (현재 사용)
- `HapticFeedback.lightImpact()` - 가벼운 충격
- `HapticFeedback.mediumImpact()` - 중간 충격
- `HapticFeedback.heavyImpact()` - 강한 충격

### 배운 점
- **Flutter 기본 기능으로 충분**: 추가 패키지 없이 `HapticFeedback`만으로 구현 가능
- **권한 불필요**: 시스템 레벨 햅틱이므로 별도 권한 설정 불필요
- **사용자 경험 개선**: 작은 디테일이지만 사용자 경험을 크게 개선할 수 있음

---

## 📝 일반적인 레슨런

### 1. Provider 무효화 타이밍
- **데이터 변경 시 즉시 무효화**: 데이터를 변경하는 작업(생성, 수정, 삭제) 후에는 관련된 모든 provider를 즉시 무효화해야 함
- **관련 화면 모두 고려**: 한 곳에서 변경한 데이터가 표시되는 모든 화면의 provider를 무효화해야 함

### 2. Supabase 조인 결과 처리
- **배열/객체 모두 처리**: Supabase의 조인 결과는 상황에 따라 배열 또는 객체로 반환될 수 있으므로, 두 경우를 모두 처리해야 함
- **안전한 타입 체크**: `is List`와 `is Map`을 사용하여 타입을 확인한 후 처리

### 3. 명시적 파라미터 전달
- **기본값에 의존 지양**: 기본값이 있더라도 명시적으로 파라미터를 전달하여 코드의 의도를 명확히 함
- **null 값도 명시**: null을 전달할 때도 명시적으로 전달하면 코드 가독성이 향상됨

### 4. UI 일관성 유지
- **조건부 위젯도 일관된 효과**: 조건에 따라 다른 위젯을 사용하더라도, 시각적 효과는 일관되게 유지해야 함
- **단일 케이스도 고려**: 여러 항목과 단일 항목 모두 동일한 사용자 경험을 제공해야 함

### 5. Bundle ID 관리
- **App Store Connect와 정확히 일치**: 프로젝트의 Bundle ID는 App Store Connect에 등록된 앱의 Bundle ID와 정확히 일치해야 함
- **리팩토링 시 확인 필수**: 프로젝트를 리팩토링하거나 새로 설정할 때도 기존 App Store Connect의 Bundle ID를 먼저 확인해야 함
- **Xcode 서명 설정 확인**: 자동 서명이 제대로 작동하려면 `CODE_SIGN_STYLE = Automatic`이 명시적으로 설정되어 있어야 함

### 6. iOS Launch Screen과 Flutter 스플래시
- **두 단계 스플래시 화면**: iOS 앱은 Launch Screen(네이티브, 정적) → Flutter 스플래시(위젯, 동적) 순서로 표시됨
- **배경색 일치 중요**: Launch Screen과 Flutter 스플래시의 배경색을 일치시켜야 자연스러운 전환 가능
- **TestFlight에서 확인**: 시뮬레이터와 실제 디바이스의 Launch Screen 동작이 다를 수 있으므로 TestFlight에서 반드시 확인해야 함

### 7. 클릭 영역 확대
- **보이지 않는 영역으로 확대**: 클릭 영역을 넓히는 것은 `minHeight`, `Expanded` 등으로 보이지 않는 영역을 확대하고, 실제 콘텐츠는 적절한 크기를 유지해야 함
- **오버플로우 주의**: 클릭 영역을 넓힐 때 부모 위젯의 제약 조건(`maxHeight`, `maxWidth` 등)을 확인해야 함

### 8. 햅틱 피드백
- **Flutter 기본 기능 활용**: `HapticFeedback`는 추가 패키지 없이 사용 가능하며, 권한도 필요 없음
- **사용자 경험 개선**: 작은 디테일이지만 사용자 경험을 크게 개선할 수 있음

### 9. 페이지네이션 최적화
- **즉시 로딩 시작**: `StateNotifier`는 생성 시 즉시 로딩을 시작하므로 `FutureProvider`보다 빠름
- **중복 요청 방지 필수**: `isLoading` 플래그로 동시 요청 방지
- **스크롤 최적화**: throttle을 적용하여 스크롤 이벤트 처리 부하 감소
- **첫 페이지와 다음 페이지 구분**: 첫 페이지는 사용자 경험을 위해 빠르게, 다음 페이지는 안정성을 위해 재시도 적용
- **캐싱 전략**: 첫 페이지만 캐싱하여 실시간성과 효율성 균형 유지
- **선택적 캐시 무효화**: 전체 캐시를 무효화하지 않고 특정 항목만 무효화하여 효율성 향상

### 10. 오버플로우 방지
- **고정 높이 주의**: `ListView.builder`의 `itemExtent`를 사용할 때는 실제 높이와 일치하는지 확인해야 함
- **동적 높이 사용**: 콘텐츠 높이가 가변적이면 `itemExtent`를 제거하고 실제 높이에 맞게 자동 계산
- **Column vs ListView.builder**: `shrinkWrap: true`를 사용하는 경우 `Column`이 더 안전할 수 있음

### 11. 재시도 로직 최적화
- **네트워크 에러만 재시도**: 인증/권한 에러는 즉시 실패 처리
- **첫 페이지는 재시도 없이**: 사용자 경험을 위해 첫 페이지는 재시도 없이 빠르게 실패 처리
- **재시도 횟수와 지연 시간 조정**: 너무 많은 재시도는 오히려 사용자 경험을 해칠 수 있음

### 12. 응답 캐싱 전략
- **JSON 직렬화로 안전한 키 생성**: `Map.toString()` 대신 `jsonEncode` 사용
- **TTL 설정**: 캐시 만료 시간을 적절히 설정하여 실시간성과 효율성 균형
- **캐시 크기 제한**: 메모리 사용량을 제한하기 위해 LRU 방식으로 오래된 항목 제거
- **선택적 무효화**: 전체 캐시를 무효화하지 않고 특정 항목만 무효화

### 13. 안드로이드 빌드 및 배포
- **Flutter SDK 업그레이드 시 iOS 확인**: `pod install` 필수
- **중복 설정 파일 정리**: Groovy와 Kotlin DSL 파일이 동시에 있으면 혼란 발생
- **서명 키 백업 필수**: 키스토어 파일과 비밀번호는 안전하게 보관
- **SHA1 지문 확인**: Google Play Console과 일치해야 업로드 가능
- **버전 코드 관리**: 업로드 시마다 반드시 증가해야 함
- **플랫폼별 기본값 차이**: iOS와 Android의 기본 동작이 다르므로 명시적 설정 필요

### 14. 안드로이드 텍스트 입력
- **IME 충돌 방지**: `autofocus`와 `requestFocus` 중복 사용 금지
- **한글 입력 지원**: 안드로이드에서 `enableSuggestions: false` 설정
- **숫자 키보드**: `TextInputType.numberWithOptions`와 `inputFormatters` 사용
- **플랫폼별 설정**: `Theme.of(context).platform`으로 플랫폼 구분

### 15. 안드로이드 UI 설정
- **앱바 타이틀**: `centerTitle: true` 명시적 설정 필요
- **텍스트 선택**: `enableInteractiveSelection: true` 설정

---

## 🔄 개선 사항

### 향후 개선 계획
1. **Provider 무효화 자동화**: 데이터 변경 시 관련 provider를 자동으로 무효화하는 유틸리티 함수 고려
2. **타입 안전성 강화**: Supabase 조인 결과를 처리하는 공통 유틸리티 함수 생성
3. **테스트 코드 작성**: 이러한 케이스들을 테스트로 커버하여 재발 방지

---

**문서 작성일:** 2025-11-19  
**작성자:** AI Assistant  
**검토자:** 개발팀  
**다음 검토 예정일:** 2025-12-27

