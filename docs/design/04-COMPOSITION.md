# 밀키웨이 컴포지션 룰 (스크린 · 씬 · 섹션 · 카드)

> **작성일**: 2026-08-17
> **상위**: `01-DESIGN_PHILOSOPHY.md`(원칙 1 밤 · 2 여운 · 3 별빛 · 4 하나의 문법) · `02-TYPOGRAPHY.md` · `03-COMPONENTS.md`
> **원천(실측)**: `previews/r1-*.html`. Carat의 골격(위계·반복·정렬선·단일강조·밀도교대)을 밀키웨이 밤 톤으로 번역.
> **목적**: 어떤 화면을 만들어도 일관된 배치·간격·리듬. 추상 금지, 모든 값은 px.

---

## 0. 관통 4원칙

1. **단일 좌측 정렬선 20px.** 헤더·섹션 제목·카드·CTA의 좌단이 예외 없이 20px. 가로 스크롤(스토리·캐러셀)만 우측 오버플로 허용, 첫 아이템 좌단 20.
2. **8pt 그리드(4pt 반허용).** 구조 간격은 8배수, 미세는 4배수.
3. **밀도 교대.** 조밀(캐러셀·리스트)↔여유(단일 카드·히어로)를 번갈아. 같은 밀도 3연속 금지.
4. **강조 1개 + 색은 하나.** 한 스크린 주강조 1개. accent(초록)는 **Lyra/행동**에만(원칙 3). 색면 카드 2연속 금지.

## 1. 스크린 프레임

| 항목 | 값 |
|------|-----|
| 폭 | 390 기준(최대 430, 초과 시 중앙) |
| 좌우 패딩 | **20** (예외 없음) |
| 배경 | `#181818` 단일. 표면 +2~4%만(원칙 1) |
| 헤더 유리(공통) | 모든 상단 유리 = **`GlassBackground`** 하나로 통일 = **GPU 셰이더 progressive blur**(`inspire_blur`, 위=진하게→아래=0, 상태바까지 자연스럽게, **단일 셰이더라 밴딩 없음**) + **배경색(#181818) 옅은 그라데이션 틴트**(0.4→0, 정지 땐 안 보임). `main()`에서 `Inspire.warmUp()` 1회. **불투명/다크단색/흰색 틴트/sliced-blur 금지**(막·색·층·밴딩). 상세·레슨런: `handoff/glass-appbar.md` |
| 헤더 CASE A (타이틀+필터칩: 책·메모탭) | `glassAppBar(title:, bottom: filterBar(칩))` + `extendBodyBehindAppBar:true` + 본문 top `glassTopPadding(context, bottomHeight: kFilterBarHeight)`. **칩 뒤 배경 넣지 말 것**(투명, 블러 위에 뜸) |
| 헤더 CASE B (타이틀만/상세: 책상세·메모상세·캘린더·검색) | `glassAppBar(title:, leading: BackButton)` + 본문 top `glassTopPadding(context)` (bottomHeight 없음) |
| 헤더 CASE C (타이틀 없음: 홈·프로필) | body를 `Stack`으로: 스크롤(`glassStatusTop(context)`, **SafeArea top 금지**) + `Positioned(top:0, child: GlassStatusBar())` |
| 필터/세그먼트 | **filterBar**(높이 44, 좌 20, 하단 여백 6)로 앱바 하단 스티키. 배경 투명. **탭마다 다르게 두지 말 것** |
| 하단 | BottomNav(홈/책/메모/나) + 상단 border 1px. FAB는 홈만 |
| safe-area | 상단 헤더·하단 탭에 가산 |

## 2. 간격 위계 (여백=여운, 원칙 2)

```
씬 경계        32~36   (성격 다른 큰 묶음 사이. 스토리→섹션, 섹션→섹션)
섹션 헤더→콘텐츠 14~16
카드 간         0(구분선) ~ 12
카드 내부       외곽 16~18 / 요소 간 8~14
카드 제목→본문   8~10 / 본문→메타 11~13
```
- **넓히는 건 씬 경계에서만.** 나머지는 고정.
- 외곽 패딩 ≥ 내부 최대 간격.

## 3. 위계 = 밝기 (원칙 3)

| 위계 | 색 토큰 | 예 |
|------|---------|-----|
| 최상위 | `white #FFF` / `textPrimary #ECECEC` | 화면 타이틀, 메모 본문, 카드 제목 |
| 보조 | `textSecondary #838383` | 저자, 책 제목(메타), 서브카피 |
| 최약 | `textTertiary #646464` | 페이지, 시간, 힌트 |
| 강조(유일) | `accent #48FF00` | Lyra, 주 행동(CTA/FAB), 스토리 새 활동 링 |

> 색으로 강조하지 말고 **밝기**로 위계. accent는 한 화면에서 의미(=Lyra/행동)로만.

## 4. 카드 내부 정렬

- 텍스트 전부 **좌측 정렬**.
- MemoCard: 작성자 행(Avatar center 정렬) → 본문 → 메타(책 좌 / 페이지 우, space-between).
- 표지+텍스트(WeeklyBook·Recommend): 이미지-텍스트블록 **center 정렬**.
- 리스트 구분: 카드 간 `1px #202020` 선(연속 메모), 캐러셀은 gap 12.

## 5. 밀도·리듬 (레이아웃별)

| 레이아웃 | 규격 |
|----------|------|
| 스토리 원 | 원 62, gap 14, 첫 아이템 20 |
| 표지 캐러셀 | 92x136, gap 12 |
| 메모 리스트 | 세로, 카드 padding 20~22, 구분선 |
| 단일 강조 카드 | 좌우 20 마진, radius 16, padding 18 |

## 6. 화면 레시피 (씬 구성)

### 홈(기존, 책 있음)
```
헤더(로고)
[씬 A 나] 스토리 원(좋아하는 책, 조밀)         [→36]
[씬 B 지금] LyraQuestionCard.home (여유·색면 1) [→36]
[씬 C 발견] WeeklyBookCard (중간)              [→34]
           DiscoveryCarousel (조밀)
BottomNav + FAB
```
- 강조 1개 = Lyra 카드(유일 색면). 발견은 담백하게 교대.

### 홈(빈, 저장 책 0)
```
헤더 → 인사(2줄) → RecommendedBookCard(주인공, 색면 1) [→34] → DiscoveryCarousel → BottomNav
```

### 메모 탭
```
헤더(타이틀 24 + SegmentFilter 전체/내 메모)
ComposePrompt
LyraQuestionCard.feed (색면 1)
MemoCard × N (구분선, 시계열)
```

### 책 상세
```
nav(‹)
BookHero (표지+제목+저자+출판사/출간일+상태)     [→28]
BookDescription (더보기 아코디언)
PrimaryCTA "이 책에 메모 남기기"
LyraQuestionCard.bookDetail (색면 1)             [→34]
"이 책을 읽은 사람들" + SegmentFilter(함께/내 메모)
MemoCard × N (시계열)
```

## 7. 전환·로딩 — 부드러움은 규칙이다 (예외 없음)

여백이 여운이면, **전환은 호흡**이다. 뚝뚝 끊기거나 깜빡이거나 섹션이 줄었다 늘어나는 건
밤하늘에 스트로보를 켜는 것과 같다. 아래는 **선택이 아니라 강제**다. 어딘 쓰고 어딘 안 쓰기 금지.

**3규칙**
1. **재로드 중엔 이전 데이터 유지.** 데이터를 이미 보여주다 갱신될 땐 스피너로 갈아치우지 말 것.
   Riverpod `.when(skipLoadingOnReload: true, skipLoadingOnRefresh: true)`.
2. **최초 로딩은 고정 높이.** 로딩 placeholder가 콘텐츠보다 작아 섹션이 줄었다 늘어나면 점프가 생긴다.
   섹션 로딩은 고정 높이 박스 안에 스피너.
3. **상태 교체는 크로스페이드.** 로딩↔데이터↔빈상태 전환은 즉시 갈아치우지 말고 180ms 페이드.
4. **세그먼트/탭은 미리 구독(prefetch).** 세그먼트 전환 시 콜드 provider가 스피너를 띄우면 끊긴다.
   전환 대상 provider를 **둘 다 `ref.watch`** 해서 첫 전환부터 즉시.

**구현 (닫힌 방법)**
- **섹션(내부 콘텐츠, intrinsic 높이)**: `AsyncView<T>` 컴포넌트 사용(03-COMPONENTS). 위 1~3을 내장.
  스피너를 직접 박지 말 것.
- **전체 높이 목록(Expanded 안 ListView)**: AnimatedSwitcher가 목록 높이를 깨므로 `AsyncView` 대신
  인라인 `.when(skipLoadingOnReload/Refresh: true)` + 규칙 4(prefetch) 적용.
- **화면 전환(메모 상세 등)**: 카드가 이미 가진 데이터를 `extra`로 넘겨 **즉시 렌더**, 서버 값은 뒤에서 갱신.
  진입 시 풀스크린 스피너로 막지 말 것.

## 8. 체크리스트 (구현 전)
- [ ] 좌측 20 정렬선 지켰나
- [ ] 간격 8/4 배수, 씬 경계에서만 넓혔나
- [ ] 주강조 1개, accent는 Lyra/행동에만
- [ ] 위계를 밝기로(색 남용 X)
- [ ] 밀도 교대(조밀↔여유), 색면 2연속 아님
- [ ] MemoCard 날짜/수정됨 규칙, 미구현 액션 없음
- [ ] AI 금지 기호 없음, 짧은 UI 끝 마침표 없음
- [ ] **비동기 렌더는 §7 준수 - 섹션은 AsyncView, 목록은 skipLoadingOnReload+prefetch, 깜빡임/점프 0**
</content>
