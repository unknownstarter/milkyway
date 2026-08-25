import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/design/cached_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'home_profile_section.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../presentation/providers/book_provider.dart';
import '../../domain/models/book.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../books/presentation/providers/user_books_provider.dart';
import '../../../home/presentation/providers/selected_book_provider.dart';

/// 빈 상태 (책이 없을 때)
class HomeEmptyState extends ConsumerWidget {
  const HomeEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authProvider);
    final popularBooksAsync = ref.watch(popularBooksProvider);

    return CustomScrollView(
      slivers: [
        // 앱바 (고정) - HomeScreen과 동일한 구조
        SliverAppBar(
          pinned: true,
          floating: false,
          elevation: 0,
          backgroundColor: const Color(0xFF181818),
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          toolbarHeight: 64,
          flexibleSpace: Container(
            color: const Color(0xFF181818),
            child: _buildAppBar(),
          ),
        ),
        // 프로필 영역
        const SliverToBoxAdapter(
          child: HomeProfileSection(),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 60), // 32 -> 60으로 증가하여 하단으로 이동
        ),
        // 빈 상태 콘텐츠
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 닉네임 첫 3글자 + ... 처리
                userAsync.when(
                  data: (user) {
                    final nickname = user?.nickname ?? '';
                    final displayName = nickname.length > 3
                        ? '${nickname.substring(0, 3)}...'
                        : nickname;
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(1.0),
                      ),
                      child: Text(
                        '$displayName님의 인생 책을 찾아주세요',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Pretendard',
                          height: 28 / 20,
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 20),
                // 검색어 입력칸 (탭 시 책 검색으로 이동)
                GestureDetector(
                  onTap: () {
                    context.pushNamed(AppRoutes.bookSearchName);
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF646464),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search,
                          color: Color(0xFF48FF00),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            textScaler: TextScaler.linear(1.0),
                          ),
                          child: Text(
                            '책 제목, 저자, ISBN으로 검색하세요',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 60), // 40 -> 60으로 증가하여 하단으로 이동
                // 지금 밀키웨이에서 많이 읽고 있는 책
                MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(1.0),
                  ),
                  child: const Text(
                    '지금 밀키웨이에서 많이 읽고 있는 책',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard',
                      height: 28 / 20,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 가로 캐로즐
                popularBooksAsync.when(
                  data: (books) {
                    if (books.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return SizedBox(
                      height: 127, // 높이 조정 (147 -> 127)
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(right: 0), // 오른쪽 패딩 제거하여 4번째 책이 살짝 걸쳐 나오도록
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final book = books[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index == books.length - 1 ? 0 : 16, // 간격 조정 (20 -> 16)
                            ),
                            child: GestureDetector(
                              onTap: () => _handleBookTap(
                                context,
                                ref,
                                book,
                              ),
                              child: Container(
                                width: 90, // 크기 조정 (104 -> 90)
                                height: 127, // 크기 조정 (147 -> 127)
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color(0xFF1A1A1A),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: book.coverUrl != null &&
                                          book.coverUrl!.isNotEmpty
                                      ? CachedImage(
                                          url: book.coverUrl,
                                          width: 90,
                                          height: 127,
                                          fit: BoxFit.contain, // cover -> contain으로 변경하여 이미지가 안 짤리게
                                          cacheWidth: 270,
                                          fallback: _buildBookPlaceholder(),
                                        )
                                      : _buildBookPlaceholder(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    height: 127, // 높이 조정 (191 -> 127)
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFECECEC),
                      ),
                    ),
                  ),
                  error: (error, stack) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 100), // 하단 네비게이션 바 공간
        ),
      ],
    );
  }

  void _handleBookTap(
    BuildContext context,
    WidgetRef ref,
    Book book,
  ) async {
    // 책 저장 다이얼로그 표시
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242424),
        title: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1.0),
          ),
          child: const Text(
            '책 저장',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
        content: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1.0),
          ),
          child: const Text(
            '이 책을 저장하시겠습니까?',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '취소',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(1.0),
              ),
              child: const Text(
                '예',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldSave == true && context.mounted) {
      try {
        // 책 저장
        final repository = ref.read(bookRepositoryProvider);
        final userId = repository.getCurrentUserId();
        await repository.createUserBookConnection(book.id, userId);

        // 관련 provider 무효화
        ref.invalidate(userBooksProvider);
        ref.invalidate(recentBooksProvider);
        ref.invalidate(homeBooksProvider);

        // 책 상세 화면으로 이동
        if (context.mounted) {
          ref.read(selectedBookIdProvider.notifier).state = book.id;
          context.pushNamed(
            AppRoutes.bookDetailName,
            pathParameters: {'id': book.id},
          );
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showError(
            context,
            e,
            operation: '책 저장',
          );
        }
      }
    }
  }

  Widget _buildBookPlaceholder() {
    return Container(
      width: 90, // 크기 조정 (104 -> 90)
      height: 127, // 크기 조정 (147 -> 127)
      color: const Color(0xFF1A1A1A),
      child: const Icon(
        Icons.book,
        color: Colors.grey,
        size: 32,
      ),
    );
  }

  // 앱바 (상단 고정) - HomeScreen과 동일
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

/// 로딩 상태
class HomeLoadingState extends StatelessWidget {
  const HomeLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // 앱바 (고정) - HomeScreen과 동일한 구조
        SliverAppBar(
          pinned: true,
          floating: false,
          elevation: 0,
          backgroundColor: const Color(0xFF181818),
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          toolbarHeight: 64,
          flexibleSpace: Container(
            color: const Color(0xFF181818),
            child: _buildAppBar(),
          ),
        ),
        // 로딩 인디케이터
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(
              color: Color(0xFFECECEC),
            ),
          ),
        ),
      ],
    );
  }

  // 앱바 (상단 고정) - HomeScreen과 동일
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

/// 에러 상태
class HomeErrorState extends StatelessWidget {
  final Object error;

  const HomeErrorState({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // 앱바 (고정) - HomeScreen과 동일한 구조
        SliverAppBar(
          pinned: true,
          floating: false,
          elevation: 0,
          backgroundColor: const Color(0xFF181818),
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          toolbarHeight: 64,
          flexibleSpace: Container(
            color: const Color(0xFF181818),
            child: _buildAppBar(),
          ),
        ),
        // 에러 메시지
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SelectableText.rich(
                TextSpan(
                  text: '에러: $error',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 앱바 (상단 고정) - HomeScreen과 동일
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

