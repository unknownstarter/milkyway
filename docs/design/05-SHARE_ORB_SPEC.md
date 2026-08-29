# 05 - 공유 오브 & 성장 카드 구현 스펙

> 상태: 초안 (2026-08-29) · 브랜치 `feature/share-orb`
> 목적: 모델 A(무료 공유 = 성장 엔진)를 실제 앱에 넣기 위한 구현 명세.
> 정합성: VISION v2 영구금지 위반 없음(광고/보상/좋아요랭킹 아님). 600명 전 프리미엄 금지 준수 - **이 기능은 전부 무료(공유하기 성격)**. 유료화 요소 0.
> BM 주의: 이건 유입/리텐션 기능이지 매출원이 아님. **BM은 계속 별도로 발굴해야 함(백로그 상시)** - 운영자 강조사항.

## 0. 한 줄 요약
유저가 읽고 남긴 데이터가 **진화하는 은하 오브 + 성장 카드**로 시각화되고, 그걸 **공유**하면 워터마크/딥링크가 붙어 자연 유입이 된다. 광고 예산 0 상황의 유일한 공짜 유입 채널.

---

## 1. 유저 플로우

```
[메모 7개 미만]
  홈 배너 "첫 오브를 만들어보세요 · 메모 n개 더" → 탭 → 바텀시트(오브 자전 + n개 더) → 메모 작성 유도
        ↓ (메모 7개 도달 = 게이트 해금)
[메모 7개 이상]
  오브 생성 · 프로필/홈에서 "내 우주" 진입
        ↓
  공유 카드 화면 (오브 + 스탯 + 연결(그때→지금) + 티어 배지)
        ↓ 공유 버튼
  카드 PNG 캡처 → public 버킷 업로드 → share code 발급 → 링크 생성
        ↓ 공유 시트(인스타/스레드/카톡/X/링크복사)
[받는 사람이 링크 클릭]
  Edge Function `share/{code}` → OG 미리보기(썸네일=오브, 타이틀=티어, 설명="너도 만들기")
                              → OS 감지 → App Store(iOS) / Play(Android) 랜딩
```

---

## 2. 티어 시스템

포인트 = `메모수 * 3 + 책권수`. **메모가 주동력(책의 3배 가중)**, 책은 보조. (임계값은 상수로 두고 튜닝)

| tier | 이름 | 포인트 | 오브 지름(px, 자산) | 색 서사 |
|---|---|---|---|---|
| t1 | 작은 성운 | 0~29 | 430 | 쿨 블루 |
| t2 | 별무리 | 30~89 | 468 | 블루바이올렛 |
| t3 | 별자리 | 90~199 | 506 | 바이올렛 + 나선 |
| t4 | 성단 | 200~499 | 544 | 마젠타 합류 |
| t5 | 은하 | 500~999 | 590 | 웜 골드코어 |
| t6 | 대은하 | 1000+ | 648 | 골드+마젠타+시안 |

- **오브 생성 게이트**: 메모 `>= 7` 일 때만 오브/공유 카드 노출. (7 미만은 배너)
- 티어 이름/임계값은 `lib/features/orb/domain/orb_tier.dart` 한 곳에서 관리.

---

## 3. 자산 (Assets)

- 배치: `assets/images/orb/orb_t1.webp ~ orb_t6.webp` (이미 복사+최적화, pubspec `assets/images/orb/` 등록됨)
- **최적화**: PNG→WebP q84(알파 유지). 6장 합계 **2.3MB → 884KB (62% 감소)**. 개당 78~93KB
- 생성 스크립트(마케팅 레포): `marketing/generate_galaxy_tiers.py` (재현 가능, 시드 고정) + `cwebp -q 84 -alpha_q 100 -m 6`
- **애니메이션 레이어링 (권장)**: 자전 시 유리 하이라이트는 고정, 내부 은하만 회전해야 자연스럽다. 두 방식 중 택1:
  - (A) **레이어 2장**: `orb_tN_galaxy.png`(내부) + `orb_tN_glass.png`(스펙큘러/림/엣지) 로 분리 출력 → Flutter에서 galaxy만 `RotationTransition`, glass는 고정 오버레이. **권장.**
  - (B) **단일 PNG**: 통짜 회전. 저속(1회전 20초+)이면 하이라이트 회전이 크게 안 거슬림. MVP 임시.
  - 생성기는 `build_orb_html`에 `galaxy`/`glass` 레이어가 이미 분리돼 있어 레이어별 출력 추가 용이.
- **forming(미생성) 오브**: t1을 `opacity .5 + saturate .7` 로 표시(별도 자산 불필요) + 진행 링 오버레이.

---

## 4. Clean Architecture 폴더

신규 feature 폴더로 격리(기존 오염 금지):

```
lib/features/orb/
  domain/
    orb_tier.dart            # Tier enum, 포인트→티어 resolver, 이름/색/자산경로
    share_payload.dart       # 카드에 들어갈 데이터 모델(스탯+연결)
  data/
    share_repository.dart    # 카드 업로드 + share_cards row + 링크
  presentation/
    providers/
      orb_providers.dart     # orbTierProvider, sharePayloadProvider, memoGateProvider
    widgets/
      orb_view.dart          # 오브(자전+글로우) 위젯
      orb_gate_banner.dart   # 홈 배너(<7)
      share_card.dart        # 공유 카드 위젯(RepaintBoundary)
    screens/
      my_orb_screen.dart     # 내 우주 화면
      share_card_screen.dart # 공유 카드 프리뷰 + 공유 버튼
```

의존성 방향 `presentation → domain → data` 준수. presentation은 Supabase 직접 호출 금지, repository 경유.

---

## 5. 데이터 계층 (재사용 최대화)

| 필요 | 상태 | 출처 |
|---|---|---|
| 읽은 책 권수 | ✅ 재사용 | `profileStatsProvider` → `ProfileStats.savedBooks` |
| 남긴 메모 수 | ✅ 재사용 | `profileStatsProvider` → `ProfileStats.memos` |
| 상위 백분위 | ✅ 재사용 | `myRankingProvider` → `RankingStats.topPercent` |
| 연속 읽은 날 | ✅ 재사용 | `myRankingProvider` → `RankingStats.streakDays` |
| 그때→지금 + Lyra 근거 | ✅ 재사용 | `ConstellationRepository.getConstellation()` (RPC `get_constellation`) 의 최강 엣지 1개 |
| 7개 게이트 | ✅ 재사용(MVP) | `ProfileStats.memos >= 7`. (성능용 전용 count RPC는 후순위) |
| 공유 카드 저장/링크 | ❌ 신규 | `share_cards` 테이블 + public 버킷 |

**연결 엣지 선택 휴리스틱** (`sharePayloadProvider`):
- `getConstellation()` 결과 edges 중 `rationale != null` 필터 → `strength` 최댓값. 동점이면 `reverses`(달라짐) > `extends`(확장) > `echo` > `similar` 우선(드라마틱한 순).
- 없으면(연결 없음) 카드는 스탯형으로 폴백(연결 블록 생략).

구현: `lib/features/orb/domain/orb_tier.dart` (테스트 `test/features/orb/orb_tier_test.dart` 통과). 요지:
```dart
int orbPoints(int books, int memos) => memos * 3 + books; // 메모 주동력
// 임계값 lo: t1 0 / t2 30 / t3 90 / t4 200 / t5 500 / t6 1000
const orbGateMemos = 7; // 오브 생성 최소 메모 수
```

---

## 6. 오브 위젯 (`orb_view.dart`)

- 입력: `OrbTier tier`, `bool animate`, `double size`.
- **자전**: `AnimationController`(period 20s, repeat) → galaxy 레이어 `RotationTransition`. glass 레이어 고정.
- **글로우 펄스**: 같은 컨트롤러의 sin 매핑으로 aura `Opacity`/`scale` 0.8~1.0 호흡(또는 별도 3s 컨트롤러).
- 레이어 (레이어링 A 기준):
  ```
  Stack:
    - Glow(aura)  : AnimatedBuilder opacity pulse
    - RotationTransition(galaxy 레이어 이미지)
    - Image(glass 레이어)  // 고정
  ```
- 단일 PNG(MVP B)면: `RotationTransition(Image(orb_tN.png))` + 뒤에 Glow.
- 성능: `RepeatingController` 1개, 화면 벗어나면 stop. 리스트 안에서는 정적 이미지.

---

## 7. 공유 카드 위젯/화면

- `share_card.dart`: 디자인 정본 = `marketing/generate_share_card*.py` 렌더 결과.
  - 구성: 상단(milkyway 워드마크 + 티어 배지) / 오브 / 헤드라인 / (연결 블록: 그때→지금 + 관계칩 + Lyra 근거) / 스탯 4(책·메모·상위%·연속) / 다음 단계 게이지 / 하단 훅("너의 우주는 어떤 모양일까").
  - 사이즈: 1080x1350(4:5) 기본. 스퀘어/스토리 파생.
  - **캡처**: `RepaintBoundary` + `boundary.toImage(pixelRatio: 1080/logicalWidth)` → PNG bytes.
- `share_card_screen.dart`: 프리뷰 + [공유] 버튼. 공유 전 **미리보기**로 어떤 메모가 노출되는지 확인시킴(프라이버시 안심).

---

## 8. 홈 배너 (`orb_gate_banner.dart`)

- 노출 조건: `memos < 7`. (7 이상이면 배너 숨김, 대신 "내 우주 보기" 진입점)
- 구성: "첫 오브를 만들어보세요" + "메모 n개만 더 남기면 오브가 생겨요" + 진행 바(memos/7) + forming 오브(진행 링).
- 탭 → 바텀시트: 큰 forming 오브 자전 + "오브가 n개 남았어요" + "지금 메모 쓰기" CTA(→ 메모 작성 라우트).
- 디자인 정본: `marketing/generate_home_banner.py`.

---

## 9. 공유 & 업로드 플로우 (`share_repository.dart`)

```
1. share_card 위젯 캡처: RepaintBoundary.toImage(pixelRatio = 1080 / logicalWidth) → 정확히 1080px 폭 (과대 캡처 금지)
2. 인코딩: JPG q85 (~150~250KB). OG/피드 호환 위해 JPG(WebP는 일부 OG 크롤러 미지원)
3. Storage public 버킷 `share_cards/{code}.jpg` 업로드 (upsert)
4. share_cards row upsert: {code(6자 base62), user_id, tier, image_path, payload}
5. 링크: https://<project-ref>.supabase.co/functions/v1/s/{code}  (내부 숏튼, 아래 10절)
6. share_plus 로 시트(이미지 파일 + 링크). 링크복사 지원.
```
- 버킷 **public** (메모 이미지와 동일 정책, `getPublicUrl`). 서명 URL 금지(만료 이슈, LESSONS 참조).
- 재공유 시 같은 code 재사용(오브 갱신 시 image 덮어쓰기 upsert).
- **사용감**: 공유 탭 → 로컬 캡처로 프리뷰 즉시 표시(낙관적) → 업로드는 백그라운드 → 완료 시 시트. 실패 시 재시도 버튼.

---

## 10. Edge Function `s` (내부 숏튼 + OG + OS 라우팅)

도메인 없이 만드는 최단 링크. `supabase/functions/s/index.ts` (신규). 함수명 `s`, 경로 `/s/{code}`, code=6자 base62. service_role로 code 조회 → OG HTML 반환.
- 최단 형태: `https://<project-ref>.supabase.co/functions/v1/s/{code}`
- code 생성: 앱에서 base62 6자(약 568억 경우의 수, 충돌 시 재생성). `share_cards.code` PK.

```ts
// GET /s/{code}
const { code } = parse(req.url);
const row = await admin.from('share_cards').select('tier,image_path').eq('code', code).single();
const img = publicUrl(row.image_path);
const tierName = TIER_KO[row.tier];         // '성단' 등
const html = `<!doctype html><html><head>
  <meta property="og:title" content="${tierName} 단계의 우주를 가지고 있어요">
  <meta property="og:description" content="지금 책 메모하고 우주 만들기">
  <meta property="og:image" content="${img}">
  <meta name="twitter:card" content="summary_large_image">
  <script>
    var ua=navigator.userAgent||'';
    if(/iPhone|iPad|iPod/i.test(ua)) location.replace('https://apps.apple.com/kr/app/id6741465148');
    else if(/Android/i.test(ua)) location.replace('https://play.google.com/store/apps/details?id=com.whatif.milkyway.android');
  </script></head>
  <body><a href="...">milkyway</a></body></html>`;
return new Response(html, { headers: { 'content-type': 'text/html; charset=utf-8' }});
```

- **MVP**: OG + OS별 스토어 랜딩. MMP/개발자포털 불필요.
- **후속**: Universal Links(iOS AASA) + App Links(Android assetlinks.json) 로 "앱 있으면 앱 열기". iOS scene 라이프사이클 파일 **건드리지 말 것**(별도 entitlement/AASA만).
- 호스트: **Supabase Edge Function URL 그대로 사용**(도메인 구매 안 함). 공유 링크 `https://<project-ref>.supabase.co/functions/v1/share?c={code}`. (후속에 원하면 커스텀 도메인 연결 가능하나 지금은 미도입)

---

## 11. DB (신규 테이블만, 스키마 변경 금지)

`supabase/migrations/2026XXXX_share_cards.sql`:

```sql
create table public.share_cards (
  code       text primary key,           -- 8자 uuid 축약
  user_id    uuid not null references auth.users(id) on delete cascade,
  tier       text not null,              -- 't1'..'t6'
  image_path text not null,              -- storage 경로
  payload    jsonb,                      -- 스탯/연결 스냅샷(선택)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.share_cards enable row level security;
-- 본인만 생성/수정
create policy "own insert" on public.share_cards for insert with check (auth.uid() = user_id);
create policy "own update" on public.share_cards for update using (auth.uid() = user_id);
-- 공개 링크는 Edge Function(service_role)이 조회 → 클라 select 정책은 최소(본인만)
create policy "own select" on public.share_cards for select using (auth.uid() = user_id);
create index on public.share_cards(user_id);
```
- 기존 테이블 스키마 변경 없음. `REFACTORING_RULES.md` 준수.

---

## 12. GA4 계측 이벤트

에러/이벤트 컨벤션(기존)과 동일 파이프. 최소 이벤트:

| 이벤트 | 파라미터 | 목적 |
|---|---|---|
| `orb_banner_view` | memos, remain | 게이트 배너 노출 |
| `orb_banner_tap` | remain | 액션 유도 클릭 |
| `orb_unlocked` | - | 메모 7 도달(활성화 마일스톤) |
| `orb_view` | tier | 내 우주/오브 조회 |
| `share_card_open` | tier, has_connection | 공유 카드 프리뷰 진입 |
| `share_sheet_open` | tier | 공유 시트 오픈 |
| `share_completed` | tier, channel | 실제 공유 완료 |
| `share_link_view`(서버) | tier | 링크 미리보기 조회(바이럴 도달) |
| `share_link_redirect`(서버) | os | 스토어 랜딩(유입) |

**판정 기준(4주)**: `share_completed / WAU >= 3%` 면 유료 테마(워터마크 제거 등) 붙일 근거. 미만이면 카드/카피 재설계.

---

## 13. 카피 (룰 준수 + humanizer)

- AI 금지 기호(em/en dash, 중간점, 곡선따옴표, 말줄임) 금지. 구분자 ` / `. 짧은 UI 마침표 금지. "당신" 금지. 느낌표 금지(시스템).
- 확정 문구:
  - 배너: "첫 오브를 만들어보세요" / "메모 {n}개만 더 남기면 오브가 생겨요"
  - 시트: "오브가 {n}개 남았어요" / "지금 메모 쓰기"
  - 카드 훅: "너의 우주는 어떤 모양일까"
  - 카드 헤드(연결형): "생각이 달라졌어요" / "그때의 나와 지금의 나"
  - OG: 타이틀 "{티어} 단계의 우주를 가지고 있어요" / 설명 "지금 책 메모하고 우주 만들기"
- 배포 전 `humanizer` 스킬로 윤문.

---

## 14. 마일스톤

- **M1 (MVP, 코어 루프)**: orb_tier + OrbView(단일 PNG 회전) + ShareCard 위젯 + 캡처/업로드 + share_cards 테이블 + Edge Function(OG+OS리다이렉트) + 홈 배너. → 공유 코어 루프 end-to-end.
- **M2 (진화/연결)**: 연결 카드(그때→지금) + 다음단계 게이지 + 레이어링 자전(galaxy/glass 분리) + 값서사 카피 옵션.
- **M3 (딥링크/최적화)**: Universal/App Links(앱 열기) + 커스텀 도메인 + 계측 대시보드 + (신호 확인 시) 유료 테마.

**리스크**
- 공유율이 낮으면(<3%) 모델 A 재설계 → C(소유권) 축 이동. 계측이 판단 근거.
- 연결 카드에 노출되는 메모가 유저 의도와 다를 수 있음 → 공유 전 프리뷰 필수, 편집(다른 연결 선택) 허용.
- 자전 성능(저사양 기기) → 리스트에선 정적, 상세에서만 애니.

## 16. 최적화 & 사용감 (운영자 필수 강조)

**이미지**
- 오브 자산: WebP q84 (2.3MB→884KB 완료). 표시 크기(오브 실제 노출 최대 ~360 logical)에 과대하지 않게.
- 공유 카드: 캡처 pixelRatio로 정확히 1080px 폭 → JPG q85(~150~250KB) → Supabase public 버킷 → 링크. 과대 캡처/원본 업로드 금지.
- 앱 내 이미지 표시: `CachedImage` 프로토콜(DEVELOPER_RULES §이미지) 준수. `Image.network` 직접 금지. 서명 URL 금지(public + getPublicUrl).

**애니메이션**
- 앱 내 애니는 전부 Flutter `AnimationController`(코드 구동, **파일 0바이트**). GIF는 마케팅 프리뷰 전용, 앱 미탑재.
- 자전 20s·글로우 3s, `vsync` 단일 컨트롤러 최소화. **화면 이탈 시 stop**, 리스트/썸네일에선 정적 이미지(애니 off). 저사양 기기 프레임 방어.

**사용감(자연스러움)**
- 공유: 탭 즉시 로컬 캡처 프리뷰(낙관적) → 업로드 백그라운드 → 시트. 스피너/실패 재시도 명확.
- 게이트 배너: 메모 작성 완료 시 카운트 실시간 반영(seen/revision 패턴), 7 도달 순간 해금 연출.
- 오브 진입: 로딩 중 저해상도/블러 → 로드 완료 시 선명(점진적). 끊김 없는 전환.

## 15. VISION/영구금지 체크
- 광고/affiliate/인플루언서보상/친구초대보상/좋아요·조회 랭킹 **아님**.
- 익명 백분위(상위 N%)만 노출, 타인 실명/메모 랭킹 없음 → 소셜 전환 정책 부합.
- 전 기능 무료 → 600명 전 프리미엄 금지 준수.
- "당신" 미사용, AI 금지 기호 미사용.
