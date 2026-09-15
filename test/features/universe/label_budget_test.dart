import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/universe/domain/label_budget.dart';

// 라벨 밀도의 계약. "상위 N권 고정"이 아니라 줌과 화면 여유가 알아서 정한다.
void main() {
  const viewport = Size(400, 800);

  LabelCandidate c(String id, double x, double y, {int notes = 1}) =>
      LabelCandidate(
          id: id, screenX: x, screenY: y, width: 120, height: 40, notes: notes);

  group('labelBudget', () {
    test('와이드샷에서는 라벨을 아예 걷는다 - 형태를 보는 샷', () {
      expect(labelBudget(0.5), 0);
      expect(labelBudget(1.0), 0);
      expect(labelBudget(kLabelWideShotScale - 0.01), 0);
    });

    test('당겨보면 라벨이 나온다 - 정보를 읽는 샷', () {
      expect(labelBudget(kLabelWideShotScale), greaterThan(0));
      expect(labelBudget(2.5), greaterThan(labelBudget(1.5)));
    });

    test('상한이 있다', () {
      expect(labelBudget(10), 24);
    });

    test('단조 증가', () {
      var prev = 0;
      for (var s = 0.5; s <= 3.0; s += 0.1) {
        final n = labelBudget(s);
        expect(n, greaterThanOrEqualTo(prev));
        prev = n;
      }
    });
  });

  group('pickLabels', () {
    test('겹치면 버린다 - 같은 자리에 몰린 후보는 하나만 산다', () {
      final picked = pickLabels(
        [c('a', 200, 400, notes: 9), c('b', 205, 402), c('d', 198, 398)],
        scale: 2.5, // 예산은 넉넉해도
        viewport: viewport,
      );
      expect(picked, ['a']);
    });

    test('벌어져 있으면 예산까지 산다', () {
      final picked = pickLabels(
        [c('a', 80, 100), c('b', 300, 300), c('d', 100, 600)],
        scale: 1.6,
        viewport: viewport,
      );
      expect(picked.length, 3);
    });

    test('축소하면 적게, 확대하면 많이 - 같은 배치에서', () {
      final cands = [
        for (var i = 0; i < 20; i++)
          c('b$i', 30.0 + (i % 5) * 85, 60.0 + (i ~/ 5) * 180, notes: 20 - i),
      ];
      final few = pickLabels(cands, scale: 1.3, viewport: viewport);
      final many = pickLabels(cands, scale: 2.5, viewport: viewport);
      expect(few.length, lessThan(many.length));
      // 축소 상태에서 살아남은 건 메모 많은 쪽이어야 한다.
      expect(few.first, 'b0');
    });

    test('화면 밖 후보는 안 그린다', () {
      final picked = pickLabels(
        [c('in', 200, 400), c('out', -500, 400), c('out2', 200, 5000)],
        scale: 2.5,
        viewport: viewport,
      );
      expect(picked, ['in']);
    });

    test('포커스된 별은 예산과 겹침을 무시하고 항상 산다', () {
      final cands = [
        for (var i = 0; i < 30; i++) c('b$i', 200, 400, notes: 30 - i),
        c('focus', 202, 401, notes: 0),
      ];
      // 와이드샷(라벨 0개)이어도 포커스는 살아야 한다.
      final picked =
          pickLabels(cands, scale: 0.5, viewport: viewport, focusedId: 'focus');
      expect(picked.first, 'focus');
    });

    test('포커스는 화면 밖이어도 살린다 - 카메라가 이동 중일 수 있다', () {
      final picked = pickLabels(
        [c('focus', -900, -900)],
        scale: 1,
        viewport: viewport,
        focusedId: 'focus',
      );
      expect(picked, ['focus']);
    });

    test('같은 입력이면 같은 결과 - 동점은 id로 가른다', () {
      final cands = [
        c('zz', 80, 100, notes: 5),
        c('aa', 300, 300, notes: 5),
      ];
      expect(pickLabels(cands, scale: 1.6, viewport: viewport),
          pickLabels(cands, scale: 1.6, viewport: viewport));
      expect(pickLabels(cands, scale: 1.6, viewport: viewport).first, 'aa');
    });

    test('후보가 없으면 빈 목록', () {
      expect(pickLabels(const [], scale: 1.6, viewport: viewport), isEmpty);
    });
  });
}
