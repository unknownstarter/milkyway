# Milkyway App - 개발자 규칙 (Developer Rules)

## 📋 개발 가이드라인

**최종 업데이트:** 2026-01-09  
**적용 대상:** 모든 개발자  
**버전:** 1.9.0

## 🎯 핵심 원칙

### 0. 작업 태도 (Claude / 모든 작업자)
- **시도도 안 해보고 "안 된다"고 단정 금지.** 어떻게든 방법을 찾아 목표를 달성할 것
- 파일 경로가 텍스트로 들어와도 일단 직접 열어서 내용을 확인할 것
- 명령이 실패할 것 같아도 일단 한 번 돌려보고 실제 에러를 본 뒤 판단할 것
- "환경이 부족해서 못 한다"고 추정하기 전에 실제로 환경을 확인할 것
- 정말 안 되면 그때서야 "X 를 시도했고 Y 때문에 안 됨, 대안은 Z" 형태로 보고
- 사용자가 같은 지시를 두 번 하게 만들지 말 것

### 0-1. iOS 빌드 절대 금지 (2026-07-01 레슨런)
**Xcode 26+ 의 scene-based architecture 자동 마이그레이션 절대 수락 금지.** 라이브 OAuth(Google/Apple) / 딥링크 / 푸시 탭 라우팅 전면 마비됨.
- `ios/Runner/Info.plist` 에 `UIApplicationSceneManifest` 키 추가 금지
- `ios/Runner/AppDelegate.swift` 가 `FlutterImplicitEngineDelegate` 채택하거나 `didInitializeImplicitFlutterEngine` 안에서 플러그인 등록 금지. 플러그인 등록은 `didFinishLaunchingWithOptions` 에서 `GeneratedPluginRegistrant.register(with: self)` 유지
- 새 머신/새 Xcode 에서 첫 빌드 후 반드시 `git diff ios/Runner/Info.plist ios/Runner/AppDelegate.swift` 로 자동 변경 여부 확인 + 실제 Google/Apple 로그인 수동 테스트
- 자세한 원인: `docs/LESSONS_LEARNED.md` 의 "2026-07-01: Xcode 26 자동 마이그레이션 함정"

### 1. 코드 품질 우선
- **단순명료한 코드** 작성
- **복잡한 로직보다는 명확한 코드** 선호
- **일관성 있는 코딩 스타일** 유지
- **불필요한 추상화 지양**

### 2. 사용자 경험 중심
- **성능 최적화** 우선
- **직관적인 UI/UX** 구현
- **에러 처리** 철저히
- **로딩 상태** 명확히 표시

## 🏗️ 아키텍처 규칙

### Clean Architecture 적용
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

### 모듈 구조
```
features/[feature]/
├── data/                  # 데이터 계층
│   ├── datasources/       # 데이터 소스
│   ├── models/           # 데이터 모델
│   └── repositories/     # 리포지토리 구현
├── domain/               # 도메인 계층
│   ├── entities/         # 엔티티
│   ├── models/           # 도메인 모델
│   └── repositories/     # 리포지토리 인터페이스
└── presentation/         # 프레젠테이션 계층
    ├── providers/        # 상태 관리
    ├── screens/          # 화면
    └── widgets/          # 위젯
```

## 🎨 디자인 시스템

### 색상 규칙
```dart
// 주요 색상
const Color primaryBackground = Color(0xFF181818);    // 다크 그레이 (기본 배경)
const Color cardBackground = Color(0xFF1A1A1A);       // 다크 그레이 (카드 배경)
const Color navigationBarBackground = Color(0xFF2C2C2C); // 네비게이션 바 배경
const Color accentColor = Color(0xFF48FF00);           // 형광 초록
const Color primaryText = Color(0xFFFFFFFF);          // 흰색
const Color secondaryText = Color(0xFF9CA3AF);        // 그레이
const Color snackbarBackground = Color(0xFF242424);    // 스낵바 배경 (통일)
```

### 타이포그래피 규칙
```dart
// Pretendard 폰트 사용
const TextStyle titleStyle = TextStyle(
  fontFamily: 'Pretendard',
  fontSize: 28,
  fontWeight: FontWeight.bold,
  color: Colors.white,
);

const TextStyle bodyStyle = TextStyle(
  fontFamily: 'Pretendard',
  fontSize: 16,
  fontWeight: FontWeight.normal,
  color: Colors.white,
);
```

### 레이아웃 규칙
```dart
// 패딩 규칙
const EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: 20);
const EdgeInsets verticalPadding = EdgeInsets.symmetric(vertical: 16);

// 반경 규칙
const double cardRadius = 12.0;
const double buttonRadius = 12.0;

// 간격 규칙
const double smallSpacing = 8.0;
const double mediumSpacing = 16.0;
const double largeSpacing = 32.0;

// 피그마 디자인 기반 간격 (책 상세 페이지)
const double appBarToBookInfo = 28.0;        // 앱바와 책 정보 사이
const double bookTitleToAuthor = 24.0;      // 책 제목과 작가 사이
const double authorToPublisher = 2.0;       // 작가와 출판사 사이
const double bookInfoToStatus = 32.0;        // 책 정보와 상태 버튼 사이
const double statusToDescription = 32.0;     // 상태 버튼과 책 소개 타이틀 사이
const double descriptionTitleToContent = 20.0; // 책 소개 타이틀과 내용 사이
const double moreButtonToMemoTitle = 40.0;   // 더보기 버튼과 책 메모 타이틀 사이
const double memoTitleToFilter = 20.0;      // 책 메모 타이틀과 필터 버튼 사이
const double filterToFirstMemo = 32.0;       // 필터 버튼과 첫 번째 메모 카드 사이
```

## 🖼️ 이미지 업로드/표시 프로토콜 (2026-08-24 추가 - 필수 준수)

> **모든 이미지(책 표지·메모 사진·프로필)는 이 규격을 따른다. 새 화면에서 이미지를 올리거나 불러올 때 반드시 이 절을 먼저 본다.** 안 지키면 홈/책탭에서 풀해상도 로드로 과부하 걸린다. 모듈(디자인 시스템)로 강제하니 직접 `Image.network` 쓰지 말 것.

### 원칙 3줄 요약
1. **표시(불러오기)는 무조건 `CachedImage`** 를 쓴다. `Image.network` 직접 사용 **금지**.
2. **업로드는 원본 금지** - image_picker 단계에서 리사이즈/압축(표지 재호스팅 포함).
3. **전송은 Supabase on-the-fly 변환**(표시폭 WebP)으로 자동 축소. `CachedImage`가 알아서 처리.

### 모듈 (직접 만들지 말고 이걸 써라)
| 목적 | 모듈 | 위치 |
|---|---|---|
| 이미지 표시(캐시+변환+WebP) | `CachedImage` | `lib/core/presentation/widgets/design/cached_image.dart` |
| URL 변환 순수함수 | `supabaseRenderUrl`, `bookCoverStoragePath` | `lib/core/utils/supabase_image.dart` |
| 메모 사진 업로드 | `MemoImageUploader` | `lib/features/memos/utils/memo_image_uploader.dart` |
| 네이버 표지 재호스팅 | `BookCoverUploader` | `lib/features/books/utils/book_cover_uploader.dart` |

### 표시 규격 (반드시 `CachedImage` + 표시폭 `cacheWidth` 지정)
```dart
// 금지 ❌
Image.network(url, fit: BoxFit.cover)
// 필수 ✅ (cacheWidth = 표시폭 x 대략 2~3배(레티나), 그 값으로 서버 변환폭도 자동 결정)
CachedImage(url: url, fit: BoxFit.cover, cacheWidth: 300, fallback: <플레이스홀더>)
```
- 표준 `cacheWidth`(surface별): 스토리 원 156 / 아바타 120~150 / 그리드·검색 표지 240~300 / 카드 대형 700 / 메모 상세 1000. 풀스크린 확대 뷰어만 `cacheWidth` 없이(원본).
- `CachedImage`는 Supabase 공개 URL이면 자동으로 `/render/image/public/...?width=&quality=80` + `Accept: image/webp`로 요청한다. **네이버 등 외부 URL은 그대로 통과**(변환 안 됨)라, 표지는 아래처럼 우리 스토리지로 재호스팅해야 변환 대상이 된다.

### 업로드 규격
- **image_picker**: 항상 `imageQuality`(80~85) + `maxWidth/maxHeight`(메모 1280, 프로필 1024) 지정. 원본 그대로 올리지 말 것.
- **책 표지(네이버)**: 저장 시 `BookCoverUploader.rehostFromNaver(naverUrl, isbn)`로 `book_covers` 버킷(공개)에 ISBN 결정적 경로로 복사. 실패 시 **네이버 URL 폴백**(저장 절대 안 깨지게).
- **버킷은 모두 public + `getPublicUrl`**(서명 URL 만료로 이미지 죽던 문제 재발 방지, 레슨런).

### 테스트 규격
- URL 변환·경로 계산은 순수함수라 반드시 유닛테스트: `test/core/supabase_image_test.dart`(업로드->저장->다시 불러오기 라운드트립 포함), `test/features/memos/memo_image_uploader_test.dart`.

## 🔧 코딩 규칙

### 1. 함수형 프로그래밍 우선
```dart
// ✅ 좋은 예
Widget _buildBookCard(Book book) {
  return Container(
    child: Text(book.title),
  );
}

// ❌ 나쁜 예
Widget _buildBookCard(Book book) {
  setState(() {
    // 상태 변경 로직
  });
  return Container(
    child: Text(book.title),
  );
}
```

### 2. const 생성자 사용
```dart
// ✅ 좋은 예
const Text(
  'Hello World',
  style: TextStyle(fontSize: 16),
);

// ❌ 나쁜 예
Text(
  'Hello World',
  style: TextStyle(fontSize: 16),
);
```

### 3. 명확한 변수명 사용
```dart
// ✅ 좋은 예
final isLoading = false;
final selectedBookId = 'book_123';
final memoList = <Memo>[];

// ❌ 나쁜 예
final flag = false;
final id = 'book_123';
final list = <Memo>[];
```

### 4. 에러 처리
```dart
// ✅ 좋은 예
try {
  final result = await apiCall();
  return result;
} catch (e) {
  print('API 호출 실패: $e');
  rethrow;
}

// ❌ 나쁜 예
final result = await apiCall(); // 에러 처리 없음
return result;
```

## 📱 UI/UX 규칙

### 0. 피그마 디자인 준수 (2025-11-07 추가)
- **피그마 좌표 기반 간격 적용** - 모든 간격은 피그마 디자인 파일의 좌표를 기준으로 설정
- **정확한 간격 측정** - 피그마에서 요소 간 거리를 정확히 측정하여 적용
- **일관된 색상 사용** - 피그마에 정의된 색상 값을 정확히 사용
- **반응형 레이아웃** - LayoutBuilder를 사용하여 화면 크기에 맞게 조정

### 1. 스낵바 색상 통일 (2025-11-07 추가)
```dart
// ✅ 모든 스낵바는 일관된 색상 사용
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('메시지'),
    backgroundColor: const Color(0xFF242424), // 통일된 색상
  ),
);
```

### 2. 책 소개 더보기 버튼 규칙 (2025-11-07 추가)
```dart
// ✅ 180자 이상일 때만 "더보기" 버튼 표시
final shouldShowMoreButton = description.length > 180 && !_isDescriptionExpanded;

// ✅ 탭 시 전체 텍스트 확장, 닫기 버튼 없음
// ✅ 화면을 나갔다가 다시 들어오면 초기 상태로 복귀
```

### 3. 빈 상태 처리 규칙 (2025-11-07 추가)
```dart
// ✅ 빈 상태는 항상 가운데 정렬
// ✅ 가능한 경우 탭 이벤트 추가 (관련 페이지로 이동)
Widget _buildEmptyState() {
  return Center(
    child: GestureDetector(
      onTap: () => context.push('/related-page'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_add, color: Colors.grey, size: 48),
          SizedBox(height: 16),
          Text('아직 메모가 없습니다'),
        ],
      ),
    ),
  );
}
```

### 4. 반응형 디자인
```dart
// 화면 크기별 대응
Widget _buildResponsiveLayout(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  
  if (screenWidth > 600) {
    return _buildTabletLayout();
  } else {
    return _buildMobileLayout();
  }
}
```

### 2. 로딩 상태 처리
```dart
// AsyncValue 사용
Widget _buildContent(AsyncValue<List<Book>> booksAsync) {
  return booksAsync.when(
    data: (books) => _buildBookList(books),
    loading: () => _buildLoadingState(),
    error: (error, stack) => _buildErrorState(error),
  );
}
```

### 3. 이미지 처리
```dart
// 네트워크 이미지 로딩
Widget _buildNetworkImage(String imageUrl) {
  return Image.network(
    imageUrl,
    fit: BoxFit.cover,
    loadingBuilder: (context, child, progress) {
      if (progress == null) return child;
      return _buildLoadingIndicator();
    },
    errorBuilder: (context, error, stack) {
      return _buildErrorPlaceholder();
    },
  );
}
```

## 🔄 상태 관리 규칙

### 1. Riverpod 사용
```dart
// Provider 정의
@riverpod
class BookList extends _$BookList {
  @override
  Future<List<Book>> build() async {
    return await _repository.getBooks();
  }
  
  Future<void> addBook(Book book) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addBook(book);
      ref.invalidateSelf();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
```

### 2. Provider 최적화
```dart
// select 사용으로 불필요한 리빌드 방지
final selectedBook = ref.watch(bookListProvider.select(
  (books) => books.value?.firstWhere((book) => book.id == selectedId),
));
```

### 3. 수정/삭제 후 상세 화면 동작 규칙 (2025-11-18 추가)

#### 🎯 핵심 원칙
**상세 화면은 항상 최신 데이터를 반영해야 하며, 수정/삭제 후 즉시 UI가 업데이트되어야 합니다.**

#### ✅ 수정(Update) 후 동작 패턴

**1. Provider에서 수정 후 관련 Provider 무효화**
```dart
// ✅ 좋은 예: updateMemoProvider에서 memoProvider 무효화
final updateMemoProvider = FutureProvider.family<void, UpdateMemoParams>(
  (ref, params) async {
    await repository.updateMemo(params);
    
    // 상세 화면 갱신을 위해 해당 item의 provider 무효화
    ref.invalidate(memoProvider(params.memoId));
    
    // 리스트 화면 갱신을 위해 리스트 provider들 무효화
    ref.invalidate(bookMemosProvider(params.bookId));
    ref.invalidate(recentMemosProvider);
    // ... 기타 관련 provider들
  },
);
```

**2. Form Provider에서도 동일하게 처리**
```dart
// ✅ 좋은 예: memoFormProvider의 updateMemo에서도 무효화
Future<bool> updateMemo({required String memoId, ...}) async {
  await _repository.updateMemo(...);
  
  // 상세 화면 갱신
  ref.invalidate(memoProvider(memoId));
  
  // 리스트 화면 갱신
  ref.invalidate(bookMemosProvider(bookId));
  // ... 기타 관련 provider들
  
  return true;
}
```

**3. 상세 화면은 ConsumerStatefulWidget으로 구현**
```dart
// ✅ 좋은 예: 화면 복귀 시 자동 갱신
class ItemDetailScreen extends ConsumerStatefulWidget {
  final String itemId;
  // ...
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 처음 나타날 때만 초기화
    if (!_hasInitialized) {
      _hasInitialized = true;
      return;
    }
    // 화면이 다시 나타날 때 (예: 수정 화면에서 돌아올 때) provider 갱신
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(itemProvider(widget.itemId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(itemProvider(widget.itemId));
    // ...
  }
}
```

#### ✅ 삭제(Delete) 후 동작 패턴

**1. Provider에서 삭제 후 관련 Provider 무효화**
```dart
// ✅ 좋은 예: deleteMemoProvider에서 memoProvider 무효화
final deleteMemoProvider = FutureProvider.family<void, DeleteMemoParams>(
  (ref, params) async {
    await repository.deleteMemo(params.memoId);
    
    // 상세 화면 갱신 (null 반환하여 화면 닫기)
    ref.invalidate(memoProvider(params.memoId));
    
    // 리스트 화면 갱신
    ref.invalidate(bookMemosProvider(params.bookId));
    ref.invalidate(recentMemosProvider);
    // ... 기타 관련 provider들
  },
);
```

**2. 상세 화면에서 null 처리**
```dart
// ✅ 좋은 예: provider가 null을 반환하면 자동으로 화면 닫기
final itemAsync = ref.watch(itemProvider(itemId));

return itemAsync.when(
  data: (item) {
    // item이 null이면 삭제된 것으로 간주하고 화면 닫기
    if (item == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.goNamed(AppRoutes.homeName);
          }
        }
      });
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _buildContent(context, item);
  },
  // ...
);
```

**3. 삭제 로직 단순화**
```dart
// ✅ 좋은 예: 삭제 요청 후 provider 무효화로 자동 처리
Future<void> _deleteItem(BuildContext context, Item item) async {
  final shouldDelete = await showDialog<bool>(...);
  
  if (shouldDelete == true) {
    try {
      // 서버에 삭제 요청
      await ref.read(deleteItemProvider(
        (itemId: item.id, ...),
      ).future);
      
      // provider가 무효화되면 item이 null이 되어 자동으로 화면이 닫힘
      // 추가로 확실하게 화면 닫기
      if (context.mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.goNamed(AppRoutes.homeName);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }
}
```

#### ❌ 나쁜 예시 (피해야 할 패턴)

```dart
// ❌ 나쁜 예: 수정 후 상세 화면 provider를 무효화하지 않음
final updateMemoProvider = FutureProvider.family<void, UpdateMemoParams>(
  (ref, params) async {
    await repository.updateMemo(params);
    // memoProvider 무효화 누락!
    ref.invalidate(bookMemosProvider(params.bookId));
  },
);

// ❌ 나쁜 예: 삭제 후 화면을 수동으로 닫기만 함 (provider 갱신 없음)
Future<void> _deleteItem(BuildContext context, Item item) async {
  await repository.deleteItem(item.id);
  context.pop(); // provider 갱신 없이 화면만 닫음
}

// ❌ 나쁜 예: ConsumerWidget 사용 (화면 복귀 시 자동 갱신 불가)
class ItemDetailScreen extends ConsumerWidget {
  // didChangeDependencies 사용 불가
}

// ❌ 나쁜 예: 복잡한 삭제 로직 (불필요한 상태 관리)
Future<void> _deleteItem(...) async {
  // 복잡한 상태 체크
  // 여러 단계의 확인
  // 불필요한 딜레이
}
```

#### 📋 체크리스트

새로운 상세 화면을 만들 때 다음을 확인하세요:

**수정 기능:**
- [ ] 수정 provider에서 해당 item의 상세 provider를 무효화하는가?
- [ ] Form provider에서도 상세 provider를 무효화하는가?
- [ ] 상세 화면이 `ConsumerStatefulWidget`으로 구현되었는가?
- [ ] `didChangeDependencies`에서 화면 복귀 시 provider를 갱신하는가?

**삭제 기능:**
- [ ] 삭제 provider에서 해당 item의 상세 provider를 무효화하는가?
- [ ] 상세 화면에서 `item == null`일 때 자동으로 화면을 닫는가?
- [ ] 삭제 로직이 단순하고 명확한가?
- [ ] 삭제 실패 시 에러 처리가 되어 있는가?

**일반:**
- [ ] 모든 관련 리스트 provider들이 무효화되는가?
- [ ] 사용자가 즉시 변경사항을 확인할 수 있는가?
- [ ] 불필요한 복잡한 로직이 없는가?

## 🔧 Supabase Edge Functions 규칙

### 1. RLS 정책 우회가 필요한 경우
RLS (Row Level Security) 정책으로 인해 클라이언트에서 다른 사용자의 데이터를 직접 조회할 수 없는 경우, **Supabase Edge Function**을 사용해야 합니다.

**예시: 닉네임 중복 체크**
```dart
// ❌ 잘못된 방법: RLS 정책으로 인해 다른 사용자의 닉네임 조회 불가
final response = await _supabase
    .from('users')
    .select('id')
    .eq('nickname', nickname)
    .maybeSingle();

// ✅ 올바른 방법: Edge Function 사용
final response = await _supabase.functions.invoke(
  'check-nickname',
  body: {
    'nickname': nickname,
    'user_id': currentUser?.id,
  },
);
```

**Edge Function 사용 시나리오**:
- 다른 사용자의 데이터 조회가 필요한 경우
- 복잡한 서버 사이드 로직이 필요한 경우
- Service Role Key가 필요한 경우 (RLS 우회)

**참고 문서**: [SUPABASE_EDGE_FUNCTIONS.md](./SUPABASE_EDGE_FUNCTIONS.md)

### 2. Edge Function 배포 규칙
- **배포 전 테스트 필수**: 로컬 환경에서 충분히 테스트 후 배포
- **에러 처리**: Edge Function 호출 시 항상 에러 처리 포함
- **입력 검증**: 모든 입력값 검증 필수
- **보안**: Service Role Key는 절대 클라이언트에 노출하지 않음

### 3. Edge Function 호출 패턴
```dart
try {
  final response = await _supabase.functions.invoke(
    'function-name',
    body: {
      'param1': value1,
      'param2': value2,
    },
  );

  if (response.status != 200) {
    final errorData = response.data;
    throw Exception('Function 호출 실패: ${errorData ?? '알 수 없는 오류'}');
  }

  final data = response.data as Map<String, dynamic>?;
  return data?['result'];
} catch (e) {
  log('Edge Function 호출 실패: $e');
  rethrow;
}
```

## 🗄️ Supabase 데이터 처리 규칙

### 1. 조인 결과 처리
Supabase의 조인 쿼리 결과는 **배열 또는 객체**로 반환될 수 있으므로, 두 경우를 모두 처리해야 합니다.

```dart
// ✅ 좋은 예: 배열과 객체 모두 처리
factory Memo.fromJson(Map<String, dynamic> json) {
  Map<String, dynamic>? users;
  final usersData = json['users'];
  if (usersData != null) {
    if (usersData is List && usersData.isNotEmpty) {
      // 배열인 경우 첫 번째 요소 사용
      users = usersData[0] as Map<String, dynamic>?;
    } else if (usersData is Map<String, dynamic>) {
      // 객체인 경우 그대로 사용
      users = usersData;
    }
  }

  return Memo(
    // ...
    userNickname: users?['nickname'],
    userAvatarUrl: users?['picture_url'],
  );
}

// ❌ 나쁜 예: 객체만 가정
factory Memo.fromJson(Map<String, dynamic> json) {
  final users = json['users'] as Map<String, dynamic>?; // 배열일 때 에러 발생
  // ...
}
```

### 2. 프로필 업데이트 시 관련 Provider 무효화
프로필 정보(닉네임, 프로필 이미지)가 변경되면, 해당 정보를 표시하는 모든 화면의 provider를 무효화해야 합니다.

```dart
// ✅ 좋은 예: 프로필 업데이트 시 관련 provider 무효화
Future<void> updateProfile({
  String? nickname,
  String? pictureUrl,
}) async {
  // ... DB 업데이트 로직 ...
  
  // 프로필 업데이트 시 메모 관련 provider들 무효화하여 최신 프로필 정보 반영
  ref.invalidate(recentMemosProvider);
  ref.invalidate(homeRecentMemosProvider);
  ref.invalidate(allMemosProvider);
  ref.invalidate(paginatedMemosProvider(null)); // 모든 메모 리스트
  // 다른 bookId들은 사용자가 접근할 때 자동으로 새로 로드됨
}

// ❌ 나쁜 예: provider 무효화 누락
Future<void> updateProfile({...}) async {
  // ... DB 업데이트만 하고 provider 무효화 안 함
  // 결과: 메모에 표시되는 프로필 정보가 업데이트되지 않음
}
```

### 3. 명시적 파라미터 전달
null 값을 전달할 때도 명시적으로 전달하여 코드의 의도를 명확히 합니다.

```dart
// ✅ 좋은 예: 명시적으로 null 전달
return const MemoList(bookId: null); // 모든 메모를 불러옴

// ❌ 나쁜 예: 기본값에 의존
return const MemoList(); // bookId가 null인지 명확하지 않음
```

## 🧪 테스트 규칙

### 1. 단위 테스트
```dart
// 테스트 파일명: [파일명]_test.dart
// 예: book_repository_test.dart

void main() {
  group('BookRepository', () {
    test('should return books when getBooks is called', () async {
      // Given
      final repository = BookRepository(mockClient);
      
      // When
      final result = await repository.getBooks();
      
      // Then
      expect(result, isA<List<Book>>());
    });
  });
}
```

### 2. 위젯 테스트
```dart
void main() {
  testWidgets('should display book list', (tester) async {
    // Given
    await tester.pumpWidget(MyApp());
    
    // When
    await tester.pumpAndSettle();
    
    // Then
    expect(find.byType(ListView), findsOneWidget);
  });
}
```

## 📦 패키지 관리

### 1. 의존성 추가 규칙
```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  # 상태 관리
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3
  
  # 네비게이션
  go_router: ^12.1.3
  
  # 백엔드
  supabase_flutter: ^2.0.3
  
  # 인증
  google_sign_in: ^6.1.6
  sign_in_with_apple: ^5.0.0
```

### 2. 버전 관리
- **메이저 버전:** 호환성 깨지는 변경
- **마이너 버전:** 새로운 기능 추가
- **패치 버전:** 버그 수정

## 🚀 성능 최적화

### 1. 이미지 최적화
```dart
// 이미지 캐싱
Widget _buildCachedImage(String url) {
  return CachedNetworkImage(
    imageUrl: url,
    fit: BoxFit.cover,
    placeholder: (context, url) => _buildLoadingIndicator(),
    errorWidget: (context, url, error) => _buildErrorPlaceholder(),
  );
}
```

### 2. 리스트 최적화
```dart
// ListView.builder 사용
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return _buildItem(items[index]);
  },
);
```

### 3. 메모리 관리
```dart
// 컨트롤러 해제
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

## 🔒 보안 규칙

### 1. API 키 관리
```dart
// .env 파일 사용
class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
```

### 2. 사용자 데이터 보호
```dart
// 민감한 정보 로깅 금지
print('User ID: ${user.id}'); // ✅ OK
print('User Password: ${user.password}'); // ❌ 금지
```

## 📝 문서화 규칙

### 1. 코드 주석
```dart
/// 사용자 인증을 처리하는 클래스
/// 
/// Google, Apple 로그인을 지원하며
/// Supabase와 연동하여 사용자 정보를 관리합니다.
class AuthService {
  /// Google 로그인을 수행합니다
  /// 
  /// [returns] 로그인 성공 시 사용자 정보, 실패 시 null
  Future<User?> signInWithGoogle() async {
    // 구현
  }
}
```

### 2. README 작성
```markdown
# Feature Name

## 개요
기능에 대한 간단한 설명

## 사용법
```dart
// 사용 예시
```

## 주의사항
- 주의할 점들
- 제한사항들
```

## 🔄 코드 리뷰 규칙

### 1. 리뷰 체크리스트
- [ ] 코드 스타일 준수
- [ ] 에러 처리 구현
- [ ] 성능 최적화
- [ ] 테스트 코드 작성
- [ ] 문서화 완료

### 2. 승인 기준
- **코드 품질:** 높음
- **테스트 커버리지:** 80% 이상
- **성능:** 요구사항 충족
- **보안:** 취약점 없음

## 🚨 **중요: 레포지토리 관리**

### 📁 **레포지토리 구조**
```
unknownstarter/
├── milkyway/           # 🏭 프로덕션 레포지토리 (원래)
└── milkyway-dev/       # 🛠️ 개발 레포지토리 (새로 생성)
```

### 🔄 **개발 워크플로우**
1. **개발 작업:** `milkyway-dev` 레포지토리에서 진행
2. **완성 후:** `milkyway` 레포지토리로 병합
3. **배포:** `milkyway` 레포지토리에서 프로덕션 배포

### 🎯 **현재 작업 레포지토리**
```bash
# ⚠️ 중요: 항상 이 레포지토리에서 작업
git clone https://github.com/unknownstarter/milkyway-dev.git
cd milkyway-dev
```

### 📋 **레포지토리별 용도**
| 레포지토리 | 용도 | 상태 | 작업 내용 |
|------------|------|------|-----------|
| **milkyway** | 프로덕션 | 대기 | 완성된 코드 병합 대기 |
| **milkyway-dev** | 개발 | 활성 | 모든 개발 작업 진행 |

### ⚠️ **주의사항**
- **절대 `milkyway` 레포지토리에서 직접 개발 금지**
- **모든 개발 작업은 `milkyway-dev`에서만 진행**
- **완성 후에만 `milkyway`로 병합**

## 🏗️ 리팩토링 규칙 (2025-11-11 추가)

### 1. 파일 크기 관리
- **단일 파일 최대 권장 크기**: 500줄 이하
- **초과 시 위젯 분리**: 기능별로 별도 파일로 분리
- **목표**: 각 파일이 단일 책임을 가지도록 구성

### 2. 위젯 분리 원칙
```dart
// ✅ 좋은 예: 위젯을 별도 파일로 분리
// widgets/reading_books_section.dart
class ReadingBooksSection extends ConsumerWidget {
  // ...
}

// ❌ 나쁜 예: 모든 위젯을 한 파일에
class HomeScreen extends ConsumerStatefulWidget {
  // 1000줄 이상의 코드...
}
```

### 3. 모듈화 가이드라인
- **재사용 가능한 위젯**: `widgets/` 디렉토리에 분리
- **화면별 위젯**: `screens/` 디렉토리에 유지
- **공통 위젯**: `core/presentation/widgets/`에 배치
- **Delegate 클래스**: 별도 파일로 분리 (예: `reading_section_delegate.dart`)

### 4. 오버플로우 방지 규칙 (2025-11-11 추가)
```dart
// ✅ 좋은 예: 이중 제한으로 오버플로우 완전 방지
SizedBox(
  height: maxHeight, // 외부 제한
  child: ClipRect(
    clipBehavior: Clip.hardEdge,
    child: SizedBox(
      height: maxHeight, // 내부 제한
      child: child,
    ),
  ),
)

// ✅ 좋은 예: 즉시 전환으로 오버플로우 구간 회피
static const double _expandedDisplayThreshold = 0.001; // 거의 0일 때만 표시
static const double _transitionThreshold = 0.01; // 1% 진행 시 즉시 전환

// ❌ 나쁜 예: 단일 제한만 사용
SizedBox(
  height: currentHeight, // 동적 높이로 인한 오버플로우 가능
  child: child,
)
```

### 5. 상태 동기화 규칙 (2025-11-11 추가)
```dart
// ✅ 좋은 예: ScrollController 리스너로 자동 동기화
_scrollController.addListener(_onScrollChanged);

void _onScrollChanged() {
  if (_scrollController.position.pixels < 10) {
    // 맨 위로 돌아올 때 동기화
    _synchronizePageController();
  }
}

// ❌ 나쁜 예: 수동 동기화 (누락 가능)
// 사용자가 직접 스크롤을 올려야만 동기화됨
```

### 6. 리팩토링 체크리스트
리팩토링 전에 다음을 확인하세요:
- [ ] 기존 기능이 100% 동작하는가?
- [ ] 파일 크기가 500줄 이하인가?
- [ ] 위젯이 재사용 가능한가?
- [ ] 단일 책임 원칙을 준수하는가?
- [ ] 오버플로우가 발생하지 않는가?
- [ ] 상태 동기화가 올바르게 작동하는가?

## 🔒 Enum 타입 안전성 규칙 (2025-11-11 추가)

### 1. Enum 사용 원칙
```dart
// ✅ 좋은 예: enum 사용
enum BookStatus {
  wantToRead('읽고 싶은'),
  reading('읽는 중'),
  completed('완독');
  
  final String value;
  const BookStatus(this.value);
  
  static BookStatus fromString(String? value) {
    if (value == null) return BookStatus.wantToRead;
    return BookStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => BookStatus.wantToRead,
    );
  }
  
  String toJson() => value;
}

// ❌ 나쁜 예: String 하드코딩
final String status = '읽고 싶은';
if (status == '읽는 중') { ... }
```

### 2. Enum 변환 규칙
- **DB에서 읽을 때**: `fromString(String?)` 사용 (null 처리 포함)
- **DB에 저장할 때**: `.value` 또는 `toJson()` 사용
- **기본값 처리**: 알 수 없는 값은 적절한 기본값 반환

### 3. Extension 메서드 활용
```dart
// ✅ 좋은 예: 필터링 로직을 enum extension에 포함
extension MemoFilterExtension on MemoFilter {
  List<Memo> filterMemos(List<Memo> memos, String? currentUserId) {
    switch (this) {
      case MemoFilter.myMemos:
        if (currentUserId == null) return [];
        return memos.where((memo) => memo.userId == currentUserId).toList();
      case MemoFilter.all:
        return memos;
    }
  }
}

// ❌ 나쁜 예: 필터링 로직이 화면에 하드코딩
final filteredMemos = _selectedFilter == MemoFilter.myMemos
    ? memos.where((memo) => memo.userId == currentUserId).toList()
    : memos;
```

### 4. Enum 일관성 규칙
- **모든 enum은 동일한 패턴 사용**: `fromString(String?)`, `toJson()`
- **null 안전성**: 모든 `fromString` 메서드는 nullable 파라미터 사용
- **기본값 처리**: null 또는 알 수 없는 값에 대한 기본값 반환

### 5. Enum 체크리스트
새로운 enum을 추가할 때 다음을 확인하세요:
- [ ] `fromString(String?)` 메서드가 구현되었는가?
- [ ] `toJson()` 또는 `.value` getter가 있는가?
- [ ] null 처리와 기본값 처리가 적절한가?
- [ ] 하드코딩된 문자열이 모두 enum으로 교체되었는가?
- [ ] DB 저장 시 `.value` 또는 `toJson()`을 사용하는가?

## 🧭 네비게이션 플로우 규칙 (2025-11-11 추가)

### 1. 온보딩 플로우 처리
```dart
// ✅ 좋은 예: 온보딩 플래그를 쿼리 파라미터로 전달
// 온보딩 완료 후
context.go('/home?autoBookSearch=true');

// 홈 화면에서 자동 책 검색 화면으로 이동
if (widget.autoBookSearch) {
  context.push('/books/search?isFromOnboarding=true');
}

// 책 검색 화면에서 책 상세로 이동
context.push('/books/detail/$bookId?isFromRegistration=true&isFromOnboarding=true');
```

### 2. 뒤로가기 로직 규칙
```dart
// ✅ 좋은 예: 플래그에 따라 적절한 네비게이션 처리
onPressed: () {
  if (widget.isFromOnboarding) {
    // 온보딩 플로우: 홈으로 이동
    context.go('/home');
  } else if (widget.isFromRegistration) {
    // 일반 등록 플로우: 홈으로 이동
    context.go('/home');
  } else {
    // 일반적인 경우: 이전 페이지로 이동
    context.pop();
  }
}

// ❌ 나쁜 예: 항상 pop()만 사용
onPressed: () => context.pop(); // 온보딩 플로우에서 문제 발생
```

### 3. 플래그 전달 체인
- **온보딩 플로우**: `온보딩 → 홈(autoBookSearch) → 책 검색(isFromOnboarding) → 책 상세(isFromOnboarding)`
- **일반 등록 플로우**: `책 검색 → 책 상세(isFromRegistration)`
- **일반 조회 플로우**: `홈/책장 → 책 상세 (플래그 없음)`

### 4. 쿼리 파라미터 처리 규칙
```dart
// ✅ 좋은 예: 라우터에서 쿼리 파라미터 파싱
GoRoute(
  path: '/books/search',
  builder: (context, state) {
    final isFromOnboarding = state.uri.queryParameters['isFromOnboarding'] == 'true';
    return BookSearchScreen(isFromOnboarding: isFromOnboarding);
  },
)

// ✅ 좋은 예: 플래그를 다음 화면으로 전달
final queryParams = 'isFromRegistration=true${widget.isFromOnboarding ? '&isFromOnboarding=true' : ''}';
context.push('/books/detail/$bookId?$queryParams');
```

### 5. 네비게이션 메서드 선택 규칙
- **`context.go()`**: 스택을 교체하고 싶을 때 (홈으로 이동, 로그인 화면 등)
- **`context.push()`**: 스택에 추가하고 싶을 때 (책 상세, 메모 작성 등)
- **`context.pop()`**: 이전 페이지로 돌아갈 때 (뒤로가기)

### 6. 네비게이션 체크리스트
새로운 화면을 추가할 때 다음을 확인하세요:
- [ ] 뒤로가기 로직이 올바른가?
- [ ] 플래그가 필요한 경우 전달되는가?
- [ ] 온보딩 플로우와 일반 플로우가 구분되는가?
- [ ] `context.go()`와 `context.push()`를 올바르게 사용하는가?

## 📦 배포 및 App Store Connect 규칙 (2025-11-20 추가)

### 1. Bundle ID 관리 규칙

#### ⚠️ 중요: Bundle ID는 App Store Connect와 정확히 일치해야 함
```dart
// ✅ 올바른 예: App Store Connect의 Bundle ID와 일치
PRODUCT_BUNDLE_IDENTIFIER = com.whatif.milkyway;

// ❌ 잘못된 예: App Store Connect와 다른 Bundle ID
PRODUCT_BUNDLE_IDENTIFIER = com.whatif.milkyway.whatifMilkywayApp;
```

#### Bundle ID 확인 절차
1. **App Store Connect에서 확인**: https://appstoreconnect.apple.com → My Apps → 앱 선택 → App Information → Bundle ID 확인
2. **프로젝트 Bundle ID 확인**: Xcode → TARGETS → Runner → Signing & Capabilities → Bundle Identifier 확인
3. **일치 여부 확인**: 두 Bundle ID가 정확히 일치하는지 확인 (대소문자, 점 포함)

#### Bundle ID 수정 방법
```bash
# project.pbxproj 파일에서 모든 Bundle ID 변경
# Runner 타겟: com.whatif.milkyway
# RunnerTests 타겟: com.whatif.milkyway.RunnerTests
```

### 2. Xcode 서명 설정 규칙

#### 자동 서명 설정 필수
```dart
// ✅ 올바른 설정: Debug, Release, Profile 모두에 설정
CODE_SIGN_STYLE = Automatic;
DEVELOPMENT_TEAM = U8354289DY; // 또는 해당 팀 ID
PRODUCT_BUNDLE_IDENTIFIER = com.whatif.milkyway;
```

#### 서명 설정 확인 체크리스트
- [ ] `CODE_SIGN_STYLE = Automatic`이 모든 빌드 설정에 있는가?
- [ ] `DEVELOPMENT_TEAM`이 올바르게 설정되어 있는가?
- [ ] `PRODUCT_BUNDLE_IDENTIFIER`가 App Store Connect와 일치하는가?
- [ ] Xcode에서 "Automatically manage signing"이 체크되어 있는가?

### 3. Archive 및 배포 규칙

#### Archive 생성 전 확인사항
1. **Bundle ID 확인**: App Store Connect의 Bundle ID와 일치하는지 확인
2. **버전 확인**: `pubspec.yaml`의 버전이 올바른지 확인
3. **서명 확인**: Xcode에서 Signing & Capabilities 확인
4. **Clean Build**: Product → Clean Build Folder (⇧⌘K)

#### Distribute App 시 주의사항
- **"Choose an app record" 화면**: Bundle ID가 일치하는 기존 앱을 선택해야 함
- **새 앱 생성 방지**: Xcode가 새 앱을 만들려고 하면 Bundle ID를 확인해야 함
- **Archive 이름**: Scheme 이름에 따라 결정되므로, 필요시 Scheme 이름 변경 고려

### 4. iOS Launch Screen 규칙

#### Launch Screen과 Flutter 스플래시의 차이
- **iOS Launch Screen**: 네이티브 레벨, Flutter 엔진 로드 전에 표시, 정적 이미지만 가능
- **Flutter 스플래시**: 위젯 레벨, Flutter 엔진 로드 후 표시, 애니메이션 가능

#### Launch Screen 설정 규칙
```xml
<!-- ✅ 올바른 설정: 배경색을 앱 테마와 일치 -->
<color key="backgroundColor" red="0" green="0" blue="0" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>

<!-- ❌ 잘못된 설정: 흰색 배경 (TestFlight에서 하얀 화면 표시) -->
<color key="backgroundColor" red="1" green="1" blue="1" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
```

#### 스플래시 화면 표시 시간
```dart
// ✅ 좋은 예: 최소 표시 시간 보장
@override
void initState() {
  super.initState();
  // 스플래시 화면 최소 표시 시간 보장 (1.5초)
  Future.delayed(const Duration(milliseconds: 1500), () {
    if (mounted) {
      _validateSession();
    }
  });
}
```

### 5. 배포 체크리스트
배포 전 다음을 확인하세요:
- [ ] Bundle ID가 App Store Connect와 정확히 일치하는가?
- [ ] Xcode 서명 설정이 올바른가? (`CODE_SIGN_STYLE = Automatic`)
- [ ] Launch Screen 배경색이 앱 테마와 일치하는가?
- [ ] 버전 번호가 올바른가? (`pubspec.yaml` 확인)
- [ ] Archive 생성 후 "Choose an app record"에서 올바른 앱이 선택되는가?
- [ ] TestFlight에서 실제 디바이스로 테스트했는가?

### 6. 배포 시 주의사항
- **리팩토링 시**: 프로젝트를 리팩토링하거나 새로 설정할 때도 기존 App Store Connect의 Bundle ID를 먼저 확인해야 함
- **환경 변경 시**: 개발 환경을 변경하거나 새로 설정할 때 Bundle ID가 변경되지 않았는지 확인
- **팀 변경 시**: Development Team이 변경되면 서명 설정을 다시 확인해야 함

---

---

## ⚡ 페이지네이션 및 성능 최적화 규칙

### 1. 서버 사이드 페이지네이션 필수

#### 대량 데이터는 반드시 페이지네이션
- **10개씩 로딩**: 한 번에 10개씩 로딩하여 초기 로딩 시간 단축
- **즉시 로딩 시작**: `StateNotifier`를 사용하여 화면 진입 시 즉시 로딩 시작
- **자동 다음 페이지 로드**: 스크롤 감지로 자동으로 다음 페이지 로드

#### ✅ 좋은 예시
```dart
class PaginatedMemosNotifier extends StateNotifier<AsyncValue<List<Memo>>> {
  int _page = 0;
  static const int _limit = 10;
  bool _hasMore = true;
  bool _isLoading = false; // 중복 요청 방지

  PaginatedMemosNotifier({required MemoRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading()) {
    loadInitialMemos(); // 생성 시 즉시 로딩 시작
  }

  Future<void> loadMoreMemos() async {
    if (_isLoading || !_hasMore || !mounted) return;
    
    _isLoading = true;
    _page++;
    try {
      final memos = await _repository.getPaginatedMemos(
        limit: _limit,
        offset: _page * _limit,
      );
      
      if (!mounted) return;
      
      _hasMore = memos.length == _limit;
      
      if (_page == 0) {
        state = AsyncValue.data(memos);
      } else {
        final currentMemos = state.value ?? [];
        state = AsyncValue.data([...currentMemos, ...memos]);
      }
    } catch (e, st) {
      if (!mounted) return;
      if (_page > 0) _page--; // 에러 시 페이지 롤백
      state = AsyncValue.error(e, st);
    } finally {
      if (mounted) _isLoading = false;
    }
  }
}
```

#### ❌ 나쁜 예시
```dart
// ❌ 나쁜 예: 전체 데이터를 한 번에 로딩
final allMemosProvider = FutureProvider<List<Memo>>((ref) async {
  return await repository.getAllMemos(); // 전체 데이터 로딩
});

// ❌ 나쁜 예: FutureProvider 사용 (화면 진입 후 로딩 시작)
final memosProvider = FutureProvider.family<List<Memo>, String>((ref, bookId) async {
  return await repository.getMemos(bookId);
});
```

### 2. 중복 요청 방지

#### isLoading 플래그 필수
- **동시 요청 방지**: `isLoading` 플래그로 동시에 여러 요청이 발생하지 않도록 방지
- **mounted 체크**: `StateNotifier`가 dispose된 후 상태 업데이트 방지

```dart
bool _isLoading = false;

Future<void> loadMoreMemos() async {
  if (_isLoading || !_hasMore || !mounted) return; // 중복 요청 방지
  
  _isLoading = true;
  try {
    // ... 로딩 로직
  } finally {
    if (mounted) _isLoading = false;
  }
}
```

### 3. 스크롤 최적화

#### Throttle 적용
- **300ms 간격**: 스크롤 이벤트를 300ms 간격으로 제한하여 불필요한 요청 방지
- **NotificationListener 사용**: `ScrollUpdateNotification`으로 스크롤 감지

```dart
DateTime? _lastScrollTime;

NotificationListener<ScrollNotification>(
  onNotification: (notification) {
    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      final now = DateTime.now();
      
      // 300ms throttle
      if (_lastScrollTime != null &&
          now.difference(_lastScrollTime!).inMilliseconds < 300) {
        return false;
      }
      
      // 하단 200px 전에 다음 페이지 로드
      if (metrics.pixels >= metrics.maxScrollExtent - 200) {
        if (notifier.hasMore && !notifier.isLoading) {
          _lastScrollTime = now;
          notifier.loadMoreMemos();
        }
      }
    }
    return false;
  },
  child: // ... 리스트 위젯
)
```

### 4. 재시도 로직

#### 네트워크 에러만 재시도
- **첫 페이지는 재시도 없이**: 사용자 경험을 위해 첫 페이지는 재시도 없이 빠르게 실패 처리
- **다음 페이지는 재시도**: 안정성을 위해 다음 페이지는 exponential backoff로 재시도
- **재시도 횟수 제한**: 최대 2-3회로 제한하여 무한 재시도 방지

```dart
// ✅ 좋은 예: 첫 페이지와 다음 페이지 구분
if (offset == 0) {
  // 첫 페이지는 재시도 없이 즉시 호출
  try {
    return await operation();
  } catch (e) {
    if (RetryHelper.isNetworkError(e)) {
      // 네트워크 에러만 재시도
      return await RetryHelper.retryWithBackoff(
        operation: operation,
        maxRetries: 2,
        initialDelay: const Duration(milliseconds: 500),
      );
    }
    rethrow;
  }
} else {
  // 다음 페이지는 재시도 적용
  return await RetryHelper.retryWithBackoff(
    operation: operation,
    maxRetries: 2,
    initialDelay: const Duration(milliseconds: 500),
  );
}
```

### 5. 응답 캐싱

#### 첫 페이지만 캐싱
- **TTL 설정**: 2분간 캐싱하여 실시간성과 효율성 균형
- **선택적 무효화**: 전체 캐시를 무효화하지 않고 특정 항목만 무효화
- **JSON 직렬화로 키 생성**: `Map.toString()` 대신 `jsonEncode` 사용

```dart
// ✅ 좋은 예: 첫 페이지만 캐싱
if (offset == 0) {
  final cached = cache.get<Map<String, dynamic>>(functionName, requestBody);
  if (cached != null) {
    return cached['memos'] as List<Memo>;
  }
  
  // ... 데이터 로딩
  
  cache.set(functionName, requestBody, result, ttl: const Duration(minutes: 2));
}

// ✅ 좋은 예: 선택적 캐시 무효화
void invalidateCache(String bookId) {
  ResponseCache().invalidate('get-public-book-memos', body: {'book_id': bookId});
}
```

### 6. 오버플로우 방지

#### 동적 높이 사용
- **itemExtent 제거**: 콘텐츠 높이가 가변적이면 `itemExtent`를 제거하고 실제 높이에 맞게 자동 계산
- **Column 사용**: `shrinkWrap: true`를 사용하는 경우 `Column`이 더 안전할 수 있음

```dart
// ✅ 좋은 예: 동적 높이
ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  // itemExtent 제거 - 실제 높이에 맞게 자동 계산
  itemCount: memos.length,
  itemBuilder: (context, index) {
    return MemoCard(memo: memos[index]); // 높이가 가변적
  },
)

// ❌ 나쁜 예: 고정 높이 (오버플로우 발생 가능)
ListView.builder(
  itemExtent: 240.0, // 실제 높이보다 작으면 오버플로우
  itemCount: memos.length,
  itemBuilder: (context, index) {
    return MemoCard(memo: memos[index]); // 실제 높이는 250px
  },
)
```

### 7. Edge Function 최적화

#### count 계산 최적화
- **첫 페이지만 count 계산**: `count: 'exact'`는 첫 페이지(offset=0)에서만 사용
- **limit 최대값 제한**: 최대 50개로 제한하여 과도한 데이터 로딩 방지

```typescript
// ✅ 좋은 예: 첫 페이지만 count 계산
const includeCount = body.include_count !== false;
const offset = Math.max(body.offset || 0, 0);

const { data, error, count } = await supabase
  .from('memos')
  .select('*', includeCount && offset === 0 ? { count: 'exact' } : undefined)
  .eq('book_id', bookId)
  .range(offset, offset + limit - 1);

const hasMore = count !== null
  ? (offset + limit) < count
  : data.length === limit; // 근사치 사용
```

### 7. 중앙화된 무효화 함수 패턴 (2026-01-09 추가)

**같은 feature 내에서 여러 provider에서 동일한 무효화 로직을 사용하는 경우, 중앙화된 함수를 제공하여 일관성과 유지보수성을 향상시킵니다.**

#### ✅ 좋은 예: 중앙화된 무효화 함수

```dart
// memo_provider.dart에 중앙화된 함수 제공
/// 메모 변경 후 관련 provider들 무효화 (중앙화된 함수)
void invalidateMemoProviders(
  Ref ref,
  String bookId, {
  String? memoId,
  bool isPublic = false,
}) {
  // 공개 메모인 경우에만 공개 메모 관련 provider 무효화
  if (isPublic) {
    ResponseCache().invalidate('get-public-book-memos', bookId: bookId);
    ref.invalidate(paginatedPublicBookMemosProvider(bookId));
  }

  // 항상 무효화해야 하는 provider들
  ref.invalidate(bookMemosProvider(bookId));
  ref.invalidate(recentMemosProvider);
  ref.invalidate(homeRecentMemosProvider);
  ref.invalidate(allMemosProvider);
  ref.invalidate(paginatedMemosProvider(bookId));
  ref.invalidate(paginatedMemosProvider(null));

  // 메모 상세 화면 갱신 (updateMemo, deleteMemo에서만 필요)
  if (memoId != null) {
    ref.invalidate(memoProvider(memoId));
  }
}

// 다른 provider에서 사용
final createMemoProvider = FutureProvider.family<void, CreateMemoParams>(
  (ref, params) async {
    await repository.createMemo(...);
    invalidateMemoProviders(ref, params.bookId, isPublic: visibility == MemoVisibility.public);
  },
);
```

#### ❌ 나쁜 예: 중복된 무효화 로직

```dart
// 각 provider에서 동일한 로직 반복 (약 160줄 중복)
final createMemoProvider = FutureProvider.family<void, CreateMemoParams>(
  (ref, params) async {
    await repository.createMemo(...);
    ResponseCache().invalidate('get-public-book-memos', bookId: params.bookId);
    ref.invalidate(bookMemosProvider(params.bookId));
    ref.invalidate(recentMemosProvider);
    // ... (10줄 이상 반복)
  },
);
```

**장점:**
- ✅ 코드 중복 제거 (160줄 → 30줄)
- ✅ 일관성 보장 (모든 메모 변경 시 동일한 무효화 로직)
- ✅ 유지보수성 향상 (한 곳에서 수정)
- ✅ 클린 아키텍처 개선 (의존성 감소)

### 8. 조건부 무효화 패턴 (2026-01-09 추가)

**데이터의 특성에 따라 선택적으로 provider를 무효화하여 불필요한 네트워크 요청을 방지합니다.**

#### ✅ 좋은 예: visibility에 따른 조건부 무효화

```dart
Future<bool> createMemo({
  required String bookId,
  MemoVisibility visibility = MemoVisibility.private,
}) async {
  await _repository.createMemo(..., visibility: visibility);

  // visibility에 따라 조건부 무효화
  invalidateMemoProviders(
    ref,
    bookId,
    isPublic: visibility == MemoVisibility.public, // Private는 공개 메모 provider 무효화 불필요
  );
}
```

#### ❌ 나쁜 예: 무조건 모든 provider 무효화

```dart
Future<bool> createMemo({...}) async {
  await _repository.createMemo(..., visibility: MemoVisibility.private);
  
  // Private 메모인데도 공개 메모 provider 무효화 (불필요)
  ResponseCache().invalidate('get-public-book-memos', bookId: bookId);
  ref.invalidate(paginatedPublicBookMemosProvider(bookId));
}
```

**효과:**
- ✅ 불필요한 네트워크 요청 감소
- ✅ 성능 향상
- ✅ 서버 부하 감소

### 9. Exponential Backoff 재시도 패턴 (2026-01-09 추가)

**타이밍 이슈나 일시적 네트워크 에러에 대응하기 위해 exponential backoff를 사용한 재시도 로직을 구현합니다.**

#### ✅ 좋은 예: Exponential Backoff

```dart
class BookDetailController extends StateNotifier<AsyncValue<Book>> {
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(milliseconds: 300);
  static const Duration _maxRetryDelay = Duration(seconds: 2);
  int _retryCount = 0;

  Future<void> loadBook({bool isRetry = false}) async {
    if (!isRetry) {
      _retryCount = 0;
    }

    try {
      final book = await _repository.getBookDetail(bookId);
      _retryCount = 0;
      state = AsyncValue.data(book);
    } catch (e, st) {
      if (_shouldRetry(e) && _retryCount < _maxRetries) {
        _retryCount++;
        // Exponential backoff: 300ms → 600ms → 1200ms
        final delay = Duration(
          milliseconds: (_initialRetryDelay.inMilliseconds *
                  (1 << (_retryCount - 1)))
              .clamp(0, _maxRetryDelay.inMilliseconds),
        );
        Timer(delay, () => loadBook(isRetry: true));
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  bool _shouldRetry(dynamic error) {
    if (error is PostgrestException) {
      switch (error.code) {
        case 'PGRST116': // 0 rows
        case 'PGRST301': // Not found
          return true;
      }
    }
    return false;
  }
}
```

#### ❌ 나쁜 예: 고정 딜레이 재시도

```dart
Future<void> loadBook() async {
  try {
    final book = await _repository.getBookDetail(bookId);
    state = AsyncValue.data(book);
  } catch (e, st) {
    // 고정 딜레이 (비효율적)
    Timer(Duration(milliseconds: 500), () => loadBook());
  }
}
```

**장점:**
- ✅ 타이밍 이슈 해결에 효과적
- ✅ 서버 부하 감소 (점진적 재시도)
- ✅ 사용자 경험 개선 (빠른 성공 시 빠른 응답)

### 10. 캐시 무효화 체크리스트 (2026-01-09 추가)

**데이터 변경 시 관련 provider 무효화를 누락하지 않기 위한 체크리스트입니다.**

#### ✅ 데이터 변경 시 체크리스트

1. **해당 항목의 상세 provider 무효화**
   ```dart
   ref.invalidate(itemProvider(itemId));
   ```

2. **해당 항목이 포함된 리스트 provider 무효화**
   ```dart
   ref.invalidate(itemListProvider);
   ref.invalidate(paginatedItemListProvider(bookId));
   ref.invalidate(paginatedItemListProvider(null)); // 전체 리스트
   ```

3. **관련 통계/요약 provider 무효화**
   ```dart
   ref.invalidate(recentItemsProvider);
   ref.invalidate(homeRecentItemsProvider);
   ref.invalidate(allItemsProvider);
   ```

4. **캐시 무효화 (Edge Function 응답 캐시)**
   ```dart
   ResponseCache().invalidate('function-name', bookId: bookId);
   ```

5. **조건부 무효화 확인**
   - 공개/비공개 여부에 따라 선택적 무효화
   - visibility 변경 시 이전/현재 상태 모두 고려

#### ✅ 예시: 메모 생성 시

```dart
Future<bool> createMemo({
  required String bookId,
  MemoVisibility visibility = MemoVisibility.private,
}) async {
  await _repository.createMemo(..., visibility: visibility);

  // ✅ 체크리스트 확인:
  // 1. 상세 provider: 없음 (생성만 함)
  // 2. 리스트 provider: 모두 무효화
  // 3. 통계 provider: 모두 무효화
  // 4. 캐시: 공개 메모인 경우만
  // 5. 조건부: visibility 확인

  invalidateMemoProviders(
    ref,
    bookId,
    isPublic: visibility == MemoVisibility.public,
  );
}
```

#### ❌ 흔한 실수

1. **페이지네이션 provider 무효화 누락**
   ```dart
   // ❌ paginatedPublicBookMemosProvider 무효화 누락
   ref.invalidate(bookMemosProvider(bookId));
   // paginatedPublicBookMemosProvider는 무효화 안 함
   ```

2. **ResponseCache 무효화 누락**
   ```dart
   // ❌ ResponseCache 무효화 누락
   ref.invalidate(bookMemosProvider(bookId));
   // ResponseCache().invalidate() 호출 안 함
   ```

3. **조건부 무효화 미적용**
   ```dart
   // ❌ Private 메모인데도 공개 메모 provider 무효화
   invalidateMemoProviders(ref, bookId, isPublic: true); // 항상 true
   ```

---

**문서 작성일:** 2025-11-11  
**최종 업데이트:** 2026-01-09  
**작성자:** AI Assistant  
**검토자:** 개발팀  
**다음 검토 예정일:** 2026-02-09
