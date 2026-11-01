import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whatif_milkyway_app/core/network/edge_function_client.dart';
import 'package:whatif_milkyway_app/features/memos/data/repositories/memo_repository.dart';
import 'package:whatif_milkyway_app/features/memos/domain/memo_exceptions.dart';

/// get-memo-by-id 응답 계약 시험.
/// 200 memo / 200 restricted / 404 -> 각각 Memo / MemoRestrictedException / MemoNotFoundException,
/// 429 / 500 / 네트워크 오류 -> 일반 예외(삭제됨으로 오인 금지).
class _FakeFunctions extends Fake implements FunctionsClient {
  _FakeFunctions(this._respond);
  final FunctionResponse Function() _respond;
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
  }) async {
    calls++;
    return _respond();
  }
}

class _NoClient extends Fake implements SupabaseClient {}

const _memoJson = {
  'id': 'm1',
  'user_id': 'u1',
  'book_id': 'b1',
  'content': '본문',
  'created_at': '2026-11-01T00:00:00Z',
  'visibility': 'private',
  'books': {'title': '책'},
};

MemoRepository _repo(FunctionResponse Function() respond) => MemoRepository(
      _NoClient(),
      edge: EdgeFunctionClient(
        _FakeFunctions(respond),
        sleep: (_) async {}, // 재시도 대기를 건너뛴다
        attemptTimeout: const Duration(milliseconds: 50),
      ),
    );

FunctionResponse _throwing(int status, [dynamic details]) =>
    throw FunctionException(status: status, details: details);

void main() {
  test('200 memo -> Memo', () async {
    final memo = await _repo(() =>
        FunctionResponse(data: {'memo': _memoJson}, status: 200)).getMemoById('m1');
    expect(memo.id, 'm1');
  });

  test('200 restricted -> MemoRestrictedException(bookId)', () async {
    final f = _repo(() => FunctionResponse(
        data: {'restricted': true, 'book_id': 'b9'}, status: 200));
    await expectLater(
      f.getMemoById('m1'),
      throwsA(isA<MemoRestrictedException>()
          .having((e) => e.bookId, 'bookId', 'b9')),
    );
  });

  test('404 -> MemoNotFoundException', () async {
    final f = _repo(() => _throwing(404, {'error': '메모를 찾을 수 없습니다.'}));
    await expectLater(f.getMemoById('m1'), throwsA(isA<MemoNotFoundException>()));
  });

  test('429 -> 일반 예외 (NotFound/Restricted 아님)', () async {
    final f = _repo(() => _throwing(429, 'Too Many Requests'));
    await expectLater(
      f.getMemoById('m1'),
      throwsA(allOf(
        isA<Exception>(),
        isNot(isA<MemoNotFoundException>()),
        isNot(isA<MemoRestrictedException>()),
      )),
    );
  });

  test('500 -> 일반 예외 (NotFound/Restricted 아님)', () async {
    final f = _repo(() => _throwing(500, {'error': 'boom'}));
    await expectLater(
      f.getMemoById('m1'),
      throwsA(allOf(
        isA<Exception>(),
        isNot(isA<MemoNotFoundException>()),
        isNot(isA<MemoRestrictedException>()),
      )),
    );
  });

  test('2xx 가 아닌 status 가 응답으로 와도 404 만 NotFound', () async {
    final notFound =
        _repo(() => FunctionResponse(data: null, status: 404));
    await expectLater(
        notFound.getMemoById('m1'), throwsA(isA<MemoNotFoundException>()));
    final tooMany = _repo(() => FunctionResponse(data: null, status: 429));
    await expectLater(
        tooMany.getMemoById('m1'),
        throwsA(allOf(isA<Exception>(), isNot(isA<MemoNotFoundException>()))));
  });

  // G1: 404 / restricted 말고는 어떤 예외도 NotFound 가 되면 안 된다.
  final notNotFound = throwsA(allOf(
    isNot(isA<MemoNotFoundException>()),
    isNot(isA<MemoRestrictedException>()),
  ));

  test('546 -> NotFound 아님', () async {
    await expectLater(
        _repo(() => _throwing(546)).getMemoById('m1'), notNotFound);
  });

  test('SocketException -> NotFound 아님', () async {
    await expectLater(
        _repo(() => throw const SocketException('offline')).getMemoById('m1'),
        notNotFound);
  });

  test('TimeoutException -> NotFound 아님', () async {
    await expectLater(
        _repo(() => throw TimeoutException('slow')).getMemoById('m1'),
        notNotFound);
  });

  test('응답 형식 오류(Map 아님) -> NotFound 아님', () async {
    await expectLater(
        _repo(() => FunctionResponse(data: 'html', status: 200))
            .getMemoById('m1'),
        notNotFound);
  });

  test('429 두 번 뒤 200 -> 메모를 받는다', () async {
    var n = 0;
    final memo = await _repo(() {
      n++;
      if (n < 3) return _throwing(429);
      return FunctionResponse(data: {'memo': _memoJson}, status: 200);
    }).getMemoById('m1');
    expect(memo.id, 'm1');
    expect(n, 3);
  });
}
