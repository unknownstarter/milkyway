import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/core/presentation/widgets/design/book_cover_fallback.dart';
import 'package:whatif_milkyway_app/features/books/presentation/widgets/book_grid_item.dart';
import 'package:whatif_milkyway_app/features/home/domain/models/book.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: SizedBox(width: 110, height: 160, child: child)),
      );

  testWidgets('cover_url 없는 책은 책 탭 그리드에서 제목과 저자를 보인다',
      (tester) async {
    final book = Book(
      id: 'b1',
      title: '표지 없는 책',
      author: '홍길동',
      coverUrl: null,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      isbn: '',
    );
    await tester.pumpWidget(wrap(BookGridItem(book: book, onTap: () {})));
    expect(find.text('표지 없는 책'), findsOneWidget);
    expect(find.text('홍길동'), findsOneWidget);
    expect(find.byIcon(Icons.book), findsNothing);
  });

  testWidgets('좁은 썸네일은 제목만 보이고 저자는 생략한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: BookCoverFallback(
            width: 54, height: 76, title: '작은 책', author: '저자'),
      ),
    ));
    expect(find.text('작은 책'), findsOneWidget);
    expect(find.text('저자'), findsNothing);
  });
}
