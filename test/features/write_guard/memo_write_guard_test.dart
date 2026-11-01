import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, FlutterAuthClientOptions, EmptyLocalStorage;
import 'package:whatif_milkyway_app/features/books/presentation/providers/user_books_provider.dart';
import 'package:whatif_milkyway_app/features/home/domain/models/book.dart';
import 'package:whatif_milkyway_app/features/memos/data/repositories/memo_repository.dart'
    as repo_lib show MemoRepository, memoRepositoryProvider;
import 'package:whatif_milkyway_app/features/memos/domain/models/memo.dart';
import 'package:whatif_milkyway_app/features/memos/domain/models/memo_visibility.dart';
import 'package:whatif_milkyway_app/features/memos/presentation/providers/memo_provider.dart'
    as memo_prov;
import 'package:whatif_milkyway_app/features/memos/presentation/screens/memo_create_screen.dart';
import 'package:whatif_milkyway_app/features/memos/presentation/screens/memo_edit_screen.dart';
import 'package:whatif_milkyway_app/features/reading/data/repositories/reading_repository.dart';
import 'package:whatif_milkyway_app/features/reading/presentation/providers/reading_providers.dart';
import 'package:whatif_milkyway_app/l10n/app_localizations.dart';

/// G6/G8: 메모 저장 실패를 성공으로 읽지 않는다 + 삭제 연타는 서버로 1번.
class _FakeRepo extends Fake implements repo_lib.MemoRepository {
  bool failWrites = false;
  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  Completer<void>? deleteGate;

  @override
  Future<void> createMemo({
    required String bookId,
    required String content,
    int? page,
    String? imageUrl,
    MemoVisibility visibility = MemoVisibility.private,
    String? lyraQuestionId,
    String? lyraQuestionText,
    String? lyraSource,
  }) async {
    createCalls++;
    if (failWrites) throw Exception('network down');
  }

  @override
  Future<void> updateMemo({
    required String memoId,
    required String content,
    int? page,
    String? imageUrl,
    MemoVisibility? visibility,
  }) async {
    updateCalls++;
    if (failWrites) throw Exception('network down');
  }

  @override
  Future<void> deleteMemo(String memoId) async {
    deleteCalls++;
    await deleteGate?.future;
  }
}

class _FakeReading extends Fake implements ReadingRepository {
  @override
  Future<void> logToday(String bookId) async {}
}

Memo _memo() => Memo(
      id: 'm1',
      userId: 'u1',
      bookId: 'b1',
      content: '원래 본문',
      createdAt: DateTime(2026, 11, 1),
      visibility: MemoVisibility.private,
      bookTitle: '책',
      books: const {'title': '책'},
    );

({Widget app, GoRouter router}) _app(_FakeRepo repo) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
          path: '/home',
          name: 'home',
          builder: (_, __) => const Scaffold(body: Text('HOME'))),
      GoRoute(
          path: '/create',
          builder: (_, __) => const MemoCreateScreen(bookId: 'b1')),
      GoRoute(
          path: '/edit', builder: (_, __) => const MemoEditScreen(memoId: 'm1')),
    ],
  );
  addTearDown(router.dispose);
  final app = ProviderScope(
    overrides: [
      // 코드베이스에 같은 이름의 provider 가 따로 있어 둘 다 덮는다
      repo_lib.memoRepositoryProvider.overrideWithValue(repo),
      memo_prov.memoRepositoryProvider.overrideWithValue(repo),
      readingRepositoryProvider.overrideWithValue(_FakeReading()),
      userBooksProvider.overrideWith((ref) async => <Book>[]),
      memo_prov.memoProvider.overrideWith((ref, id) async => _memo()),
    ],
    child: MaterialApp.router(
      locale: const Locale('ko'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      routerConfig: router,
    ),
  );
  return (app: app, router: router);
}

/// 홈 위에 대상 화면을 push 해서 pop 여부를 관찰한다.
Future<void> _open(WidgetTester tester, _FakeRepo repo, String route) async {
  final h = _app(repo);
  await tester.pumpWidget(h.app);
  await tester.pump();
  h.router.push(route);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

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

  testWidgets('작성 실패 -> 저장 토스트와 pop 없음, 입력 유지', (tester) async {
    final repo = _FakeRepo()..failWrites = true;
    await _open(tester, repo, '/create');
    await tester.enterText(find.byType(TextField).first, '남긴 생각');
    await tester.pump();
    await tester.tap(find.text(l.commonSave));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repo.createCalls, 1);
    expect(find.text(l.memoSaved), findsNothing);
    expect(find.byType(MemoCreateScreen), findsOneWidget);
    expect(find.text('남긴 생각'), findsOneWidget);
  });

  testWidgets('작성 성공 -> 저장 토스트 + pop (기존 동작)', (tester) async {
    final repo = _FakeRepo();
    await _open(tester, repo, '/create');
    await tester.enterText(find.byType(TextField).first, '남긴 생각');
    await tester.pump();
    await tester.tap(find.text(l.commonSave));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repo.createCalls, 1);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(l.memoSaved), findsOneWidget);
    expect(find.byType(MemoCreateScreen), findsNothing);
  });

  testWidgets('수정 실패 -> 수정 토스트와 pop 없음, 입력 유지', (tester) async {
    final repo = _FakeRepo()..failWrites = true;
    await _open(tester, repo, '/edit');
    await tester.enterText(find.byType(TextField).first, '고친 생각');
    await tester.pump();
    await tester.tap(find.text(l.commonSave));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repo.updateCalls, 1);
    expect(find.text(l.memoUpdated), findsNothing);
    expect(find.byType(MemoEditScreen), findsOneWidget);
    expect(find.text('고친 생각'), findsOneWidget);
  });

  testWidgets('수정 성공 -> 수정 토스트 + pop (기존 동작)', (tester) async {
    final repo = _FakeRepo();
    await _open(tester, repo, '/edit');
    await tester.enterText(find.byType(TextField).first, '고친 생각');
    await tester.pump();
    await tester.tap(find.text(l.commonSave));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repo.updateCalls, 1);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(l.memoUpdated), findsOneWidget);
    expect(find.byType(MemoEditScreen), findsNothing);
  });

  testWidgets('수정 화면 삭제 연타 -> repository.deleteMemo 1번', (tester) async {
    final repo = _FakeRepo()..deleteGate = Completer<void>();
    await _open(tester, repo, '/edit');

    // 앱바 삭제 -> 확인 팝업 -> 확인. 요청이 끝나기 전에 3번 반복한다.
    var dialogsShown = 0;
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text(l.memoDelete).first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
      final confirm = find.descendant(
          of: find.byType(AlertDialog), matching: find.text(l.memoDelete));
      if (confirm.evaluate().isNotEmpty) {
        dialogsShown++;
        await tester.tap(confirm);
        await tester.pump(const Duration(milliseconds: 300));
      }
    }
    // 진행 중에는 삭제 버튼이 잠겨 확인 팝업이 다시 뜨지 않는다
    expect(dialogsShown, 1);
    expect(repo.deleteCalls, 1);

    repo.deleteGate!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(repo.deleteCalls, 1);
  });
}
