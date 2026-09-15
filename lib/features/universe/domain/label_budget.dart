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

/// 와이드샷 경계. 이보다 멀리서 보면 라벨을 **아예 걷는다**.
///
/// 핸드오프 "라벨 가시성(중요)" 절의 규칙이다. 기울어진 와이드샷에서는 라벨이
/// 반드시 겹치므로, 와이드샷은 **형태를 보는 샷**, 당겨본 화면은 **정보를 읽는
/// 샷**으로 역할을 나눈다. 겹침 회피로 몇 개 살려봐야 읽히지도 않고 지저분하다.
const double kLabelWideShotScale = 1.15;

/// 줌 배율 -> 라벨 허용 개수.
/// 와이드샷에서는 0. 경계를 넘으면 당길수록 늘어난다(상한 24).
int labelBudget(double scale) {
  if (scale < kLabelWideShotScale) return 0;
  final n = (2 + 12 * (scale - kLabelWideShotScale)).round();
  return n.clamp(1, 24);
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
