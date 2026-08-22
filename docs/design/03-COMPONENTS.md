# 밀키웨이 컴포넌트 인벤토리 (닫힌 집합)

> **작성일**: 2026-08-17
> **상위**: `01-DESIGN_PHILOSOPHY.md`(원칙 4 하나의 문법) · `02-TYPOGRAPHY.md`
> **원칙**: 컴포넌트는 **닫힌 집합**이다. 새 화면을 위해 새 카드를 발명하지 않고 아래 variant를 쓴다. 인라인 재발명 금지(중복 사고: `memo_card`/`add_action_modal` 이중, 바텀네비 2개).
> **근거 목업**: `previews/r1-home.html` · `r1-home-empty.html` · `r1-memo-feed.html` · `r1-book-detail.html`
> **상태 공통**: 모든 탭 요소는 `default` / `pressed`(scale .98). 로딩=스켈레톤, 에러=섹션 격리(숨김), 빈=안내.

---

## 원자 (Primitives)

| 컴포넌트 | 용도 | 토큰 · 규격 |
|----------|------|-------------|
| **Avatar** | 사용자 표식 | 원형. `sm 34` / `md 40`. 이니셜 or 이미지. bg `surface`, border `#333` |
| **Chip / Badge** | 상태·라벨 | pill(999). `수정됨`=accent 소프트, `내 메모`=surface, `오늘의 물음`=accent 소프트. `type/label`(12/600) |
| **StatusChip** | 읽기 상태 | 테두리 pill. accent. "읽는 중 38%" / "완독" / "읽고 싶은" |
| **SegmentFilter** | 필터 탭 | 가로 pill 칩. 활성=`white` bg + 검정. 비활성=`surface`+`border`. `type/segment` 12.5/600 |
| **PrimaryCTA** | 주 행동 | 풀폭 h50~54, radius 12~14, bg `accent`, 검정 텍스트 15/800 |
| **GhostCTA** | 보조 행동 | 테두리 pill, accent 텍스트+테두리(예: "이 물음에 메모 남기기") |
| **BottomNav** | 전역 내비 | 홈 / 책 / 메모 / 나. 활성 `white`, 비활성 `tertiary`. **구현체 1개로 통일**(기존 2개 폐기) |
| **FAB** | 메모 쓰기 | 원형 56, bg `accent`, 검정 `+`. 홈에만 |
| **AppDialog** (`showAppConfirm`) | 확인 팝업 | 제목+본문+취소/확인. `surface`+`modal 24`. 톤 `accent`(긍정)/`danger`(파괴). 앱 전역 팝업은 이걸로 통일(AlertDialog 직접 X) |
| **AsyncView** | 비동기 섹션 렌더 | 로딩/에러/빈/데이터를 **부드럽게**(skipLoadingOnReload+고정높이+크로스페이드). 섹션 로딩에 스피너 직접 박기 금지. 규칙 `04-COMPOSITION.md §7` |
| **glassAppBar** | 앱바(표준) | 반투명 55% + 블러 18(콘텐츠가 뒤로 비쳐 넓어 보임). `Scaffold(extendBodyBehindAppBar: true)` + 스크롤 본문 상단 `glassTopPadding` 필수. 정렬/세그먼트 칩은 `bottom`에 넣어 상단 스티키. 불투명 AppBar 직접 쓰기 지양 |

## 조합 컴포넌트 (Composite)

### MemoCard ★핵심 재사용
- **용도**: 메모 표시(피드·책 상세 공용).
- **anatomy**: [작성자 행(선택): Avatar + 이름 + 날짜 + tag] + 본문(`body` 16/1.6) + 메타(책 / 페이지).
- **날짜 규칙**: 기본 `created_at`. `updated_at > created_at`이면 **`수정됨` 칩 + 날짜=수정일**.
- **variant**: `feed`(작성자+책+페이지) / `bookDetail`(작성자+페이지, 책 생략) / `mine`(`내 메모` 칩) / `others`.
- **state**: default / edited(수정됨) / pressed.
- **금지**: 별·잇기·담기 같은 미구현 액션 노출(받을 플로우 없음).

### LyraQuestionCard ★엔진
- **용도**: Lyra의 물음 노출(N3). 톤=친근·위트, 이모지 OK, AI 기호 금지.
- **anatomy**: [Avatar `L`/dot + "Lyra" or "Lyra의 물음"] + [tag "오늘의 물음"] + 물음 본문(15~15.5/1.6) + [GhostCTA "이 물음에 메모 남기기"].
- **variant**: `home`(지금 읽는 책 미니 표지 헤더 + 물음 + CTA) / `feed`(메모 탭) / `bookDetail`(CTA 없이 물음만) / `inRecommend`(추천 카드 하단).
- **스타일**: `surface` + accent 소프트 그라데이션 딤(원칙 3: 유일한 색면). border `#232323`.

### RecommendedBookCard (빈 홈 주인공)
- **용도**: 저장 책 0일 때 최근 공개 메모 있는 책 추천.
- **anatomy**: [표지 76x112 + 작성자 생각 라벨 + 메모 인용 + 책/저자] + [LyraQuestion 프리뷰] + [PrimaryCTA "저장하고 답하기"].
- **폴백**: 최근 공개 메모 없음/오래됨 → DiscoveryCover 추천 → 큐레이션 프리셋.

### StoryCircle (좋아하는 책)
- **용도**: 홈 상단 가로 스크롤. 인스타 스토리 문법.
- **anatomy**: 링(62) + 표지 원형(58) + 라벨(11).
- **variant**: `new`(초록 conic 링 = 새 메모/물음) / `seen`(회색 링) / `add`(+).

### DiscoveryCover / DiscoveryCarousel
- **용도**: "다른 사람이 담은 책". 표지만 + 메타(시간/누구).
- **규격**: 표지 92x136, radius 8, meta `caption`.

### WeeklyBookCard
- **용도**: 이번 주 함께 읽는 책(N2). 단일 강조.
- **anatomy**: 표지 74x108 + 제목 + 저자 + 라이브("지금 N명이 함께 읽는 중", accent dot).

### BookHero
- **용도**: 책 상세 상단(기존 유지).
- **anatomy**: 표지 104x154 + 제목(최대 3줄) + 저자 + 출판사/출간일 + StatusChip.

### BookDescription (기존 유지)
- **용도**: 책 소개. **240자 초과 시 자르고 "더보기" 아코디언**(기존 `book_detail_screen` 로직).
- **anatomy**: h3 "책 소개" + 본문(`bodySmall` 14/1.65) + "더보기"(chevron).

### ComposePrompt
- **용도**: 메모 쓰기 진입(메모 탭 상단).
- **anatomy**: Avatar/`+` + "오늘 읽은 문장을 남겨보세요"(secondary).

---

## 화면별 사용 컴포넌트 매핑

| 화면 | 컴포넌트 |
|------|----------|
| 홈(기존) | StoryCircle · LyraQuestionCard`home` · WeeklyBookCard · DiscoveryCarousel · BottomNav · FAB |
| 홈(빈) | RecommendedBookCard · DiscoveryCarousel · BottomNav |
| 메모 탭 | SegmentFilter · ComposePrompt · LyraQuestionCard`feed` · MemoCard`feed` |
| 책 상세 | BookHero · BookDescription · PrimaryCTA · LyraQuestionCard`bookDetail` · SegmentFilter(함께/내 메모) · MemoCard`bookDetail` |

## 구현 (클린 아키텍처)
- 공용 원자·조합은 `lib/core/presentation/widgets/`(전역) 또는 각 feature `presentation/widgets/`.
- 신규: `Saju*` 아님 — 밀키웨이는 `Mw*` 없이 의미명(`MemoCard`, `LyraQuestionCard`, `StoryCircle`). 기존 위젯 grep 후 재활용, 인라인 재발명 금지.
- 토큰만 사용(`AppColors`/`AppTypography`/spacing). 인라인 스타일 금지.
</content>
