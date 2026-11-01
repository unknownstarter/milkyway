import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/core/presentation/widgets/design/memo_card.dart';
import 'package:whatif_milkyway_app/core/providers/seen_tracker_provider.dart';
import 'package:whatif_milkyway_app/core/services/seen_tracker.dart';
import 'package:whatif_milkyway_app/features/memos/presentation/providers/memo_new_comment_provider.dart';
import 'package:whatif_milkyway_app/l10n/app_localizations.dart';

class _Seen implements SeenTracker {
  final Map<String, DateTime> m;
  _Seen([Map<String, DateTime>? init]) : m = init ?? {};
  @override
  Future<void> markMemoViewed(String id) async => m['memo:$id'] = DateTime.now();
  @override
  Future<DateTime?> memoLastViewed(String id) async => m['memo:$id'];
  @override
  Future<void> markBookViewed(String bookId) async {}
  @override
  Future<DateTime?> bookLastViewed(String bookId) async => null;
  @override
  Future<Map<String, DateTime>> allBookViewed(List<String> ids) async => {};
  @override
  Future<void> markTabSeen(String tabKey) async {}
  @override
  Future<DateTime?> tabLastSeen(String tabKey) async => null;
}

class _Host extends ConsumerWidget {
  final MemoNewCommentKey k;
  const _Host(this.k);
  @override
  Widget build(BuildContext context, WidgetRef ref) => MemoCard(
        content: '문장',
        authorName: '노아',
        commentCount: 2,
        hasNewComment: ref.watch(memoHasNewCommentProvider(k)).value ?? false,
      );
}

Widget _app(Widget home, [List<Override> overrides = const []]) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: Scaffold(body: home),
      ),
    );

Future<void> _pump(WidgetTester t, MemoNewCommentKey k, SeenTracker seen) async {
  await t.pumpWidget(_app(_Host(k), [seenTrackerServiceProvider.overrideWithValue(seen)]));
  await t.pump();
  await t.pump();
}

void main() {
  final dot = find.byKey(const Key('memo-card-new-comment-dot'));
  final at = DateTime.utc(2026, 11, 1, 12);

  testWidgets('내 메모 + 본 적 없는 새 댓글이면 점', (t) async {
    await _pump(t, (memoId: 'm1', isMine: true, lastCommentAt: at), _Seen());
    expect(dot, findsOneWidget);
  });

  testWidgets('내 메모 + 댓글이 본 시각보다 늦으면 점', (t) async {
    await _pump(t, (memoId: 'm1', isMine: true, lastCommentAt: at),
        _Seen({'memo:m1': at.subtract(const Duration(hours: 1))}));
    expect(dot, findsOneWidget);
  });

  testWidgets('본 뒤면 점 없음', (t) async {
    await _pump(t, (memoId: 'm1', isMine: true, lastCommentAt: at),
        _Seen({'memo:m1': at.add(const Duration(minutes: 1))}));
    expect(dot, findsNothing);
  });

  testWidgets('남의 메모면 점 없음', (t) async {
    await _pump(t, (memoId: 'm1', isMine: false, lastCommentAt: at), _Seen());
    expect(dot, findsNothing);
  });

  testWidgets('MemoCard 기본값은 점 없음', (t) async {
    await t.pumpWidget(_app(
        const MemoCard(content: '문장', authorName: '노아', commentCount: 2)));
    expect(dot, findsNothing);
    expect(find.text('2'), findsOneWidget);
  });
}
