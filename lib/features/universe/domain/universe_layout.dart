/// 은하 한 장의 완성된 배치. 서재가 바뀔 때만 만들고 캐시한다.
/// placeNamed 가 110패스 O(n^2)라 절대 매 프레임 만들면 안 된다.
library;

import 'universe_math.dart';

/// 디자인 좌표계. 모든 배치 수학이 이 기준으로 나온다(1080x1920, 중심 540,880).
/// 실기기 크기로는 화면에서 스케일만 맞춘다.
const double kDesignWidth = 1080;
const double kDesignHeight = 1920;
const double kDesignCenterX = 540;
const double kDesignCenterY = 880;

/// 은하 팔레트(nebula). 별 색은 book.id 해시로 뽑은 colorIndex 가 고른다.
const List<int> kUniversePalette = [
  0xFF7FE9FF,
  0xFFB98BFF,
  0xFFFFD479,
  0xFFFF8F6B,
];

const int kUniverseBg = 0xFF03030A;

/// 서재 상태. 첫 진입 유도를 여기서 갈라준다.
enum UniversePhase {
  /// 책이 하나도 없다 -> 책을 담으라고 한다.
  noBooks,

  /// 책은 있는데 메모가 없다 -> 별은 떴지만 다 흐리다. 메모를 쓰라고 한다.
  noNotes,

  /// 정상.
  ready,
}

class UniverseLayout {
  final List<PlacedStar> stars;
  final double maxRadius;
  final int totalBooks;
  final int totalNotes;
  final int dust;
  final UniversePhase phase;

  const UniverseLayout({
    required this.stars,
    required this.maxRadius,
    required this.totalBooks,
    required this.totalNotes,
    required this.dust,
    required this.phase,
  });

  /// 책 목록으로 은하를 만든다.
  ///
  /// 제목이 있는 책만 라벨 후보(placeNamed)로 간다. 라벨 후보가 너무 많으면
  /// 릴랙세이션이 O(n^2)라 느려지고 어차피 화면에 다 못 그린다. 메모 많은 순으로
  /// [namedLimit] 권까지만 라벨 후보로 두고 나머지는 성단(placeAnon)으로 보낸다.
  factory UniverseLayout.build(
    List<UniverseBook> books, {
    int namedLimit = 24,
  }) {
    final totalBooks = books.length;
    final totalNotes = books.fold<int>(0, (s, b) => s + b.notes);
    if (totalBooks == 0) {
      return const UniverseLayout(
        stars: [],
        maxRadius: 300,
        totalBooks: 0,
        totalNotes: 0,
        dust: 60,
        phase: UniversePhase.noBooks,
      );
    }

    final maxR = galaxyRadius(totalBooks);

    // 라벨 후보 선정: 메모 많은 순. 동점이면 id로 갈라 항상 같은 결과가 되게.
    final sorted = [...books]..sort((a, b) {
        final c = b.notes.compareTo(a.notes);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    final named = <UniverseBook>[];
    final anon = <UniverseBook>[];
    for (final b in sorted) {
      if (b.title.trim().isNotEmpty && named.length < namedLimit) {
        named.add(b);
      } else {
        anon.add(b);
      }
    }

    final stars = <PlacedStar>[
      ...placeAnon(anon, maxR),
      ...placeNamed(named, maxR),
    ];

    return UniverseLayout(
      stars: stars,
      maxRadius: maxR,
      totalBooks: totalBooks,
      totalNotes: totalNotes,
      dust: dustCount(totalNotes),
      phase: totalNotes == 0 ? UniversePhase.noNotes : UniversePhase.ready,
    );
  }
}
