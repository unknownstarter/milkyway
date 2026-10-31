import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../discovery/presentation/providers/discovery_providers.dart';
import '../../../memos/presentation/providers/memo_provider.dart';
import 'book_provider.dart';

/// 복귀 시 새로고침을 건너뛰는 최소 간격
const Duration othersContentRefreshInterval = Duration(seconds: 30);

/// 다른 사람이 남긴 콘텐츠(공개 메모 피드, 담은 책, 스토리)를 그리는 provider 무효화.
/// 홈 당겨서 새로고침과 앱 복귀 새로고침이 함께 쓴다. Ref/WidgetRef 모두 받도록 콜백으로 받는다.
void invalidateOthersContent(void Function(ProviderOrFamily) invalidate) {
  invalidate(homePublicMemoFeedProvider);
  invalidate(publicMemoFeedProvider);
  invalidate(paginatedPublicFeedProvider);
  invalidate(booksSavedByOthersProvider);
  invalidate(homeStoriesProvider);
}

/// 무효화 후 홈에서 바로 보이는 값이 새로 올 때까지 기다린다(실패는 삼킴, 각 위젯이 에러 상태를 그림).
Future<void> refreshOthersContent(WidgetRef ref) async {
  invalidateOthersContent(ref.invalidate);
  await Future.wait<Object?>([
    ref.read(homePublicMemoFeedProvider.future),
    ref.read(booksSavedByOthersProvider.future),
    ref.read(homeStoriesProvider.future),
  ].map((f) => f.then<Object?>((v) => v, onError: (_) => null)));
}
