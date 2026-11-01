import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase, FlutterAuthClientOptions, EmptyLocalStorage;
import 'package:whatif_milkyway_app/core/providers/seen_tracker_provider.dart';
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

class _Harness {
  _Harness(this.repo, {Memo? initialMemo})
      : inset = ValueNotifier(0.0),
        _initialMemo = initialMemo;
  final _FakeRepo repo;
  final ValueNotifier<double> inset;
  final Memo? _initialMemo;
  late final GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
          path: '/home',
          name: 'home',
          builder: (_, __) => const Scaffold(body: Text('HOME'))),
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
}
