# Milkyway App - 프로젝트 개요

## 📱 앱 소개

**Milkyway**는 독서 메모를 관리하는 모바일 앱입니다.  
사용자가 읽은 책에 대한 메모를 작성하고 관리할 수 있으며,  
깔끔한 UI/UX로 독서 경험을 향상시킵니다.

## 🎯 주요 기능

### 📚 책 관리
- **책 등록** - 네이버 도서 API를 통한 책 검색 및 등록
- **책 상태 관리** - 읽고 싶은, 읽는 중, 읽음 상태 관리
- **책 표지 표시** - 네트워크 이미지 로딩 및 캐싱

### 📝 메모 관리
- **메모 작성** - 텍스트, 페이지, 이미지 첨부 가능
- **메모 편집** - 기존 메모 수정 및 삭제
- **메모 공개/비공개** - 가시성 설정

### 🏠 홈 화면
- **스와이프 가능한 책 목록** - PageView 기반 구현
- **포커싱 효과** - 선택된 책 강조 표시
- **메모 섹션** - 선택된 책의 메모 표시
- **스크롤 가능한 메모 목록** - ListView 기반

## 🎨 디자인 시스템

> ⚠️ **2026-05-29 코드 실측 기준 동기화.** 진실의 원천은 `lib/core/theme/` 토큰 파일.
> 본 README는 요약만 담는다. 자세한 토큰 목록과 사용 가이드는 [PRD.md](./PRD.md#-디자인-시스템) 참조.

### 색상 (요약)
- **메인 배경:** `#181818` (`AppColors.bgPrimary`)
- **카드 표면:** `#1A1A1A` (`AppColors.surface`)
- **브랜드 액센트:** `#48FF00` 형광 초록 (`AppColors.accentGreen`)
- **본문 텍스트:** `#ECECEC` (`AppColors.textPrimary`)
- **보조 텍스트:** `#838383` (`AppColors.textSecondary`)

### 타이포그래피
- **폰트 패밀리:** Pretendard (전역)
- 사이즈 단계: 28 / 24 / 20 / 18 / 16 / 14 / 12
- 토큰: `AppTypography.{display, heading, title, subtitle, body, bodyBold, bodySmall, caption, label}`

### 레이아웃
- **화면 좌우 패딩:** 20px (`AppSpacing.pageHorizontal`)
- **카드 반경:** 12px 기본 (`AppRadius.card`), 책 표지 8px, 알약 버튼 20px
- 간격 스케일: 4 / 8 / 12 / 16 / 20 / 24 / 32 / 40

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

## 📁 프로젝트 구조

```
lib/
├── core/                    # 공통 기능
│   ├── config/             # 설정
│   ├── errors/             # 에러 처리
│   ├── presentation/       # 공통 UI
│   ├── providers/          # 공통 Provider
│   ├── router/             # 라우팅
│   ├── services/           # 서비스
│   ├── theme/              # 테마
│   ├── usecases/           # 유스케이스
│   └── utils/              # 유틸리티
└── features/               # 기능별 모듈
    ├── auth/              # 인증
    ├── books/             # 책 관리
    ├── memos/             # 메모 관리
    └── home/              # 홈 화면
```

## 🚨 **중요: 레포지토리 관리**

### 📁 **레포지토리 구조**
```
unknownstarter/
├── milkyway/           # 🏭 프로덕션 레포지토리 (원래)
└── milkyway-dev/       # 🛠️ 개발 레포지토리 (새로 생성)
```

### 🎯 **현재 작업 레포지토리**
```bash
# ⚠️ 중요: 항상 이 레포지토리에서 작업
git clone https://github.com/unknownstarter/milkyway-dev.git
cd milkyway-dev
```

### ⚠️ **주의사항**
- **절대 `milkyway` 레포지토리에서 직접 개발 금지**
- **모든 개발 작업은 `milkyway-dev`에서만 진행**
- **완성 후에만 `milkyway`로 병합**

---

## 🚀 시작하기

### 필수 요구사항
- Flutter 3.16.0+
- Dart 3.2.0+
- iOS 13.0+ / Android API 21+

### 설치 및 실행
```bash
# ⚠️ 중요: 개발용 레포지토리 클론
git clone https://github.com/unknownstarter/milkyway-dev.git
cd milkyway-dev

# 의존성 설치
flutter pub get

# 앱 실행
flutter run
```

### 환경 설정
```bash
# .env 파일 생성
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

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

## 🔧 개발 가이드

### 코드 스타일
- **함수형 프로그래밍** 우선
- **const 생성자** 사용
- **명확한 변수명** 사용
- **80자 줄 길이** 제한

### 네이밍 컨벤션
- **파일명:** snake_case
- **클래스명:** PascalCase
- **변수명:** camelCase
- **상수:** UPPER_SNAKE_CASE

### 상태 관리
```dart
// Riverpod Provider 사용
@riverpod
class BookList extends _$BookList {
  @override
  Future<List<Book>> build() async {
    return await _repository.getBooks();
  }
}
```

## 🧪 테스트

### 단위 테스트
```bash
# 테스트 실행
flutter test

# 커버리지 확인
flutter test --coverage
```

### 위젯 테스트
```bash
# 위젯 테스트 실행
flutter test test/widget_test.dart
```

## 📊 성능 최적화

### 이미지 최적화
- **CachedNetworkImage** 사용
- **이미지 압축** 적용
- **로딩 상태** 표시

### 리스트 최적화
- **ListView.builder** 사용
- **가상화** 적용
- **무한 스크롤** 구현

## 🔒 보안

### API 키 관리
- **.env 파일** 사용
- **환경 변수** 설정
- **민감한 정보** 보호

### 사용자 데이터 보호
- **Supabase RLS** 적용
- **인증 토큰** 관리
- **데이터 암호화** 적용

## 📈 성능 지표

### 로딩 시간
- **앱 시작:** < 3초
- **화면 전환:** < 1초
- **이미지 로딩:** < 2초

### 메모리 사용량
- **최대 메모리:** 100MB
- **이미지 캐싱:** 50MB
- **데이터 캐싱:** 20MB

## 🚀 배포

### 개발 단계
1. **알파 버전** - 내부 테스트
2. **베타 버전** - 제한적 사용자 테스트
3. **프로덕션** - 정식 출시

### 플랫폼 지원
- **iOS:** 13.0+
- **Android:** API 21+ (Android 5.0+)

## 📚 문서

### 핵심 문서 (루트)
- [PRD (Product Requirements Document)](./PRD.md) - 제품 요구사항 문서
- [개발자 규칙](./DEVELOPER_RULES.md) - 개발 가이드라인 및 규칙
- [레슨런](./LESSONS_LEARNED.md) - 학습 내용 및 교훈
- [변경 히스토리](./CHANGELOG.md) - 버전별 변경 사항
- [작업 관리](./TASK_MASTER.md) - 작업 현황 및 진행 상황

### 문서 구조
```
docs/
├── 핵심 문서 (루트)
│   ├── README.md
│   ├── PRD.md
│   ├── DEVELOPER_RULES.md
│   ├── LESSONS_LEARNED.md
│   ├── CHANGELOG.md
│   └── TASK_MASTER.md
│
├── code-reviews/          # 코드 리뷰 문서
├── guides/                # 설정 가이드
│   ├── notifications/     # 푸시 알림 설정
│   ├── deployment/        # 배포 가이드
│   └── configuration/     # 기타 설정
├── technical/             # 기술 문서
├── refactoring/           # 리팩토링 계획
└── project/               # 프로젝트 관련 문서
```

### 주요 가이드
- **푸시 알림 설정**: [guides/notifications/](./guides/notifications/)
- **배포 가이드**: [guides/deployment/](./guides/deployment/)
- **기술 문서**: [technical/](./technical/)

## 🤝 기여하기

### 개발 프로세스
1. **이슈 생성** - 버그 리포트 또는 기능 요청
2. **브랜치 생성** - feature/issue-number 형식
3. **코드 작성** - 개발자 규칙 준수
4. **테스트 작성** - 단위 테스트, 위젯 테스트
5. **PR 생성** - 코드 리뷰 요청
6. **병합** - 승인 후 메인 브랜치 병합

### 코드 리뷰 체크리스트
- [ ] 코드 스타일 준수
- [ ] 에러 처리 구현
- [ ] 성능 최적화
- [ ] 테스트 코드 작성
- [ ] 문서화 완료

## 📞 연락처

**프로젝트 매니저:** AI Assistant  
**개발팀:** Flutter Team  
**문서 작성일:** 2024-12-19  
**다음 업데이트:** 2024-12-20

---

**이 프로젝트는 Flutter와 Supabase를 사용하여 개발되었습니다.**
