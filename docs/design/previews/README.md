# Milkyway 화면 프리뷰 인벤토리 (Release 1)

> 작성일 2026-08-18. 헤드리스 Chrome으로 렌더한 목업 HTML/PNG. 노아 검토 완료분.
> 렌더: `"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --screenshot=out.png --window-size=390,H --force-device-scale-factor=2 file://<path>`
> 디자인 정본: `../01-DESIGN_PHILOSOPHY.md` ~ `../04-COMPOSITION.md`. 실행: `../../handoff/2026-08-15-ACTION-PLAN.md`.

## Release 1 화면 세트 (확정 목업)

| 화면 | 파일 | 핵심 |
|------|------|------|
| 온보딩 장르 | `onb-genre.html` | 선택 1~3개, 건너뛰기 가능. 추천 정렬용(게이팅 X) |
| 온보딩 책 담기 ★ | `onb-books.html` | 남이 담은/메모한 실제 책 + 사회적 증거 + 다중 담기. 온보딩 주인공 |
| 홈 (기존, 책 있음) | `r1-home.html` | 좋아하는 책 스토리 원 + 지금 읽는 책 Lyra 물음 카드 + 이번 주 함께 읽는 책 + 다른 사람이 담은 책 |
| 홈 (빈, 책 0) | `r1-home-empty.html` | 최근 공개 메모 있는 책 추천 카드(작성자 생각 + Lyra 물음 + 저장하고 답하기) |
| 메모 탭 (피드) | `r1-memo-feed.html` | 메모 남기기 + Lyra 물음 + 내/타인 메모. 액션 없음(본문+책/쪽만) |
| 메모 작성 (Lyra) | `memo-create.html` | Lyra 물음에 답하는 중 카드 + 본문 + 툴바(쪽/사진/공개토글) |
| 메모 작성 (일반) | `memo-create-plain.html` | Lyra 카드 없이 책 맥락 + 본문 + 툴바 |
| 메모 상세 | `memo-detail.html` | 작성자/날짜/수정됨 + 본문 + 이미지 + 책으로 이동 + 공개 표시 |
| 책 상세 | `r1-book-detail.html` | 기존 상위정보(표지/제목/저자/출판사/상태/책소개 더보기) + Lyra 물음 + 이 책을 읽은 사람들(함께/내 메모) |
| 캘린더 월 | `calendar-month.html` | 메모/책 세그먼트, 날짜 칩/점+개수 |
| 캘린더 바텀시트 | `calendar-sheet.html` | 날짜 탭 → 그날 리스트 → 하나 선택 → 상세 |
| 마이페이지 (나) | `mypage.html` | 프로필 + 나의 별자리 요약 + 설정 그룹 |

## 탭 IA
홈 · 책 · 메모 · 나 (바텀네비 1개로 통일). 캘린더 진입점 = 책 탭/메모 탭 앱바 아이콘(컨텍스트별 기본 모드).

## 핵심 플로우
- **온보딩**: 닉네임 → 프로필 → 장르(선택) → 책 담기 → 홈(채워진 서재 + Lyra 물음)
- **N3 엔진 루프**: 책 등록 → Lyra 물음 → 홈/메모탭/책상세 노출 → "이 물음에 메모 남기기" → 메모 작성(Lyra 카드) → 같은 책 상세 "함께"에 답이 모임
- **메모 진입점**: 홈 FAB / 책 상세 "이 책에 메모" / 메모 탭 compose = 일반 작성 · Lyra 물음 탭 = Lyra 카드 있는 작성
- **캘린더**: 탭 앱바 → 월뷰(메모/책) → 날짜 → 바텀시트 → 상세

## 공유 자원
- `ds.css` — 우주형 탐색안(01~05)용. Release 1은 각 파일 인라인 스타일(현 앱 디자인 시스템: #181818 · Pretendard · #48FF00). 코드 이식 시 `../02-TYPOGRAPHY.md` 토큰으로.
- 카피 규칙 준수: em대시/중간점/곡선따옴표/말줄임 없음, 짧은 UI 끝 마침표 없음, 이모지는 Lyra 콘텐츠 한정 허용.

## 초기 방향 탐색 (참고, 미채택 스킨)
`home.html`, `01-threads/02-cluster/03-curation/04-book-galaxy/05-oneline.html` — 우주형 풀리디자인 탐색. 방향(함께/사유확장)은 채택, 스킨은 현 앱 시스템 유지로 정리됨.
</content>
