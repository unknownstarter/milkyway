// 내부 숏튼(short-link) + OG 미리보기 + 딥링크(커스텀 스킴) 랜딩.
//
// 공개 링크: https://mymilkyway.xyz/s/{code}
//   -> Cloudflare Worker(workers/share-landing)가 이 함수로 프록시한다.
//
// 왜 워커를 거치나: Supabase는 `*.supabase.co`에서 HTML 서빙을 막는다(피싱 방지).
// 여기서 `text/html`을 보내도 응답은 `text/plain` + `CSP: default-src 'none'; sandbox`로
// 강등돼 크롤러가 OG를 안 읽고 브라우저는 하얀 화면이 된다. 워커가 content-type을
// 되돌린다. **이 함수를 supabase.co 주소로 직접 열면 여전히 깨진다. 정상이다.**
//
// 공개 접근 필요 -> 배포 시 `--no-verify-jwt` (JWT 없이 크롤러/브라우저 접근).
// 동작:
//   - 크롤러(카톡/페북/X): JS 미실행 -> OG 메타만 읽어 미리보기.
//   - 실유저 모바일: 본문을 먼저 그린 뒤 앱 열기 시도. 미설치면 스토어로 폴백.
//   - 인앱 브라우저(카톡/인스타/라인 등): 커스텀 스킴 자동 이동이 차단돼 화면이 죽으므로
//     자동 이동을 하지 않고 버튼 탭(사용자 제스처)으로만 연다.
// 디퍼드 딥링크(미설치->설치후 카드)는 미채택 -> 지문(IP/UA) 수집 안 함.
// 상세: docs/design/07-DEEP_LINK.md
import { createClient } from 'npm:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error('환경 변수가 설정되지 않았습니다. Supabase 설정을 확인하세요.');
}
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

const TIER_KO: Record<string, string> = {
  t1: '작은 성운', t2: '별무리', t3: '별자리', t4: '성단', t5: '은하', t6: '대은하',
};
const APP_STORE = 'https://apps.apple.com/kr/app/id6741465148';
const ANDROID_PACKAGE = 'com.whatif.milkyway.android';
const PLAY_BASE = `https://play.google.com/store/apps/details?id=${ANDROID_PACKAGE}`;
// 워커가 x-public-origin을 못 넘긴 경우의 폴백(og:url용).
const PUBLIC_ORIGIN_FALLBACK = 'https://mymilkyway.xyz';

const esc = (s: string) =>
  s.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c] as string));

Deno.serve(async (req) => {
  const url = new URL(req.url);
  const seg = url.pathname.split('/').filter(Boolean);
  const code = seg[seg.length - 1]; // 마지막 세그먼트 = 코드
  const origin = req.headers.get('x-public-origin') || PUBLIC_ORIGIN_FALLBACK;

  let tierName = '나만의';
  let img = '';
  let payload: Record<string, unknown> | null = null;
  const hasCode = !!code && code !== 's';
  if (hasCode) {
    const { data } = await supabase
      .from('share_cards')
      .select('tier, image_path, payload')
      .eq('code', code)
      .maybeSingle();
    if (data) {
      tierName = TIER_KO[data.tier as string] ?? '나만의';
      img = supabase.storage.from('share_cards').getPublicUrl(data.image_path as string).data.publicUrl;
      payload = (data.payload as Record<string, unknown> | null) ?? null;
    }
  }

  // 공유 종류별 OG. 회고(wrapped)면 회고 문구, 아니면 오브 티어 문구.
  const isWrapped = !!payload && payload.kind === 'wrapped';
  const period = isWrapped ? String(payload!.period ?? '') : '';
  const title = isWrapped
    ? (period ? `${period} 은하 회고` : '나의 은하 회고')
    : `${tierName} 단계의 우주를 가지고 있어요`;
  const desc = isWrapped
    ? '한 달 동안 멈춘 순간들'
    : '지금 책 메모하고 우주 만들기';
  // 회고면 OG 썸네일 = 책 표지(payload.cover_url). 없으면 위에서 잡은 정적 오브 이미지 폴백.
  if (isWrapped && payload && payload.cover_url) {
    img = String(payload.cover_url);
  }

  const pageUrl = `${origin}/s/${hasCode ? code : ''}`;
  const iosScheme = hasCode ? `milkyway://card/${code}` : 'milkyway://';
  // 안드로이드는 intent:// 가 인앱 브라우저에서도 상대적으로 잘 열리고,
  // 미설치 시 browser_fallback_url로 알아서 스토어에 떨군다.
  const andIntent = `intent://card/${hasCode ? code : ''}#Intent;scheme=milkyway;` +
    `package=${ANDROID_PACKAGE};S.browser_fallback_url=${encodeURIComponent(PLAY_BASE)};end`;

  const html = `<!doctype html><html lang="ko"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(title)} - milkyway</title>
<meta name="description" content="${esc(desc)}">
<link rel="canonical" href="${esc(pageUrl)}">
<meta property="og:type" content="website">
<meta property="og:site_name" content="milkyway">
<meta property="og:locale" content="ko_KR">
<meta property="og:url" content="${esc(pageUrl)}">
<meta property="og:title" content="${esc(title)}">
<meta property="og:description" content="${esc(desc)}">
${img ? `<meta property="og:image" content="${esc(img)}">
<meta property="og:image:secure_url" content="${esc(img)}">
<meta property="og:image:alt" content="${esc(title)}">` : ''}
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="${esc(title)}">
<meta name="twitter:description" content="${esc(desc)}">
${img ? `<meta name="twitter:image" content="${esc(img)}">` : ''}
<style>
  body{margin:0;background:#0a0a10;color:#fff;min-height:100vh;display:flex;flex-direction:column;
    align-items:center;justify-content:center;gap:20px;padding:40px 24px;box-sizing:border-box;
    font-family:-apple-system,'Apple SD Gothic Neo','Pretendard',sans-serif;text-align:center}
  img.card{width:min(260px,70vw);border-radius:20px;box-shadow:0 20px 60px rgba(0,0,0,.5)}
  .wm{font-weight:800;letter-spacing:.2em;font-size:14px;color:#B9B9C6}
  h1{font-size:20px;font-weight:700;margin:0;line-height:1.45;letter-spacing:-.02em}
  p.sub{margin:0;font-size:14px;color:#9A9AA8}
  .open{display:inline-block;padding:15px 30px;border-radius:999px;background:#8A7CFF;color:#fff;
    text-decoration:none;font-weight:800;font-size:16px}
  .hint{font-size:13px;color:#8A8A98;line-height:1.6;max-width:300px;display:none}
  .st{display:flex;gap:18px;font-size:13px}
  .st a{color:#8A7CFF;text-decoration:none;font-weight:700}
</style></head>
<body>
${img ? `<img class="card" src="${esc(img)}" alt="${esc(title)}">` : ''}
<div class="wm">MILKYWAY</div>
<h1>${esc(title)}</h1>
<p class="sub">${esc(desc)}</p>
<a class="open" id="open" href="${esc(iosScheme)}">앱에서 열기</a>
<div class="hint" id="hint">카카오톡 안에서는 앱이 바로 안 열릴 수 있어요<br>오른쪽 아래 메뉴에서 다른 브라우저로 열어주세요</div>
<div class="st"><a href="${esc(APP_STORE)}">App Store</a><a href="${esc(PLAY_BASE)}">Google Play</a></div>
<script>
  (function () {
    var ua = navigator.userAgent || '';
    var isIOS = /iPhone|iPad|iPod/i.test(ua);
    var isAnd = /Android/i.test(ua);
    // 인앱 웹뷰(카톡/인스타/페북/라인/네이버/다음). 커스텀 스킴 자동 이동이 막혀서
    // location.href를 때리면 페이지가 그대로 죽는다(하얀 화면). 자동 이동 금지.
    var inApp = /KAKAOTALK|Instagram|FBAN|FBAV|FB_IAB|Line\\/|NAVER|DaumApps|everytimeApp/i.test(ua);

    var open = document.getElementById('open');
    var link = isAnd ? ${JSON.stringify(andIntent)} : ${JSON.stringify(iosScheme)};
    open.setAttribute('href', link);

    if (inApp) {
      document.getElementById('hint').style.display = 'block';
      return; // 본문은 그대로 보여준다. 여는 건 사용자가 버튼을 눌렀을 때만.
    }
    if (!isIOS && !isAnd) return; // 데스크톱은 스토어 링크만 보여주면 된다.

    // 일반 모바일 브라우저: 본문을 그린 뒤 한 박자 늦게 앱 열기 시도.
    // 앱이 열리면 페이지가 백그라운드로 가므로 스토어 이동을 취소한다.
    setTimeout(function () {
      var store = isIOS ? ${JSON.stringify(APP_STORE)} : ${JSON.stringify(PLAY_BASE)};
      var t = Date.now();
      var timer = setTimeout(function () {
        if (!document.hidden && Date.now() - t < 2500) location.replace(store);
      }, 1400);
      document.addEventListener('visibilitychange', function () {
        if (document.hidden) clearTimeout(timer);
      });
      location.href = link;
    }, 250);
  })();
</script>
</body></html>`;

  return new Response(html, {
    headers: {
      // supabase.co 직접 접근이면 플랫폼이 text/plain으로 강등한다(어쩔 수 없음).
      // 워커를 거치면 워커가 이 값으로 되돌려준다.
      'content-type': 'text/html; charset=utf-8',
      'cache-control': 'public, max-age=300',
    },
  });
});
