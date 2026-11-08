# 🤖 안드로이드 배포 가이드 (Android Deployment Guide)

## 📋 개요

이 문서는 Milkyway 앱의 안드로이드 빌드 및 Google Play Store 배포 과정을 정리한 가이드입니다.

**최종 업데이트:** 2025-11-27  
**작성자:** AI Assistant  
**검토자:** 개발팀

---

## 🛠️ 빌드 환경 설정

버전 값은 `pubspec.yaml`, 빌드 환경은 `android/` 설정과 `.github/workflows/ci.yml` 이 정본이다. 이 문서에는 버전 숫자를 적지 않는다.

### 앱 식별자

```gradle
defaultConfig {
    applicationId "com.whatif.milkyway.android"
    minSdkVersion flutter.minSdkVersion  // API 24 (Android 7.0) 이상
    targetSdkVersion flutter.targetSdkVersion
}
```

---

## 🔐 앱 서명 (App Signing)

### 키스토어 생성

```bash
cd android/app
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload \
  -storepass <비밀번호> \
  -keypass <비밀번호> \
  -dname "CN=Noah Hwang, OU=whatif, O=whatif, L=Seoul, ST=Seoul, C=KR"
```

### key.properties 설정

`android/app/key.properties` 파일 생성:

```properties
storePassword=<키스토어_비밀번호>
keyPassword=<키_비밀번호>
keyAlias=upload
storeFile=upload-keystore.jks
```

### 키스토어 관리

- **위치**: `android/app/upload-keystore.jks`
- **백업 필수**: 키스토어 파일과 비밀번호는 안전하게 보관
- **분실 시**: 앱 업데이트 불가능 (Google Play Console에서 업로드 키 재설정 필요)

### 키스토어 SHA1 지문 확인

```bash
keytool -list -v -keystore upload-keystore.jks -alias upload -storepass <비밀번호>
```

Google Play Console에서 요구하는 SHA1 지문과 일치해야 합니다.

---

## 📦 AAB 빌드

### 빌드 명령어

```bash
# 프로젝트 루트에서
flutter clean
flutter build appbundle --release
```

### 빌드 결과

- **파일 위치**: `build/app/outputs/bundle/release/app-release.aab`
- **파일 크기**: 약 136MB
- **버전 코드**: `pubspec.yaml`의 `version` 필드에서 자동으로 가져옴

### 버전 코드 관리

- **형식**: `major.minor.patch+buildNumber` (예: `1.2.3+45`)
- **규칙**: Google Play Console에 업로드할 때마다 버전 코드는 반드시 증가해야 함
- **업데이트**: `pubspec.yaml`의 `version` 필드 수정

---

## 🚀 Google Play Console 업로드

### 1단계: Google Play Console 접속

1. https://play.google.com/console 접속
2. 앱 선택

### 2단계: 테스트 트랙 선택

- **내부 테스트**: 빠른 테스트용 (테스터 이메일 추가)
- **알파**: 제한된 테스트
- **베타**: 공개 베타 테스트

### 3단계: 새 버전 생성

1. 선택한 트랙에서 "새 버전 만들기" 클릭
2. "앱 번들 업로드" 클릭
3. `build/app/outputs/bundle/release/app-release.aab` 파일 업로드

### 4단계: 출시 노트 작성

- "이 버전의 새로운 기능"에 변경사항 입력
- 예시:
  ```
  - 안드로이드 빌드 설정 업그레이드
  - 텍스트 입력 개선 (한글 입력 지원)
  - UI 개선 및 버그 수정
  ```

### 5단계: 출시

1. "저장" 클릭
2. "검토" 클릭
3. "내부 테스트에 출시" (또는 해당 트랙) 클릭

---

## ⚠️ 일반적인 문제 및 해결

### 1. 서명 키 불일치

**에러 메시지:**
```
Your Android App Bundle is signed with the wrong key.
Expected: SHA1: XX:XX:XX...
Actual: SHA1: YY:YY:YY...
```

**해결 방법:**
- 기존 키스토어 파일 확인
- `key.properties`의 비밀번호 확인
- 키스토어 SHA1 지문이 Google Play Console과 일치하는지 확인

### 2. 버전 코드 중복

**에러 메시지:**
```
Version code X has already been used. Try another version code.
```

**해결 방법:**
- `pubspec.yaml`의 버전 코드 증가
- 예: `1.2.3+45` → `1.2.3+46`

### 3. CocoaPods 동기화 오류 (iOS 빌드 시)

**에러 메시지:**
```
The sandbox is not in sync with the Podfile.lock.
```

**해결 방법:**
```bash
cd ios
pod install
```

### 4. 지원되지 않는 기기

**Google Play Console 메시지:**
- "Doesn't support framework version (X devices)"
- "Doesn't support required ABI (X devices)"

**설명:**
- 정상적인 현상입니다. 오래된 기기들은 지원하지 않습니다.
- 현재 최소 SDK: API 24 (Android 7.0 Nougat) 이상
- 지원 ABI: `arm64-v8a`, `armeabi-v7a`, `x86`, `x86_64`

---

## 🔧 플랫폼별 특이사항

### 안드로이드 전용 설정

#### 소셜 로그인
- **Google Sign-In만 사용** (iOS는 Apple Sign-In + Google Sign-In)
- Firebase Console에서 SHA-1 지문 등록 필요

#### 텍스트 입력 최적화
- `enableSuggestions: false` (안드로이드에서 한글 IME 충돌 방지)
- `enableInteractiveSelection: true` (텍스트 선택 활성화)
- `autofocus` 제거 (IME 충돌 방지)

#### 앱바 타이틀
- `centerTitle: true` 명시적 설정 필요 (안드로이드 기본값은 `false`)

#### 숫자 키보드
- `TextInputType.numberWithOptions(signed: false, decimal: false)` 사용
- `inputFormatters: [FilteringTextInputFormatter.digitsOnly]` 추가

### AndroidManifest.xml 설정

```xml
<application
    android:enableOnBackInvokedCallback="true">
    <activity
        android:windowSoftInputMode="adjustResize">
```

---

## 릴리즈 절차 (2026-11)

- 빌드 전 필수 체크는 루트 `CLAUDE.md` 의 "릴리즈 빌드 전 필수 체크" 절을 따른다
- 빌드 후 `scripts/check_release_env.sh --built` 로 확인한다. 번들된 `.env` 가 운영 Supabase 인지, aab 서명과 업로드 인증서 SHA256 이 맞는지, 버전이 올라갔는지 본다
- git worktree 에는 `key.properties` 와 `upload-keystore.jks` 가 없다. 메인 체크아웃에서 복사해 쓰고, 절대 커밋하지 않는다

---

## 📝 체크리스트

### 빌드 전 확인
- [ ] `pubspec.yaml` 버전 코드 확인 및 증가
- [ ] `key.properties` 파일 존재 및 비밀번호 확인
- [ ] 키스토어 파일 위치 확인
- [ ] `google-services.json` 최신 버전 확인

### 빌드 후 확인
- [ ] AAB 파일 생성 확인
- [ ] 파일 크기 확인 (약 136MB)
- [ ] 버전 코드 확인

### 업로드 전 확인
- [ ] Google Play Console에서 기대하는 SHA1 지문 확인
- [ ] 키스토어 SHA1 지문과 일치 확인
- [ ] 이전 버전 코드 확인 (중복 방지)

### 업로드 후 확인
- [ ] 업로드 성공 확인
- [ ] 출시 노트 작성 확인
- [ ] 테스트 트랙 설정 확인

---

## 🔗 참고 자료

- [Flutter Android 배포 가이드](https://docs.flutter.dev/deployment/android)
- [Google Play Console 도움말](https://support.google.com/googleplay/android-developer)
- [Android 앱 서명 가이드](https://developer.android.com/studio/publish/app-signing)
- [AAB 형식 가이드](https://developer.android.com/guide/app-bundle)

---

**문서 작성일:** 2025-11-27  
**작성자:** AI Assistant  
**검토자:** 개발팀  
**다음 검토 예정일:** 2025-12-27

