import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/models/book.dart';
import '../providers/book_provider.dart';
import '../providers/selected_book_provider.dart';
import '../../../../core/presentation/widgets/add_floating_action_button.dart';
import '../widgets/reading_section_delegate.dart';
import '../widgets/reading_books_section.dart';
import '../widgets/home_memo_section.dart';
import '../widgets/home_profile_section.dart';
import '../widgets/home_empty_states.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final bool autoBookSearch;

  const HomeScreen({
    super.key,
    this.autoBookSearch = false,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late PageController _pageController;
  bool _hasResetPageController = false;
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _isHorizontalDraggingNotifier =
      ValueNotifier<bool>(false);
  bool _wasCollapsed = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.4);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면 재진입 시 PageController 리셋 플래그 초기화
    _hasResetPageController = false;

    // ScrollController 리스너 추가: 스크롤이 맨 위로 돌아올 때 PageController 동기화
    // 중복 추가 방지를 위해 먼저 제거 후 추가
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.addListener(_onScrollChanged);

    final userBooksAsync = ref.read(homeBooksProvider);
    userBooksAsync.whenData((books) {
      final selectedBookId = ref.read(selectedBookIdProvider);
      
      if (books.isEmpty) {
        // 책이 없으면 선택 해제
        if (selectedBookId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(selectedBookIdProvider.notifier).state = null;
            }
          });
        }
      } else {
        // 선택된 책이 없거나 삭제된 책이 선택되어 있으면 첫 번째 책 선택
        final isSelectedBookValid = selectedBookId != null &&
            books.any((book) => book.id == selectedBookId);
        
        if (!isSelectedBookValid) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(selectedBookIdProvider.notifier).state = books[0].id;
            }
          });
        }
      }
      // 뒤로가기 후 동기화 제거: GoRouter가 페이지를 캐싱하므로 상태가 유지됨
      // 실제 데이터 변경 시에만 동기화 필요 (예: 책 목록 변경)
    });

    // 온보딩에서 온 경우 자동으로 책 검색 화면으로 이동
    if (widget.autoBookSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pushNamed(
            AppRoutes.bookSearchName,
            queryParameters: {'isFromOnboarding': 'true'},
          );
        }
      });
    }
  }

  // 스크롤 변경 시 호출: 맨 위로 돌아올 때 PageController 동기화
  void _onScrollChanged() {
    if (!_scrollController.hasClients) return;

    final scrollPosition = _scrollController.position.pixels;
    final isExpanded = scrollPosition < 10; // expanded 상태 체크 (맨 위)
    final wasCollapsed = _wasCollapsed;
    
    // collapsed 상태에서 expanded 상태로 전환될 때 즉시 동기화
    if (wasCollapsed && isExpanded) {
      _syncPageControllerToSelectedBook();
    }
    
    // 스크롤이 맨 위에 가까울 때 (10px 이내) 동기화
    if (isExpanded) {
      _syncPageControllerToSelectedBook();
    }
    
    // collapsed 상태 업데이트
    _wasCollapsed = !isExpanded;
  }

  // PageController를 선택된 책의 인덱스로 동기화
  void _syncPageControllerToSelectedBook() {
    if (!_pageController.hasClients) return;
    
    final booksAsync = ref.read(homeBooksProvider);
    booksAsync.whenData((books) {
      if (books.isEmpty || !_pageController.hasClients) return;

      final selectedBookId = ref.read(selectedBookIdProvider);
      if (selectedBookId == null) return;

      // 선택된 책의 인덱스 찾기
      final selectedIndex =
          books.indexWhere((book) => book.id == selectedBookId);
      if (selectedIndex == -1) return;

      final currentPage = _pageController.page?.round() ?? 0;
      // 현재 페이지와 선택된 책의 인덱스가 다르면 동기화
      if (currentPage != selectedIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients) {
            _pageController.jumpToPage(selectedIndex);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollChanged);
    _pageController.dispose();
    _scrollController.dispose();
    _isHorizontalDraggingNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userBooksAsync = ref.watch(homeBooksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      body: SafeArea(
        child: userBooksAsync.when(
          data: (books) => _buildContent(books),
          loading: () => const HomeLoadingState(),
          error: (error, stack) => HomeErrorState(error: error),
        ),
      ),
      floatingActionButton: const AddFloatingActionButton(),
    );
  }

  Widget _buildContent(List<Book> books) {
    if (books.isEmpty) {
      return const HomeEmptyState();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: _isHorizontalDraggingNotifier,
      builder: (context, isHorizontalDragging, _) {
    return CustomScrollView(
          controller: _scrollController,
          physics: isHorizontalDragging
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(),
      slivers: [
        // 앱바 (고정)
        SliverAppBar(
          pinned: true,
          floating: false,
          elevation: 0,
          backgroundColor: const Color(0xFF181818),
              surfaceTintColor: Colors.transparent, // Material 3에서 배경색 변경 방지
          automaticallyImplyLeading: false,
          toolbarHeight: 64,
              flexibleSpace: Container(
                color: const Color(0xFF181818), // 배경색 명시적으로 설정
                child: _buildAppBar(),
              ),
        ),
        // 프로필 영역
            const SliverToBoxAdapter(
              child: HomeProfileSection(),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 34), // Figma: 프로필과 "읽고 있는 책" 타이틀 사이 34px
        ),

        // Reading 섹션 (Sticky 효과)
        SliverPersistentHeader(
          pinned: true,
              delegate: ReadingSectionDelegate(
                expandedChild: ReadingBooksSection(
                  books: books,
                  pageController: _pageController,
                  scrollController: _scrollController,
                  isHorizontalDraggingNotifier: _isHorizontalDraggingNotifier,
                  hasResetPageController: _hasResetPageController,
                  onPageControllerReset: () {
                    setState(() {
                      _hasResetPageController = true;
                    });
                  },
                ),
                collapsedChild: CollapsedReadingBooksSection(books: books),
                height: 28.0 +
                    16.0 +
                    191.0, // 제목(28px) + 간격(16px) + 책 높이(191px) = 235px
          ),
        ),
            // Reading 섹션과 Memo 섹션 사이 간격 (Reading 섹션이 축소될 때도 유지)
        const SliverToBoxAdapter(
              child: SizedBox(
                height: 32,
                child: ClipRect(
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox.shrink(),
                ),
              ),
        ),

        // Memo 섹션
        SliverToBoxAdapter(
              child: HomeMemoSection(books: books),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 100), // 하단 네비게이션 바 공간
        ),
      ],
        );
      },
    );
  }

  // 앱바 (상단 고정)
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      child: Image.asset(
        'assets/images/logo_horizontal.png',
        height: 37,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Text(
          'Home',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }
}
