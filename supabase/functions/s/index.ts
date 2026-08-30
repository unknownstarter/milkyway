// 내부 숏튼(short-link) + OG 미리보기 + 딥링크(커스텀 스킴) 랜딩.
// 링크: https://<project-ref>.supabase.co/functions/v1/s/{code}
// 공개 접근 필요 -> 배포 시 `--no-verify-jwt` (JWT 없이 크롤러/브라우저 접근).
// 동작:
//   - 크롤러(카톡/페북/X): JS 미실행 -> OG 메타만 읽어 미리보기.
//   - 실유저 모바일: 앱 열기 시도(milkyway://card/{code}) -> 앱 뜨면 그 카드로,
//     미설치면 스토어로 폴백. iOS 디퍼드용 지문도 기록.
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
const PLAY_BASE = 'https://play.google.com/store/apps/details?id=com.whatif.milkyway.android';

const esc = (s: string) =>
  s.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c] as string));

// 크롤러/봇 UA는 지문 기록 제외(실유저만).
const isBot = (ua: string) =>
  /bot|crawler|spider|facebookexternalhit|slackbot|twitterbot|scrap|preview|whatsapp|line\//i.test(ua);

Deno.serve(async (req) => {
  const url = new URL(req.url);
  const seg = url.pathname.split('/').filter(Boolean);
  const code = seg[seg.length - 1]; // 마지막 세그먼트 = 코드

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

  // iOS 디퍼드용 지문 기록(실유저 모바일만, 실패해도 페이지엔 영향 없음).
  const ua = req.headers.get('user-agent') ?? '';
  if (hasCode && img && !isBot(ua)) {
    const ip = (req.headers.get('x-forwarded-for') ?? '').split(',')[0].trim();
    const lang = (req.headers.get('accept-language') ?? '').split(',')[0].trim();
    try {
      await supabase.from('deferred_clicks').insert({ code, ip, ua, lang });
    } catch (_) { /* noop */ }
  }

  const playUrl = PLAY_BASE + '&referrer=' + encodeURIComponent('orb_code=' + (hasCode ? code : ''));
  const scheme = hasCode ? `milkyway://card/${code}` : 'milkyway://';

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
  const html = `<!doctype html><html lang="ko"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>milkyway</title>
<meta property="og:type" content="website">
<meta property="og:title" content="${esc(title)}">
<meta property="og:description" content="${esc(desc)}">
${img ? `<meta property="og:image" content="${esc(img)}">` : ''}
<meta name="twitter:card" content="summary_large_image">
<script>
  var scheme = ${JSON.stringify(scheme)};
  var appStore = ${JSON.stringify(APP_STORE)};
  var play = ${JSON.stringify(playUrl)};
  var ua = navigator.userAgent || '';
  var isIOS = /iPhone|iPad|iPod/i.test(ua);
  var isAnd = /Android/i.test(ua);
  if (isIOS || isAnd) {
    var store = isIOS ? appStore : play;
    var t = Date.now();
    // 앱이 열리면 페이지가 백그라운드로 -> 스토어 이동 취소.
    var timer = setTimeout(function () {
      if (!document.hidden && Date.now() - t < 2500) location.replace(store);
    }, 1400);
    document.addEventListener('visibilitychange', function () {
      if (document.hidden) clearTimeout(timer);
    });
    // 앱 열기 시도(설치 시 그 카드로 랜딩).
    location.href = scheme;
  }
</script>
<style>
  body{margin:0;background:#0a0a10;color:#fff;min-height:100vh;display:flex;flex-direction:column;
    align-items:center;justify-content:center;gap:22px;padding:40px 24px;box-sizing:border-box;
    font-family:-apple-system,'Apple SD Gothic Neo','Pretendard',sans-serif}
  img{width:260px;border-radius:20px;box-shadow:0 20px 60px rgba(0,0,0,.5)}
  .wm{font-weight:800;letter-spacing:.2em}
  .open{display:inline-block;padding:14px 28px;border-radius:999px;background:#8A7CFF;color:#fff;
    text-decoration:none;font-weight:800;font-size:16px}
  .st{display:flex;gap:16px;font-size:14px}
  .st a{color:#8A7CFF;text-decoration:none;font-weight:700}
</style></head>
<body>
${img ? `<img src="${esc(img)}" alt="">` : ''}
<div class="wm">milkyway</div>
<a class="open" href="${esc(scheme)}">앱에서 열기</a>
<div class="st"><a href="${esc(APP_STORE)}">App Store</a><a href="${esc(playUrl)}">Google Play</a></div>
</body></html>`;

  return new Response(html, {
    headers: {
      'content-type': 'text/html; charset=utf-8',
      'cache-control': 'public, max-age=300',
    },
  });
});
