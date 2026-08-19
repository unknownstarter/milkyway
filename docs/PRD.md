# Milkyway App - Product Requirements Document (PRD)

## 📋 프로젝트 개요

**프로젝트명:** Milkyway - 독서 메모 관리 앱  
**버전:** 1.0.0  
**최종 업데이트:** 2024-12-19  
**개발 상태:** 개발 중

## 🎯 핵심 기능

### 1. 사용자 인증
- **Google 로그인** - OAuth 2.0 기반
- **Apple 로그인** - Sign in with Apple
- **프로필 관리** - 닉네임, 프로필 이미지 설정

### 2. 책 관리
- **책 등록** - 네이버 도서 API 연동
- **책 상태 관리** - 읽고 싶은, 읽는 중, 읽음
- **책 표지 표시** - 네트워크 이미지 로딩
- **책 상세 정보** - 제목, 저자, 출판사, 설명

### 3. 메모 관리
- **메모 작성** - 텍스트, 페이지, 이미지 첨부
- **메모 편집** - 기존 메모 수정
- **메모 삭제** - 메모 제거
- **메모 공개/비공개** - 가시성 설정

### 4. 홈 화면
- **스와이프 가능한 책 목록** - PageView 기반
- **포커싱 효과** - 선택된 책 강조
- **메모 섹션** - 선택된 책의 메모 표시
- **스크롤 가능한 메모 목록** - ListView 기반

## 🎨 디자인 시스템

> ⚠️ **2026-05-29 코드 실측 기준 동기화.**
> 값의 진실은 `lib/core/theme/` 하위의 토큰 파일이며, 본 문서는 그 요약본이다.
> 토큰과 본 문서가 어긋나면 **토큰을 신뢰**한다.

### 색상 팔레트 — `lib/core/theme/app_colors.dart`
| 토큰 | 값 | 용도 |
|---|---|---|
| `AppColors.bgPrimary` | `#181818` | 메인 화면 배경 (코드 내 51회) |
| `AppColors.surface` | `#1A1A1A` | 기본 카드 표면 (28회) |
| `AppColors.surfaceMuted` | `#242424` | 스낵바, 보조 표면 (18회) |
| `AppColors.surfaceElevated` | `#2C2C2C` | 강조 카드 (4회) |
| `AppColors.textPrimary` | `#ECECEC` | 본문/주요 텍스트 (26회) |
| `AppColors.textSecondary` | `#838383` | 보조 텍스트 — 가장 빈번 (41회) |
| `AppColors.textTertiary` | `#646464` | 흐린 텍스트, placeholder (13회) |
| `AppColors.textBright` | `#DEDEDE` | 거의 흰색 강조 텍스트 |
| `AppColors.accentGreen` | `#48FF00` | 브랜드 액센트 — 토글, 액션 강조 (17회) |
| `AppColors.accentPurple` | `#4117EB` | 메모 추가 모달 한정 보조 액센트 (격리 사용) |
| `AppColors.divider` | `#313131` | 구분선, 비활성 외곽선 |

> 에러 텍스트는 현재 `Colors.red` (Material 기본) 직접 사용. semantic 토큰(success/warning/error)은 **미구현**.
> Book Status별 색상도 **미구현** — 상태 표시는 텍스트로만.

### 타이포그래피 — `lib/core/theme/app_typography.dart`
폰트 패밀리: **Pretendard** (전역 통일)

| 토큰 | 사이즈 / 굵기 | 용도 |
|---|---|---|
| `AppTypography.display` | 28 / Bold | 최상위 타이틀, 로고 fallback |
| `AppTypography.heading` | 24 / w600 | 화면 메인 헤더 |
| `AppTypography.title` | 20 / w600 | 섹션 헤딩 (가장 흔함) |
| `AppTypography.subtitle` | 18 / w600 | 카드 내 강조, 다이얼로그 제목 |
| `AppTypography.body` | 16 / w400 | 본문 — 가장 빈번 (91회) |
| `AppTypography.bodyBold` | 16 / w600 | 본문 강조, 버튼 라벨 |
| `AppTypography.bodySmall` | 14 / w400 | 보조 설명 |
| `AppTypography.caption` | 12 / w400 | 메타정보, timestamp |
| `AppTypography.label` | 12 / w600 | 배지, 태그 |

### 레이아웃 — `lib/core/theme/app_spacing.dart`
| 토큰 | 값 | 비고 |
|---|---|---|
| `AppSpacing.lg` / `pageHorizontal` | 20px | 화면 좌우 표준 패딩 (50회) |
| `AppSpacing.base` | 16px | 기본 간격 |
| `AppSpacing.sm` / `xs` | 8 / 4 | 미세 간격 |
| `AppRadius.card` | 12px | 카드 기본 (37회) |
| `AppRadius.cover` | 8px | 책 표지 (23회) |
| `AppRadius.pill` | 20px | 알약 버튼 (18회) |

## 🏗️ 기술 스택

### Frontend
- **Flutter:** 3.16.0+
- **Dart:** 3.2.0+
- **Riverpod:** 상태 관리
- **GoRouter:** 네비게이션

### Backend
- **Supabase:** 백엔드 서비스
- **PostgreSQL:** 데이터베이스
- **Supabase Storage:** 파일 저장소

### 외부 API
- **네이버 도서 검색 API:** 책 정보 조회
- **Google Sign-In:** OAuth 인증
- **Apple Sign-In:** OAuth 인증

## 📱 화면 구성

### 1. 인증 화면
- **스플래시 화면** - 앱 로딩
- **로그인 화면** - Google/Apple 로그인
- **온보딩 화면** - 닉네임, 프로필 이미지 설정

### 2. 메인 화면
- **홈 화면** - 책 목록, 메모 섹션
- **책 목록 화면** - 등록된 책 관리
- **메모 목록 화면** - 모든 메모 관리
- **프로필 화면** - 사용자 정보

### 3. 상세 화면
- **책 상세 화면** - 책 정보, 메모 목록
- **메모 상세 화면** - 메모 내용, 이미지
- **메모 작성/편집 화면** - 메모 생성/수정

## 🔧 개발 규칙

### 코드 스타일
- **함수형 프로그래밍** 우선
- **const 생성자** 사용
- **명확한 변수명** 사용
- **80자 줄 길이** 제한

### 파일 구조
```
lib/
├── core/           # 공통 기능
├── features/       # 기능별 모듈
│   ├── auth/       # 인증
│   ├── books/      # 책 관리
│   ├── memos/      # 메모 관리
│   └── home/       # 홈 화면
└── main.dart       # 앱 진입점
```

### 네이밍 컨벤션
- **파일명:** snake_case
- **클래스명:** PascalCase
- **변수명:** camelCase
- **상수:** UPPER_SNAKE_CASE

## 📊 성능 요구사항

### 로딩 시간
- **앱 시작:** < 3초
- **화면 전환:** < 1초
- **이미지 로딩:** < 2초

### 메모리 사용량
- **최대 메모리:** 100MB
- **이미지 캐싱:** 50MB
- **데이터 캐싱:** 20MB

## 🚀 배포 계획

### 개발 단계
1. **알파 버전** - 내부 테스트
2. **베타 버전** - 제한적 사용자 테스트
3. **프로덕션** - 정식 출시

### 플랫폼 지원
- **iOS:** 13.0+
- **Android:** API 21+ (Android 5.0+)

## 📈 성공 지표

### 사용자 지표
- **일일 활성 사용자 (DAU)**
- **월간 활성 사용자 (MAU)**
- **사용자 유지율**

### 기능 지표
- **책 등록 수**
- **메모 작성 수**
- **이미지 업로드 수**

## 🔄 업데이트 계획

### v1.1.0 (예정)
- **메모 검색 기능**
- **메모 태그 시스템**
- **메모 공유 기능**

### v1.2.0 (예정)
- **독서 통계**
- **목표 설정**
- **소셜 기능**

---

**문서 작성일:** 2024-12-19  
**작성자:** AI Assistant  
**검토자:** 개발팀
