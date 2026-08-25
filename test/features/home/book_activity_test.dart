import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/home/domain/book_activity.dart';
import 'package:whatif_milkyway_app/features/home/domain/models/book.dart';
import 'package:whatif_milkyway_app/features/home/domain/models/book_status.dart';

Book _book(
  String id, {
  DateTime? myLastMemoAt,
  DateTime? othersLastPublicMemoAt,
}) {
  final now = DateTime(2026, 1, 1);
  return Book(
    id: id,
    title: 't-$id',
    author: 'a',
    isbn: 'i-$id',
    createdAt: now,
    updatedAt: now,
    status: BookStatus.wantToRead,
    myLastMemoAt: myLastMemoAt,
    othersLastPublicMemoAt: othersLastPublicMemoAt,
  );
}

void main() {
  final t0 = DateTime(2026, 1, 10, 0, 0, 0);
  final tEarlier = DateTime(2026, 1, 9, 0, 0, 0);
  final tLater = DateTime(2026, 1, 11, 0, 0, 0);

  group('hasNewOthers', () {
    test('others > lastViewed면 true', () {
      expect(hasNewOthers(tLater, t0), isTrue);
    });

    test('others == lastViewed면 false', () {
      expect(hasNewOthers(t0, t0), isFalse);
    });

    test('others < lastViewed면 false', () {
      expect(hasNewOthers(tEarlier, t0), isFalse);
    });

    test('lastViewed == null이고 others != null이면 true', () {
      expect(hasNewOthers(t0, null), isTrue);
    });

    test('others == null이면 항상 false', () {
      expect(hasNewOthers(null, null), isFalse);
      expect(hasNewOthers(null, t0), isFalse);
    });
  });

  group('sortByActivity 그룹 순서 A → B → C', () {
    test('A(내 메모) 먼저, myLastMemoAt DESC', () {
      final books = [
        _book('a1', myLastMemoAt: tEarlier),
        _book('a2', myLastMemoAt: tLater),
      ];
      final sorted = sortByActivity(books, {});
      expect(sorted.map((b) => b.id).toList(), ['a2', 'a1']);
    });

    test('B(안 본 남의 새 공개 메모) othersLastPublicMemoAt DESC', () {
      final books = [
        _book('b1', othersLastPublicMemoAt: tEarlier),
        _book('b2', othersLastPublicMemoAt: tLater),
      ];
      final sorted = sortByActivity(books, {});
      expect(sorted.map((b) => b.id).toList(), ['b2', 'b1']);
    });

    test('C(나머지)는 원래 순서 유지', () {
      final books = [
        _book('c1'),
        _book('c2'),
      ];
      final sorted = sortByActivity(books, {});
      expect(sorted.map((b) => b.id).toList(), ['c1', 'c2']);
    });

    test('A/B/C 혼합 순서', () {
      final books = [
        _book('c1'),
        _book('b1', othersLastPublicMemoAt: t0),
        _book('a1', myLastMemoAt: t0),
      ];
      final sorted = sortByActivity(books, {});
      expect(sorted.map((b) => b.id).toList(), ['a1', 'b1', 'c1']);
    });

    test('내 메모 있으면 others가 있어도 A(내 메모 우선)', () {
      final books = [
        _book('x', myLastMemoAt: t0, othersLastPublicMemoAt: tLater),
      ];
      final sorted = sortByActivity(books, {});
      // A 그룹으로 분류되어 정렬 유지.
      expect(sorted.map((b) => b.id).toList(), ['x']);
    });

    test('본 책(others <= lastViewed)은 B가 아닌 C로 분류', () {
      final books = [
        _book('seen', othersLastPublicMemoAt: t0),
        _book('newB', othersLastPublicMemoAt: tLater),
      ];
      // 'seen'은 t0에 봤음 → B 아님. 'newB'는 안 봄 → B.
      final sorted = sortByActivity(books, {'seen': t0});
      expect(sorted.map((b) => b.id).toList(), ['newB', 'seen']);
    });
  });
}
