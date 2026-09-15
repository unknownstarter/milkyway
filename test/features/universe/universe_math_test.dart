import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/universe/domain/universe_math.dart';

// 배치 수학은 디자인 원본(JS)과 **비트 단위로 같아야** 한다.
// 다르면 디자인에서 확인한 배치와 앱의 배치가 어긋나고, 유저 입장에서는
// 업데이트할 때마다 별이 이사한 것처럼 보인다.
//
// 아래 기대값은 design_handoff_my_universe/universe-scene.jsx 의 함수를
// node 로 그대로 돌려 뽑은 것이다.
void main() {
  group('hash32 - 원본 JS와 동일', () {
    const cases = {
      'a': 3826002220,
      'book-1': 2430922394,
      '5f2c1e9a-1111-4b2c-9c3d-000000000001': 1845988342,
      '한글책': 745349580,
      '': 2166136261,
    };
    test('알려진 입력에 대해 같은 해시', () {
      cases.forEach((input, expected) {
        expect(hash32(input), expected, reason: 'hash32("$input")');
      });
    });
  });

  group('rndFrom(mulberry32) - 원본 JS와 동일', () {
    const cases = <int, List<String>>{
      7: ['0.011704753153', '0.061958257575', '0.976907632779',
          '0.699028705712', '0.521445268532'],
      41238: ['0.211475519463', '0.600607781205', '0.784923228901',
              '0.531840140466', '0.177161729895'],
      41343: ['0.273629747331', '0.735961679835', '0.071606175741',
              '0.992471707053', '0.610219676746'],
      2166136261: ['0.611244452186', '0.493524291785', '0.774024883518',
                   '0.412286111619', '0.812265781453'],
    };
    test('seed별 앞 5개 난수가 같다', () {
      cases.forEach((seed, expected) {
        final r = rndFrom(seed);
        for (var i = 0; i < expected.length; i++) {
          expect(r().toStringAsFixed(12), expected[i],
              reason: 'rndFrom($seed) #$i');
        }
      });
    });
  });

  group('galaxyRadius', () {
    test('원본과 동일하고 상한에서 멈춘다', () {
      const cases = {0: 300.0, 1: 371.727246, 7: 515.181738, 50: 706.867448};
      cases.forEach((n, expected) {
        expect(galaxyRadius(n), closeTo(expected, 0.000001), reason: 'n=$n');
      });
      // 400권에서 상한. 1000권이어도 더 안 자란다(화면을 안 뚫는다).
      expect(galaxyRadius(400), closeTo(920.0, 0.000001));
      expect(galaxyRadius(1000), closeTo(920.0, 0.000001));
    });
  });

  group('배치 - 결정성이 핵심', () {
    List<UniverseBook> lib(int n, {bool titled = false}) => List.generate(
          n,
          (i) => UniverseBook(
            id: 'book-$i',
            title: titled ? '책 $i' : '',
            notes: i % 7,
          ),
        );

    test('같은 서재는 언제나 같은 배치(익명)', () {
      final a = placeAnon(lib(40), galaxyRadius(40));
      final b = placeAnon(lib(40), galaxyRadius(40));
      for (var i = 0; i < a.length; i++) {
        expect(a[i].angle, b[i].angle);
        expect(a[i].radius, b[i].radius);
        expect(a[i].colorIndex, b[i].colorIndex);
      }
    });

    test('같은 서재는 언제나 같은 배치(라벨)', () {
      final a = placeNamed(lib(9, titled: true), galaxyRadius(9));
      final b = placeNamed(lib(9, titled: true), galaxyRadius(9));
      for (var i = 0; i < a.length; i++) {
        expect(a[i].angle, b[i].angle, reason: '$i');
        expect(a[i].radius, b[i].radius, reason: '$i');
      }
    });

    test('책을 더 담아도 기존 책의 색/깊이는 안 바뀐다', () {
      // 위치는 은하 반경이 자라면서 같이 자라지만, id에서 나오는 값은 불변이어야 한다.
      final before = placeAnon(lib(10), galaxyRadius(10));
      final after = placeAnon(lib(11), galaxyRadius(11));
      for (var i = 0; i < before.length; i++) {
        expect(after[i].colorIndex, before[i].colorIndex, reason: 'book-$i 색');
        expect(after[i].depth, before[i].depth, reason: 'book-$i 깊이');
      }
    });

    test('라벨 배치는 은하 밖으로 안 나간다', () {
      final maxR = galaxyRadius(12);
      for (final s in placeNamed(lib(12, titled: true), maxR)) {
        expect(s.radius, lessThanOrEqualTo(maxR + 0.001), reason: s.id);
        expect(s.x.abs(), lessThanOrEqualTo(340.001), reason: '${s.id} x');
      }
    });

    test('라벨 배치는 서로 너무 붙지 않는다', () {
      // 110패스 릴랙세이션이 실제로 밀어냈는지. 타원 판정 기준 0.75 이상이면 읽힌다.
      final stars = placeNamed(lib(8, titled: true), galaxyRadius(8));
      for (var i = 0; i < stars.length; i++) {
        for (var j = i + 1; j < stars.length; j++) {
          final dx = (stars[j].x - stars[i].x) / 235.0;
          final dy = (stars[j].y - stars[i].y) / 215.0;
          expect((dx * dx + dy * dy), greaterThan(0.75 * 0.75),
              reason: '$i-$j 라벨이 겹친다');
        }
      }
    });

    test('빈 서재는 빈 배치', () {
      expect(placeAnon(const [], 300), isEmpty);
      expect(placeNamed(const [], 300), isEmpty);
    });
  });

  group('dustCount', () {
    test('메모 수에 따라 배경 밀도, 상하한 있음', () {
      expect(dustCount(0), 60);
      expect(dustCount(50), 60);
      expect(dustCount(200), 180);
      expect(dustCount(10000), 620);
    });
  });
}
