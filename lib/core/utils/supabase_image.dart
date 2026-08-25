/// Supabase Storage 이미지 전송 최적화 유틸(순수 함수 - 테스트 가능).
///
/// 원본은 우리 스토리지에 그대로 두고, 표시 시점에 on-the-fly 변환(render) 엔드포인트로
/// 바꿔 **표시폭 크기 + WebP**로 받는다(원본 수 MB -> 수 KB, CDN 엣지 캐시).
/// 외부(비-Supabase) URL은 변환 대상이 아니므로 그대로 반환.
library;

const String kSupabasePublicMarker = '/storage/v1/object/public/';
const String kSupabaseRenderMarker = '/storage/v1/render/image/public/';

/// 우리 Supabase Storage의 공개 오브젝트 URL인지.
bool isSupabasePublicObjectUrl(String url) =>
    url.contains(kSupabasePublicMarker);

/// [url]이 Supabase 공개 오브젝트면 render(변환) URL로 재작성.
/// - [width]가 null이면 변환 없이 원본 URL 그대로.
/// - 비-Supabase URL(네이버 등 외부)은 그대로 반환.
/// - 이미 쿼리스트링이 있으면 `&`로 이어붙임.
/// - [quality]는 1-100로 클램프.
String supabaseRenderUrl(String url, {int? width, int quality = 80}) {
  if (width == null || width <= 0) return url;
  if (!isSupabasePublicObjectUrl(url)) return url;
  final q = quality.clamp(1, 100);
  final rendered = url.replaceFirst(kSupabasePublicMarker, kSupabaseRenderMarker);
  final sep = rendered.contains('?') ? '&' : '?';
  // ⚠️ width 만 주면 Supabase가 높이를 원본 그대로 둬서 세로로 짓눌린 왜곡본을 반환한다.
  // 반드시 height + resize=contain 으로 **비율 보존**해야 함. height 는 넉넉히(width*3)
  // 줘서 사실상 폭 기준으로 바운드되게(대부분 이미지 aspect < 1:3) 한다. contain 은
  // 패딩 없이 비율대로 축소만 하므로 최종 표시 크롭은 Flutter BoxFit.cover 가 담당.
  return '$rendered${sep}width=$width&height=${width * 3}&resize=contain&quality=$q';
}

/// Supabase Storage에 재호스팅할 책 표지의 오브젝트 경로.
/// ISBN 기준으로 결정적(같은 책=같은 경로, 중복 업로드 없음). ISBN이 비면 null.
String? bookCoverStoragePath(String? isbn) {
  final trimmed = isbn?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  // ISBN에 공백(네이버는 "isbn10 isbn13" 두 개를 공백으로 줌)이 있으면 첫 토큰만.
  final token = trimmed.split(RegExp(r'\s+')).first;
  final safe = token.replaceAll(RegExp(r'[^0-9Xx]'), '');
  if (safe.isEmpty) return null;
  return 'covers/$safe.jpg';
}
