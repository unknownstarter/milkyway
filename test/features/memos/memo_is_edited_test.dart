import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/memos/domain/models/memo.dart';
import 'package:whatif_milkyway_app/features/memos/domain/models/memo_visibility.dart';

Memo _memo({required DateTime created, DateTime? updated}) => Memo(
      id: 'm',
      userId: 'u',
      bookId: 'b',
      content: 'c',
      createdAt: created,
      updatedAt: updated,
      visibility: MemoVisibility.private,
      bookTitle: 't',
      books: const {},
    );

void main() {
  final base = DateTime(2026, 8, 20, 10, 0, 0);

  test('updatedAt null 이면 수정 아님', () {
    expect(_memo(created: base, updated: null).isEdited, isFalse);
  });

  test('created == updated 이면 수정 아님', () {
    expect(_memo(created: base, updated: base).isEdited, isFalse);
  });

  test('생성 아티팩트(1초 미만 차이)는 수정 아님', () {
    // createMemo가 now()를 두 번 불러 updated_at이 수 ms 늦는 실측 케이스
    expect(
      _memo(created: base, updated: base.add(const Duration(milliseconds: 300)))
          .isEdited,
      isFalse,
    );
  });

  test('수 초 이상 뒤 = 실제 수정', () {
    expect(
      _memo(created: base, updated: base.add(const Duration(seconds: 5)))
          .isEdited,
      isTrue,
    );
  });
}
