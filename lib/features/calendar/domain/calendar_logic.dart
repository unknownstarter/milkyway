/// 캘린더 순수 로직(테스트 대상). 시간대 무시하고 연월일로만 다룬다.

/// 연월일만 남긴 키.
DateTime dayKey(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

bool sameDay(DateTime a, DateTime b) => dayKey(a) == dayKey(b);

/// items를 일자별 개수로 집계.
Map<DateTime, int> countByDay<T>(List<T> items, DateTime Function(T) dateOf) {
  final map = <DateTime, int>{};
  for (final it in items) {
    final k = dayKey(dateOf(it));
    map[k] = (map[k] ?? 0) + 1;
  }
  return map;
}

/// 특정 일자에 해당하는 items만(최신 입력 순 유지).
List<T> itemsOnDay<T>(
  List<T> items,
  DateTime Function(T) dateOf,
  DateTime day,
) {
  final k = dayKey(day);
  return [
    for (final it in items)
      if (dayKey(dateOf(it)) == k) it,
  ];
}

/// 월 그리드 한 칸.
class MonthCell {
  final DateTime date;
  final bool inMonth; // 이번 달이면 true, 앞/뒤 달이면 false(dim)

  const MonthCell(this.date, this.inMonth);
}

/// 일요일 시작 월 그리드. 필요한 주 수만큼만 생성(빈 주 없음).
List<MonthCell> monthGrid(int year, int month) {
  final first = DateTime(year, month, 1);
  final leading = first.weekday % 7; // Mon=1..Sun=7 -> Sun=0
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final weeks = ((leading + daysInMonth) / 7).ceil();
  final start = first.subtract(Duration(days: leading));
  return [
    for (var i = 0; i < weeks * 7; i++)
      MonthCell(
        DateTime(start.year, start.month, start.day + i),
        DateTime(start.year, start.month, start.day + i).month == month,
      ),
  ];
}
