# Notification 시스템 설정 가이드

**작성일:** 2026-01-02  
**버전:** 간단 구현 버전

## ✅ 완료된 작업

### 1. 데이터베이스 마이그레이션
- ✅ `users` 테이블에 `fcm_token` 컬럼 추가
- ✅ `users` 테이블에 `notification_enabled` 컬럼 추가

### 2. Flutter 앱 구현
- ✅ `NotificationService` 구현 (FCM 토큰 관리, 알림 수신, 로컬 알림 표시)
- ✅ `FirebaseService`에 FCM 초기화 추가
- ✅ Profile 화면에 알림 설정 타일 추가
- ✅ 로그인 시 알림 권한 다이얼로그 표시
- ✅ 알림 탭 시 딥링크 처리 (메모 상세 화면으로 이동)

### 3. Edge Function 구현
- ✅ `notify-new-public-memo` Edge Function 생성
- ✅ FCM HTTP API를 사용한 알림 전송 로직 구현
- ✅ 배치 전송 지원 (최대 500개 토큰씩)

### 4. 메모 생성 시 알림 트리거
- ✅ `MemoRepository.createMemo`에서 공개 메모 생성 시 알림 Edge Function 호출

---

## 🔧 설정 필요 사항

### ✅ 1. Edge Function 배포 완료

`notify-new-public-memo` Edge Function이 성공적으로 배포되었습니다.

---

### 2. FCM 서비스 계정 설정 (필수)

푸시는 FCM HTTP v1 을 쓴다. 레거시 서버 키(`FCM_SERVER_KEY`)는 더 이상 쓰지 않는다.
서비스 계정 JSON 을 Supabase 시크릿 `FCM_SERVICE_ACCOUNT_JSON` 으로 넣는다.
자세한 방법은 [FCM_SERVICE_ACCOUNT_SETUP_GUIDE.md](./FCM_SERVICE_ACCOUNT_SETUP_GUIDE.md) 참고.
발송 코드는 `supabase/functions/_shared/notify.ts`.

**주의:**
- 서비스 계정 키는 민감한 정보이므로 시크릿으로만 관리
- Git에 커밋하지 않도록 주의

---

### 3. iOS 추가 설정 (필수)

**✅ 1단계: entitlements 파일 설정 완료**
- `ios/Runner/Runner.entitlements`에 `aps-environment` 추가 완료

**2단계: Xcode에서 Push Notifications Capability 추가**
1. Xcode에서 `ios/Runner.xcworkspace` 열기
2. 왼쪽 네비게이터에서 **Runner** 프로젝트 선택
3. **TARGETS** → **Runner** 선택
4. **Signing & Capabilities** 탭 클릭
5. **+ Capability** 버튼 클릭
6. **Push Notifications** 검색 후 추가
   - 이 작업을 하면 Xcode가 자동으로 `Runner.entitlements` 파일을 업데이트합니다
   - `aps-environment`가 `production` 또는 `development`로 설정됩니다

**3단계: APNs 인증 키 생성 및 Firebase Console에 업로드**

**APNs 인증 키 생성:**
1. [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list) 접속
2. **Keys** 섹션으로 이동
3. **+ (플러스)** 버튼 클릭하여 새 키 생성
4. **Key Name** 입력 (예: "milkyway-push-notifications")
5. **Apple Push Notifications service (APNs)** 체크
6. **Continue** → **Register** 클릭
7. **Download** 버튼 클릭하여 `.p8` 파일 다운로드
   - ⚠️ **중요**: 이 파일은 한 번만 다운로드 가능하므로 안전한 곳에 보관하세요
8. **Key ID** 복사 (나중에 필요)

**Firebase Console에 APNs 인증 키 업로드:**
1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 선택: `milkyway-app-f0848`
3. 프로젝트 설정 (⚙️) → **Cloud Messaging** 탭
4. **Apple app configuration** 섹션에서:
   - **APNs Authentication Key** 섹션의 **Upload** 버튼 클릭
   - 다운로드한 `.p8` 파일 선택
   - **Key ID** 입력 (Apple Developer Portal에서 복사한 값)
   - **Team ID** 입력 (Apple Developer Portal → Membership에서 확인 가능)
   - **Upload** 클릭

**참고:**
- APNs 인증 키는 프로덕션과 개발 환경 모두에서 사용 가능합니다
- 이전에 APNs 인증서를 사용했다면, 인증 키로 마이그레이션하는 것이 권장됩니다

---

## 📱 사용자 플로우

### 알림 수신 플로우
1. 사용자 A가 책을 저장
2. 사용자 B가 해당 책에 공개 메모 작성
3. `MemoRepository.createMemo`에서 `notify-new-public-memo` Edge Function 호출
4. Edge Function이:
   - 해당 책을 저장한 모든 사용자 조회 (작성자 제외)
   - FCM 토큰이 있고 알림이 활성화된 사용자 필터링
   - FCM HTTP API로 알림 전송
5. 사용자 A의 기기에서 알림 수신
6. 알림 탭 시 메모 상세 화면으로 이동

### 알림 설정 플로우
1. **로그인 시:**
   - 새 디바이스에서 로그인하면 알림 권한 다이얼로그 표시
   - "내가 읽고 있는 책에 새로운 메모가 등록되면 알려드려요!" 메시지

2. **Profile 화면:**
   - 알림 설정 타일에서 알림 ON/OFF 가능
   - 알림을 켤 때 권한 확인 및 요청

---

## 🧪 테스트 방법

### 1. 알림 권한 테스트
- [ ] 새 디바이스에서 로그인 시 알림 권한 다이얼로그 표시 확인
- [ ] Profile 화면에서 알림 설정 토글 동작 확인

### 2. FCM 토큰 등록 테스트
- [ ] 로그인 후 FCM 토큰이 `users` 테이블에 저장되는지 확인
- [ ] `notification_enabled`가 `true`로 설정되는지 확인

### 3. 알림 전송 테스트
- [ ] 사용자 A가 책을 저장
- [ ] 사용자 B가 해당 책에 공개 메모 작성
- [ ] 사용자 A의 기기에서 알림 수신 확인
- [ ] 알림 탭 시 메모 상세 화면으로 이동 확인

### 4. Edge Function 테스트
```bash
# Edge Function 직접 테스트
curl -X POST https://your-project.supabase.co/functions/v1/notify-new-public-memo \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "book_id": "book-id-here",
    "memo_id": "memo-id-here",
    "memo_content": "테스트 메모 내용",
    "memo_author_nickname": "테스트 사용자",
    "memo_author_id": "author-id-here"
  }'
```

---

## ⚠️ 주의사항

### 1. FCM 서버 키 보안
- FCM 서버 키는 절대 Git에 커밋하지 않기
- Supabase Secrets로 안전하게 관리
- 정기적으로 키 로테이션 권장

### 2. 알림 전송 실패 처리
- Edge Function에서 알림 전송 실패해도 메모 생성은 성공
- 실패한 토큰은 자동으로 재시도하지 않음 (FCM이 처리)
- 만료된 토큰은 FCM이 자동으로 제거

### 3. 배치 전송 제한
- FCM은 한 번에 최대 500개의 토큰까지 지원
- 더 많은 사용자가 있으면 자동으로 배치 분할

### 4. 알림 탭 딥링크
- 현재는 `memo_id`만 처리
- 향후 다른 타입의 알림 추가 시 확장 필요

---

## 🔄 향후 개선 사항

1. **Firebase Admin SDK 사용**
   - 현재는 FCM HTTP API 사용
   - 향후 Firebase Admin SDK로 전환 고려 (더 안전하고 기능이 많음)

2. **알림 타입 확장**
   - 현재는 "새 공개 메모"만 지원
   - 향후 다른 알림 타입 추가 가능

3. **알림 히스토리**
   - 사용자가 받은 알림 목록 표시
   - 읽음/안 읽음 상태 관리

4. **알림 설정 세분화**
   - 현재는 전체 알림 ON/OFF만 지원
   - 향후 알림 타입별 설정 가능

---

## 📚 참고 문서

- [Firebase Cloud Messaging 문서](https://firebase.google.com/docs/cloud-messaging)
- [FCM HTTP API 문서](https://firebase.google.com/docs/cloud-messaging/http-server-ref)
- [Supabase Edge Functions 문서](https://supabase.com/docs/guides/functions)

