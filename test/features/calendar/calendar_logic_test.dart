import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/calendar/domain/calendar_logic.dart';

void main() {
  group('countByDay / itemsOnDay', () {
    final items = [
      DateTime(2026, 8, 7, 9),
      DateTime(2026, 8, 7, 22),
      DateTime(2026, 8, 15, 1),
    ];
    DateTime id(DateTime d) => d;

    test('같은 날은 합산된다', () {
      final counts = countByDay(items, id);
      expect(counts[DateTime(2026, 8, 7)], 2);
      expect(counts[DateTime(2026, 8, 15)], 1);
      expect(counts.containsKey(DateTime(2026, 8, 8)), isFalse);
    });

    test('itemsOnDay는 그날 것만(시간 무시)', () {
      final onSeven = itemsOnDay(items, id, DateTime(2026, 8, 7, 12));
      expect(onSeven.length, 2);
    });
  });

  group('monthGrid', () {
    test('일요일 시작 + 7의 배수 칸 + 첫날은 이달 1일 직전 일요일', () {
      final cells = monthGrid(2026, 8);
      expect(cells.length % 7, 0);
      expect(cells.first.date.weekday % 7, 0); // 일요일
      final first = DateTime(2026, 8, 1);
      final leading = first.weekday % 7;
      expect(cells.first.date, DateTime(2026, 8, 1 - leading));
      final aug1 = cells.firstWhere((c) => c.date == first);
      expect(aug1.inMonth, isTrue);
    });

    test('모든 이번 달 날짜(1..말일) 포함, 앞뒤 달은 dim', () {
      final cells = monthGrid(2026, 8);
      final inMonthDays =
          cells.where((c) => c.inMonth).map((c) => c.date.day).toList();
      expect(inMonthDays.first, 1);
      expect(inMonthDays.last, 31);
      expect(inMonthDays.length, 31);
      // 첫 칸이 이달이 아니면 dim
      if (cells.first.date != DateTime(2026, 8, 1)) {
        expect(cells.first.inMonth, isFalse);
      }
    });
  });
}
