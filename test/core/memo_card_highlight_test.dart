import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/core/presentation/widgets/design/memo_card.dart';

// 검색 결과에서 "왜 이게 걸렸는지"를 보여주는 강조. 두 가지가 중요하다.
// 1) 검색어가 없을 때 원문이 쪼개지거나 사라지면 안 된다. 이 카드는 검색 화면
//    밖에서도(홈·책 상세·피드) 쓰이므로 기본 경로가 멀쩡해야 한다.
// 2) 이어 붙였을 때 원문과 한 글자도 달라지면 안 된다. 강조는 색만 바꾸는 일이다.

const _base = TextStyle(color: Color(0xFFECECEC));
const _match = TextStyle(color: Color(0xFF00FF00));

String _joined(List<TextSpan> spans) => spans.map((s) => s.text ?? '').join();
List<String> _matched(List<TextSpan> spans) =>
    spans.where((s) => s.style == _match).map((s) => s.text ?? '').toList();

void main() {
  group('highlightSpans', () {
    test('검색어가 없으면 통짜 하나 - 호출부가 분기할 필요가 없다', () {
      final spans = highlightSpans('리더십에 대하여', null, base: _base, match: _match);
      expect(spans, hasLength(1));
      expect(spans.single.text, '리더십에 대하여');
      expect(spans.single.style, _base);
    });

    test('빈 문자열과 공백만도 통짜로 본다', () {
      for (final q in ['', '   ']) {
        final spans = highlightSpans('리더십', q, base: _base, match: _match);
        expect(spans, hasLength(1), reason: '검색어: "$q"');
        expect(_matched(spans), isEmpty);
      }
    });

    test('가운데 일치를 앞뒤와 나눈다', () {
      final spans = highlightSpans('나는 불안감이 크다', '불안감', base: _base, match: _match);
      expect(_joined(spans), '나는 불안감이 크다');
      expect(_matched(spans), ['불안감']);
    });

    test('여러 번 나오면 전부 강조한다', () {
      final spans = highlightSpans('책 책 책', '책', base: _base, match: _match);
      expect(_matched(spans), ['책', '책', '책']);
      expect(_joined(spans), '책 책 책');
    });

    test('대소문자는 무시하되 원문 표기는 지킨다', () {
      final spans = highlightSpans('The Having', 'having', base: _base, match: _match);
      expect(_matched(spans), ['Having']);
      expect(_joined(spans), 'The Having');
    });

    test('맨 앞과 맨 뒤 일치에서 빈 조각을 만들지 않는다', () {
      final head = highlightSpans('불안감이 크다', '불안감', base: _base, match: _match);
      expect(head.first.style, _match);
      expect(head.map((s) => s.text), everyElement(isNotEmpty));

      final tail = highlightSpans('크다 불안감', '불안감', base: _base, match: _match);
      expect(tail.last.style, _match);
      expect(tail.map((s) => s.text), everyElement(isNotEmpty));
    });

    test('못 찾으면 원문 그대로 - 강조 0개', () {
      final spans = highlightSpans('리더십에 대하여', '해빙', base: _base, match: _match);
      expect(_joined(spans), '리더십에 대하여');
      expect(_matched(spans), isEmpty);
    });

    test('이어 붙이면 언제나 원문과 같다 - 강조는 색만 바꾸는 일이다', () {
      const text = '해빙 The Having 해빙';
      for (final q in ['해빙', 'having', 'The', ' 해빙 ', '없는말']) {
        expect(_joined(highlightSpans(text, q, base: _base, match: _match)), text,
            reason: '검색어: "$q"');
      }
    });

    test('검색어 양옆 공백은 떼고 찾는다 - 입력창에서 그대로 넘어온다', () {
      final spans = highlightSpans('불안감', '  불안감  ', base: _base, match: _match);
      expect(_matched(spans), ['불안감']);
    });
  });
}
