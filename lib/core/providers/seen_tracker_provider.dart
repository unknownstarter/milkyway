import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/seen_tracker.dart';

/// SeenTracker 서비스(로컬 SharedPreferences). DI/테스트를 위해 provider로 주입.
final seenTrackerServiceProvider = Provider<SeenTracker>((ref) => SeenTracker());

/// '봤음' 리비전 3종. 종류별로 분리해 **관심 있는 파생 provider만** 재계산되게 한다.
/// (단일 전역 카운터면 책탭을 봤을 때 메모탭 배지의 네트워크까지 재호출되어 비용이 샘)
class SeenRevisions {
  final int bookViewed; // 홈 스토리 링 / 책탭 썸네일 점
  final int tabBooks; // 하단 네비 Books 점
  final int tabMemos; // 하단 네비 Memos 점
  const SeenRevisions(
      {this.bookViewed = 0, this.tabBooks = 0, this.tabMemos = 0});

  SeenRevisions copyWith({int? bookViewed, int? tabBooks, int? tabMemos}) =>
      SeenRevisions(
        bookViewed: bookViewed ?? this.bookViewed,
        tabBooks: tabBooks ?? this.tabBooks,
        tabMemos: tabMemos ?? this.tabMemos,
      );
}

/// '봤음' 상태의 **반응형** 컨트롤러.
///
/// 이전엔 비반응형 서비스를 그냥 read 해서 봤음을 기록해도 파생 provider(링/점)가
/// 몰랐다 → 화면마다 수동 `ref.invalidate(...)`를 흩뿌려야 했고 빠지면 점이 안 사라졌다.
/// 이제 mark* 가 해당 리비전을 올리고, 파생 provider는 `.select`로 관심 리비전만 구독 →
/// 봤음 기록 시 그 파생만 자동 재계산(Riverpod 의존성 그래프 정석).
class SeenController extends Notifier<SeenRevisions> {
  SeenTracker get _tracker => ref.read(seenTrackerServiceProvider);

  @override
  SeenRevisions build() => const SeenRevisions();

  Future<void> markBookViewed(String bookId) async {
    await _tracker.markBookViewed(bookId);
    state = state.copyWith(bookViewed: state.bookViewed + 1);
  }

  Future<void> markTabSeen(String tabKey) async {
    await _tracker.markTabSeen(tabKey);
    state = tabKey == SeenTracker.tabBooks
        ? state.copyWith(tabBooks: state.tabBooks + 1)
        : state.copyWith(tabMemos: state.tabMemos + 1);
  }

  // 읽기(판정용). 파생 provider는 관심 리비전을 select로 구독하고 데이터는 이걸로 읽는다.
  Future<Map<String, DateTime>> allBookViewed(List<String> bookIds) =>
      _tracker.allBookViewed(bookIds);

  Future<DateTime?> tabLastSeen(String tabKey) => _tracker.tabLastSeen(tabKey);
}

final seenControllerProvider =
    NotifierProvider<SeenController, SeenRevisions>(SeenController.new);
