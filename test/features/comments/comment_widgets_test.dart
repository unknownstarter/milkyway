import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/comments/domain/models/comment.dart';
import 'package:whatif_milkyway_app/features/comments/presentation/widgets/comment_tile.dart';
import 'package:whatif_milkyway_app/features/comments/presentation/widgets/comment_composer.dart';
import 'package:whatif_milkyway_app/core/presentation/widgets/design/memo_card.dart';

Comment _comment({String content = '좋은 문장이네요', String? updated}) =>
    Comment.fromJson({
      'id': 'c1',
      'memo_id': 'm1',
      'user_id': 'u1',
      'content': content,
      'created_at': '2026-08-22T00:00:00.000Z',
      'updated_at': updated ?? '2026-08-22T00:00:00.000Z',
      'users': {'nickname': '노아', 'picture_url': null},
    });

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('CommentTile', () {
    testWidgets('작성자/본문 노출 + 본인이면 나 칩', (tester) async {
      await tester.pumpWidget(wrap(CommentTile(
        comment: _comment(),
        isMine: true,
      )));
      expect(find.text('노아'), findsOneWidget);
      expect(find.text('좋은 문장이네요'), findsOneWidget);
      expect(find.text('나'), findsOneWidget);
    });

    testWidgets('본인 댓글 더보기 = 수정/삭제', (tester) async {
      await tester.pumpWidget(wrap(CommentTile(
        comment: _comment(),
        isMine: true,
        onEdit: () {},
        onDelete: () {},
      )));
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      expect(find.text('수정하기'), findsOneWidget);
      expect(find.text('삭제하기'), findsOneWidget);
      expect(find.text('신고하기'), findsNothing);
    });

    testWidgets('타인 댓글 더보기 = 숨기기/신고', (tester) async {
      await tester.pumpWidget(wrap(CommentTile(
        comment: _comment(),
        isMine: false,
        onReport: () {},
        onHide: () {},
      )));
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      expect(find.text('이 댓글 숨기기'), findsOneWidget);
      expect(find.text('신고하기'), findsOneWidget);
      expect(find.text('수정하기'), findsNothing);
    });
  });

  group('CommentComposer', () {
    testWidgets('책 미저장(locked)이면 담기 유도 힌트 + 탭 시 콜백', (tester) async {
      var locked = false;
      final controller = TextEditingController();
      await tester.pumpWidget(wrap(CommentComposer(
        controller: controller,
        locked: true,
        onSend: (_) {},
        onLockedTap: () => locked = true,
      )));
      expect(find.text('책을 담으면 댓글을 남길 수 있어'), findsOneWidget);
      // locked면 AbsorbPointer가 TextField를 막고 상위 GestureDetector가 탭을 받음
      await tester.tap(find.byType(TextField), warnIfMissed: false);
      expect(locked, isTrue);
    });

    testWidgets('전송 버튼 탭하면 trim된 텍스트로 onSend', (tester) async {
      String? sent;
      final controller = TextEditingController(text: '  좋아요  ');
      await tester.pumpWidget(wrap(CommentComposer(
        controller: controller,
        onSend: (t) => sent = t,
      )));
      await tester.tap(find.byIcon(Icons.arrow_upward));
      expect(sent, '좋아요');
    });

    testWidgets('편집 모드면 체크 아이콘 + 수정 힌트', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(wrap(CommentComposer(
        controller: controller,
        isEditing: true,
        onSend: (_) {},
        onCancelEdit: () {},
      )));
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('댓글 수정'), findsOneWidget);
    });
  });

  group('MemoCard 댓글 수', () {
    testWidgets('commentCount > 0 이면 숫자 노출', (tester) async {
      await tester.pumpWidget(wrap(const MemoCard(
        content: '문장',
        authorName: '노아',
        commentCount: 3,
      )));
      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    testWidgets('commentCount 0 이면 미노출', (tester) async {
      await tester.pumpWidget(wrap(const MemoCard(
        content: '문장',
        authorName: '노아',
        commentCount: 0,
      )));
      expect(find.byIcon(Icons.chat_bubble_outline), findsNothing);
    });
  });
}
