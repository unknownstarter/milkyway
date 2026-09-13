/**
 * 공유 링크 랜딩 프록시.
 *
 * 왜 필요한가: Supabase는 `*.supabase.co`에서 HTML 서빙을 막는다(피싱 방지).
 * 엣지 함수가 `text/html`을 보내도 응답은 `text/plain` + `CSP: default-src 'none'; sandbox`로
 * 강등돼서 (1) 카톡/페북 크롤러가 OG 태그를 안 읽고 (2) 인앱 웹뷰가 하얀 화면이 된다.
 * 엣지 함수뿐 아니라 Storage도 동일하게 막힌다(실측 확인).
 *
 * 이 워커가 하는 일은 하나뿐이다: 엣지 함수 응답을 받아 content-type을 text/html로
 * 되돌리고 강등용 헤더를 떼어낸 뒤 우리 도메인에서 내보낸다.
 *
 *   https://mymilkyway.xyz/s/{code}  ->  {SUPABASE_URL}/functions/v1/s/{code}
 *
 * 부수효과로 Supabase 프로젝트 ref가 사용자에게 안 보인다.
 */

// 강등/차단용으로 Supabase가 붙이는 헤더. 그대로 흘리면 워커를 거쳐도 화면이 죽는다.
const STRIP = [
  'content-security-policy',
  'content-security-policy-report-only',
  'x-content-type-options',
  'content-disposition',
];

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // 헬스체크: DNS/라우트가 붙었는지 브라우저로 바로 확인용.
    if (url.pathname === '/healthz') {
      return new Response('ok', {
        headers: { 'content-type': 'text/plain; charset=utf-8' },
      });
    }

    const m = url.pathname.match(/^\/s\/([A-Za-z0-9_-]{1,32})\/?$/);
    if (!m) {
      // 공유 링크가 아닌 경로는 홈으로. (추후 랜딩 페이지가 생기면 여기를 바꾼다)
      return Response.redirect('https://apps.apple.com/kr/app/id6741465148', 302);
    }
    const code = m[1];

    const upstream = `${env.SUPABASE_URL}/functions/v1/s/${code}`;
    let res;
    try {
      res = await fetch(upstream, {
        // UA를 넘겨야 엣지 함수가 크롤러/실유저를 구분할 수 있다.
        headers: {
          'user-agent': request.headers.get('user-agent') ?? '',
          'accept-language': request.headers.get('accept-language') ?? '',
          // 엣지 함수가 og:url 등 절대 URL을 만들 때 쓴다.
          'x-public-origin': url.origin,
        },
        cf: { cacheTtl: 60, cacheEverything: false },
      });
    } catch {
      return new Response('일시적인 오류입니다. 잠시 후 다시 시도해 주세요.', {
        status: 502,
        headers: { 'content-type': 'text/plain; charset=utf-8' },
      });
    }

    const body = await res.text();
    const headers = new Headers();
    for (const [k, v] of res.headers) {
      if (!STRIP.includes(k.toLowerCase())) headers.set(k, v);
    }
    // 핵심 한 줄. 이게 없으면 브라우저도 크롤러도 이 페이지를 HTML로 취급하지 않는다.
    headers.set('content-type', 'text/html; charset=utf-8');
    headers.set('cache-control', 'public, max-age=300');
    headers.set('referrer-policy', 'no-referrer-when-downgrade');

    return new Response(body, { status: res.status, headers });
  },
};
