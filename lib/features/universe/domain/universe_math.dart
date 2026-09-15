/// 나의 우주(책 은하) 배치 수학.
///
/// 좌표는 하드코딩이 아니라 **book.id 해시**에서 나온다. 같은 서재는 언제나 같은
/// 배치가 되어야 한다 - 유저가 "내 별은 저기쯤"이라고 기억할 수 있어야 하니까.
/// 그래서 id가 바뀌면 별이 이사한다. id는 절대 갈아끼우지 말 것.
///
/// 디자인 원본(JS)과 **비트 단위로 같은 값**이 나와야 한다. 다르면 디자인에서 본
/// 배치와 앱의 배치가 어긋난다. 기준값은 test/features/universe/universe_math_test.dart
/// 에 원본 실행 결과로 박아뒀다.
/// 출처: design_handoff_my_universe/universe-scene.jsx
library;

import 'dart:math' as math;

/// 32비트 곱셈(JS Math.imul). Dart int는 64비트라 그냥 곱하면 값이 달라진다.
int _imul(int a, int b) {
  final ah = (a >> 16) & 0xffff;
  final al = a & 0xffff;
  final bh = (b >> 16) & 0xffff;
  final bl = b & 0xffff;
  return ((al * bl) + ((((ah * bl + al * bh) & 0xffff) << 16))) & 0xFFFFFFFF;
}

int _u32(int v) => v & 0xFFFFFFFF;

/// FNV-1a 32bit. 문자열 -> 부호 없는 32비트 해시.
int hash32(String s) {
  int h = 2166136261;
  for (var i = 0; i < s.length; i++) {
    h = _u32(h ^ s.codeUnitAt(i));
    h = _imul(h, 16777619);
  }
  return _u32(h);
}

/// mulberry32. 같은 seed면 같은 수열.
double Function() rndFrom(int seed) {
  int a = _u32(seed);
  return () {
    a = _u32(a + 0x6D2B79F5);
    int t = _imul(a ^ (a >>> 15), _u32(1 | a));
    t = _u32(_u32(t + _imul(t ^ (t >>> 7), _u32(61 | t))) ^ t);
    return _u32(t ^ (t >>> 14)) / 4294967296;
  };
}

double _clamp(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);

/// 은하 반경. 장서가 늘면 은하가 자란다. 로그라 1000권이어도 화면을 안 뚫는다.
double galaxyRadius(int n) =>
    300 + math.min(1.0, math.log(n + 1) / math.log(400)) * 620;

/// 배치가 끝난 별 하나. 좌표는 디자인 좌표계(1080x1920, 중심 540,880) 기준의
/// 중심 기준 극좌표.
class PlacedStar {
  final String id;
  final String title;
  final String author;
  final int notes;

  /// 중심 기준 각도(라디안)와 반경.
  final double angle;
  final double radius;

  /// 팔레트 인덱스(0~3).
  final int colorIndex;

  /// 은하 원반 두께 방향 깊이(0.35~1.0). 앞뒤 겹침에 쓴다.
  final double depth;

  /// 제목 라벨 후보인지(= 제목이 있는 책).
  final bool named;

  const PlacedStar({
    required this.id,
    required this.title,
    required this.author,
    required this.notes,
    required this.angle,
    required this.radius,
    required this.colorIndex,
    required this.depth,
    required this.named,
  });

  double get x => math.cos(angle) * radius;
  double get y => math.sin(angle) * radius;
}

/// 배치 입력. 앱의 Book에서 이것만 뽑아 넘긴다.
class UniverseBook {
  final String id;
  final String title;
  final String author;
  final int notes;

  const UniverseBook({
    required this.id,
    required this.title,
    this.author = '',
    this.notes = 0,
  });
}

/// 제목 없는 책 - 성단을 이뤄 뭉친다. 책이 많아질수록 성단 수도 늘어난다.
/// 균일하게 흩뿌리면 은하로 안 보인다.
List<PlacedStar> placeAnon(List<UniverseBook> list, double maxR) {
  final n = list.length;
  if (n == 0) return const [];
  final K = math.max(1, math.min(16, (math.sqrt(n) / 1.5).round()));
  final crnd = rndFrom(41231 + K * 7);
  final cores = <({double a, double r, double spread})>[];
  for (var k = 0; k < K; k++) {
    final arm = k % 3;
    final u = crnd();
    final cr = 180 + math.pow(u, 0.55) * (maxR - 180);
    cores.add((
      a: arm * (math.pi * 2 / 3) + cr * 0.0044 + (crnd() - 0.5) * 0.7,
      r: cr.toDouble(),
      spread: maxR * (0.07 + crnd() * 0.1),
    ));
  }
  return list.map((book) {
    final h = hash32(book.id);
    final core = cores[h % K];
    final g1 = ((h >>> 4) % 1000) / 1000;
    final g2 = ((h >>> 13) % 1000) / 1000;
    // 균등난수 3개의 평균 = 가우시안 근사. 성단 중심이 촘촘하고 바깥이 옅어진다.
    final mag = (g1 + g2 + ((h >>> 22) % 1000) / 1000) / 1.5 - 1;
    final dir = ((h >>> 8) % 6283) / 1000;
    final cx = math.cos(core.a) * core.r + math.cos(dir) * core.spread * mag * 1.8;
    final cy = math.sin(core.a) * core.r + math.sin(dir) * core.spread * mag * 1.8;
    return PlacedStar(
      id: book.id,
      title: '',
      author: '',
      notes: book.notes,
      angle: math.atan2(cy, cx),
      radius: math.sqrt(cx * cx + cy * cy),
      colorIndex: (h >>> 17) % 4,
      depth: 0.35 + (((h >>> 21) % 1000) / 1000) * 0.65,
      named: false,
    );
  }).toList();
}

/// 라벨이 붙는 책 - 해시로 무작위 배치한 뒤 라벨이 겹치는 쌍만 서로 밀어낸다.
/// 균등 배분은 인위적으로 보여서 이렇게 한다.
///
/// **비싸다.** 110패스 O(n^2)라 서재가 바뀔 때만 돌리고 결과를 캐시할 것.
/// 매 프레임 돌리면 안 된다.
List<PlacedStar> placeNamed(List<UniverseBook> list, double maxR) {
  if (list.isEmpty) return const [];
  final pts = list.map((book) {
    final h = hash32(book.id);
    final u = ((h >>> 3) % 10000) / 10000;
    final r = 200 + math.sqrt(u) * (maxR * 0.92 - 200);
    final ang = ((h >>> 9) % 62831) / 10000;
    return _Pt(book, h, math.cos(ang) * r, math.sin(ang) * r);
  }).toList();

  // 라벨 상자는 가로로 넓다 - 겹침 판정도 타원으로 한다.
  const rx = 235.0, ry = 215.0, minR = 190.0, xLim = 340.0;
  final maxRR = maxR, yLim = maxR;
  for (var pass = 0; pass < 110; pass++) {
    for (var i = 0; i < pts.length; i++) {
      for (var j = i + 1; j < pts.length; j++) {
        var dx = pts[j].x - pts[i].x;
        var dy = pts[j].y - pts[i].y;
        var d = math.sqrt((dx / rx) * (dx / rx) + (dy / ry) * (dy / ry));
        if (d < 0.001) {
          dx = rx;
          dy = 0;
          d = 0.5;
        }
        if (d < 1) {
          final push = (1 - d) / d * 0.28;
          pts[i].x -= dx * push;
          pts[i].y -= dy * push;
          pts[j].x += dx * push;
          pts[j].y += dy * push;
        }
      }
      pts[i].x = _clamp(pts[i].x, -xLim, xLim);
      pts[i].y = _clamp(pts[i].y, -yLim, yLim);
      final rr = math.sqrt(pts[i].x * pts[i].x + pts[i].y * pts[i].y);
      if (rr < minR) {
        final t = minR / (rr == 0 ? 1 : rr);
        pts[i].x *= t;
        pts[i].y *= t;
      } else if (rr > maxRR) {
        final t = maxRR / rr;
        pts[i].x *= t;
        pts[i].y *= t;
      }
    }
  }

  return pts.map((p) {
    return PlacedStar(
      id: p.book.id,
      title: p.book.title,
      author: p.book.author,
      notes: p.book.notes,
      angle: math.atan2(p.y, p.x),
      radius: math.sqrt(p.x * p.x + p.y * p.y),
      colorIndex: (p.h >>> 17) % 4,
      depth: 0.35 + (((p.h >>> 21) % 1000) / 1000) * 0.65,
      named: true,
    );
  }).toList();
}

class _Pt {
  final UniverseBook book;
  final int h;
  double x;
  double y;
  _Pt(this.book, this.h, this.x, this.y);
}

/// 배경 별먼지 개수. 총 메모 수가 배경 밀도를 정한다.
/// 개별 메모와 1:1로 대응시키지 않는다(메모 수천 개여도 성능이 안 무너지게).
int dustCount(int totalNotes) => _clamp(totalNotes * 0.9, 60, 620).round();
