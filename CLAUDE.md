# Milkyway — Claude Code 가이드

## 진실의 원천
**`docs/VISION_v2.md`** — 모든 작업의 기준. v0.1.0+17 출시 전까지 코드와 충돌 시 문서 우선.

## 새 세션 시작 시 읽기 순서 (필수)
1. **`docs/VISION_v2.md`** — 비전·코어 가치·Lyra 페르소나·IA·BM·로드맵
2. **`REFACTORING_RULES.md`** — 절대 변경 금지 영역 (DB 스키마·OAuth·validation 등)
3. **`BUSINESS_LOGIC_POLICY.md`** — 회원/책/메모 정책, RLS, 에러 처리
4. **`DATABASE_SCHEMA.md`** — 6개 테이블 + ERD + Storage bucket
5. **`docs/PRD.md`** — v1.0 기록 보존. v2와 충돌 시 v2 우선
6. **`.claude/agents/`** — 전문 직군 페르소나. 필요 시점에 선택 호출

작업 시작 전 체크:
- [ ] VISION v2 해당 절 읽었나
- [ ] 영구 금지 항목(§6.2) 위반 없나
- [ ] 현재 로드맵 단계 확인 (현재: **v0.1.0+17 준비 중**)

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

## 영구 금지 (VISION v2 §6.2, §10)
광고 · affiliate · 인플루언서 초청 · 친구 초대 보상 · 좋아요 카운트 공개 · 팔로우/팔로워 · 푸시 남발(하루 1개 상한, 상호작용 알림은 별개) · 인기 메모 랭킹(좋아요/조회순 공개 순위) · "당신" 호칭 · 느낌표(시스템 카피).
> **소셜 전환 확정 (2026-08-22)**: 아래 3개는 도입 완료라 영구금지에서 제외.
> - **댓글**: 내가 저장한 책의 공개 메모에 댓글. 본인 수정/삭제, 타인 신고/숨김, 작성자에게 푸시. `lib/features/comments/`.
> - **랭킹**: '인기 메모 랭킹'(메모 좋아요/조회순 줄세우기)은 **여전히 금지**. 대신 **익명 백분위 + 개인 성장**(상위 N% / 지난주 대비 / 연속 읽은 날)만 허용. 타인 실명/메모 노출 없음. `lib/features/ranking/`.
> - **Lyra 일반 질문**: 홈에서 책 무관 질문도, 답하면 다음 질문. `general_questions` + `memo_question_context`(답 스냅샷).
> 이모지 적당히 허용(2026-08-17 개정). 팔로우/팔로워는 아직 미도입. `docs/handoff/2026-08-15-ACTION-PLAN.md` 참조.

## 카피 부호 룰 (AI 금지 기호 — 그로스커리어 §6.5 차용)
사용자 노출 카피 금지: em dash `—`, en dash `–`, 중간점 `·`, 곡선따옴표 `" " ' '`, 단일 말줄임 `…`. 짧은 구분자는 ` - ` 또는 `/`. 짧은 UI 문구(타이틀/라벨/CTA/안내/빈상태/토스트)는 끝 마침표 금지(문단형 본문은 예외). 카피는 `humanizer` 스킬로 윤문. 상세: `docs/design/01-DESIGN_PHILOSOPHY.md` 원칙 6.
> **개정 2026-08-17**: 이모지 허용(적당히). Lyra 톤 = 친근·위트(고상/겉멋 폐기). 위 영구금지의 "이모지"는 무효화. 단 AI 금지 기호는 이모지와 무관하게 절대 유지. "당신" 호칭 금지 유지.

## 자주 쓰는 명령
- `flutter run` · `flutter test` · `flutter analyze`
- `flutter build apk` · `flutter build ios`
- `supabase functions deploy <name>` · `supabase migration up`
- `supabase functions serve` (로컬 Edge Function 테스트)
