import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whatif_milkyway_app/core/network/edge_function_client.dart';
import 'package:whatif_milkyway_app/features/memos/data/repositories/memo_repository.dart'
    show MemoRepository;
import 'package:whatif_milkyway_app/features/memos/domain/models/memo.dart';
import 'package:whatif_milkyway_app/features/memos/presentation/providers/memo_provider.dart';
import 'package:whatif_milkyway_app/features/memos/presentation/screens/memo_list_screen.dart';
import 'package:whatif_milkyway_app/l10n/app_localizations.dart';

/// 오류를 빈 목록으로 삼키면 "아직 공개된 메모가 없어요" 라는 거짓 빈 상태가 뜬다.
/// 오류는 오류 문구 + 다시 시도로 보여야 한다.
class _FakeFunctions extends Fake implements FunctionsClient {
  _FakeFunctions(this.respond);
  Future<FunctionResponse> Function() respond;
  int calls = 0;

  @override
  Future<FunctionResponse> invoke(
    String functionName, {
    Map<String, String>? headers,
    Object? body,
    Iterable<MultipartFile>? files,
    Map<String, dynamic>? queryParameters,
    HttpMethod method = HttpMethod.post,
    String? region,
  }) {
    calls++;
    return respond();
  }
}

class _NoClient extends Fake implements SupabaseClient {}

MemoRepository _repo(_FakeFunctions f) => MemoRepository(
  _NoClient(),
  edge: EdgeFunctionClient(f, sleep: (_) async {}),
);

/// 화면용: 내 메모는 비어 있고(getPaginatedMemos), 공개 피드는 진짜 repository 경로.
class _ScreenRepo extends Fake implements MemoRepository {
  _ScreenRepo(this._public);
  final MemoRepository _public;

  @override
  Future<List<Memo>> getPaginatedMemos({
    required int limit,
    required int offset,
    String? bookId,
  }) async => [];

  @override
  Future<List<Memo>> getPublicFeed({
    int limit = 20,
    int offset = 0,
    bool excludeSelf = false,
  }) => _public.getPublicFeed(
    limit: limit,
    offset: offset,
    excludeSelf: excludeSelf,
  );
}

Future<void> _openPublicTab(WidgetTester tester, _FakeFunctions f) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        memoRepositoryProvider.overrideWithValue(_ScreenRepo(_repo(f))),
      ],
      child: MaterialApp.router(
        locale: const Locale('ko'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        routerConfig: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, __) => const MemoListScreen()),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.text('공개').first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('repository', () {
    test('getPublicFeed: 500 이 끝내 계속되면 던진다([] 아님)', () async {
      final f = _FakeFunctions(
        () async => throw const FunctionException(status: 500),
      );
      await expectLater(
        _repo(f).getPublicFeed(),
        throwsA(isA<FunctionException>()),
      );
    });

    test('getPublicFeed: 네트워크 오류도 던진다', () async {
      final f = _FakeFunctions(() async => throw const SocketException('x'));
      await expectLater(
        _repo(f).getPublicFeed(),
        throwsA(isA<SocketException>()),
      );
    });

    test('getPublicFeed: 200 인데 memos 가 null 이면 []', () async {
      final f = _FakeFunctions(
        () async =>
            const FunctionResponse(data: <String, dynamic>{}, status: 200),
      );
      expect(await _repo(f).getPublicFeed(), isEmpty);
    });

    test('getPublicBookMemos: 오류는 던지고, memos null 은 []', () async {
      final bad = _FakeFunctions(
        () async => throw const FunctionException(status: 503),
      );
      await expectLater(
        _repo(bad).getPublicBookMemos('b1'),
        throwsA(isA<FunctionException>()),
      );
      final empty = _FakeFunctions(
        () async =>
            const FunctionResponse(data: <String, dynamic>{}, status: 200),
      );
      expect(await _repo(empty).getPublicBookMemos('b1'), isEmpty);
    });

    test('getPaginatedPublicBookMemos: 오류는 던진다', () async {
      final bad = _FakeFunctions(
        () async => throw const FunctionException(status: 500),
      );
      await expectLater(
        _repo(
          bad,
        ).getPaginatedPublicBookMemos(bookId: 'b-err', limit: 10, offset: 10),
        throwsA(isA<FunctionException>()),
      );
    });
  });

  group('메모 탭 공개 세그먼트', () {
    testWidgets('피드 오류 -> 오류 문구 + 다시 시도, 빈 상태 문구는 없다', (tester) async {
      final f = _FakeFunctions(
        () async => throw const FunctionException(status: 500),
      );
      await _openPublicTab(tester, f);
      expect(find.text('피드를 불러오지 못했어요'), findsOneWidget);
      expect(find.text('아직 공개된 메모가 없어요'), findsNothing);
      expect(find.text('다시 시도'), findsOneWidget);
    });

    testWidgets('다시 시도 -> 다시 불러와 성공하면 빈 상태가 정직하게 뜬다', (tester) async {
      var fail = true;
      final f = _FakeFunctions(() async {
        if (fail) throw const FunctionException(status: 500);
        return const FunctionResponse(
          data: <String, dynamic>{'memos': <dynamic>[]},
          status: 200,
        );
      });
      await _openPublicTab(tester, f);
      expect(find.text('피드를 불러오지 못했어요'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('다시 시도'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('피드를 불러오지 못했어요'), findsNothing);
      expect(find.text('아직 공개된 메모가 없어요'), findsOneWidget);
    });
  });
}
