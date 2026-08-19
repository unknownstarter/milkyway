import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../core/presentation/widgets/add_floating_action_button.dart';
import '../../../../core/presentation/widgets/design/story_circle.dart';
import '../../../../core/presentation/widgets/design/discovery_cover.dart';
import '../../domain/models/book.dart';
import '../../domain/models/book_status.dart';
import '../providers/book_provider.dart';
import '../../../discovery/data/models/recommended_book.dart';
import '../../../discovery/presentation/providers/discovery_providers.dart';
import '../../../lyra/presentation/providers/lyra_providers.dart';
import '../../../lyra/presentation/widgets/lyra_question_card.dart';

/// 홈 = 발견 피드. 좋아하는 책 스토리 + 지금 읽는 책 Lyra 물음 + 다른 사람이 담은 책.
/// (내 서재/책 캐러셀은 '책' 탭으로 이동. N2 '이번 주 함께 읽는 책'은 데이터 준비 후.)
class HomeScreen extends ConsumerStatefulWidget {
  final bool autoBookSearch;

  const HomeScreen({super.key, this.autoBookSearch = false});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _lyraShownLogged = false;

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).logScreenView('home_screen');
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

  void _openBook(String bookId) =>
      context.pushNamed(AppRoutes.bookDetailName, pathParameters: {'id': bookId});

  void _openSearch() => context.pushNamed(AppRoutes.bookSearchName);

  void _answer(String bookId, String question) => context.pushNamed(
        AppRoutes.memoCreateName,
        queryParameters: {'bookId': bookId, 'lyraQuestion': question},
      );

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(homeBooksProvider);
    final books = booksAsync.asData?.value ?? const <Book>[];

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      floatingActionButton: const AddFloatingActionButton(),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accentGreen,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            ref.invalidate(homeBooksProvider);
            ref.invalidate(booksSavedByOthersProvider);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              _header(),
              const SizedBox(height: 6),
              _stories(books),
              _lyraHighlight(books),
              const SizedBox(height: 34),
              _discoverySection(books),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Text(
        'milkyway',
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 21,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _stories(List<Book> books) {
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          StoryCircle(
            label: '담기',
            ring: StoryRing.add,
            onTap: _openSearch,
          ),
          for (final b in books) ...[
            const SizedBox(width: 14),
            StoryCircle(
              label: b.title,
              coverUrl: b.coverUrl,
              ring: b.status == BookStatus.reading
                  ? StoryRing.active
                  : StoryRing.seen,
              onTap: () => _openBook(b.id),
            ),
          ],
        ],
      ),
    );
  }

  /// 지금 읽는 책(없으면 첫 책)의 Lyra 물음. 물음 없으면 섹션 숨김.
  Widget _lyraHighlight(List<Book> books) {
    if (books.isEmpty) return const SizedBox.shrink();
    final reading = books.firstWhere(
      (b) => b.status == BookStatus.reading,
      orElse: () => books.first,
    );
    final questionAsync = ref.watch(bookQuestionProvider(reading.id));
    return questionAsync.maybeWhen(
      data: (q) {
        if (q == null) return const SizedBox.shrink();
        if (!_lyraShownLogged) {
          _lyraShownLogged = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(analyticsProvider).logEvent(
                'lyra_question_shown', {'book_id': reading.id, 'surface': 'home'});
          });
        }
        return Padding(
          padding: const EdgeInsets.only(top: 22),
          child: LyraQuestionCard(
            question: q.question,
            bookTitle: reading.title,
            bookCoverUrl: reading.coverUrl,
            bookStatusLabel: reading.status.value,
            onAnswer: () => _answer(reading.id, q.question),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _discoverySection(List<Book> myBooks) {
    final async = ref.watch(booksSavedByOthersProvider);
    return async.maybeWhen(
      data: (all) {
        final myIds = myBooks.map((b) => b.id).toSet();
        final books = all.where((b) => !myIds.contains(b.id)).toList();
        if (books.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('다른 사람이 담은 책', style: AppTypography.title),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 192,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: books.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => DiscoveryCover(
                  title: books[i].title,
                  author: books[i].author,
                  coverUrl: books[i].coverUrl,
                  meta: books[i].proofLabel,
                  onTap: () => _openBook(books[i].id),
                ),
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
