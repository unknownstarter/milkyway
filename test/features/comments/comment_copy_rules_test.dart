import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/comments/domain/models/comment.dart';
import 'package:whatif_milkyway_app/features/comments/presentation/widgets/comment_tile.dart';
import 'package:whatif_milkyway_app/features/comments/presentation/widgets/comment_composer.dart';
import 'package:whatif_milkyway_app/l10n/app_localizations.dart';

/// 카피 부호/톤 규칙 강제 (docs/design/01-DESIGN_PHILOSOPHY.md 원칙 6, CLAUDE.md).
/// - AI 금지 기호: em대시 / en대시 / 중간점 / 곡선따옴표 / 단일 말줄임
/// - '당신' 호칭 금지, 시스템 카피 느낌표 금지
/// 위젯 트리에 렌더된 모든 Text 문자열을 수집해 정규식으로 검사한다.
/// 사용자 본문(comment.content)은 사용자 입력이라 검사 대상에서 제외하고,
/// 시스템/UI 카피만 골라 검사한다.
void main() {
  Widget wrap(Widget child) => MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: Scaffold(body: child),
      );

  // 시스템 카피에 절대 들어오면 안 되는 문자.
  final banned = RegExp(r'[—–·“”‘’…]');
  // '당신' 호칭 금지.
  final honorific = RegExp('당신');
  // 시스템 카피 느낌표 금지.
  final bang = RegExp('!');

  /// 위젯 트리의 모든 Text.data 를 모으되, [exclude] 에 든 문자열은 뺀다
  /// (사용자 입력 본문 등).
  List<String> systemTexts(WidgetTester tester, {Set<String> exclude = const {}}) {
    return tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .where((s) => s.isNotEmpty && !exclude.contains(s))
        .toList();
  }

  void assertClean(List<String> texts) {
    for (final s in texts) {
      expect(banned.hasMatch(s), isFalse,
          reason: 'AI 금지 기호 발견: "$s"');
      expect(honorific.hasMatch(s), isFalse,
          reason: '"당신" 호칭 발견: "$s"');
      expect(bang.hasMatch(s), isFalse,
          reason: '시스템 카피 느낌표 발견: "$s"');
    }
  }

  Comment mkComment() => Comment.fromJson({
        'id': 'c1',
        'memo_id': 'm1',
        'user_id': 'u1',
        'content': 'USER_BODY_PLACEHOLDER',
        'created_at': '2026-08-22T00:00:00.000Z',
        'updated_at': '2026-08-22T00:00:30.000Z', // 30s -> not edited
        'users': {'nickname': '노아', 'picture_url': null},
      });

  testWidgets('CommentTile 시스템 카피에 금지기호/당신/느낌표 없음', (tester) async {
    await tester.pumpWidget(wrap(CommentTile(
      comment: mkComment(),
      isMine: true,
    )));
    assertClean(systemTexts(tester, exclude: {'USER_BODY_PLACEHOLDER'}));
  });

  testWidgets('CommentTile 본인 메뉴 카피 금지기호/느낌표 없음', (tester) async {
    await tester.pumpWidget(wrap(CommentTile(
      comment: mkComment(),
      isMine: true,
      onEdit: () {},
      onDelete: () {},
    )));
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    assertClean(systemTexts(tester, exclude: {'USER_BODY_PLACEHOLDER'}));
  });

  testWidgets('CommentTile 타인 메뉴 카피 금지기호/느낌표 없음', (tester) async {
    await tester.pumpWidget(wrap(CommentTile(
      comment: mkComment(),
      isMine: false,
      onReport: () {},
      onHide: () {},
    )));
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    assertClean(systemTexts(tester, exclude: {'USER_BODY_PLACEHOLDER'}));
  });

  testWidgets('CommentComposer 힌트 카피(잠금/작성/편집) 규칙 준수', (tester) async {
    // locked
    await tester.pumpWidget(wrap(CommentComposer(
      controller: TextEditingController(),
      locked: true,
      onSend: (_) {},
      onLockedTap: () {},
    )));
    assertClean(systemTexts(tester));

    // 작성
    await tester.pumpWidget(wrap(CommentComposer(
      controller: TextEditingController(),
      onSend: (_) {},
    )));
    assertClean(systemTexts(tester));

    // 편집
    await tester.pumpWidget(wrap(CommentComposer(
      controller: TextEditingController(),
      isEditing: true,
      onSend: (_) {},
      onCancelEdit: () {},
    )));
    assertClean(systemTexts(tester));
  });
}
