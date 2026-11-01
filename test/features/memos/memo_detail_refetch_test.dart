import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show
        Supabase,
        FlutterAuthClientOptions,
        EmptyLocalStorage,
        FunctionsClient,
        FunctionResponse,
        FunctionException,
        MultipartFile,
        HttpMethod,
        SupabaseClient;
import 'package:whatif_milkyway_app/core/network/edge_function_client.dart';
import 'package:whatif_milkyway_app/core/providers/seen_tracker_provider.dart';
import 'package:whatif_milkyway_app/features/home/data/repositories/book_repository.dart'
    show BookRepository;
import 'package:whatif_milkyway_app/features/home/presentation/providers/book_provider.dart'
    show bookRepositoryProvider;
import 'package:whatif_milkyway_app/features/comments/domain/models/comment.dart';
import 'package:whatif_milkyway_app/features/comments/presentation/providers/comment_providers.dart';
import 'package:whatif_milkyway_app/features/memos/data/repositories/memo_repository.dart'
    show MemoRepository;
import 'package:whatif_milkyway_app/features/memos/domain/memo_exceptions.dart';
import 'package:whatif_milkyway_app/features/memos/domain/models/memo.dart';
import 'package:whatif_milkyway_app/features/memos/domain/models/memo_visibility.dart';
import 'package:whatif_milkyway_app/features/memos/presentation/providers/memo_provider.dart';
import 'package:whatif_milkyway_app/features/memos/presentation/screens/memo_detail_screen.dart';
import 'package:whatif_milkyway_app/l10n/app_localizations.dart';

/// 운영 장애(2026-11-01): 키보드(MediaQuery viewInsets) 프레임마다 get-memo-by-id 를 다시 불러
/// 서버가 429 를 줬고, provider 가 오류를 null 로 삼켜 화면이 홈으로 튕겼다.
class _FakeRepo extends Fake implements MemoRepository {
  _FakeRepo(this._result);
  Future<Memo> Function() _result;
  int calls = 0;

  @override
  Future<Memo> getMemoById(String memoId) {
    calls++;
    return _result();
  }
}

Memo _memo() => Memo(
      id: 'm1',
      userId: 'u1',
      bookId: 'b1',
      content: '초기 본문',
      createdAt: DateTime(2026, 11, 1),
      visibility: MemoVisibility.private,
      bookTitle: '책',
      books: const {'title': '책'},
    );

class _FakeSeen extends SeenController {
  @override
  Future<void> markMemoViewed(String memoId) async {}
}

class _FakeBookRepo extends Fake implements BookRepository {
  _FakeBookRepo(this._connection);
  Future<bool> Function() _connection;
  int connectionCalls = 0;

  @override
  String getCurrentUserId() => 'u-me';

  @override
  Future<bool> hasUserBookConnection(String bookId, String userId) {
    connectionCalls++;
    return _connection();
  }
}

class _PopCounter extends NavigatorObserver {
  int pops = 0;
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pops++;
  }
}

class _Harness {
  _Harness(this.repo, {Memo? initialMemo, _FakeBookRepo? bookRepo})
      : inset = ValueNotifier(0.0),
        _initialMemo = initialMemo,
        bookRepo = bookRepo ?? _FakeBookRepo(() async => false);
  final _FakeRepo repo;
  final _FakeBookRepo bookRepo;
  final _PopCounter pops = _PopCounter();
  final ValueNotifier<double> inset;
  final Memo? _initialMemo;
  late final GoRouter router = GoRouter(
    initialLocation: '/home',
    observers: [pops],
    routes: [
      GoRoute(
          path: '/home',
          name: 'home',
          builder: (_, __) => const Scaffold(body: Text('HOME'))),
      GoRoute(
          path: '/book/:id',
          name: 'book-detail',
          builder: (_, __) => const Scaffold(body: Text('BOOK'))),
      GoRoute(
        path: '/detail',
        builder: (_, __) =>
            MemoDetailScreen(memoId: 'm1', initialMemo: _initialMemo),
      ),
    ],
  );

  Widget build() => ProviderScope(
        overrides: [
          memoRepositoryProvider.overrideWithValue(repo),
          bookRepositoryProvider.overrideWithValue(bookRepo),
          seenControllerProvider.overrideWith(_FakeSeen.new),
          commentsProvider.overrideWith((ref, id) async => <Comment>[]),
          isBookSavedProvider.overrideWith((ref, id) async => false),
        ],
        child: MaterialApp.router(
          locale: const Locale('ko'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          routerConfig: router,
          builder: (context, child) => ValueListenableBuilder<double>(
            valueListenable: inset,
            builder: (context, v, _) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(viewInsets: EdgeInsets.only(bottom: v)),
              child: child!,
            ),
          ),
        ),
      );
}

Future<void> _open(WidgetTester tester, _Harness h) async {
  await tester.pumpWidget(h.build());
  await tester.pump();
  h.router.push('/detail');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    // Auth notifier 가 Supabase.instance 를 잡으므로 더미로 초기화(네트워크 호출 없음).
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'anon',
      authOptions: FlutterAuthClientOptions(
        localStorage: const EmptyLocalStorage(),
        autoRefreshToken: false,
      ),
    );
  });

  testWidgets('키보드 viewInsets 를 30번 바꿔도 getMemoById 는 1번', (tester) async {
    final h = _Harness(_FakeRepo(() async => _memo()));
    await _open(tester, h);
    for (var i = 0; i < 30; i++) {
      h.inset.value = i.isEven ? 300 : 0;
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 100));
    expect(h.repo.calls, 1);
    expect(find.text('초기 본문'), findsWidgets);
  });

  testWidgets('429 류 오류여도 pop 하지 않고 initialMemo 를 계속 보인다', (tester) async {
    final h = _Harness(
      _FakeRepo(() async => throw Exception('메모 조회 실패(429)')),
      initialMemo: _memo(),
    );
    await _open(tester, h);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(MemoDetailScreen), findsOneWidget);
    expect(find.text('초기 본문'), findsWidgets);
  });

  testWidgets('MemoNotFoundException 이면 pop', (tester) async {
    final h = _Harness(
      _FakeRepo(() async => throw const MemoNotFoundException()),
    );
    await _open(tester, h);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(MemoDetailScreen), findsNothing);
  });

  testWidgets('오류 뒤 화면을 다시 열면 다시 부른다(영구 null/오류 없음)', (tester) async {
    final repo = _FakeRepo(() async => throw Exception('메모 조회 실패(500)'));
    final h = _Harness(repo);
    await _open(tester, h);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(MemoDetailScreen), findsOneWidget);
    expect(repo.calls, 1);

    h.router.pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(MemoDetailScreen), findsNothing);

    repo._result = () async => _memo();
    h.router.push('/detail');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(repo.calls, 2);
    expect(find.text('초기 본문'), findsWidgets);
  });

  // G1: 서버가 404/restricted 라고 말한 것이 아니면 어떤 예외에서도 닫히지 않는다.
  final errors = <String, Object>{
    '429': const FunctionException(status: 429),
    '500': const FunctionException(status: 500),
    '546': const FunctionException(status: 546),
    'SocketException': const SocketException('offline'),
    'TimeoutException': TimeoutException('slow'),
    '형식 오류': const FormatException('bad json'),
    '일반 Exception': Exception('boom'),
  };
  for (final entry in errors.entries) {
    testWidgets('G1 ${entry.key} 계속 -> 안 닫히고 initialMemo 를 보인다', (tester) async {
      final h = _Harness(
        _FakeRepo(() async => throw entry.value),
        initialMemo: _memo(),
      );
      await _open(tester, h);
      for (var i = 0; i < 10; i++) {
        h.inset.value = i.isEven ? 300 : 0;
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(MemoDetailScreen), findsOneWidget);
      expect(find.text('초기 본문'), findsWidgets);
      expect(h.pops.pops, 0);
    });
  }

  testWidgets('G1 오류만 있고 넘어온 메모도 없으면 오류 화면 + 다시 시도(닫히지 않음)',
      (tester) async {
    final h = _Harness(_FakeRepo(() async => throw const SocketException('x')));
    await _open(tester, h);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(MemoDetailScreen), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
    expect(h.pops.pops, 0);
  });

  testWidgets('429 한 번 뒤 200 -> 실제 repository + 재시도 클라이언트로 메모가 보인다',
      (tester) async {
    final fake = _FakeFunctions();
    var n = 0;
    fake.respond = () async {
      n++;
      if (n == 1) throw const FunctionException(status: 429);
      return FunctionResponse(data: {
        'memo': {
          'id': 'm1',
          'user_id': 'u1',
          'book_id': 'b1',
          'content': '서버 본문',
          'created_at': '2026-11-01T00:00:00Z',
          'visibility': 'private',
          'books': {'title': '책'},
        }
      }, status: 200);
    };
    final real = MemoRepository(
      _NoClient(),
      edge: EdgeFunctionClient(fake, sleep: (_) async {}),
    );
    final h = _Harness(_FakeRepo(() => real.getMemoById('m1')));
    await _open(tester, h);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('서버 본문'), findsWidgets);
    expect(n, 2);
  });

  testWidgets('404 -> 닫힘 1번만(리빌드가 여러 번이어도)', (tester) async {
    final h = _Harness(
      _FakeRepo(() async => throw const MemoNotFoundException()),
    );
    await _open(tester, h);
    for (var i = 0; i < 10; i++) {
      h.inset.value = i.isEven ? 300 : 0;
      await tester.pump();
    }
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(MemoDetailScreen), findsNothing);
    expect(h.pops.pops, 1);
  });

  testWidgets('restricted + 리빌드 여러 번 -> _routeRestricted 는 1번', (tester) async {
    final gate = Completer<bool>();
    final book = _FakeBookRepo(() => gate.future);
    final h = _Harness(
      _FakeRepo(() async => throw MemoRestrictedException('b1')),
      bookRepo: book,
    );
    await _open(tester, h);
    for (var i = 0; i < 20; i++) {
      h.inset.value = i.isEven ? 300 : 0;
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(book.connectionCalls, 1);
    gate.complete(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(book.connectionCalls, 1);
    expect(find.text('BOOK'), findsOneWidget);
  });

  testWidgets('restricted + 책 저장 여부 조회 오류 -> 담기 팝업 없음, 닫히지 않고 다시 시도',
      (tester) async {
    var fail = true;
    final book = _FakeBookRepo(() async {
      if (fail) throw const SocketException('offline');
      return true;
    });
    final h = _Harness(
      _FakeRepo(() async => throw MemoRestrictedException('b1')),
      bookRepo: book,
    );
    await _open(tester, h);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('책 담기'), findsNothing); // 팝업 제목
    expect(find.byType(MemoDetailScreen), findsOneWidget);
    expect(h.pops.pops, 0);
    expect(find.text('다시 시도'), findsOneWidget);
    expect(book.connectionCalls, 1);

    fail = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 500));
    expect(book.connectionCalls, 2);
    expect(find.text('BOOK'), findsOneWidget);
  });

  testWidgets('메모 안 책 행 탭 + 조회 오류 -> 담기 팝업 없음, 화면 유지', (tester) async {
    final book = _FakeBookRepo(() async => throw const SocketException('offline'));
    final h = _Harness(
      _FakeRepo(() async => _memo()),
      initialMemo: _memo(),
      bookRepo: book,
    );
    await _open(tester, h);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('책').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(book.connectionCalls, 1);
    expect(find.text('책 담기'), findsNothing);
    expect(find.byType(MemoDetailScreen), findsOneWidget);
    expect(h.pops.pops, 0);
  });
}

class _NoClient extends Fake implements SupabaseClient {}

class _FakeFunctions extends Fake implements FunctionsClient {
  Future<FunctionResponse> Function() respond =
      () async => FunctionResponse(data: null, status: 200);

  @override
  Future<FunctionResponse> invoke(
    String functionName, {
    Map<String, String>? headers,
    Object? body,
    Iterable<MultipartFile>? files,
    Map<String, dynamic>? queryParameters,
    HttpMethod method = HttpMethod.post,
    String? region,
  }) =>
      respond();
}
