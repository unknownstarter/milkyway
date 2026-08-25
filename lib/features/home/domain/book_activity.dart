import 'models/book.dart';

/// 책 활동(내 메모 / 남의 새 공개 메모) 판정과 정렬을 담당하는 순수 함수 모음.
///
/// 기기 로컬 last-viewed(SeenTracker)와 RPC 랭킹 결과만으로 계산되며
/// 부수효과가 없다. 홈 스토리 원과 책탭 정렬/점이 동일 로직을 공유한다.

/// "안 본 남의 새 공개 메모"가 있는가.
///
/// others != null 이고, (아직 안 봤거나 || others가 마지막 조회 이후)면 true.
/// others == null 이면 항상 false.
bool hasNewOthers(DateTime? othersLastPublicMemoAt, DateTime? lastViewed) {
  if (othersLastPublicMemoAt == null) return false;
  if (lastViewed == null) return true;
  return othersLastPublicMemoAt.isAfter(lastViewed);
}

/// 홈/책탭 공용 정렬.
///
/// 순서:
///   [A: 내 메모 있는 책 - myLastMemoAt DESC]
///   [B: 내 메모 없고 안 본 남의 새 공개 메모 - othersLastPublicMemoAt DESC]
///   [C: 나머지 - 원래 순서 유지]
///
/// [viewed]는 bookId -> 마지막 조회 시각. 원본 리스트는 변형하지 않는다.
List<Book> sortByActivity(List<Book> books, Map<String, DateTime> viewed) {
  final groupA = <Book>[];
  final groupB = <Book>[];
  final groupC = <Book>[];

  for (final b in books) {
    if (b.myLastMemoAt != null) {
      groupA.add(b);
    } else if (hasNewOthers(b.othersLastPublicMemoAt, viewed[b.id])) {
      groupB.add(b);
    } else {
      groupC.add(b);
    }
  }

  groupA.sort((a, b) => b.myLastMemoAt!.compareTo(a.myLastMemoAt!));
  groupB.sort(
      (a, b) => b.othersLastPublicMemoAt!.compareTo(a.othersLastPublicMemoAt!));

  return [...groupA, ...groupB, ...groupC];
}
