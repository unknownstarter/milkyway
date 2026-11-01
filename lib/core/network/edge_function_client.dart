import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/analytics_provider.dart';

/// 앱 전체의 엣지 함수 호출 관문. `functions.invoke(` 는 이 파일에서만 부른다(CI 가 막는다).
///
/// 2026-11-01 장애: 화면이 프레임마다 get-memo-by-id 를 불러 1초에 94번이 나갔고, Supabase 가
/// 429 를 줬다. 같은 일이 다른 함수에서 반복되지 않도록 호출 자체를 여기서 조인다.
///
/// - 동시에 같은 함수 + 같은 body 가 여러 번 오면 서버에는 1번만 보낸다(진행 중인 것에만 합친다.
///   결과 캐시는 없다).
/// - 함수별 1초 [maxCallsPerSecond] 번을 넘는 호출은 버리지 않고 기다렸다 보낸다.
/// - 429/500/502/503/504/546/네트워크/시간 초과는 최대 2번 다시 보낸다. 최종 실패는 원래 예외 그대로.
class EdgeFunctionClient {
  EdgeFunctionClient(
    this._functions, {
    this.onThrottled,
    this.maxCallsPerSecond = 8,
    this.attemptTimeout = const Duration(seconds: 15),
    Future<void> Function(Duration)? sleep,
    DateTime Function()? now,
    Random? random,
  }) : _sleep = sleep ?? Future<void>.delayed,
       _now = now ?? DateTime.now,
       _random = random ?? Random();

  static const List<Duration> _backoff = [
    Duration(milliseconds: 400),
    Duration(milliseconds: 1200),
  ];
  static const Duration _maxRetryDelay = Duration(seconds: 5);
  static const Set<int> _retryableStatus = {429, 500, 502, 503, 504, 546};

  final FunctionsClient _functions;

  /// 속도 제한에 걸려 기다리게 된 순간 함수 이름과 함께 불린다(함수별 1초 1번).
  final void Function(String functionName)? onThrottled;
  final int maxCallsPerSecond;
  final Duration attemptTimeout;
  final Future<void> Function(Duration) _sleep;
  final DateTime Function() _now;
  final Random _random;

  final Map<String, Future<FunctionResponse>> _inflight = {};
  final Map<String, List<DateTime>> _sent = {};
  final Map<String, DateTime> _lastThrottleLog = {};

  Future<FunctionResponse> invoke(String name, {Map<String, dynamic>? body}) {
    final key = '$name|${_canonical(body)}';
    final existing = _inflight[key];
    if (existing != null) return existing;

    final future = _run(name, body);
    _inflight[key] = future;
    void clear(Object? _) {
      if (identical(_inflight[key], future)) _inflight.remove(key);
    }

    future.then(clear, onError: clear);
    return future;
  }

  Future<FunctionResponse> _run(String name, Map<String, dynamic>? body) async {
    var attempt = 0;
    while (true) {
      await _acquire(name);
      try {
        return await _functions
            .invoke(name, body: body)
            .timeout(attemptTimeout);
      } catch (e) {
        if (attempt >= _backoff.length || !_isRetryable(e)) rethrow;
        await _sleep(_delayFor(attempt, e));
        attempt++;
      }
    }
  }

  /// 함수별 슬라이딩 윈도우. 1초 안에 [maxCallsPerSecond] 번이 찼으면 가장 오래된 호출이
  /// 1초를 넘길 때까지 기다린다.
  Future<void> _acquire(String name) async {
    final sent = _sent.putIfAbsent(name, () => []);
    while (true) {
      final now = _now();
      sent.removeWhere((t) => now.difference(t) >= const Duration(seconds: 1));
      if (sent.length < maxCallsPerSecond) {
        sent.add(now);
        return;
      }
      _reportThrottled(name, now);
      final wait = const Duration(seconds: 1) - now.difference(sent.first);
      await _sleep(
        wait > Duration.zero ? wait : const Duration(milliseconds: 1),
      );
    }
  }

  void _reportThrottled(String name, DateTime now) {
    final last = _lastThrottleLog[name];
    if (last != null && now.difference(last) < const Duration(seconds: 1)) {
      return;
    }
    _lastThrottleLog[name] = now;
    try {
      onThrottled?.call(name);
    } catch (_) {
      // 계측 실패가 호출을 막으면 안 된다.
    }
  }

  static bool _isRetryable(Object e) {
    if (e is FunctionException) return _retryableStatus.contains(e.status);
    return e is SocketException ||
        e is TimeoutException ||
        e is http.ClientException;
  }

  Duration _delayFor(int attempt, Object e) {
    final retryAfter = e is FunctionException ? _retryAfterOf(e) : null;
    final Duration delay;
    if (retryAfter != null) {
      delay = retryAfter;
    } else {
      delay = _backoff[attempt] + Duration(milliseconds: _random.nextInt(201));
    }
    return delay > _maxRetryDelay ? _maxRetryDelay : delay;
  }

  /// supabase SDK 의 [FunctionException] 은 응답 헤더를 주지 않는다. 서버가 본문
  /// (`details`)에 `retry_after`(초)를 실어 보낸 경우에만 읽는다.
  static Duration? _retryAfterOf(FunctionException e) {
    final details = e.details;
    if (details is! Map) return null;
    final raw = details['retry_after'] ?? details['Retry-After'];
    final seconds = raw is num ? raw : num.tryParse('$raw');
    if (seconds == null || seconds < 0) return null;
    return Duration(milliseconds: (seconds * 1000).round());
  }

  static String _canonical(Object? value) => jsonEncode(_sorted(value));

  static Object? _sorted(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((k) => '$k').toList()..sort();
      return {for (final k in keys) k: _sorted(value[k])};
    }
    if (value is List) return value.map(_sorted).toList();
    return value;
  }
}

final edgeFunctionClientProvider = Provider<EdgeFunctionClient>((ref) {
  return EdgeFunctionClient(
    Supabase.instance.client.functions,
    onThrottled: (name) =>
        ref.read(analyticsProvider).logError('edge_throttled', operation: name),
  );
});
