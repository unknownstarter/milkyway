import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/features/orb/domain/orb_tier.dart';
import 'package:whatif_milkyway_app/l10n/app_localizations.dart';
import 'package:whatif_milkyway_app/features/wrapped/domain/wrapped_data.dart';
import 'package:whatif_milkyway_app/features/wrapped/presentation/widgets/wrapped_card.dart';

// 레이아웃 계약: 회고 카드가 1080x1350 안에 오버플로 없이 들어가는지.
// 선택 섹션(책/문장/Lyra/상위%)이 빠져도 안전한지 조합으로 검증.
// (폰트/아이콘 로드 없이도 오버플로는 잡힌다 - 가장 흔한 버그 방어.)
WrappedData _data({
  String? book = '미움받을 용기',
  String? author = '기시미 이치로',
  String? quote = '타인의 기대를 채우려 살지 않아도 된다',
  String? lyra = '그 문장이 왜 8월 내내 너에게 남았을까',
  int? topPercent = 7,
}) =>
    WrappedData(
      year: 2026,
      month: 8,
      memoCount: 34,
      readDays: 21,
      topPercent: topPercent,
      bookTitle: book,
      bookAuthor: author,
      bookCoverUrl: null,
      bookMemoCount: 9,
      quote: quote,
      quoteBookTitle: quote == null ? null : '미움받을 용기',
      lyra: lyra,
      tier: OrbTier.t4,
    );

void main() {
  final cases = <String, WrappedData>{
    '전체': _data(),
    '상위% 없음': _data(topPercent: null),
    '책 없음': _data(book: null, author: null),
    '저자 없음': _data(author: null),
    '문장 없음': _data(quote: null),
    'Lyra 없음': _data(lyra: null),
    '스탯만': _data(book: null, author: null, quote: null, lyra: null),
    '긴 제목/문장': _data(
      book: '아주 긴 제목의 책 제목이 두 줄을 넘어가면 잘리는지 확인하는 케이스입니다',
      quote: '아주 긴 인용 문장이 세 줄을 넘어가면 말줄임으로 처리되는지 확인하기 위한 긴 문장 테스트입니다 '
          '두 번째 문장도 이어집니다 세 번째 문장도 이어집니다 네 번째 문장까지 갑니다',
    ),
  };

  testWidgets('WrappedCard 오버플로 없음(섹션 조합)', (tester) async {
    tester.view.physicalSize = const Size(WrappedCard.w, WrappedCard.h);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final entry in cases.entries) {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        debugShowCheckedModeBanner: false,
        home: Material(
          type: MaterialType.transparency,
          child: WrappedCard(data: entry.value),
        ),
      ));
      expect(tester.takeException(), isNull, reason: '케이스=${entry.key} 오버플로');
    }
  });
}
