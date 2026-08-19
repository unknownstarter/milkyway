# 📐 Milkyway 리팩토링 PRD (Product Requirements Document)

> **프로젝트**: Milkyway App 전면 리팩토링
> **목표**: UI/UX 개선, 코드 품질 향상, 유지보수성 강화
> **원칙**: 기능 100% 보존

---

## 1. 프로젝트 개요

### 1.1 배경
현재 Milkyway 앱은 기능적으로는 완성되었으나, 다음과 같은 문제가 있습니다:
- 디자인 시스템 부재로 인한 일관성 부족
- 코드 중복 (특히 권한 처리, 이미지 picker)
- GoRouter 네비게이션 구조 문제 (스택 쌓임)
- 스타일 하드코딩 및 인라인 스타일

### 1.2 목표
- ✅ **사용성 개선**: 깔끔하고 일관된 UI/UX
- ✅ **네비게이션 최적화**: GoRouter 제대로 활용
- ✅ **유지보수성 향상**: 코드 중복 제거, 구조 개선
- ✅ **기능 100% 보존**: 모든 비즈니스 로직 유지

### 1.3 범위
- **포함**: UI, 스타일, 컴포넌트 구조, 네비게이션
- **제외**: DB 스키마, API 로직, 비즈니스 규칙

---

## 2. 디자인 요구사항

### 2.1 디자인 시스템

> ⚠️ **2026-05-29 코드 실측 기준 동기화.**
> 본 절은 더 이상 "이상적 계획"이 아니라 **현재 코드베이스의 실제 사용 토큰**을 기록한다.
> 진실의 원천: `lib/core/theme/{app_colors, app_typography, app_spacing}.dart`.
> 토큰을 늘리거나 바꿀 때 이 절을 동시에 갱신할 것.

#### 색상 팔레트 — `lib/core/theme/app_colors.dart`

**Background & Surface**
| 토큰 | Hex | 코드 빈도 | 용도 |
|---|---|---|---|
| `bgPrimary` | `#181818` | 51회 | 메인 화면 배경 (`AppTheme.scaffoldBackgroundColor`) |
| `surface` | `#1A1A1A` | 28회 | 기본 카드 |
| `surfaceMuted` | `#242424` | 18회 | 스낵바, 보조 패널 |
| `surfaceElevated` | `#2C2C2C` | 4회 | 도드라진 카드 (collapsed reading section 등) |

**Text**
| 토큰 | Hex | 코드 빈도 | 용도 |
|---|---|---|---|
| `textPrimary` | `#ECECEC` | 26회 | 본문/주요 텍스트 |
| `textSecondary` | `#838383` | 41회 (최다) | 저자, 메타, 시간 |
| `textTertiary` | `#646464` | 13회 | placeholder, disabled |
| `textBright` | `#DEDEDE` | DEDEDE/DADADA 통합 | 거의 흰색 강조 |

**Accent**
| 토큰 | Hex | 코드 빈도 | 용도 |
|---|---|---|---|
| `accentGreen` | `#48FF00` | 17회 | 브랜드 액센트 — 토글, 강조 라인, 주요 액션 |
| `accentPurple` | `#4117EB` | 4회 (격리) | **메모 추가 모달 한정**. 새 컴포넌트는 가급적 `accentGreen` 사용 |

**Divider**: `divider = #313131` (4회)

> ⚠️ **미구현 영역** — 이전 계획에 있던 다음 컬러군은 **현재 코드에 존재하지 않음**:
> - Semantic Colors (Success/Warning/Error/Info) — 에러 텍스트는 `Colors.red` (Material 기본) 직접 사용
> - Book Status Colors (Want to Read/Reading/Completed) — 상태는 텍스트로만 표시
>
> 추가가 필요하면 별도 작업으로 토큰 정의 + 적용까지 한꺼번에 진행할 것.

#### 타이포그래피 — `lib/core/theme/app_typography.dart`

**폰트 패밀리**: `Pretendard` (전역 통일, 코드 내 175회 명시)

| 토큰 | Size / Weight | Height | 용도 |
|---|---|---|---|
| `display` | 28 / Bold | 1.2 | 최상위 타이틀 |
| `heading` | 24 / w600 | 1.25 | 화면 메인 헤더 |
| `title` | 20 / w600 | 1.3 | 섹션 헤딩 (가장 흔함) |
| `subtitle` | 18 / w600 | 1.3 | 카드 내 강조, 다이얼로그 |
| `body` | 16 / w400 | 1.5 | 본문 (91회) |
| `bodyBold` | 16 / w600 | 1.5 | 본문 강조, 버튼 라벨 |
| `bodySmall` | 14 / w400 | 1.5 | 보조 설명 |
| `caption` | 12 / w400 | 1.4 | 메타정보 |
| `label` | 12 / w600 | 1.2 | 배지, 태그 |

> Letter spacing은 토큰에 미반영. 필요한 경우 호출처에서 `.copyWith(letterSpacing: ...)`.

#### Spacing & Layout — `lib/core/theme/app_spacing.dart`

**Spacing scale**: `xs(4) / sm(8) / md(12) / base(16) / lg(20) / xl(24) / xxl(32) / xxxl(40)`

- 화면 좌우 표준 패딩: `AppSpacing.pageHorizontal` = `EdgeInsets.symmetric(horizontal: 20)` (50회)

**Radius scale** — `AppRadius`:
| 토큰 | 값 | 빈도 | 용도 |
|---|---|---|---|
| `cover` | 8 | 23회 | 책 표지 |
| `card` | 12 | 37회 (최다) | 카드 기본 |
| `cardLarge` | 16 | 6회 | 큰 카드 |
| `pill` | 20 | 18회 | 알약 버튼 |
| `modal` | 24 | 5회 | 모달 시트 |

### 2.2 디자인 방향
- **미니멀**: v0 스타일 참고, 깔끔하고 명확
- **별 테마**: 최소한만 적용 (로그인/스플래시)
- **파스텔/그라데이션**: 사용하지 않음
- **비비드**: 피하고 차분한 톤 유지

---

## 3. 기능 요구사항

### 3.1 절대 변경 금지 항목

#### 인증 & 회원
- Google/Apple OAuth 로그인 플로우
- 온보딩 프로세스 (닉네임 → 프로필 이미지 → 책 소개)
- 닉네임 Validation (2-20자, 특수문자 제외)
- onboarding_completed 플래그 체크

#### 책 관리
- Naver Book Search API 연동
- ISBN 중복 체크
- 책 상태 ('읽고 싶은', '읽는 중', '완독')
- user_books 관계 테이블 로직

#### 메모 관리
- 페이지 번호 저장
- 이미지 첨부 (Supabase Storage)
- visibility (private/public)
- 메모 pagination (limit: 10)

#### 데이터베이스
- 모든 테이블 구조
- RLS 정책
- Foreign Key Constraints
- Check Constraints

### 3.2 변경 허용 항목

#### UI/UX
- 컴포넌트 구조 및 위젯 분리
- 색상, 폰트, 간격 (디자인 시스템 적용)
- 레이아웃 및 애니메이션
- 빈 상태, 에러 상태 UI

#### 네비게이션
- GoRouter 라우트 구조
- ShellRoute 활용한 BottomNav 통합
- Named routes 및 pathParameters
- 화면 전환 방식 (Navigator → context.go/pop)

#### 코드 구조
- Provider 파일 위치
- 서비스 레이어 추출 (중복 제거)
- 에러 타입 표준화
- 로깅 방식 통일

---

## 4. 기술 요구사항

### 4.1 아키텍처
- **패턴**: Clean Architecture (Data-Domain-Presentation)
- **상태 관리**: Riverpod (@riverpod annotation)
- **라우팅**: GoRouter
- **테마**: Material Design 3

### 4.2 컴포넌트 구조
```
lib/core/
  theme/              # 디자인 시스템
    - app_colors.dart
    - app_typography.dart
    - app_spacing.dart
    - app_constants.dart
    - app_theme.dart
  
  presentation/
    widgets/          # 공통 컴포넌트
      buttons/
      layouts/
      states/
      inputs/
      images/
      dialogs/
      animations/
  
  services/           # 비즈니스 로직 재사용
    - permission_service.dart
    - image_picker_service.dart
    - storage_service.dart
  
  utils/              # 유틸리티
    - validators.dart
    - formatters.dart
    - logger.dart
```

### 4.3 GoRouter 구조
```
/ (Splash)
/login
/onboarding/nickname
/onboarding/profile-image
/onboarding/book-intro

ShellRoute (with BottomNav):
  /home
  /books
  /books/detail/:id
  /books/search
  /memos
  /memos/detail/:id
  /memos/create
  /memos/edit/:id
  /profile
```

---

## 5. 성공 기준

### 5.1 기능 검증
- ✅ 모든 기존 기능 정상 동작
- ✅ 로그인/회원가입 플로우 정상
- ✅ 책 검색/등록/상태 변경 정상
- ✅ 메모 CRUD 정상
- ✅ 이미지 업로드 정상

### 5.2 코드 품질
- ✅ 코드 중복 80% 감소
- ✅ 일관된 코딩 스타일
- ✅ 명확한 파일 구조
- ✅ 적절한 주석 및 문서

### 5.3 성능
- ✅ 네비게이션 응답 속도 개선
- ✅ 불필요한 rebuild 제거
- ✅ 이미지 로딩 최적화

### 5.4 사용자 경험
- ✅ 일관된 디자인
- ✅ 직관적인 네비게이션
- ✅ 부드러운 애니메이션
- ✅ 명확한 에러 메시지

---

## 6. 마일스톤

### Phase 1: 디자인 시스템 (1-2일)
- [ ] 색상 팔레트
- [ ] 타이포그래피
- [ ] Spacing & Constants
- [ ] Material Theme 3

### Phase 2: 서비스 레이어 (1-2일)
- [ ] Permission Service
- [ ] ImagePicker Service
- [ ] Storage Service
- [ ] API Config

### Phase 3: 공통 컴포넌트 (2-3일)
- [ ] 버튼, 레이아웃
- [ ] 상태, 입력
- [ ] 이미지, 다이얼로그
- [ ] 애니메이션

### Phase 4: 유틸리티 & 에러 처리 (1일)
- [ ] Validators
- [ ] Formatters
- [ ] AppLogger
- [ ] AppException

### Phase 5: Provider 구조 (1일)
- [ ] Provider 파일 분리
- [ ] @riverpod 전환

### Phase 6: GoRouter (1-2일)
- [ ] 라우트 재설계
- [ ] MainShell 구현
- [ ] Named Routes

### Phase 7: Repository 통합 (1일)
- [ ] BookRepository 통합
- [ ] 중복 메서드 제거

### Phase 8: 화면 리팩토링 (4-5일)
- [ ] Home, BookShelf, MemoList
- [ ] BookDetail, MemoDetail
- [ ] Profile, Auth, Onboarding

### Phase 9: 최적화 & 정리 (1-2일)
- [ ] Provider 최적화
- [ ] 이미지 최적화
- [ ] Asset 정리
- [ ] 전체 테스트

---

## 7. 리스크 관리

### 7.1 주요 리스크
| 리스크 | 확률 | 영향 | 완화 방안 |
|--------|------|------|-----------|
| 네비게이션 변경 시 기능 손상 | 중 | 고 | 단계별 테스트, 기존 로직 최대한 유지 |
| Provider 전환 시 상태 손실 | 중 | 중 | 점진적 전환, 철저한 테스트 |
| 권한 처리 로직 통합 실수 | 저 | 고 | 기존 로직 100% 복사, 검증 |
| DB 쿼리 실수로 변경 | 저 | 고 | 코드 리뷰, REFACTORING_RULES.md 준수 |

### 7.2 롤백 계획
- Git branch 전략: `refactor/phase-{N}`
- 각 Phase 완료 시 커밋
- 문제 발생 시 이전 Phase로 롤백

---

## 8. 참고 문서
- `REFACTORING_RULES.md`: 리팩토링 절대 규칙
- `BUSINESS_LOGIC_POLICY.md`: 비즈니스 로직 정책
- `DATABASE_SCHEMA.md`: DB 구조 문서

---

**작성일**: 2025-01-22
**작성자**: Product & Dev Team
**승인**: 대기 중
**버전**: 1.0

