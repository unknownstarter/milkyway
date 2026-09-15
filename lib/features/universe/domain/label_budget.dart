/// 라벨을 몇 개, 어떤 걸 보여줄지 고른다.
///
/// 문제: 서재가 커지면 라벨 300개가 겹쳐서 아무것도 못 읽는다. 그렇다고 "상위 7권"
/// 처럼 숫자를 박으면 확대해도 더 안 나온다.
///
/// 해법 3단:
///   1. **예산** - 줌이 클수록 라벨을 더 많이 허용한다.
///   2. **화면 좌표 그리디 충돌 회피** - 후보를 순위대로 훑으며 이미 놓인 라벨과
///      겹치면 버린다. 축소하면 서로 붙으니 적게 살아남고, 확대하면 벌어지니 많이
///      살아남는다. 밀도 조절을 따로 안 해도 알아서 된다.
///   3. **페이드** - 매 프레임 채택 여부가 바뀌므로 즉시 켜고 끄면 깜빡인다.
///      채택되면 1로, 아니면 0으로 서서히 간다(호출부가 보간).
///
/// 배치 자체(placeNamed 릴랙세이션)는 월드 좌표에서 한 번만 돌리고 캐시한다.
/// 여기는 매 프레임 도는 렌더 단계 판정이라 싸야 한다.
library;

import 'dart:ui' show Offset, Rect, Size;

class LabelCandidate {
  final String id;

  /// 화면 좌표(별 위치).
  final double screenX;
  final double screenY;

  /// 라벨 상자 크기(측정된 텍스트 기준).
  final double width;
  final double height;

  /// 정렬 우선순위. 메모가 많을수록 먼저.
  final int notes;

  const LabelCandidate({
    required this.id,
    required this.screenX,
    required this.screenY,
    required this.width,
    required this.height,
    required this.notes,
  });
}

/// 줌 배율 -> 라벨 허용 개수.
/// 0.5배에서 3개, 1배에서 7개, 2.5배에서 19개. 상한 24는 화면에 물리적으로
/// 들어가는 한계에 가깝다(어차피 충돌 회피에서 더 걸러진다).
int labelBudget(double scale) {
  final n = (3 + 8 * (scale - 0.5)).round();
  return n.clamp(3, 24);
}

/// 지금 그릴 라벨을 고른다. 반환 순서 = 그리는 순서.
///
/// [focusedId] 는 예산·충돌과 무관하게 항상 살린다. 유저가 방금 누른 별의 이름이
/// 사라지면 그게 제일 이상하다.
List<String> pickLabels(
  List<LabelCandidate> candidates, {
  required double scale,
  required Size viewport,
  String? focusedId,
  double margin = 24,
  double gap = 8,
}) {
  final budget = labelBudget(scale);

  bool onScreen(LabelCandidate c) =>
      c.screenX > -margin &&
      c.screenX < viewport.width + margin &&
      c.screenY > -margin &&
      c.screenY < viewport.height + margin;

  final ordered = [...candidates]..sort((a, b) {
      if (a.id == focusedId) return -1;
      if (b.id == focusedId) return 1;
      final c = b.notes.compareTo(a.notes);
      return c != 0 ? c : a.id.compareTo(b.id);
    });

  final taken = <Rect>[];
  final picked = <String>[];
  for (final c in ordered) {
    final isFocused = c.id == focusedId;
    if (!isFocused && picked.length >= budget) break;
    if (!isFocused && !onScreen(c)) continue;

    final box = Rect.fromCenter(
      center: Offset(c.screenX, c.screenY),
      width: c.width + gap * 2,
      height: c.height + gap * 2,
    );
    if (!isFocused && taken.any((t) => t.overlaps(box))) continue;

    taken.add(box);
    picked.add(c.id);
  }
  return picked;
}
