import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:whatif_milkyway_app/features/auth/data/current_user_lookup.dart';

/// 2026-11-01 류 사고 방지(G7): 네트워크/서버 오류를 "사용자 없음"으로 읽지 않는다.
Map<String, dynamic> _row() => {
      'id': 'u1',
      'email': 'a@b.c',
      'nickname': 'neo',
      'picture_url': null,
      'created_at': '2026-11-01T00:00:00Z',
      'updated_at': '2026-11-01T00:00:00Z',
      'onboarding_completed': true,
    };

Future<void> _noRefresh() async {}

void main() {
  test('세션 없음 -> null (행 조회도 안 함)', () async {
    var fetched = 0;
    final user = await lookupCurrentUser(
      sessionUserId: () => null,
      refreshIfNeeded: _noRefresh,
      fetchRow: (_) async {
        fetched++;
        return _row();
      },
    );
    expect(user, isNull);
    expect(fetched, 0);
  });

  test('행 없음(조회 성공 + null) -> null', () async {
    final user = await lookupCurrentUser(
      sessionUserId: () => 'u1',
      refreshIfNeeded: _noRefresh,
      fetchRow: (_) async => null,
    );
    expect(user, isNull);
  });

  test('행 있음 -> User', () async {
    final user = await lookupCurrentUser(
      sessionUserId: () => 'u1',
      refreshIfNeeded: _noRefresh,
      fetchRow: (_) async => _row(),
    );
    expect(user?.id, 'u1');
    expect(user?.onboardingCompleted, isTrue);
  });

  test('PostgrestException -> throw (null 아님)', () async {
    await expectLater(
      lookupCurrentUser(
        sessionUserId: () => 'u1',
        refreshIfNeeded: _noRefresh,
        fetchRow: (_) async =>
            throw const PostgrestException(message: 'rate limited', code: '429'),
      ),
      throwsA(isA<PostgrestException>()),
    );
  });

  test('SocketException -> throw (null 아님)', () async {
    await expectLater(
      lookupCurrentUser(
        sessionUserId: () => 'u1',
        refreshIfNeeded: _noRefresh,
        fetchRow: (_) async => throw const SocketException('offline'),
      ),
      throwsA(isA<SocketException>()),
    );
  });

  test('refresh 네트워크 오류는 삼키고 조회를 계속한다', () async {
    final user = await lookupCurrentUser(
      sessionUserId: () => 'u1',
      refreshIfNeeded: () async => throw AuthRetryableFetchException(),
      fetchRow: (_) async => _row(),
    );
    expect(user?.id, 'u1');
  });

  test('refresh 429 는 거부가 아니다 -> 조회를 계속한다', () async {
    final user = await lookupCurrentUser(
      sessionUserId: () => 'u1',
      refreshIfNeeded: () async =>
          throw const AuthApiException('rate', statusCode: '429'),
      fetchRow: (_) async => _row(),
    );
    expect(user?.id, 'u1');
  });

  test('refresh token 거부(400) -> null (세션 무효, 조회 안 함)', () async {
    var fetched = 0;
    final user = await lookupCurrentUser(
      sessionUserId: () => 'u1',
      refreshIfNeeded: () async => throw const AuthApiException(
          'Invalid Refresh Token',
          statusCode: '400',
          code: 'refresh_token_not_found'),
      fetchRow: (_) async {
        fetched++;
        return _row();
      },
    );
    expect(user, isNull);
    expect(fetched, 0);
  });

  test('isSessionRejected 분류', () {
    expect(isSessionRejected(const AuthApiException('x', statusCode: '401')), isTrue);
    expect(isSessionRejected(AuthSessionMissingException()), isTrue);
    expect(isSessionRejected(AuthRetryableFetchException()), isFalse);
    expect(isSessionRejected(const AuthApiException('x', statusCode: '500')), isFalse);
    expect(isSessionRejected(const SocketException('x')), isFalse);
  });
}
