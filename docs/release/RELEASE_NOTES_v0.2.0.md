# 밀키웨이 0.2.0 (빌드 18) 릴리즈 노트

> 배포일: 2026-08-20 / 버전 `0.2.0+18`

---

## 스토어 What's New (사용자 공개 카피)

### 짧은 버전 (App Store / Play Store 상단)
함께 읽고 사유를 넓히는 공간으로 새단장했어요. 홈이 발견 피드로 바뀌고, Lyra가 책마다 물음을 건네요. 읽은 날을 기록하는 캘린더와 더 빨라진 이미지 로딩까지 📖

### 자세한 버전
📖 홈이 새로워졌어요
좋아하는 책과 지금 읽는 책, 다른 사람이 담은 책을 한눈에 봐요. 지금 읽는 책에는 Lyra가 사유를 넓혀줄 물음을 건네요

✍️ 메모가 더 쉬워졌어요
빈 페이지 대신 물음에 답하듯 메모를 남겨보세요. 메모 탭에서 내 메모와 다른 사람의 공개 메모를 함께 볼 수 있고, 작성 화면도 깔끔하게 새로 만들었어요

🗓 읽은 날을 기록해요
메모가 없어도 오늘 읽은 책을 한 번에 남기고, 캘린더에서 메모와 읽은 책을 날짜별로 돌아봐요

⚡ 더 빨라졌어요
이미지 로딩 속도를 개선했어요

그 외 온보딩과 마이페이지를 비롯한 여러 화면을 다듬었어요

---

## 내부 변경 요약 (팀용, 비공개)

**신규 기능**
- 홈 = 발견 피드 (스토리 원 / Lyra 물음 카드 / 다른 사람이 담은 책 / 최근 메모 책 / 읽기 배너 / 기록 스트립)
- 읽음 트래킹: `reading_logs` 테이블 + 오늘 읽음 토글 + 메모 저장 시 자동 읽음 + 캘린더 읽음 세그먼트
- 캘린더 (메모 / 읽음), 마이페이지 내 기록 통계

**디자인 시스템**
- 공용 컴포넌트 레이어 신설 (Avatar/Chip/StatusChip/SegmentFilter/Button/MemoCard/ComposePrompt/StoryCircle/DiscoveryCover/BannerBar/CachedImage)
- 전 화면 재디자인 (홈/메모탭/메모작성·편집·상세/책상세/마이페이지/캘린더)

**백엔드**
- Edge Function `get-public-memo-feed`, `lyra-question`(N3)
- RPC `get_recommended_books`
- 테이블 `reading_logs` (db push 완료)

**버그 수정**
- 새 온보딩 완료 플래그 미설정으로 인한 무한 재진입 루프 수정
- 새 메모가 수정됨으로 오검출되던 문제 수정 (created_at/updated_at 동일 타임스탬프 + isEdited 임계값)
- 이미지 캐싱 미적용으로 인한 로딩 지연 개선

**계측 (Firebase Analytics = GA4)**
- 미계측이던 메모 작성 KPI 복구
- 이벤트 네이밍 컨벤션 `view_/click_ + _in_<screen>` 채택
- 화면뷰 누락 보강 (메모탭 / 메모상세 / 캘린더 / 마이페이지)

**빌드 키 (참고)**
- Supabase URL/anon: `.env` (에셋 번들, gitignore) - API URL이 `.supabase.co` 인지 항상 확인
- Firebase: `lib/firebase_options.dart` (코드) + `android/app/google-services.json`
- Naver: 서버(Edge Function)에만. 클라 `--dart-define` 불필요
