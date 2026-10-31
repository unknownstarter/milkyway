import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/discovery/presentation/providers/discovery_providers.dart';
import 'package:whatif_milkyway_app/features/home/presentation/providers/book_provider.dart';
import 'package:whatif_milkyway_app/features/home/presentation/widgets/others_content_resume_refresher.dart';
import 'package:whatif_milkyway_app/features/memos/presentation/providers/memo_provider.dart';

void main() {
  testWidgets('복귀 시 30초 지났으면 다시 받고, 안 지났으면 건너뛴다', (tester) async {
    var builds = 0;
    var clock = DateTime(2026, 1, 1);
    final container = ProviderContainer(overrides: [
      homePublicMemoFeedProvider.overrideWith((ref) async {
        builds++;
        return [];
      }),
      booksSavedByOthersProvider.overrideWith((ref) async => []),
      homeStoriesProvider.overrideWith((ref) async => []),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: OthersContentResumeRefresher(
          now: () => clock,
          child: Consumer(builder: (context, ref, _) {
            ref.watch(homePublicMemoFeedProvider);
            return const SizedBox();
          }),
        ),
      ),
    ));
    await tester.pump();
    expect(builds, 1);

    Future<void> backgroundAndBack() async {
      for (final s in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
      await tester.pump();
    }

    clock = clock.add(const Duration(seconds: 10));
    await backgroundAndBack();
    expect(builds, 1);

    clock = clock.add(const Duration(seconds: 40));
    await backgroundAndBack();
    expect(builds, 2);
  });
}
