import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../providers/book_search_provider.dart';
import '../providers/book_register_provider.dart';
import '../../domain/models/naver_book.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/presentation/widgets/design/glass_app_bar.dart';

class BookSearchScreen extends ConsumerStatefulWidget {
  final bool isFromOnboarding;

  const BookSearchScreen({
    super.key,
    this.isFromOnboarding = false,
  });

  @override
  ConsumerState<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends ConsumerState<BookSearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // 위젯이 완전히 빌드된 후에 포커스 요청
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
    ref.read(analyticsProvider).logScreenView('book_search_screen');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        ref.read(searchBooksProvider.notifier).searchBooks(query);
      }
    });
  }

  void _handleBackButton(BuildContext context) {
    // 이전 페이지로 돌아갈 수 있는지 확인
    if (context.canPop()) {
      context.pop();
    } else {
      // 이전 페이지가 없으면 무조건 홈으로 이동
      // (책 검색 화면은 온보딩 완료 후에만 접근 가능)
      context.goNamed(AppRoutes.homeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchBooksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      extendBodyBehindAppBar: true,
      appBar: glassAppBar(
        title: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: const Text(
            '책 검색',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _handleBackButton(context),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: glassTopPadding(context)),
          // 검색 입력
          _buildSearchInput(),
          
          // 검색 결과
          Expanded(
            child: searchState.when(
              data: (books) => _buildSearchResults(books),
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onChanged: _onSearchChanged,
        // autofocus 제거: initState의 requestFocus와 중복되어 IME 충돌 발생
        textInputAction: TextInputAction.search,
        keyboardType: TextInputType.text,
        enableInteractiveSelection: true,
        enableSuggestions: !isAndroid, // 안드로이드에서는 false (한글 IME 충돌 방지)
        cursorColor: Colors.white,
        style: const TextStyle(color: Colors.white, fontFamily: 'Pretendard'),
        decoration: InputDecoration(
          hintText: '책 제목, 저자, ISBN으로 검색하세요',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontFamily: 'Pretendard'),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF48FF00)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchBooksProvider.notifier).clearSearch();
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade800),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade800),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<NaverBook> books) {
    if (books.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return _buildBookItem(book);
      },
    );
  }

  Widget _buildBookItem(NaverBook book) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildBookCover(book),
        title: Text(
          book.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              book.author,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
                fontFamily: 'Pretendard',
              ),
            ),
            if (book.publisher.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                book.publisher,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add, color: Color(0xFF48FF00)),
          onPressed: () => _onBookTap(book),
        ),
        onTap: () => _onBookTap(book),
      ),
    );
  }

  Widget _buildBookCover(NaverBook book) {
    return Container(
      width: 60,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade900,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: book.coverUrl.isNotEmpty
            ? Image.network(
                book.coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildBookPlaceholder(),
              )
            : _buildBookPlaceholder(),
      ),
    );
  }

  Widget _buildBookPlaceholder() {
    return Container(
      color: Colors.grey.shade900,
      child: const Icon(
        Icons.book,
        color: Colors.grey,
        size: 24,
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFFECECEC),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            '검색 중 오류가 발생했습니다',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Pretendard',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
              fontFamily: 'Pretendard',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: const Icon(
              Icons.search,
              color: Colors.grey,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '검색 결과가 없습니다',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '다른 키워드로 검색해보세요',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onBookTap(NaverBook book) async {
    try {
      await ref
          .read(analyticsProvider)
          .logEvent('click_book_select_in_book_search');

      final repository = ref.read(bookRepositoryProvider);
      final existingBook = await repository.findBookByIsbn(book.isbn);

      if (existingBook != null) {
        // 책이 이미 존재하는 경우
        final hasConnection = await repository.hasUserBookConnection(
          existingBook.id,
          repository.getCurrentUserId(),
        );

        if (hasConnection) {
          // 이미 연결된 책
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '이미 등록된 책입니다',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Color(0xFF242424),
              ),
            );
          }
        } else {
          // 책은 있지만 사용자와 연결되지 않은 경우
          await _connectBook(existingBook.id);
        }
      } else {
        // 새로운 책 등록
        await _registerNewBook(book);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, operation: '책 등록');
      }
    }
  }

  Future<void> _connectBook(String bookId) async {
    try {
      await ref.read(bookRegisterProvider.notifier).connectExistingBook(bookId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '책이 등록되었습니다',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF242424),
          ),
        );
        // 책 상세 페이지로 이동 (등록 플래그 및 온보딩 플래그 포함)
        context.pushNamed(
          AppRoutes.bookDetailName,
          pathParameters: {'id': bookId},
          queryParameters: {
            'isFromRegistration': 'true',
            if (widget.isFromOnboarding) 'isFromOnboarding': 'true',
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, operation: '책 연결');
      }
    }
  }

  Future<void> _registerNewBook(NaverBook naverBook) async {
    try {
      final book = await ref.read(bookRegisterProvider.notifier).registerBook(naverBook);
      if (mounted) {
        if (book != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '새 책이 등록되었습니다',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Color(0xFF242424),
            ),
          );
          // 책 상세 페이지로 이동 (등록 플래그 및 온보딩 플래그 포함)
          context.pushNamed(
            AppRoutes.bookDetailName,
            pathParameters: {'id': book.id},
            queryParameters: {
              'isFromRegistration': 'true',
              if (widget.isFromOnboarding) 'isFromOnboarding': 'true',
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '책 등록에 실패했습니다',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Color(0xFF242424),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, operation: '책 등록');
      }
    }
  }
}