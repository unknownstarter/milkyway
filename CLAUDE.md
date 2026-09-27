# Milkyway — Claude Code 가이드

## 진실의 원천 (2문서 체제 - 2026-09-24 재정리)
출시 이후이므로 **코드가 우선, 문서가 따라간다**. 문서가 코드와 어긋나면 문서를 고칠 것.

| 문서 | 무엇의 정본인가 | 충돌 시 |
|---|---|---|
| **`docs/PRD_v2.md`** | **제품 정의 · BM · 가격 · AI/검색 아키텍처 · MVP 우선순위 · 비용 원칙** | 이쪽이 우선 |
| **`docs/VISION_v3.md`** | **톤 · Lyra(사서) 인격 · IA · 영구 금지(§6.2) · 페르소나** | 톤/금지 사항은 이쪽이 우선 |

- PRD v2가 Milkyway를 **Personal Reading Intelligence**(남긴 생각을 다시 찾고 연결하고 활용)로 재정의했다. 제품 방향 질문은 여기서 답을 찾는다.
- VISION v3 §6 BM "재설계 대기"는 **해소됨**. BM 정본은 PRD v2 §7 (Free + Milkyway+ 월 9,900원).
- `VISION_v2.md` · `docs/PRD.md`(v1.0)는 기록 보존. 정본 아님.

## 새 세션 시작 시 읽기 순서 (필수)
1. **`docs/PRD_v2.md`** — 제품 정의·BM·Free/Paid 경계·검색 구조·MVP 우선순위
2. **`docs/VISION_v3.md`** — 톤·Lyra·IA·영구 금지
3. **`REFACTORING_RULES.md`** — 절대 변경 금지 영역 (DB 스키마·OAuth·validation 등)
4. **`BUSINESS_LOGIC_POLICY.md`** — 회원/책/메모 정책, RLS, 에러 처리
5. **`DATABASE_SCHEMA.md`** — 6개 테이블 + ERD + Storage bucket
6. **`.claude/agents/`** — 전문 직군 페르소나. 필요 시점에 선택 호출

작업 시작 전 체크:
- [ ] PRD v2 해당 절 읽었나 (제품/BM/비용) + VISION v3 톤·금지 위반 없나
- [ ] PRD v2 §36 Engineering Principle 7문항 통과하나 (특히 "LLM이 반드시 필요한가")
- [ ] 현재 단계 확인 (아래 참조)

## 현재 단계 (2026-09-24)
**0.2.11+100 스토어 배포 완료.** 다음 사이클 = PRD v2 MVP 1순위 착수.

| 순서 | 일감 | 과금 |
|---|---|---|
| 1 | **메모 키워드 검색** (현재 앱에 내 메모를 찾는 검색이 아예 없음) | 무료 |
| 2 | **의미 검색** (쿼리 임베딩 → 벡터 검색. LLM 불필요) | Milkyway+ |
| 3 | **Lyra 대화형 검색 (RAG)** - 2번 위에 얹는다 | Milkyway+ |
| 4 | **인앱결제 + 페이월** (`subscriptions` · `ai_usage` 테이블 신규) | - |

**이미 깔려 있는 인프라 (신규 제작 금지, 재사용할 것):**
- `memo_embeddings` (pgvector 1024차원 + HNSW) · `memo_edges` · `match_memos` / `get_constellation` RPC
  → `supabase/migrations/20260822152417_connectome_schema.sql`
- `connect-memo` 엣지 함수 = 메모 저장 시 Voyage 임베딩 자동 생성 + 연결 판정 (작동 중)
- Related Thoughts(PRD v2 2순위)는 **별자리 기능으로 이미 출시됨** (`lib/features/constellation/`)
- 주의: `match_memos`는 **메모→메모**용이다. 검색은 **쿼리→메모** RPC가 별도로 필요.

## 브랜치 · PR · 세션 이름 규칙
이미 굳어져 있던 관행을 명문화한 것이다. 새로 만드는 게 아니라 지키는 것.

### 타입 프리픽스 (공통)
| 프리픽스 | 언제 |
|---|---|
| `feat` | 사용자가 체감하는 새 기능 |
| `fix` | 버그 수정 |
| `docs` | 문서만 (코드 변경 0) |
| `chore` | 빌드·설정·정리·의존성. 제품 동작 불변 |
| `refactor` | 동작 불변, 구조만 변경 |
| `perf` | 성능·용량 |
| `release` | 버전 올림 + 릴리즈 노트 |

`feature/` 아니고 **`feat/`**. (`feature/comments-and-account-deletion`는 과거 예외)

### 브랜치
```
<type>/<kebab-slug>        예: feat/memo-keyword-search
```
- 슬러그는 **영문 소문자 + 하이픈**. 한글·대문자·언더스코어 금지
- 3~5단어. 무엇을 하는지 읽히게 (`feat/fix1` X)
- 릴리즈는 `release/<버전>` (예: `release/0.2.11`)
- **main에 직접 커밋 금지.** 항상 브랜치 -> PR

### PR 제목
```
<type>: <무엇을 했나> - <왜 / 뭐가 문제였나>
```
- 본문은 한국어. `- <왜>` 는 있으면 좋다 (없어도 됨)
- 커밋 메시지 첫 줄도 같은 형식
- 부호 룰 적용: em dash·중간점·곡선따옴표·느낌표 금지. 구분자는 ` - ` 또는 `/`
- 예: `feat: 공유 링크에 '그때 → 지금'을 싣는다 - 오브만 덩그러니 있던 문제`

### PR 본문 뼈대
```
## 왜      문제 정의. 이게 없으면 리뷰가 안 된다
## 무엇    변경 요약
## 검증    flutter analyze / flutter test 결과, 실기기 확인 여부
```

### 세션 이름 (`/rename`)
```
milkyway:<type>/<slug>     브랜치명과 같게
```
여러 세션을 동시에 띄울 때 `/resume`에서 구분된다. 브랜치를 새로 딸 때마다 맞춰준다.
**작업이 바뀌면 세션 이름도 바꾼다.**

### 한 PR = 한 가지
문서 정리 PR에 기능 코드를 얹지 않는다. 섞이면 리뷰도 롤백도 어려워진다.

## 작업 태도 (필수)
**시도도 안 해보고 "안 된다"고 단정 금지.** 어떻게든 방법을 찾아 목표를 달성할 것.
- 파일 경로가 텍스트로 들어와도 일단 `Read` 툴로 열어볼 것 (이미지든 로그든)
- 명령이 실패할 것 같아도 일단 한 번 돌려보고 실제 에러를 보고 판단
- "환경이 부족해서 못 한다"고 추정하기 전에 실제로 환경을 확인할 것
- 정말 안 되면 그때서야 "X 를 시도했고 Y 때문에 안 됨, 대안은 Z" 형태로 보고
- 사용자가 같은 지시를 두 번 하게 만들지 말 것

## 토큰 효율 규칙
- `find` / `grep`으로 위치부터 찾기. 전체 파일은 필요한 절만 `Read offset/limit`
- 큰 문서(`docs/CHANGELOG.md` 55KB · `docs/LESSONS_LEARNED.md` 42KB · `docs/DEVELOPER_RULES.md` 50KB)는 섹션 단위로만
- 한 번 읽은 파일 반복 Read 금지. Edit/Write 직후 검증 Read 안 함
- 광범위 탐색(3쿼리 초과)은 `Explore` 서브에이전트로 위임 — 메인 컨텍스트 보호
- 전문 관점 필요할 때만 직군 에이전트 호출 (매번 부르지 말 것)
- 작업 결과 요약은 1~2문장. 코드 주석 거의 없음 (의도가 비자명할 때만)
- 동일 작업에 동일 에이전트 중복 호출 금지

## Clean Architecture
```
lib/
  core/         theme · router(GoRouter) · services · config · providers
  features/
    <feature>/
      data/          repositories · datasources · models
      domain/        entities · usecases(optional)
      presentation/  screens · widgets · providers(Riverpod @riverpod)
```

**원칙**:
- 의존성 방향: `presentation → domain → data` (역방향 금지)
- presentation은 Supabase 직접 호출 금지. **반드시 repository 경유**
- Riverpod provider는 `presentation/providers/`. `@riverpod` annotation 사용
- 신규 surface(v2의 별자리·책 스레드)는 **신규 feature 폴더**로 (기존 폴더 오염 X)
- DB는 **신규 테이블·RPC**로 확장 (기존 테이블 스키마 변경 금지 — `REFACTORING_RULES.md`)
- 파일 길이 300줄 초과 시 분할 검토. 한 위젯에 비즈니스 로직 X
- **이미지(표지·메모사진·프로필) 올리거나 불러올 땐 `Image.network` 직접 금지.** 표시는 `CachedImage`, 업로드/변환/재호스팅은 정해진 모듈만 사용. 규격(cacheWidth·WebP·버킷·폴백)은 `docs/DEVELOPER_RULES.md` §🖼️ 이미지 업로드/표시 프로토콜 참조

## 디자인 시스템 - 우회 금지
`lib/core/presentation/widgets/design/` 에 있는 것은 **반드시 재사용**한다. 화면에서 다시 만들지 않는다.

| 하지 말 것 | 대신 | 왜 |
|---|---|---|
| `ScaffoldMessenger.showSnackBar` 직접 호출 | `showAppSnackBar` / `showAppPillSnackBar` | 기본값이 하단 고정이라 하단 액션바("메모하기")를 덮는다. ScaffoldMessenger 는 전역이라 **화면 전환을 따라가서 도착 화면의 버튼을 가린다** |
| `Image.network` | `CachedImage` | 아래 이미지 프로토콜 참조 |
| 색상 하드코딩 (`Color(0xFF242424)`) | `AppColors` 토큰 | 같은 값이라도 토큰으로. 바꿀 때 한 곳만 고친다 |

**스낵바는 CI 가 막는다.** `.github/workflows/ci.yml` 의 "스낵바 디자인 시스템 우회 검사" 단계가
`design/app_snackbar.dart` 밖의 `showSnackBar` 를 찾으면 빌드를 실패시킨다.
변형이 필요하면 화면에서 만들지 말고 **`app_snackbar.dart` 에 이름 붙여 추가**할 것.

## 전문 직군 에이전트
`.claude/agents/<name>.md` 정의. 필요 시 `Agent(subagent_type: "<name>")` 호출:

| 에이전트 | 페르소나 | 호출 시점 |
|---|---|---|
| `po` | 김서윤 | 백로그 우선순위, MVP 범위, 기능 정의 |
| `pm` | 박지우 | 일정·의존성·출시 계획, 릴리즈 노트 |
| `pd` | 이하늘 | UI/UX, 카피 톤, 한국 정서 미학 |
| `backend` | 정수민 | Supabase 스키마·RPC·RLS·Edge Function |
| `flutter` | 한가을 | Flutter 구현·Riverpod·Clean Arch 정합 |
| `data-analyst` | 최예린 | 지표 정의·SQL·코호트 |
| `data-scientist` | 윤도하 | LLM 평가·A/B 실험·Lyra 톤 측정 |
| `marketer` | 신아라 | 그로스·콘텐츠·자연 유입·톤 유지 |
| `business-owner` | 이정원 | BM·runway·전략 결정 보조 |

모두 여성. 각자 개성. 호출 시 해당 직군 관점에서만 답함.

## iOS scene 라이프사이클 (2026-08-20 전략 전환 — momo 방식 채택)
**Xcode 26 scene 마이그레이션을 '되돌리지 않고' 제대로 채택한다.** (이전엔 되돌렸으나, `flutter build ipa`가 매 빌드마다 재마이그레이션해 CLI/Transporter 배포가 불가능했음. momo-app이 scene을 채택하고 OAuth를 그 위에서 작동시켜 정상 배포하는 걸 확인 → 같은 전략으로 전환.)

**정상 상태(되돌리지 말 것):**
- `ios/Runner/Info.plist` 에 `UIApplicationSceneManifest` 존재 (`UISceneDelegateClassName = FlutterSceneDelegate`)
- `ios/Runner/AppDelegate.swift` 가 `FlutterImplicitEngineDelegate` 채택 + `didInitializeImplicitFlutterEngine` 에서 `GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)` + OAuth 이중방어용 `application(open:)` override

**작동 원리:** OAuth 콜백 URL(Google 역클라이언트ID scheme)은 scene 환경에서 `FlutterSceneDelegate.scene(openURLContexts:)` 가 Flutter 플러그인 체인(google_sign_in)으로 전달 → Google 로그인 정상. Apple 로그인은 네이티브(ASAuthorizationController)라 URL 콜백 없이 작동. milkyway는 Kakao 미사용.

**⚠️ 배포 전 실기기 필수 확인 (OAuth가 깨지는 바로 그 영역):**
- Google 로그인 / Apple 로그인 실제로 눌러서 되는지
- 푸시 알림 탭 라우팅 / 딥링크
- 파일이 이미 scene 상태라 `flutter build ipa` 가 재마이그레이션 안 함(`git diff ios/Runner/*` 깨끗해야 정상). diff가 생기면 오히려 문제.

자세한 배경: `docs/LESSONS_LEARNED.md`.

## 영구 금지 (VISION v3 §6.2, §10)
광고 · affiliate · 인플루언서 초청 · 친구 초대 보상 · 좋아요 카운트 공개 · 팔로우/팔로워 · 푸시 남발(하루 1개 상한, 상호작용 알림은 별개) · 인기 메모 랭킹(좋아요/조회순 공개 순위) · "당신" 호칭 · 느낌표(시스템 카피).
> **소셜 전환 확정 (2026-08-22)**: 아래 3개는 도입 완료라 영구금지에서 제외.
> - **댓글**: 내가 저장한 책의 공개 메모에 댓글. 본인 수정/삭제, 타인 신고/숨김, 작성자에게 푸시. `lib/features/comments/`.
> - **랭킹**: '인기 메모 랭킹'(메모 좋아요/조회순 줄세우기)은 **여전히 금지**. 대신 **익명 백분위 + 개인 성장**(상위 N% / 지난주 대비 / 연속 읽은 날)만 허용. 타인 실명/메모 노출 없음. `lib/features/ranking/`.
> - **Lyra 일반 질문**: 홈에서 책 무관 질문도, 답하면 다음 질문. `general_questions` + `memo_question_context`(답 스냅샷).
> 이모지 적당히 허용(2026-08-17 개정). 팔로우/팔로워는 아직 미도입. `docs/handoff/2026-08-15-ACTION-PLAN.md` 참조.

## 카피 부호 룰 (AI 금지 기호 — 그로스커리어 §6.5 차용)
사용자 노출 카피 금지: em dash `—`, en dash `–`, 중간점 `·`, 곡선따옴표 `" " ' '`, 단일 말줄임 `…`. 짧은 구분자는 ` - ` 또는 `/`. 짧은 UI 문구(타이틀/라벨/CTA/안내/빈상태/토스트)는 끝 마침표 금지(문단형 본문은 예외). 카피는 `humanizer` 스킬로 윤문. 상세: `docs/design/01-DESIGN_PHILOSOPHY.md` 원칙 6.
> **개정 2026-08-17**: 이모지 허용(적당히). Lyra 톤 = 친근·위트(고상/겉멋 폐기). 위 영구금지의 "이모지"는 무효화. 단 AI 금지 기호는 이모지와 무관하게 절대 유지. "당신" 호칭 금지 유지.

## 게이트 (설치 필수)
**새 맥에서 클론했으면 이 한 줄을 먼저 칠 것.** 안 치면 pre-push 훅이 조용히 꺼진 채로 개발된다.

```bash
git config core.hooksPath scripts/git-hooks
```

| 게이트 | 무엇을 | 언제 |
|---|---|---|
| `scripts/git-hooks/pre-push` | `flutter analyze` + `flutter test` (전체 8초) | 푸시 전. 빠른 피드백용 |
| `.github/workflows/ci.yml` | 같은 둘 | PR/main push. **머지를 막는 진짜 게이트** |

훅은 `--no-verify` 로 우회되고 머신당 수동 설치라 믿을 수 없다. 그래서 진짜 게이트는 CI 쪽이다.
CI 의 Flutter 버전(`.github/workflows/ci.yml`)은 로컬 전역 Flutter 와 같은 값을 유지할 것. 어긋나면 문제가 조용해진다.
배포는 로컬 `flutter build ipa` + `scripts/upload_testflight.sh`(altool) 경로다. Xcode Cloud 는 쓰지 않는다.

## 자주 쓰는 명령
- `flutter run` · `flutter test` · `flutter analyze`
- `flutter build apk` · `flutter build ios`
- `supabase functions deploy <name>` · `supabase migration up`
- `supabase functions serve` (로컬 Edge Function 테스트)
