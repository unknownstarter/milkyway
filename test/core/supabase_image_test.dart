import 'package:flutter_test/flutter_test.dart';
import 'package:whatif_milkyway_app/core/utils/supabase_image.dart';

// 이미지 업로드->저장->다시 불러오기(표시) 경로에서 "값"이 정확히 계산되는지 검증.
// 순수 함수라 네트워크/바인딩 없이 결정적으로 테스트 가능.
void main() {
  const base = 'https://hyjgfgzexvxhgfmqgiqu.supabase.co';
  const publicObj =
      '$base/storage/v1/object/public/memo_images/u1/123.jpg';

  group('supabaseRenderUrl - 표시 시 변환 URL', () {
    test('Supabase 공개 오브젝트는 render URL + width/quality 로 재작성', () {
      final out = supabaseRenderUrl(publicObj, width: 156, quality: 80);
      expect(out, contains('/storage/v1/render/image/public/memo_images/u1/123.jpg'));
      expect(out, contains('width=156'));
      expect(out, contains('quality=80'));
      expect(out, isNot(contains('/object/public/')));
    });

    test('비율 왜곡 방지 - height + resize=contain 포함(회귀 잠금)', () {
      // width만 주면 Supabase가 세로로 짓눌린 왜곡본을 반환하던 버그 방지.
      final out = supabaseRenderUrl(publicObj, width: 150);
      expect(out, contains('width=150'));
      expect(out, contains('height=450')); // width*3
      expect(out, contains('resize=contain'));
    });

    test('width 미지정이면 원본 URL 그대로(변환 안 함)', () {
      expect(supabaseRenderUrl(publicObj), publicObj);
      expect(supabaseRenderUrl(publicObj, width: null), publicObj);
    });

    test('width <= 0 이면 원본 그대로', () {
      expect(supabaseRenderUrl(publicObj, width: 0), publicObj);
      expect(supabaseRenderUrl(publicObj, width: -5), publicObj);
    });

    test('비-Supabase(네이버 등 외부) URL은 절대 건드리지 않음', () {
      const naver = 'https://bookthumb-phinf.pstatic.net/cover/183/808/18380862.jpg?type=m1';
      expect(supabaseRenderUrl(naver, width: 156), naver);
      const google = 'https://lh3.googleusercontent.com/a/abc=s96-c';
      expect(supabaseRenderUrl(google, width: 120), google);
    });

    test('이미 쿼리스트링이 있으면 & 로 이어붙임', () {
      const withQuery = '$base/storage/v1/object/public/memo_images/u1/123.jpg?v=2';
      final out = supabaseRenderUrl(withQuery, width: 200);
      expect(out, contains('.jpg?v=2&width=200'));
      expect(out, contains('resize=contain'));
      expect(out, contains('quality='));
    });

    test('quality 는 1-100 로 클램프', () {
      expect(supabaseRenderUrl(publicObj, width: 100, quality: 999),
          contains('quality=100'));
      expect(supabaseRenderUrl(publicObj, width: 100, quality: 0),
          contains('quality=1'));
    });

    test('isSupabasePublicObjectUrl 판별', () {
      expect(isSupabasePublicObjectUrl(publicObj), isTrue);
      expect(isSupabasePublicObjectUrl('https://naver.com/x.jpg'), isFalse);
    });
  });

  group('bookCoverStoragePath - 재호스팅 경로(ISBN 결정적)', () {
    test('일반 ISBN', () {
      expect(bookCoverStoragePath('9788934985907'), 'covers/9788934985907.jpg');
    });

    test('네이버식 "isbn10 isbn13" 공백이면 첫 토큰만', () {
      expect(bookCoverStoragePath('8934985909 9788934985907'),
          'covers/8934985909.jpg');
    });

    test('하이픈/공백 등 잡문자 제거(숫자·X만)', () {
      expect(bookCoverStoragePath('978-89-349-8590-7'),
          'covers/9788934985907.jpg');
      expect(bookCoverStoragePath('  897X  '), 'covers/897X.jpg');
    });

    test('빈/널/유효문자 없음이면 null(폴백 유도)', () {
      expect(bookCoverStoragePath(null), isNull);
      expect(bookCoverStoragePath(''), isNull);
      expect(bookCoverStoragePath('   '), isNull);
      expect(bookCoverStoragePath('---'), isNull);
    });
  });

  group('업로드->저장->다시 불러오기 라운드트립(값 정확성)', () {
    test('네이버 표지를 우리 버킷에 저장한 URL이, 표시 때 render 변환으로 정확히 이어짐', () {
      // 1) 저장: ISBN 기준 경로 -> 우리 스토리지 공개 URL
      final path = bookCoverStoragePath('9788934985907');
      expect(path, isNotNull);
      final storedUrl =
          '$base/storage/v1/object/public/book_covers/$path';

      // 2) 다시 불러오기(표시): 스토리 원 156px WebP 변환
      final display = supabaseRenderUrl(storedUrl, width: 156, quality: 80);
      expect(display,
          '$base/storage/v1/render/image/public/book_covers/covers/9788934985907.jpg?width=156&height=468&resize=contain&quality=80');
    });

    test('레거시(네이버 URL 그대로 저장된 기존 책)는 표시 때도 원본 유지', () {
      const legacy = 'https://bookthumb-phinf.pstatic.net/cover/1.jpg?type=m1';
      expect(supabaseRenderUrl(legacy, width: 300), legacy);
    });
  });
}
