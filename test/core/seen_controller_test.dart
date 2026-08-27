import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whatif_milkyway_app/core/providers/seen_tracker_provider.dart';
import 'package:whatif_milkyway_app/core/services/seen_tracker.dart';

// 반응형 seen 상태 계약 잠금.
// 핵심 1: mark* 하면 해당 리비전이 올라 이를 구독하는 파생 provider가 수동 invalidate 없이
//         자동 재계산된다.
// 핵심 2: 리비전이 종류별로 분리 + .select 구독이라, 관심 없는 mark엔 재계산되지 않는다
//         (책탭 마크가 메모탭 배지 네트워크를 깨우지 않음).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('mark* 가 종류별 리비전을 증가시킨다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(seenControllerProvider.notifier);

    expect(container.read(seenControllerProvider).bookViewed, 0);
    await ctrl.markBookViewed('b1');
    expect(container.read(seenControllerProvider).bookViewed, 1);
    expect(container.read(seenControllerProvider).tabBooks, 0); // 다른 종류 불변

    await ctrl.markTabSeen(SeenTracker.tabBooks);
    expect(container.read(seenControllerProvider).tabBooks, 1);
    await ctrl.markTabSeen(SeenTracker.tabMemos);
    expect(container.read(seenControllerProvider).tabMemos, 1);
  });

  test('select 구독: 관심 리비전이 바뀔 때만 재계산(격리)', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(seenControllerProvider.notifier);

    final bookViewedRebuilds = <int>[];
    final tabMemosRebuilds = <int>[];
    final bookViewedSel =
        Provider<int>((ref) => ref.watch(seenControllerProvider.select((s) => s.bookViewed)));
    final tabMemosSel =
        Provider<int>((ref) => ref.watch(seenControllerProvider.select((s) => s.tabMemos)));

    container.listen(bookViewedSel, (_, n) => bookViewedRebuilds.add(n),
        fireImmediately: true);
    container.listen(tabMemosSel, (_, n) => tabMemosRebuilds.add(n),
        fireImmediately: true);
    expect(bookViewedRebuilds, [0]);
    expect(tabMemosRebuilds, [0]);

    // 책 봤음 -> bookViewed 구독만 재계산, tabMemos는 그대로
    await ctrl.markBookViewed('b1');
    await Future<void>.delayed(Duration.zero);
    expect(bookViewedRebuilds, [0, 1]);
    expect(tabMemosRebuilds, [0]); // 메모탭 배지는 안 깨어남(네트워크 누수 방지)

    // 메모탭 봤음 -> tabMemos만 재계산, bookViewed는 그대로
    await ctrl.markTabSeen(SeenTracker.tabMemos);
    await Future<void>.delayed(Duration.zero);
    expect(tabMemosRebuilds, [0, 1]);
    expect(bookViewedRebuilds, [0, 1]);
  });

  test('mark 후 데이터 읽기(allBookViewed/tabLastSeen)가 반영된다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(seenControllerProvider.notifier);

    expect((await ctrl.allBookViewed(['b1'])).containsKey('b1'), isFalse);
    await ctrl.markBookViewed('b1');
    expect((await ctrl.allBookViewed(['b1'])).containsKey('b1'), isTrue);

    expect(await ctrl.tabLastSeen(SeenTracker.tabBooks), isNull);
    await ctrl.markTabSeen(SeenTracker.tabBooks);
    expect(await ctrl.tabLastSeen(SeenTracker.tabBooks), isNotNull);
  });
}
