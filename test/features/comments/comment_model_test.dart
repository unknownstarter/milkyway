import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/comments/domain/models/comment.dart';

void main() {
  Map<String, dynamic> base({Object? users, String? updated}) => {
        'id': 'c1',
        'memo_id': 'm1',
        'user_id': 'u1',
        'content': '좋은 문장이네요',
        'created_at': '2026-08-22T00:00:00.000Z',
        'updated_at': updated ?? '2026-08-22T00:00:00.000Z',
        'users': users,
      };

  group('Comment.fromJson', () {
    test('users가 객체일 때 작성자 정보 파싱', () {
      final c = Comment.fromJson(base(
          users: {'nickname': '노아', 'picture_url': 'http://x/a.jpg'}));
      expect(c.id, 'c1');
      expect(c.memoId, 'm1');
      expect(c.content, '좋은 문장이네요');
      expect(c.authorNickname, '노아');
      expect(c.authorAvatarUrl, 'http://x/a.jpg');
    });

    test('users가 배열일 때 첫 요소 사용', () {
      final c = Comment.fromJson(base(users: [
        {'nickname': '하늘', 'picture_url': null}
      ]));
      expect(c.authorNickname, '하늘');
      expect(c.authorAvatarUrl, isNull);
    });

    test('users가 null이면 작성자 정보 없음', () {
      final c = Comment.fromJson(base(users: null));
      expect(c.authorNickname, isNull);
    });
  });

  group('isEdited', () {
    test('created==updated면 수정 아님', () {
      final c = Comment.fromJson(base());
      expect(c.isEdited, isFalse);
    });

    test('1초 이내 차이는 수정 아님(insert 타이밍)', () {
      final c = Comment.fromJson(
          base(updated: '2026-08-22T00:00:00.500Z'));
      expect(c.isEdited, isFalse);
    });

    test('수 초 이상 뒤면 수정됨', () {
      final c =
          Comment.fromJson(base(updated: '2026-08-22T00:05:00.000Z'));
      expect(c.isEdited, isTrue);
    });
  });
}
