import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'router_extensions.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/nickname_screen.dart';
import '../../features/onboarding/presentation/screens/profile_image_screen.dart';
import '../../features/onboarding/presentation/screens/genre_screen.dart';
import '../../features/discovery/presentation/screens/onboarding_book_saving_screen.dart';
import '../../features/onboarding/presentation/screens/book_intro_screen.dart';
import '../../features/books/presentation/screens/book_search_screen.dart';
import '../../features/books/presentation/screens/book_shelf_screen.dart';
import '../../features/memos/presentation/screens/memo_list_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/profile_edit_screen.dart';
import '../../features/books/presentation/screens/book_detail_screen.dart';
import '../../features/memos/presentation/screens/memo_detail_screen.dart';
import '../../features/memos/presentation/screens/memo_create_screen.dart';
import '../../features/memos/presentation/screens/memo_edit_screen.dart';
import 'main_shell.dart';
import 'app_routes.dart';

/// 앱의 메인 라우터
/// 
/// GoRouter 기반 네비게이션 시스템
/// - ShellRoute로 BottomNavigationBar 통합
/// - pathParameters 사용 (extra 대신)
/// - Named routes 지원
final router = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    // 스플래시 화면
    GoRoute(
      path: AppRoutes.splash,
      name: AppRoutes.splashName,
      builder: (context, state) => const SplashScreen(),
    ),
    
    // 로그인 화면
    GoRoute(
      path: AppRoutes.login,
      name: AppRoutes.loginName,
      builder: (context, state) => const LoginScreen(),
    ),
    
    // 온보딩 화면들
    GoRoute(
      path: AppRoutes.onboardingNickname,
      name: AppRoutes.onboardingNicknameName,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const NicknameScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // secondaryAnimation이 활성화되면 뒤로가기 (왼쪽에서 오른쪽으로)
          // 그렇지 않으면 앞으로가기 (오른쪽에서 왼쪽으로)
          final isReverse = secondaryAnimation.status == AnimationStatus.forward ||
              secondaryAnimation.value > 0;
          
          // 첫 번째 화면은 뒤로가기 시에만 애니메이션 적용
          if (isReverse) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
              ),
              child: child,
            );
          }
          return child;
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.onboardingProfileImage,
      name: AppRoutes.onboardingProfileImageName,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ProfileImageScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // secondaryAnimation이 활성화되면 뒤로가기 (왼쪽에서 오른쪽으로)
          // 그렇지 않으면 앞으로가기 (오른쪽에서 왼쪽으로)
          final isReverse = secondaryAnimation.status == AnimationStatus.forward ||
              secondaryAnimation.value > 0;
          
          final begin = isReverse ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
          const end = Offset.zero;
          
          return SlideTransition(
            position: Tween<Offset>(begin: begin, end: end).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
            ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.onboardingGenre,
      name: AppRoutes.onboardingGenreName,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const GenreScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final isReverse =
              secondaryAnimation.status == AnimationStatus.forward ||
                  secondaryAnimation.value > 0;
          final begin = isReverse ? Offset.zero : const Offset(1.0, 0.0);
          final end = isReverse ? const Offset(1.0, 0.0) : Offset.zero;
          return SlideTransition(
            position: Tween<Offset>(begin: begin, end: end).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.onboardingBookSaving,
      name: AppRoutes.onboardingBookSavingName,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const OnboardingBookSavingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final isReverse =
              secondaryAnimation.status == AnimationStatus.forward ||
                  secondaryAnimation.value > 0;
          final begin = isReverse ? Offset.zero : const Offset(1.0, 0.0);
          final end = isReverse ? const Offset(1.0, 0.0) : Offset.zero;
          return SlideTransition(
            position: Tween<Offset>(begin: begin, end: end).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.onboardingBookIntro,
      name: AppRoutes.onboardingBookIntroName,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const BookIntroScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // 뒤로가기 감지: secondaryAnimation이 활성화되면 뒤로가기
          final isReverse = secondaryAnimation.status == AnimationStatus.forward ||
              secondaryAnimation.value > 0;
          
          // 뒤로가기 시: 현재 화면이 오른쪽으로 나감 (0 → 1.0)
          // 앞으로가기 시: 현재 화면이 오른쪽에서 왼쪽으로 들어옴 (1.0 → 0)
          final begin = isReverse ? Offset.zero : const Offset(1.0, 0.0);
          final end = isReverse ? const Offset(1.0, 0.0) : Offset.zero;
          
          return SlideTransition(
            position: Tween<Offset>(begin: begin, end: end).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
            ),
            child: child,
          );
        },
      ),
    ),
    
    // 책 검색 화면 (별도 라우트)
    GoRoute(
      path: AppRoutes.bookSearch,
      name: AppRoutes.bookSearchName,
      builder: (context, state) {
        final isFromOnboarding = state.getBoolQuery('isFromOnboarding');
        return BookSearchScreen(isFromOnboarding: isFromOnboarding);
      },
    ),
    
    // 책 상세 화면 (하단 네비게이션바 없음)
    GoRoute(
      path: '${AppRoutes.bookDetail}/:id',
      name: AppRoutes.bookDetailName,
      builder: (context, state) {
        final bookId = state.requirePathParam('id');
        final isFromRegistration = state.getBoolQuery('isFromRegistration');
        final isFromOnboarding = state.getBoolQuery('isFromOnboarding');
        return BookDetailScreen(
          bookId: bookId,
          isFromRegistration: isFromRegistration,
          isFromOnboarding: isFromOnboarding,
        );
      },
    ),
    
    // 메모 작성 화면 (ShellRoute 밖 - 책 상세에서 접근용)
    // 주의: ShellRoute 안에도 동일한 경로가 있지만, 
    // ShellRoute 밖에서는 하단 네비게이션바 없이 표시됨
    GoRoute(
      path: AppRoutes.memoCreate,
      name: AppRoutes.memoCreateName,
      builder: (context, state) {
        final bookId = state.uri.queryParameters['bookId'];
        return MemoCreateScreen(
          bookId: bookId,
        );
      },
    ),
    
    // 프로필 수정 화면 (ShellRoute 밖 - 하단 네비게이션바 없음)
    GoRoute(
      path: AppRoutes.profileEdit,
      name: AppRoutes.profileEditName,
      builder: (context, state) => const ProfileEditScreen(),
    ),
    
    // 메모 상세 화면 (ShellRoute 밖 - 하단 네비게이션바 없음)
    GoRoute(
      path: '${AppRoutes.memoDetail}/:id',
      name: AppRoutes.memoDetailName,
      builder: (context, state) => MemoDetailScreen(
        memoId: state.requirePathParam('id'),
      ),
    ),
    
    // 메모 편집 화면 (ShellRoute 밖 - 하단 네비게이션바 없음)
    GoRoute(
      path: '${AppRoutes.memoEdit}/:id',
      name: AppRoutes.memoEditName,
      builder: (context, state) => MemoEditScreen(
        memoId: state.requirePathParam('id'),
      ),
    ),
    
    // 메인 앱 Shell (BottomNavigationBar 포함)
    ShellRoute(
      builder: (context, state, child) => MainShell(
        location: state.uri.toString(),
        child: child,
      ),
      routes: [
        // 홈 화면
        GoRoute(
          path: AppRoutes.home,
          name: AppRoutes.homeName,
          pageBuilder: (context, state) {
            final autoBookSearch = state.getBoolQuery('autoBookSearch');
            return NoTransitionPage(
              child: HomeScreen(autoBookSearch: autoBookSearch),
            );
          },
        ),
        
        // 책 관련 화면들
        GoRoute(
          path: AppRoutes.books,
          name: AppRoutes.booksName,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: BookShelfScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.bookShelf,
          name: AppRoutes.bookShelfName,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: BookShelfScreen(),
          ),
        ),
        
        // 메모 관련 화면들
        GoRoute(
          path: AppRoutes.memos,
          name: AppRoutes.memosName,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MemoListScreen(),
          ),
        ),
        // 메모 작성 화면 (ShellRoute 안 - 하단 네비게이션바 있음)
        // 주의: ShellRoute 밖에도 동일한 경로가 있지만,
        // ShellRoute 안에서는 하단 네비게이션바와 함께 표시됨
        // GoRouter는 첫 번째 매칭되는 라우트를 사용하므로,
        // ShellRoute 밖의 라우트가 우선순위가 높음
        // 따라서 ShellRoute 안의 이 라우트는 실제로 사용되지 않을 수 있음
        
        // 프로필 화면
        GoRoute(
          path: AppRoutes.profile,
          name: AppRoutes.profileName,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfileScreen(),
          ),
        ),
      ],
    ),
  ],
  observers: [RouteObserver<ModalRoute<void>>()],
);
