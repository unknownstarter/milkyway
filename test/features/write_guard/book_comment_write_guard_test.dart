import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, FlutterAuthClientOptions, EmptyLocalStorage;
import 'package:whatif_milkyway_app/core/providers/seen_tracker_provider.dart';
import 'package:whatif_milkyway_app/core/router/app_routes.dart';
import 'package:whatif_milkyway_app/core/presentation/widgets/pill_filter_button.dart';
import 'package:whatif_milkyway_app/features/books/data/services/naver_book_service.dart';
import 'package:whatif_milkyway_app/features/books/domain/models/naver_book.dart';
import 'package:whatif_milkyway_app/features/books/presentation/providers/book_search_provider.dart';
import 'package:whatif_milkyway_app/features/books/presentation/screens/book_detail_screen.dart';
import 'package:whatif_milkyway_app/features/books/presentation/screens/book_search_screen.dart';
import 'package:whatif_milkyway_app/features/comments/data/repositories/comment_repository.dart';
import 'package:whatif_milkyway_app/features/comments/domain/models/comment.dart';
import 'package:whatif_milkyway_app/features/comments/presentation/providers/comment_providers.dart';
import 'package:whatif_milkyway_app/features/comments/presentation/widgets/comment_section.dart';
import 'package:whatif_milkyway_app/features/home/data/repositories/book_repository.dart';
import 'package:whatif_milkyway_app/features/home/domain/models/book.dart';
import 'package:whatif_milkyway_app/features/home/domain/models/book_status.dart';
import 'package:whatif_milkyway_app/features/home/presentation/providers/book_provider.dart';
import 'package:whatif_milkyway_app/features/lyra/data/models/book_question.dart';
import 'package:whatif_milkyway_app/features/lyra/presentation/providers/lyra_providers.dart';
import 'package:whatif_milkyway_app/features/memos/domain/models/memo.dart';
import 'package:whatif_milkyway_app/features/memos/presentation/providers/memo_provider.dart'
    as memo_prov;
import 'package:whatif_milkyway_app/features/reading/presentation/providers/reading_providers.dart';
import 'package:whatif_milkyway_app/l10n/app_localizations.dart';

/// G6/G8: 책 등록 실패를 성공으로 읽지 않는다, 책 상태 변경 실패는 되돌린다,
/// 댓글/책 담기 쓰기는 진행 중 다시 눌려도 서버로 1번만 간다.
Book _book({BookStatus status = BookStatus.wantToRead}) => Book(
      id: 'b1',
      title: '테스트 책',
      author: '저자',
      status: status,
      createdAt: DateTime(2026, 11, 1),
      updatedAt: DateTime(2026, 11, 1),
      isbn: '123',
    );

class _FakeBookRepo extends Fake implements BookRepository {
  bool owned = false;
  bool failConnect = false;
  bool failStatus = false;
  Completer<void>? connectGate;
  Completer<void>? statusGate;
  int connectCalls = 0;
  int statusCalls = 0;
  BookStatus status = BookStatus.wantToRead;

  @override
  String getCurrentUserId() => 'u1';

  @override
  Future<Book?> findBookByIsbn(String isbn) async => _book();

  @override
  Future<bool> hasUserBookConnection(String bookId, String userId) async =>
      owned;

  @override
  Future<void> createUserBookConnection(String bookId, String userId) async {
    connectCalls++;
    await connectGate?.future;
    if (failConnect) throw Exception('network down');
  }

  // 검색 시험에서는 등록 직후 invalidate 로 만들어졌다 곧바로 폐기되는
  // BookDetailController 의 로딩이 시험 종료 뒤 상태를 건드리지 않게 멈춰 둔다
  bool hangDetail = false;

  @override
  Future<Book> getBookDetail(String bookId) async {
    if (hangDetail) await Completer<void>().future;
    return _book(status: status);
  }

  @override
  Future<void> updateBookStatus(String bookId, BookStatus s) async {
    statusCalls++;
    await statusGate?.future;
    if (failStatus) throw Exception('network down');
    status = s;
  }
}

class _FakeNaverService extends NaverBookService {}

class _FixedSearch extends BookSearchNotifier {
  _FixedSearch() : super(service: _FakeNaverService()) {
    state = AsyncValue.data([
      NaverBook(
        title: '검색된 책',
        author: '저자',
        isbn: '123',
        coverUrl: '',
        description: '',
        publisher: '',
        pubdate: '',
      ),
    ]);
  }
}

class _FakeSeen extends SeenController {
  @override
  Future<void> markBookViewed(String bookId) async {}
}

class _FakeComments extends Fake implements CommentRepository {
  int hideCalls = 0;
  Completer<void>? hideGate;

  @override
  Future<void> hideComment(String commentId) async {
    hideCalls++;
    await hideGate?.future;
  }
}

Comment _comment() => Comment.fromJson({
      'id': 'c1',
      'memo_id': 'm1',
      'user_id': 'other',
      'content': '남의 댓글',
      'created_at': '2026-08-22T00:00:00.000Z',
      'updated_at': '2026-08-22T00:00:00.000Z',
      'users': {'nickname': '다른 별', 'picture_url': null},
    });

Widget _wrap(List<Override> overrides, GoRouter router) => ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        locale: const Locale('ko'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        routerConfig: router,
      ),
    );

GoRouter _router(Widget screen) {
  final r = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
          path: '/home',
          name: 'home',
          builder: (_, __) => const Scaffold(body: Text('HOME'))),
      GoRoute(path: '/screen', builder: (_, __) => screen),
      GoRoute(
        path: '/detail/:id',
        name: AppRoutes.bookDetailName,
        builder: (_, __) => const Scaffold(body: Text('BOOK_DETAIL')),
      ),
    ],
  );
  addTearDown(r.dispose);
  return r;
}

Future<void> _push(WidgetTester tester, Widget app, GoRouter router) async {
  await tester.pumpWidget(app);
  await tester.pump();
  router.push('/screen');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

bool _pillActive(WidgetTester tester, String label) => tester
    .widget<PillFilterButton>(find.widgetWithText(PillFilterButton, label))
    .isActive;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      publishableKey: 'anon',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        autoRefreshToken: false,
      ),
    );
  });

  final l = lookupAppL10n(const Locale('ko'));

  group('책 검색 - 등록', () {
    Future<_FakeBookRepo> open(WidgetTester tester,
        {bool fail = false, Completer<void>? gate}) async {
      // 결과 카드의 ListTile 배경 경고(기존 화면의 시각 경고)만 무시한다
      final prev = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.exceptionAsString().contains('ListTile background color')) return;
        prev?.call(d);
      };
      addTearDown(() => FlutterError.onError = prev);
      final repo = _FakeBookRepo()
        ..failConnect = fail
        ..hangDetail = true
        ..connectGate = gate;
      final router = _router(const BookSearchScreen());
      await _push(
        tester,
        _wrap([
          bookRepositoryProvider.overrideWithValue(repo),
          searchBooksProvider.overrideWith((ref) => _FixedSearch()),
        ], router),
        router,
      );
      return repo;
    }

    testWidgets('connectExistingBook 실패 -> 추가됐어요 없음 + 이동 없음', (tester) async {
      final repo = await open(tester, fail: true);
      await tester.tap(find.text('검색된 책').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(repo.connectCalls, 1);
      expect(find.text(l.bookAdded), findsNothing);
      expect(find.text('BOOK_DETAIL'), findsNothing);
      expect(find.byType(BookSearchScreen), findsOneWidget);
    });

    testWidgets('성공이면 추가됐어요 + 책 상세로 이동 (기존 동작)', (tester) async {
      final repo = await open(tester);
      await tester.tap(find.text('검색된 책').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(repo.connectCalls, 1);
      expect(find.text('BOOK_DETAIL'), findsOneWidget);
    });

    testWidgets('진행 중 연타 -> createUserBookConnection 1번', (tester) async {
      final gate = Completer<void>();
      final repo = await open(tester, gate: gate);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('검색된 책').last);
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(repo.connectCalls, 1);
      gate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(repo.connectCalls, 1);
    });
  });

  group('책 상세 - 상태 변경', () {
    Future<_FakeBookRepo> open(WidgetTester tester,
        {bool fail = false, Completer<void>? gate}) async {
      final repo = _FakeBookRepo()
        ..failStatus = fail
        ..statusGate = gate;
      final router = _router(const BookDetailScreen(bookId: 'b1'));
      await _push(
        tester,
        _wrap([
          bookRepositoryProvider.overrideWithValue(repo),
          seenControllerProvider.overrideWith(_FakeSeen.new),
          readTodayProvider.overrideWith((ref, id) async => false),
          bookQuestionProvider.overrideWith((ref, id) async => null as BookQuestion?),
          memo_prov.publicBookMemosProvider
              .overrideWith((ref, id) async => <Memo>[]),
          memo_prov.bookMemosProvider.overrideWith((ref, id) async => <Memo>[]),
        ], router),
        router,
      );
      await tester.pump(const Duration(milliseconds: 200));
      return repo;
    }

    testWidgets('실패 -> 선택한 상태를 되돌린다', (tester) async {
      final repo = await open(tester, fail: true);
      expect(_pillActive(tester, l.bookStatusWantToRead), isTrue);

      await tester.tap(find.text(l.bookStatusReading));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(repo.statusCalls, 1);
      expect(_pillActive(tester, l.bookStatusWantToRead), isTrue);
      expect(_pillActive(tester, l.bookStatusReading), isFalse);
      expect(find.textContaining('상태로 바꿨어요'), findsNothing);
    });

    testWidgets('진행 중 연타 -> updateBookStatus 1번', (tester) async {
      final gate = Completer<void>();
      final repo = await open(tester, gate: gate);
      await tester.tap(find.text(l.bookStatusReading));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text(l.bookStatusCompleted));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text(l.bookStatusReading));
      await tester.pump(const Duration(milliseconds: 50));

      expect(repo.statusCalls, 1);
      // 진행 중에는 처음 고른 상태가 보인다
      expect(_pillActive(tester, l.bookStatusReading), isTrue);

      gate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(repo.statusCalls, 1);
      expect(_pillActive(tester, l.bookStatusReading), isTrue);
    });
  });

  group('댓글', () {
    Future<_FakeComments> open(
      WidgetTester tester, {
      required Future<bool> Function() saved,
      Completer<void>? hideGate,
    }) async {
      final repo = _FakeComments()..hideGate = hideGate;
      final router = _router(const Scaffold(
        body: CommentSection(
            memoId: 'm1', bookId: 'b1', header: SizedBox(height: 10)),
      ));
      await _push(
        tester,
        _wrap([
          bookRepositoryProvider.overrideWithValue(_FakeBookRepo()),
          commentRepositoryProvider.overrideWithValue(repo),
          commentsProvider.overrideWith((ref, id) async => [_comment()]),
          isBookSavedProvider.overrideWith((ref, id) => saved()),
        ], router),
        router,
      );
      await tester.pump(const Duration(milliseconds: 200));
      return repo;
    }

    testWidgets('숨기기 연타 -> hideComment 1번', (tester) async {
      final gate = Completer<void>();
      final repo = await open(tester, saved: () async => true, hideGate: gate);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byIcon(Icons.more_horiz).first);
        await tester.pump(); // 시트 애니메이션은 첫 프레임 뒤부터 흐른다
        await tester.pump(const Duration(milliseconds: 700));
        final hide = find.text(l.commentHide);
        if (hide.evaluate().isNotEmpty) {
          await tester.tap(hide);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 700));
        }
      }
      expect(repo.hideCalls, 1);
      gate.complete();
      await tester.pump(const Duration(milliseconds: 300));
      expect(repo.hideCalls, 1);
    });

    testWidgets('isBookSavedProvider 오류 -> 책 담기 팝업 안 뜸, 작성창 안 잠김',
        (tester) async {
      await open(tester, saved: () async => throw Exception('network down'));
      expect(find.text(l.commentComposerLocked), findsNothing);
      await tester.tap(find.byType(TextField), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(l.commentSaveBookTitle), findsNothing);
    });

    testWidgets('미저장(false)이면 잠그고 책 담기 팝업 (기존 동작)', (tester) async {
      await open(tester, saved: () async => false);
      expect(find.text(l.commentComposerLocked), findsOneWidget);
      await tester.tap(find.byType(TextField), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(l.commentSaveBookTitle), findsOneWidget);
    });
  });

  group('isCommentComposerUnlocked', () {
    test('저장됨 / 미저장 / 확인 중 / 확인 실패', () {
      expect(isCommentComposerUnlocked(const AsyncData(true)), isTrue);
      expect(isCommentComposerUnlocked(const AsyncData(false)), isFalse);
      expect(isCommentComposerUnlocked(const AsyncLoading<bool>()), isFalse);
      expect(
        isCommentComposerUnlocked(
            AsyncError<bool>(Exception('x'), StackTrace.empty)),
        isTrue,
      );
    });
  });
}
