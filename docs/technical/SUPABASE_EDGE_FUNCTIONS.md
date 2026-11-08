# 🔧 Supabase Edge Functions 가이드

> **Supabase Edge Functions 배포 및 관리 가이드**
> **⚠️ 이 문서는 Supabase Edge Functions의 배포, 관리, 문제 해결 방법을 다룹니다.**

---

## 현재 함수 목록 (2026-11-08)

정본은 `supabase/functions/` 디렉터리다. 아래 목록과 어긋나면 디렉터리가 맞다. 공용 코드는 `_shared/`.

| 함수 | 용도 |
|---|---|
| `check-nickname` | 닉네임 중복 체크 (RLS 우회) |
| `connect-memo` | 메모 저장 직후 임베딩(Voyage) 생성, 유사 메모 검색, 관계 4종 판정(Lyra), `memo_edges` 저장 |
| `delete-user` | 계정 삭제 (사용자 데이터 및 auth.users) |
| `deliver-pending-notifications` | 방해 금지 시간에 모아둔 알림을 아침 7시(사용자 현지)에 묶어 발송. pg_cron 이 10분마다 호출 |
| `get-memo-by-id` | 메모 1건 조회 (타 유저 정보 조인용 service role 경유) |
| `get-public-book-memos` | 책별 공개 메모 목록 (타 유저 정보 조인용 service role 경유) |
| `get-public-memo-feed` | 전역 공개 메모 피드 (메모 탭 공개, 홈 최근 공개 메모) |
| `lyra-question` | 책 소개를 바탕으로 사유 확장 물음 1개를 생성해 `book_questions` 에 저장 |
| `notify-new-comment` | 새 댓글 푸시 알림 |
| `notify-new-public-memo` | 새 공개 메모 푸시 알림 |
| `s` | 공유 링크 숏코드 + OG 미리보기 + 딥링크 랜딩 |
| `search-books` | 책 검색. Google Books, Naver, Open Library 순 폴백 |
| `search-memos-semantic` | 의미 검색. 검색어 쿼리 임베딩 후 내 메모 벡터 검색 (LLM 호출 없음) |
| `translate-questions` | Lyra 물음을 en/ja/zh 로 번역해 `question_translations` 에 캐시 |

앱은 엣지 함수를 반드시 `lib/core/network/edge_function_client.dart` 를 통해서만 호출한다 (CI 가 강제한다).

아래 개요와 상세 절은 초기 3개 함수 기준이라 낡았다. 참고용으로만 읽을 것.

---

## 📋 개요

Milkyway 앱은 Supabase Edge Functions를 사용하여 RLS (Row Level Security) 정책을 우회하고, 서버 사이드 로직을 실행합니다. 현재 배포된 Edge Functions는 다음과 같습니다:

1. **check-nickname**: 닉네임 중복 체크
2. **delete-user**: 계정 삭제 (사용자 데이터 및 auth.users 삭제)
3. **search-books**: 책 검색 (향후 사용 예정)

---

## 🚀 Edge Functions 목록

### 1. check-nickname

**목적**: 닉네임 중복 체크 (RLS 정책 우회)

**위치**: `supabase/functions/check-nickname/index.ts`

**기능**:
- Service Role Key를 사용하여 RLS 정책을 우회
- 모든 사용자의 닉네임을 조회하여 중복 여부 확인
- 현재 사용자의 닉네임과 동일하면 사용 가능 처리

**요청 형식**:
```json
POST /functions/v1/check-nickname
{
  "nickname": "사용할 닉네임",
  "user_id": "현재 사용자 ID (선택적)"
}
```

**응답 형식**:
```json
{
  "available": true  // 또는 false
}
```

**에러 응답**:
```json
{
  "error": "에러 메시지"
}
```

**사용 위치**:
- `lib/features/auth/presentation/providers/auth_provider.dart`
  - `checkNicknameAvailability()` 메서드
- 온보딩 화면 (`nickname_screen.dart`)
- 프로필 수정 화면 (`profile_edit_screen.dart`)

**RLS 정책 우회 이유**:
- `users` 테이블의 RLS 정책은 `user_id = auth.uid()`로 설정되어 있음
- 클라이언트에서는 다른 사용자의 닉네임을 직접 조회할 수 없음
- Edge Function의 Service Role Key를 사용하여 모든 사용자 데이터 조회 가능

---

### 2. delete-user

**목적**: 계정 삭제 (사용자 데이터 및 auth.users 삭제)

**위치**: `supabase/functions/delete-user/index.ts`

**기능**:
- 프로필 이미지 삭제 (Supabase Storage)
- 관련 테이블 데이터 삭제 (`memos`, `user_books`, `statistics`, `users`)
- `auth.users`에서 사용자 삭제 (admin API 사용)

**요청 형식**:
```json
POST /functions/v1/delete-user
{
  "user_id": "삭제할 사용자 ID"
}
```

**응답 형식**:
```json
{
  "success": true
}
```

**사용 위치**:
- `lib/features/auth/presentation/providers/auth_provider.dart`
  - `deleteAccount()` 메서드

---

### 3. search-books

**목적**: 책 검색 (향후 사용 예정)

**위치**: `supabase/functions/search-books/index.ts`

**상태**: 구현 완료, 현재 미사용

---

## 📦 배포 방법

### 사전 요구사항

1. **Supabase CLI 설치**
   ```bash
   # Homebrew (macOS)
   brew install supabase/tap/supabase
   
   # 또는 npm
   npm install -g supabase
   ```

2. **프로젝트 연결**
   ```bash
   cd /Users/noahs/milkyway
   supabase link --project-ref <PROJECT_REF>
   ```
   
   현재 프로젝트: `hyjgfgzexvxhgfmqgiqu` (milkyway)

3. **Docker Desktop 실행**
   - Edge Function 배포 시 Docker가 필요합니다
   - Docker Desktop이 실행 중이어야 합니다

### 배포 명령어

#### 단일 Function 배포
```bash
# check-nickname 배포
supabase functions deploy check-nickname --no-verify-jwt

# delete-user 배포
supabase functions deploy delete-user --no-verify-jwt

# search-books 배포
supabase functions deploy search-books --no-verify-jwt
```

#### 모든 Functions 배포
```bash
supabase functions deploy --no-verify-jwt
```

**옵션 설명**:
- `--no-verify-jwt`: JWT 토큰 검증 비활성화 (필요한 경우)
- `--project-ref <REF>`: 특정 프로젝트에 배포 (기본값: 연결된 프로젝트)

### 배포 확인

1. **Supabase Dashboard**
   - https://supabase.com/dashboard/project/hyjgfgzexvxhgfmqgiqu/functions
   - 배포된 Functions 목록 확인
   - 로그 및 메트릭 확인

2. **CLI로 확인**
   ```bash
   supabase functions list
   ```

---

## 🔍 문제 해결

### 1. 배포 실패: Docker 연결 오류

**증상**:
```
failed to inspect docker image: Cannot connect to the Docker daemon
```

**해결 방법**:
1. Docker Desktop 실행 확인
2. Docker가 정상 실행 중인지 확인:
   ```bash
   docker ps
   ```
3. Docker 재시작 후 다시 배포

### 2. 배포 실패: 프로젝트 연결 오류

**증상**:
```
Cannot find project ref. Have you run supabase link?
```

**해결 방법**:
```bash
# 프로젝트 연결
supabase link --project-ref hyjgfgzexvxhgfmqgiqu
```

### 3. Function 호출 실패: 401 Unauthorized

**원인**: JWT 토큰 검증 실패

**해결 방법**:
- Function 배포 시 `--no-verify-jwt` 옵션 사용
- 또는 Function 코드에서 JWT 검증 로직 제거

### 4. RLS 정책 오류

**증상**: Edge Function에서 데이터 조회 실패

**원인**: Service Role Key 미사용

**해결 방법**:
- Edge Function에서 Service Role Key 사용 확인:
  ```typescript
  const supabase = createClient(
    SUPABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY  // Service Role Key 사용
  );
  ```

---

## 🔐 보안 고려사항

### Service Role Key 관리

- **절대 클라이언트에 노출하지 않음**
- Edge Function에서만 사용
- 환경 변수로 관리 (`SUPABASE_SERVICE_ROLE_KEY`)

### JWT 검증

- 현재는 `--no-verify-jwt` 옵션 사용
- 프로덕션 환경에서는 필요에 따라 JWT 검증 활성화 고려
- 민감한 작업(계정 삭제 등)은 추가 인증 필요

### 입력 검증

- 모든 입력값 검증 필수
- SQL Injection 방지
- XSS 공격 방지

---

## 📝 개발 가이드

### 새 Edge Function 추가

1. **Function 디렉토리 생성**
   ```bash
   mkdir -p supabase/functions/my-function
   ```

2. **index.ts 파일 생성**
   ```typescript
   import { createClient } from 'npm:@supabase/supabase-js@2';

   const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
   const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

   const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

   Deno.serve(async (req) => {
     // Function 로직
   });
   ```

3. **배포**
   ```bash
   supabase functions deploy my-function --no-verify-jwt
   ```

### 로컬 테스트

```bash
# 로컬 Supabase 시작
supabase start

# Function 로컬 실행
supabase functions serve my-function
```

---

## 📚 관련 문서

- [Supabase Edge Functions 공식 문서](https://supabase.com/docs/guides/functions)
- [Deno 런타임 문서](https://deno.land/manual)
- [DATABASE_SCHEMA.md](../../DATABASE_SCHEMA.md) - 데이터베이스 스키마
- [DEVELOPER_RULES.md](../DEVELOPER_RULES.md) - 개발자 규칙

---

## 🔄 변경 이력

### 2025-11-20
- **check-nickname Function 추가**
  - 닉네임 중복 체크 기능 구현
  - RLS 정책 우회를 위한 Service Role Key 사용
  - 프로덕션 환경에 배포 완료

### 2025-01-16
- **delete-user Function 추가**
  - 계정 삭제 기능 구현
  - 프로덕션 환경에 배포 완료

---

**마지막 업데이트**: 2025-11-20  
**작성자**: AI Assistant  
**검토자**: 개발팀  
**다음 검토 예정일**: 2025-12-20

