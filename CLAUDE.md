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

## 영구 금지 (VISION v2 §6.2, §10)
광고 · affiliate · 인플루언서 초청 · 친구 초대 보상 · 좋아요 카운트 공개 · 팔로우/팔로워 · 댓글 · 푸시 남발(하루 1개 상한) · 인기 메모 랭킹 · "당신" 호칭 · 이모지 · 느낌표(시스템 카피).

## 자주 쓰는 명령
- `flutter run` · `flutter test` · `flutter analyze`
- `flutter build apk` · `flutter build ios`
- `supabase functions deploy <name>` · `supabase migration up`
- `supabase functions serve` (로컬 Edge Function 테스트)
