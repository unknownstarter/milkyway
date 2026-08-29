// 내부 숏튼(short-link) + OG 미리보기 + OS별 스토어 리다이렉트.
// 링크: https://<project-ref>.supabase.co/functions/v1/s/{code}
// 공개 접근 필요 -> 배포 시 `--no-verify-jwt` (JWT 없이 크롤러/브라우저 접근).
// 상세: docs/design/05-SHARE_ORB_SPEC.md §10
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
const PLAY = 'https://play.google.com/store/apps/details?id=com.whatif.milkyway.android';

const esc = (s: string) =>
  s.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c] as string));

Deno.serve(async (req) => {
  const url = new URL(req.url);
  const seg = url.pathname.split('/').filter(Boolean);
  const code = seg[seg.length - 1]; // 마지막 세그먼트 = 코드

  let tierName = '나만의';
  let img = '';
  if (code && code !== 's') {
    const { data } = await supabase
      .from('share_cards')
      .select('tier, image_path')
      .eq('code', code)
      .maybeSingle();
    if (data) {
      tierName = TIER_KO[data.tier as string] ?? '나만의';
      img = supabase.storage.from('share_cards').getPublicUrl(data.image_path as string).data.publicUrl;
    }
  }

  const title = `${tierName} 단계의 우주를 가지고 있어요`;
  const desc = '지금 책 메모하고 우주 만들기';
  const html = `<!doctype html><html lang="ko"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>milkyway</title>
<meta property="og:type" content="website">
<meta property="og:title" content="${esc(title)}">
<meta property="og:description" content="${esc(desc)}">
${img ? `<meta property="og:image" content="${esc(img)}">` : ''}
<meta name="twitter:card" content="summary_large_image">
<script>
  var ua = navigator.userAgent || '';
  if (/iPhone|iPad|iPod/i.test(ua)) location.replace('${APP_STORE}');
  else if (/Android/i.test(ua)) location.replace('${PLAY}');
</script>
<style>
  body{margin:0;background:#0a0a10;color:#fff;min-height:100vh;display:flex;flex-direction:column;
    align-items:center;justify-content:center;gap:20px;
    font-family:-apple-system,'Apple SD Gothic Neo','Pretendard',sans-serif}
  img{width:280px;border-radius:20px;box-shadow:0 20px 60px rgba(0,0,0,.5)}
  .wm{font-weight:800;letter-spacing:.2em}
  .st{display:flex;gap:16px}
  a{color:#8A7CFF;text-decoration:none;font-weight:700}
</style></head>
<body>
${img ? `<img src="${esc(img)}" alt="">` : ''}
<div class="wm">milkyway</div>
<div class="st"><a href="${APP_STORE}">App Store</a><a href="${PLAY}">Google Play</a></div>
</body></html>`;

  return new Response(html, {
    headers: {
      'content-type': 'text/html; charset=utf-8',
      'cache-control': 'public, max-age=300',
    },
  });
});
