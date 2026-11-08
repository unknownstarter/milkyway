# Notification 시스템 테스트 가이드

**작성일:** 2026-01-02

## ✅ 현재 상태

- ✅ Edge Function 배포 완료 (v2)
- ✅ FCM 서비스 계정 키 설정 완료
- ✅ FCM HTTP v1 API 구현 완료

---

## 🧪 테스트 방법

### 방법 1: 앱에서 실제 테스트 (권장)

#### 준비 단계

1. **테스트 사용자 A 설정**
   - 앱에서 로그인
   - 알림 권한 허용 (로그인 시 다이얼로그 또는 Profile → 알림 설정)
   - 책 저장 (예: "소년이 온다")
   - Profile → 알림 설정이 **ON**인지 확인

2. **테스트 사용자 B 설정**
   - 다른 기기/계정으로 로그인
   - 같은 책 저장 (예: "소년이 온다")
   - 또는 이미 저장된 책이 있다면 그대로 사용

#### 테스트 실행

1. **사용자 B가 공개 메모 작성**
   - 저장한 책 선택
   - 메모 작성 화면으로 이동
   - 메모 내용 입력
   - **공개**로 설정
   - 메모 저장

2. **사용자 A 기기에서 확인**
   - 알림 수신 확인
   - 알림 탭 시 메모 상세 화면으로 이동 확인

---

### 방법 2: Edge Function 직접 테스트

#### 테스트 데이터 확인

먼저 데이터베이스에서 실제 데이터를 확인:

```sql
-- 1. FCM 토큰이 있는 사용자 확인
SELECT id, fcm_token, notification_enabled FROM users 
WHERE fcm_token IS NOT NULL AND notification_enabled = true 
LIMIT 1;

-- 2. 해당 사용자가 저장한 책 확인
SELECT ub.book_id, b.title 
FROM user_books ub 
INNER JOIN books b ON ub.book_id = b.id 
WHERE ub.user_id = '사용자_ID' 
LIMIT 1;

-- 3. 해당 책에 대한 공개 메모 확인
SELECT id, user_id, content 
FROM memos 
WHERE book_id = '책_ID' AND visibility = 'public' 
ORDER BY created_at DESC 
LIMIT 1;
```

#### Edge Function 호출

터미널에서 다음 명령어 실행:

```bash
curl -X POST https://hyjgfgzexvxhgfmqgiqu.supabase.co/functions/v1/notify-new-public-memo \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh5amdmZ3pleHZ4aGdmbXFnaXF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcwMTUxNTAsImV4cCI6MjA1MjU5MTE1MH0.pFU0Ic_p_BXOLLnO2N0vL_SknOz7mVgcWCX482w1iUc" \
  -H "Content-Type: application/json" \
  -d '{
    "book_id": "실제_책_ID",
    "memo_id": "실제_메모_ID",
    "memo_content": "테스트 메모 내용",
    "memo_author_nickname": "테스트 사용자",
    "memo_author_id": "메모_작성자_ID"
  }'
```

**예상 응답:**
- 성공 시:
  ```json
  {
    "success": true,
    "tokens_count": 1,
    "success_count": 1,
    "failure_count": 0,
    "message": "알림 전송 완료: 1개 성공, 0개 실패"
  }
  ```

- 알림을 받을 사용자가 없는 경우:
  ```json
  {
    "message": "알림을 받을 사용자가 없습니다."
  }
  ```

---

### 방법 3: Supabase 로그 확인

Edge Function 실행 로그를 확인하여 오류가 없는지 확인:

1. [Supabase Dashboard](https://supabase.com/dashboard/project/hyjgfgzexvxhgfmqgiqu) 접속
2. **Logs** → **Edge Functions** 선택
3. `notify-new-public-memo` 함수의 로그 확인
4. 오류 메시지 확인

---

## 🔍 문제 해결

### 문제: "알림을 받을 사용자가 없습니다"

**원인:**
- 해당 책을 저장한 사용자가 없음
- FCM 토큰이 등록되지 않음
- 알림이 비활성화됨 (`notification_enabled = false`)
- 메모 작성자에게는 알림이 가지 않음

**해결:**
1. 다른 사용자가 해당 책을 저장했는지 확인
2. 사용자의 FCM 토큰이 등록되었는지 확인:
   ```sql
   SELECT id, fcm_token, notification_enabled FROM users WHERE id = '사용자_ID';
   ```
3. 알림 설정이 활성화되어 있는지 확인

### 문제: "FCM_SERVICE_ACCOUNT_JSON 환경 변수가 설정되지 않았습니다"

**해결:**
1. Supabase Dashboard → Settings → Edge Functions → Secrets 확인
2. `FCM_SERVICE_ACCOUNT_JSON`이 존재하는지 확인
3. JSON 형식이 올바른지 확인

### 문제: "서비스 계정 JSON 파싱 실패"

**해결:**
1. JSON 파일의 전체 내용이 복사되었는지 확인
2. JSON 형식이 올바른지 확인 (중괄호, 따옴표 등)
3. `private_key`의 줄바꿈(`\n`)이 올바르게 포함되었는지 확인

### 문제: "OAuth2 토큰 획득 실패"

**해결:**
1. 서비스 계정 키가 올바른지 확인
2. Firebase 프로젝트가 활성화되어 있는지 확인
3. 서비스 계정에 필요한 권한이 있는지 확인

### 문제: 알림은 전송되지만 수신되지 않음

**확인 사항:**
1. 앱이 백그라운드에 있는지 확인 (포그라운드에서는 로컬 알림으로 표시)
2. 기기의 알림 설정이 활성화되어 있는지 확인
3. FCM 토큰이 유효한지 확인 (만료된 토큰일 수 있음)

---

## 📊 테스트 체크리스트

### 기본 기능 테스트
- [ ] Edge Function이 정상적으로 호출되는지 확인
- [ ] FCM 서비스 계정 키가 올바르게 파싱되는지 확인
- [ ] OAuth2 토큰이 정상적으로 획득되는지 확인
- [ ] FCM v1 API 호출이 성공하는지 확인

### 실제 알림 테스트
- [ ] 사용자 A가 책을 저장
- [ ] 사용자 A의 FCM 토큰이 등록되었는지 확인
- [ ] 사용자 B가 같은 책에 공개 메모 작성
- [ ] 사용자 A 기기에서 알림 수신 확인
- [ ] 알림 탭 시 메모 상세 화면으로 이동 확인

### 에러 처리 테스트
- [ ] FCM 토큰이 없는 경우 처리 확인
- [ ] 알림이 비활성화된 경우 처리 확인
- [ ] 메모 작성자에게는 알림이 가지 않는지 확인

---

## 🎯 다음 단계

테스트 완료 후:
1. 실제 사용자에게 알림이 정상적으로 전송되는지 확인
2. 알림 탭 시 딥링크가 정상 작동하는지 확인
3. 필요 시 로그를 확인하여 최적화

---

## 📚 참고 자료

- [FCM 서비스 계정 키 설정 가이드](./FCM_SERVICE_ACCOUNT_SETUP_GUIDE.md)
- [Notification 시스템 설정 가이드](./NOTIFICATION_SETUP.md)

