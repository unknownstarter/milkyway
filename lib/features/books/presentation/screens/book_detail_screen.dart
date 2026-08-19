import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/book_detail_provider.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../core/presentation/widgets/pill_filter_button.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../home/domain/models/book.dart';
import '../../../home/domain/models/book_status.dart';
import '../../../home/presentation/providers/book_provider.dart';
import '../../../books/presentation/providers/user_books_provider.dart';
import '../../../memos/presentation/providers/memo_provider.dart';
import '../../../home/presentation/providers/selected_book_provider.dart';
import '../../../lyra/presentation/providers/lyra_providers.dart';
import '../../../lyra/presentation/widgets/lyra_question_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/presentation/widgets/design/segment_filter.dart';
import '../../../../core/presentation/widgets/design/memo_card.dart';
import '../../../memos/domain/models/memo.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  final String bookId;
  final bool isFromRegistration;
  final bool isFromOnboarding;

  const BookDetailScreen({
    super.key,
    required this.bookId,
    this.isFromRegistration = false,
    this.isFromOnboarding = false,
  });

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  BookStatus? _selectedStatus;
  bool _isDescriptionExpanded = false;
  bool _lyraQuestionShownLogged = false;
  int _memoSegment = 0; // 0 = 함께(공개), 1 = 내 메모

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).logScreenView('book_detail_screen');
  }

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(bookDetailProvider(widget.bookId));

    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181818),
        surfaceTintColor: Colors.transparent, // Material 3에서 스크롤 시 색상 변경 방지
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (widget.isFromOnboarding) {
              // 온보딩을 통해 책 검색 → 책 저장 → 책 상세로 온 경우 홈으로 이동
              context.goNamed(AppRoutes.homeName);
            } else if (widget.isFromRegistration) {
              // 일반적으로 책 등록 후 진입한 경우 홈으로 이동
              context.goNamed(AppRoutes.homeName);
            } else {
              // 일반적인 경우 이전 페이지로 이동
              context.pop();
            }
          },
        ),
        title: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: const Text(
            '책 상세페이지',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 20,
              height: 28 / 20,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          bookAsync.when(
            data: (book) => TextButton(
              onPressed: () => _deleteBook(book),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
                child: const Text(
                  '삭제',
                  style: TextStyle(
                    color: Colors.red,
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: bookAsync.when(
        data: (book) {
          // 상태 동기화: 책 상태가 변경된 경우 업데이트
          if (_selectedStatus != book.status) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedStatus = book.status;
                });
              }
            });
          }
          return _buildContent(book);
        },
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error),
      ),
    );
  }

  Widget _buildContent(Book book) {
    // 하단 버튼 높이 계산: 버튼(41px) + 상하 패딩(20px * 2) + SafeArea
    final bottomPadding = 41 + 20 * 2 + MediaQuery.of(context).padding.bottom + 20; // 추가 여유 공간 20px
    
    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 앱바와 책 정보 사이 간격 (피그마: 앱바 타이틀 끝 2757 ~ 책 정보 시작 2786 = 29px)
              const SizedBox(height: 28),
              // 책 정보 영역
              _buildBookInfo(book),
              const SizedBox(
                  height: 32), // 피그마: 책 정보 영역 끝(2934) ~ 상태 버튼(2966) = 32px

              // 상태 버튼
              _buildStatusButtons(book),
              const SizedBox(
                  height: 32), // 피그마: 상태 버튼 끝(3006) ~ 책 소개 타이틀(3038) = 32px

              // Lyra 물음 카드 (있을 때만 노출, 섹션 격리)
              _buildLyraQuestion(book),

              // 책 소개 섹션
              if (book.description != null && book.description!.isNotEmpty)
                _buildBookDescription(book),
              if (book.description != null && book.description!.isNotEmpty)
                const SizedBox(
                    height: 40), // 피그마: 더보기 버튼 끝(3315) ~ 책 메모 타이틀(3355) = 40px

              // 메모 섹션
              _buildMemosSection(book),
            ],
          ),
        ),
        // 하단 고정 메모하기 버튼 (하단 네비게이션바 영역에 플로팅)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            bottom: false, // SafeArea를 false로 하여 하단까지 확장
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 불투명 배경 (181818 색상으로 버튼 뒤와 아래 영역 모두 가리기)
                Container(
                  color: const Color(0xFF181818),
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: 20,
                  ),
                  child: _buildAddMemoButton(book),
                ),
                // 하단 영역까지 181818로 가리기
                Container(
                  color: const Color(0xFF181818),
                  height: MediaQuery.of(context).padding.bottom,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Lyra 물음 카드. 물음이 있을 때만 노출되고, 실패/없음이면 화면에 아무 영향 없음.
  Widget _buildLyraQuestion(Book book) {
    final questionAsync = ref.watch(bookQuestionProvider(book.id));
    return questionAsync.maybeWhen(
      data: (q) {
        if (q == null) return const SizedBox.shrink();
        // 노출 계측 1회
        if (!_lyraQuestionShownLogged) {
          _lyraQuestionShownLogged = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref
                .read(analyticsProvider)
                .logEvent('lyra_question_shown', {'book_id': book.id});
          });
        }
        return Column(
          children: [
            LyraQuestionCard(
              question: q.question,
              onAnswer: () => _addMemo(book, lyraQuestion: q.question),
            ),
            const SizedBox(height: 32),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildBookInfo(Book book) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 책 표지 (104x147)
          _buildBookCover(book, 104, 147),
          const SizedBox(width: 20),
          // 책 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 책 제목 (피그마: 최대 84px, 3줄)
                // MediaQuery로 텍스트 스케일을 제한하여 디바이스 글자 크기 설정과 무관하게 일정한 크기 유지
                MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(1.0), // 텍스트 스케일을 1.0으로 고정
                  ),
                  child: SizedBox(
                    height: 84, // 피그마: 책 제목 최대 높이 84px (3줄 × 28px lineHeight)
                    child: Text(
                      book.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        height: 28 / 20,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // 피그마: 책 제목 끝(2871) ~ Frame 25 시작(2895) = 24px
                const SizedBox(height: 24),
                // 저자 및 출판사 정보 (텍스트 스케일 고정)
                MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 저자
                      Text(
                        book.author,
                        style: const TextStyle(
                          color: Color(0xFFDADADA),
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          height: 16.8 / 12,
                        ),
                      ),
                      // 피그마: 저자(2895, height: 17) ~ 출판사(2917) = 22px
                      // 하지만 저자 끝(2912) ~ 출판사(2917) = 5px
                      // 실제로는 더 작은 간격이 필요할 수 있음
                      const SizedBox(height: 2),
                      // 출판사 및 출판일
                      Row(
                        children: [
                          if (book.publisher != null && book.publisher!.isNotEmpty)
                            Text(
                              book.publisher!,
                              style: const TextStyle(
                                color: Color(0xFFDADADA),
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                height: 16.8 / 12,
                              ),
                            ),
                          if (book.publisher != null &&
                              book.publisher!.isNotEmpty &&
                              book.pubdate != null &&
                              book.pubdate!.isNotEmpty)
                            const Text(
                              ' · ',
                              style: TextStyle(
                                color: Color(0xFFDADADA),
                                fontSize: 12,
                              ),
                            ),
                          if (book.pubdate != null && book.pubdate!.isNotEmpty)
                            Text(
                              book.pubdate!,
                              style: const TextStyle(
                                color: Color(0xFFDADADA),
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                height: 16.8 / 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCover(Book book, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade900,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: book.coverUrl != null && book.coverUrl!.isNotEmpty
            ? Image.network(
                book.coverUrl!,
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildBookPlaceholder(width, height),
              )
            : _buildBookPlaceholder(width, height),
      ),
    );
  }

  Widget _buildBookPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade900,
      child: const Icon(
        Icons.book,
        color: Colors.grey,
        size: 32,
      ),
    );
  }

  Widget _buildStatusButtons(Book book) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          PillFilterButton(
            label: BookStatus.wantToRead.value,
            isActive: (_selectedStatus ?? BookStatus.wantToRead) ==
                BookStatus.wantToRead,
            onTap: () {
              setState(() {
                _selectedStatus = BookStatus.wantToRead;
              });
              _changeStatus(book, BookStatus.wantToRead);
            },
            width: 90,
            fontSize: 16,
            activeFontWeight: FontWeight.w400,
            inactiveFontWeight: FontWeight.w400,
          ),
          const SizedBox(width: 12),
          PillFilterButton(
            label: BookStatus.reading.value,
            isActive: (_selectedStatus ?? BookStatus.wantToRead) ==
                BookStatus.reading,
            onTap: () {
              setState(() {
                _selectedStatus = BookStatus.reading;
              });
              _changeStatus(book, BookStatus.reading);
            },
            width: 90,
            fontSize: 16,
            activeFontWeight: FontWeight.w400,
            inactiveFontWeight: FontWeight.w400,
          ),
          const SizedBox(width: 12),
          PillFilterButton(
            label: BookStatus.completed.value,
            isActive: (_selectedStatus ?? BookStatus.wantToRead) ==
                BookStatus.completed,
            onTap: () {
              setState(() {
                _selectedStatus = BookStatus.completed;
              });
              _changeStatus(book, BookStatus.completed);
            },
            width: 72,
            fontSize: 16,
            activeFontWeight: FontWeight.w400,
            inactiveFontWeight: FontWeight.w400,
          ),
        ],
      ),
    );
  }

  Widget _buildBookDescription(Book book) {
    final description = book.description ?? '';
    // 12px 폰트 기준으로 더보기 조건 조정 (약 240자)
    final shouldShowMoreButton =
        description.length > 240 && !_isDescriptionExpanded;
    final displayText = _isDescriptionExpanded
        ? description
        : (description.length > 240
            ? description.substring(0, 240)
            : description);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
            child: const Text(
              '책 소개',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 20,
                height: 28 / 20,
              ),
            ),
          ),
          const SizedBox(
              height: 20), // 피그마: 책 소개 타이틀 끝(3066) ~ 책 소개 내용(3086) = 20px
          Text(
            displayText,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              height: 18 / 12,
            ),
          ),
          if (shouldShowMoreButton) ...[
            const SizedBox(height: 20), // 피그마: 책 소개 내용 끝 ~ 더보기 버튼
            // 더보기 버튼 (240자 이상일 때만 표시)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isDescriptionExpanded = true;
                });
              },
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF242424),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '더보기',
                      style: TextStyle(
                        color: Color(0xFFDADADA),
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        height: 24 / 16,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFFDADADA),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemosSection(Book book) {
    final async = _memoSegment == 0
        ? ref.watch(publicBookMemosProvider(book.id))
        : ref.watch(bookMemosProvider(book.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('이 책의 메모', style: AppTypography.title),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SegmentFilter(
            segments: const ['함께', '내 메모'],
            selectedIndex: _memoSegment,
            onChanged: (i) => setState(() => _memoSegment = i),
          ),
        ),
        const SizedBox(height: 16),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(
                  color: AppColors.textSecondary, strokeWidth: 2),
            ),
          ),
          error: (_, __) => _memoSectionMessage('메모를 불러오지 못했어요'),
          data: (memos) {
            if (memos.isEmpty) {
              return _memoSectionMessage(
                  _memoSegment == 0 ? '아직 공개된 메모가 없어요' : '아직 남긴 메모가 없어요');
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  for (final m in memos) ...[
                    _memoCard(m),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _memoCard(Memo m) {
    final edited = m.updatedAt != null && m.updatedAt!.isAfter(m.createdAt);
    final date = edited ? m.updatedAt! : m.createdAt;
    return MemoCard(
      content: m.content,
      authorName: m.userNickname ?? '밀키웨이',
      authorImageUrl: m.userAvatarUrl,
      dateText: _relativeDate(date),
      edited: edited,
      showMineTag: _memoSegment == 1,
      page: m.page,
      onTap: () => context.pushNamed(AppRoutes.memoDetailName,
          pathParameters: {'id': m.id}),
    );
  }

  static String _relativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    return '${dt.year}.$mm.$dd';
  }

  Widget _memoSectionMessage(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(text,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary)),
      ),
    );
  }

  Widget _buildAddMemoButton(Book book) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFDEDEDE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
          child: InkWell(
          onTap: () => _addMemo(book),
          borderRadius: BorderRadius.circular(20),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
            child: const Center(
              child: Text(
                '메모하기',
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  height: 24 / 16,
                ),
              ),
            ),
          ),
        ),
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
          const Text(
            '책 정보를 불러올 수 없습니다',
            style: TextStyle(
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

  Future<void> _changeStatus(Book book, BookStatus newStatus) async {
    try {
      await ref
          .read(bookDetailProvider(widget.bookId).notifier)
          .updateStatus(newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '상태를 "${newStatus.value}"로 변경했습니다',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF242424),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, operation: '책 상태 변경');
      }
    }
  }

  void _addMemo(Book book, {String? lyraQuestion}) {
    context.pushNamed(
      AppRoutes.memoCreateName,
      queryParameters: {
        'bookId': book.id,
        if (lyraQuestion != null) 'lyraQuestion': lyraQuestion,
      },
    );
  }

  Future<void> _deleteBook(Book? book) async {
    if (book == null) return;

    // 삭제 확인 다이얼로그
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          '책 삭제',
          style: TextStyle(color: Colors.white, fontFamily: 'Pretendard'),
        ),
        content: const Text(
          '책을 삭제하면 해당 책의 메모도 모두 삭제되며 복구할 수 없습니다.\n\n정말 삭제하시겠습니까?',
          style: TextStyle(color: Colors.white, fontFamily: 'Pretendard'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '취소',
              style: TextStyle(color: Colors.grey, fontFamily: 'Pretendard'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red, fontFamily: 'Pretendard'),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      final repository = ref.read(bookRepositoryProvider);
      await repository.deleteUserBook(book.id);

      // 관련 provider들 invalidate
      ref.invalidate(bookDetailProvider(book.id));
      ref.invalidate(userBooksProvider);
      ref.invalidate(recentBooksProvider);
      ref.invalidate(homeBooksProvider);
      ref.invalidate(bookMemosProvider(book.id));
      ref.invalidate(recentMemosProvider);
      ref.invalidate(homeRecentMemosProvider);
      ref.invalidate(allMemosProvider);

      // 삭제된 책이 선택되어 있으면 선택 해제 또는 첫 번째 책으로 변경
      final selectedBookId = ref.read(selectedBookIdProvider);
      if (selectedBookId == book.id) {
        // 남은 책 목록 가져오기
        final booksAsync = ref.read(userBooksProvider);
        booksAsync.whenData((books) {
          if (books.isNotEmpty) {
            // 남은 책이 있으면 첫 번째 책 선택
            ref.read(selectedBookIdProvider.notifier).state = books[0].id;
          } else {
            // 남은 책이 없으면 선택 해제
            ref.read(selectedBookIdProvider.notifier).state = null;
          }
        });
      }

      if (mounted) {
        // 이전 화면으로 이동
        if (widget.isFromOnboarding || widget.isFromRegistration) {
          context.goNamed(AppRoutes.homeName);
        } else {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, operation: '책 삭제');
      }
    }
  }
}
