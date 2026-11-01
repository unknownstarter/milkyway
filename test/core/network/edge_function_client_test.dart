import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whatif_milkyway_app/core/network/edge_function_client.dart';

/// 하위 FunctionsClient 가짜. 호출마다 [respond] 가 응답하거나 던진다.
class _FakeFunctions extends Fake implements FunctionsClient {
  _FakeFunctions(this.respond);
  Future<FunctionResponse> Function(
    String name,
    Map<String, dynamic>? body,
    int n,
  )
  respond;
  final List<(String, Map<String, dynamic>?)> calls = [];

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
    calls.add((functionName, body as Map<String, dynamic>?));
    return respond(functionName, body, calls.length);
  }
}

FunctionResponse _ok([Object? data]) =>
    FunctionResponse(data: data ?? {'ok': true}, status: 200);

/// 가상 시계. sleep 은 깨울 시각만 등록하고, [drive] 가 대기열이 빌 때마다 시계를 가장 이른
/// 깨움 시각으로 돌린다. 실제로 기다리지 않으면서 동시 대기자의 순서를 현실처럼 지킨다.
class _Clock {
  DateTime t = DateTime(2026, 11, 1, 12);
  final List<Duration> sleeps = [];
  final List<(DateTime, Completer<void>)> _pending = [];
  DateTime now() => t;
  Future<void> sleep(Duration d) {
    sleeps.add(d);
    final c = Completer<void>();
    _pending.add((t.add(d), c));
    return c.future;
  }

  Future<T> drive<T>(Future<T> f) async {
    var done = false;
    T? value;
    Object? error;
    StackTrace? st;
    f.then(
      (v) {
        done = true;
        value = v;
      },
      onError: (Object e, StackTrace s) {
        done = true;
        error = e;
        st = s;
      },
    );
    while (!done) {
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      if (done) break;
      if (_pending.isEmpty) continue;
      _pending.sort((a, b) => a.$1.compareTo(b.$1));
      final next = _pending.removeAt(0);
      if (next.$1.isAfter(t)) t = next.$1;
      next.$2.complete();
    }
    if (error != null) Error.throwWithStackTrace(error!, st!);
    return value as T;
  }
}

EdgeFunctionClient _client(
  _FakeFunctions f,
  _Clock c, {
  List<String>? throttled,
  Duration attemptTimeout = const Duration(seconds: 15),
}) => EdgeFunctionClient(
  f,
  sleep: c.sleep,
  now: c.now,
  attemptTimeout: attemptTimeout,
  onThrottled: throttled?.add,
);

void main() {
  test('G3 같은 함수 + 같은 body 동시 100번 -> 하위 1번', () async {
    final gate = Completer<FunctionResponse>();
    final f = _FakeFunctions((_, __, ___) => gate.future);
    final c = _client(f, _Clock());
    final futures = [
      for (var i = 0; i < 100; i++)
        c.invoke('get-memo-by-id', body: {'memo_id': 'm1', 'a': 1}),
    ];
    gate.complete(_ok());
    final results = await Future.wait(futures);
    expect(f.calls.length, 1);
    expect(results.every((r) => r.status == 200), isTrue);
  });

  test('G3 body 키 순서가 달라도 같은 키', () async {
    final gate = Completer<FunctionResponse>();
    final f = _FakeFunctions((_, __, ___) => gate.future);
    final c = _client(f, _Clock());
    final a = c.invoke('x', body: {'a': 1, 'b': 2});
    final b = c.invoke('x', body: {'b': 2, 'a': 1});
    gate.complete(_ok());
    await Future.wait([a, b]);
    expect(f.calls.length, 1);
  });

  test('G3 다른 body 는 각각 하위 호출', () async {
    final f = _FakeFunctions((_, __, ___) async => _ok());
    final c = _client(f, _Clock());
    await Future.wait([
      c.invoke('x', body: {'id': 1}),
      c.invoke('x', body: {'id': 2}),
      c.invoke('y', body: {'id': 1}),
    ]);
    expect(f.calls.length, 3);
  });

  test('G3 끝난 뒤에는 합치지 않는다(결과 캐시 없음)', () async {
    final f = _FakeFunctions((_, __, ___) async => _ok());
    final c = _client(f, _Clock());
    await c.invoke('x', body: {'id': 1});
    await c.invoke('x', body: {'id': 1});
    expect(f.calls.length, 2);
  });

  test('G3 실패한 호출도 끝나면 지워져 다음 호출은 새로 보낸다', () async {
    final f = _FakeFunctions(
      (_, __, n) async =>
          n == 1 ? throw const FunctionException(status: 404) : _ok(),
    );
    final c = _client(f, _Clock());
    await expectLater(
      c.invoke('x', body: {'id': 1}),
      throwsA(isA<FunctionException>()),
    );
    await Future<void>.delayed(Duration.zero);
    final r = await c.invoke('x', body: {'id': 1});
    expect(r.status, 200);
    expect(f.calls.length, 2);
  });

  test('G5 429, 429, 200 -> 성공, 하위 3번, 400ms/1200ms 대기', () async {
    final clock = _Clock();
    final f = _FakeFunctions(
      (_, __, n) async =>
          n < 3 ? throw const FunctionException(status: 429) : _ok(),
    );
    final r = await clock.drive(_client(f, clock).invoke('x'));
    expect(r.status, 200);
    expect(f.calls.length, 3);
    expect(clock.sleeps.length, 2);
    expect(clock.sleeps[0].inMilliseconds, inInclusiveRange(400, 600));
    expect(clock.sleeps[1].inMilliseconds, inInclusiveRange(1200, 1400));
  });

  test('G5 429 x3 -> FunctionException(429) 그대로, 하위 3번', () async {
    final f = _FakeFunctions(
      (_, __, ___) async => throw const FunctionException(status: 429),
    );
    final clock = _Clock();
    await expectLater(
      clock.drive(_client(f, clock).invoke('x')),
      throwsA(isA<FunctionException>().having((e) => e.status, 'status', 429)),
    );
    expect(f.calls.length, 3);
  });

  for (final status in [500, 502, 503, 504, 546]) {
    test('G5 $status 도 재시도한다', () async {
      final f = _FakeFunctions(
        (_, __, n) async =>
            n < 2 ? throw FunctionException(status: status) : _ok(),
      );
      final clock = _Clock();
      final r = await clock.drive(_client(f, clock).invoke('x'));
      expect(r.status, 200);
      expect(f.calls.length, 2);
    });
  }

  for (final status in [400, 401, 403, 404, 409]) {
    test('G5 $status 는 바로 던진다(1번만)', () async {
      final f = _FakeFunctions(
        (_, __, ___) async => throw FunctionException(status: status),
      );
      await expectLater(
        _client(f, _Clock()).invoke('x'),
        throwsA(
          isA<FunctionException>().having((e) => e.status, 'status', status),
        ),
      );
      expect(f.calls.length, 1);
    });
  }

  test('G5 SocketException 재시도', () async {
    final f = _FakeFunctions(
      (_, __, n) async =>
          n < 2 ? throw const SocketException('offline') : _ok(),
    );
    final clock = _Clock();
    final r = await clock.drive(_client(f, clock).invoke('x'));
    expect(r.status, 200);
    expect(f.calls.length, 2);
  });

  test('G5 http ClientException 재시도', () async {
    final f = _FakeFunctions(
      (_, __, n) async => n < 2 ? throw http.ClientException('reset') : _ok(),
    );
    final clock = _Clock();
    final r = await clock.drive(_client(f, clock).invoke('x'));
    expect(r.status, 200);
    expect(f.calls.length, 2);
  });

  test('G5 시도별 시간 초과 -> TimeoutException 재시도, 끝내 실패하면 그대로', () async {
    final f = _FakeFunctions(
      (_, __, ___) => Completer<FunctionResponse>().future,
    );
    final clock = _Clock();
    await expectLater(
      clock.drive(
        _client(
          f,
          clock,
          attemptTimeout: const Duration(milliseconds: 10),
        ).invoke('x'),
      ),
      throwsA(isA<TimeoutException>()),
    );
    expect(f.calls.length, 3);
  });

  test('G5 형식 오류(FormatException)는 재시도하지 않는다', () async {
    final f = _FakeFunctions(
      (_, __, ___) async => throw const FormatException('bad'),
    );
    await expectLater(
      _client(f, _Clock()).invoke('x'),
      throwsA(isA<FormatException>()),
    );
    expect(f.calls.length, 1);
  });

  test('G5 Retry-After 가 있으면 그 값을 쓴다', () async {
    final clock = _Clock();
    final f = _FakeFunctions(
      (_, __, n) async => n < 2
          ? throw const FunctionException(
              status: 429,
              details: {'retry_after': 3},
            )
          : _ok(),
    );
    await clock.drive(_client(f, clock).invoke('x'));
    expect(clock.sleeps, [const Duration(seconds: 3)]);
  });

  test('G5 Retry-After 는 최대 5초로 자른다', () async {
    final clock = _Clock();
    final f = _FakeFunctions(
      (_, __, n) async => n < 2
          ? throw const FunctionException(
              status: 429,
              details: {'retry_after': 60},
            )
          : _ok(),
    );
    await clock.drive(_client(f, clock).invoke('x'));
    expect(clock.sleeps, [const Duration(seconds: 5)]);
  });

  test('G4 서로 다른 body 20번 -> 첫 1초 안에 8번 이하, 결국 20번 모두 나간다', () async {
    final clock = _Clock();
    final start = clock.t;
    final sendTimes = <DateTime>[];
    final f = _FakeFunctions((_, __, ___) async {
      sendTimes.add(clock.t);
      return _ok();
    });
    final throttled = <String>[];
    final c = _client(f, clock, throttled: throttled);
    final results = await clock.drive(
      Future.wait([
        for (var i = 0; i < 20; i++) c.invoke('x', body: {'i': i}),
      ]),
    );
    expect(results.length, 20);
    expect(f.calls.length, 20);
    final firstSecond = sendTimes
        .where((t) => t.difference(start) < const Duration(seconds: 1))
        .length;
    expect(firstSecond, lessThanOrEqualTo(8));
    // 어느 1초 구간에도 8번을 넘지 않는다.
    for (final t in sendTimes) {
      final inWindow = sendTimes
          .where(
            (s) =>
                !s.isBefore(t) && s.difference(t) < const Duration(seconds: 1),
          )
          .length;
      expect(inWindow, lessThanOrEqualTo(8));
    }
  });

  test('G4 edge_throttled 는 함수별 1초에 1번만 알린다', () async {
    final clock = _Clock();
    final f = _FakeFunctions((_, __, ___) async => _ok());
    final throttled = <String>[];
    final c = _client(f, clock, throttled: throttled);
    await clock.drive(
      Future.wait([
        for (var i = 0; i < 20; i++) c.invoke('x', body: {'i': i}),
      ]),
    );
    // 20번 = 8 + 8 + 4 -> 약 2초에 걸쳐 나가므로 알림은 2번 안팎. 20번이 아니다.
    expect(throttled, isNotEmpty);
    expect(throttled.length, lessThanOrEqualTo(3));
    expect(throttled.toSet(), {'x'});
  });

  test('G4 한도 안이면 기다리지 않고 알리지도 않는다', () async {
    final clock = _Clock();
    final f = _FakeFunctions((_, __, ___) async => _ok());
    final throttled = <String>[];
    final c = _client(f, clock, throttled: throttled);
    await Future.wait([
      for (var i = 0; i < 8; i++) c.invoke('x', body: {'i': i}),
    ]);
    expect(clock.sleeps, isEmpty);
    expect(throttled, isEmpty);
  });

  test('G4 한도는 함수별이다', () async {
    final clock = _Clock();
    final f = _FakeFunctions((_, __, ___) async => _ok());
    final c = _client(f, clock);
    await Future.wait([
      for (var i = 0; i < 8; i++) c.invoke('a', body: {'i': i}),
      for (var i = 0; i < 8; i++) c.invoke('b', body: {'i': i}),
    ]);
    expect(clock.sleeps, isEmpty);
  });
}
