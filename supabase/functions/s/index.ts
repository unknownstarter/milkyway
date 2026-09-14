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
// 랜딩은 앱의 '내 우주' 화면을 최대한 그대로 옮긴다(별 배경 + 오브 + 배지 + 헤드라인 +
// 스탯 4칸 + 진행바). 숫자는 발행 시 share_cards.payload에 실어둔 스냅샷을 쓴다.
// 상세: docs/design/07-DEEP_LINK.md
import { createClient } from 'npm:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error('환경 변수가 설정되지 않았습니다. Supabase 설정을 확인하세요.');
}
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

const TIERS = ['t1', 't2', 't3', 't4', 't5', 't6'] as const;
const TIER_KO: Record<string, string> = {
  t1: '작은 성운', t2: '별무리', t3: '별자리', t4: '성단', t5: '은하', t6: '대은하',
};
// lib/features/orb/presentation/widgets/orb_palette.dart 와 동일해야 한다.
const TIER_ACCENT: Record<string, string> = {
  t1: '#9DB4FF', t2: '#A99CFF', t3: '#9A8CFF',
  t4: '#C48CFF', t5: '#FF9ECB', t6: '#FFC24D',
};
// lib/features/orb/domain/orb_tier.dart 의 lo 값과 동일해야 한다.
const TIER_LO: Record<string, number> = {
  t1: 0, t2: 30, t3: 90, t4: 200, t5: 500, t6: 1000,
};

const APP_STORE = 'https://apps.apple.com/kr/app/id6741465148';
const ANDROID_PACKAGE = 'com.whatif.milkyway.android';
const PLAY_BASE = `https://play.google.com/store/apps/details?id=${ANDROID_PACKAGE}`;
const PUBLIC_ORIGIN_FALLBACK = 'https://mymilkyway.xyz';

const esc = (s: string) =>
  s.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c] as string));

/// 받침에 따라 이/가 를 고른다. "별무리이 됐어요" 같은 게 나오면 안 된다.
const iga = (word: string) => {
  const c = word.charCodeAt(word.length - 1);
  const hasJong = c >= 0xac00 && c <= 0xd7a3 && (c - 0xac00) % 28 !== 0;
  return hasJong ? '이' : '가';
};

const num = (v: unknown, d = 0) => {
  const n = Number(v);
  return Number.isFinite(n) ? n : d;
};

/// 코드에서 결정적으로 별 배경을 만든다(새로고침해도 같은 하늘).
function starField(seed: string): string {
  let h = 2166136261;
  for (let i = 0; i < seed.length; i++) {
    h ^= seed.charCodeAt(i);
    h = Math.imul(h, 16777619) >>> 0;
  }
  const rnd = () => {
    h ^= h << 13; h >>>= 0;
    h ^= h >> 17;
    h ^= h << 5; h >>>= 0;
    return h / 4294967296;
  };
  let out = '';
  for (let i = 0; i < 90; i++) {
    const x = (rnd() * 100).toFixed(2);
    const y = (rnd() * 100).toFixed(2);
    const s = (rnd() * 1.6 + 0.6).toFixed(2);
    const o = (rnd() * 0.55 + 0.15).toFixed(2);
    out += `<i style="left:${x}%;top:${y}%;width:${s}px;height:${s}px;opacity:${o}"></i>`;
  }
  return out;
}

Deno.serve(async (req) => {
  const url = new URL(req.url);
  const seg = url.pathname.split('/').filter(Boolean);
  const code = seg[seg.length - 1];
  const origin = req.headers.get('x-public-origin') || PUBLIC_ORIGIN_FALLBACK;

  let tier = 't1';
  // 페이지 본문에 쓰는 오브(투명 배경 아님 -> CSS 마스크로 처리)와
  // OG 썸네일(단계명/워드마크가 얹힌 1200x630 카드)은 다른 이미지다.
  let orbImg = '';
  let payload: Record<string, unknown> | null = null;
  const hasCode = !!code && code !== 's';
  if (hasCode) {
    const { data } = await supabase
      .from('share_cards')
      .select('tier, image_path, payload')
      .eq('code', code)
      .maybeSingle();
    if (data) {
      tier = TIERS.includes(data.tier as typeof TIERS[number]) ? (data.tier as string) : 't1';
      orbImg = supabase.storage.from('share_cards')
        .getPublicUrl(data.image_path as string).data.publicUrl;
      payload = (data.payload as Record<string, unknown> | null) ?? null;
    }
  }
  const tierName = TIER_KO[tier];
  const accent = TIER_ACCENT[tier];

  const isWrapped = !!payload && payload.kind === 'wrapped';
  const period = isWrapped ? String(payload!.period ?? '') : '';

  // 스탯 스냅샷(오브 공유에만 실린다). 구버전 링크는 payload가 없어 이 블록을 건너뛴다.
  const hasStats = !!payload && payload.kind === 'orb';
  const books = hasStats ? num(payload!.books) : 0;
  const memos = hasStats ? num(payload!.memos) : 0;
  const topPercent = hasStats && payload!.top_percent != null ? num(payload!.top_percent) : null;
  const streakDays = hasStats ? num(payload!.streak_days) : 0;
  const pointsToNext = hasStats && payload!.points_to_next != null
    ? num(payload!.points_to_next) : null;

  // 친구가 카톡에서 받는 카드다. 단계만 알리는 상태 보고("성단 단계의 우주를
  // 가지고 있어요")는 아무 감흥이 없어서, 숫자로 변화를 보여주는 쪽으로 바꿨다.
  // 스탯이 없는 구버전 링크는 숫자 없이 같은 구조로 폴백.
  // 백분위가 제일 세게 꽂힌다(자랑). 없으면 메모 수, 그것도 없으면 단계만.
  // 상위 N%는 익명 백분위라 '인기 메모 랭킹' 영구금지에 걸리지 않는다(VISION v3 §6.2).
  const title = isWrapped
    ? (period ? `${period}, 멈춘 순간들이 은하가 됐어요` : '멈춘 순간들이 은하가 됐어요')
    : hasStats && topPercent !== null && topPercent > 0
      ? `상위 ${topPercent}%, ${tierName}까지 왔어요`
      : hasStats
        ? `메모 ${memos}개가 모여 ${tierName}${iga(tierName)} 됐어요`
        : `책 읽다 멈춘 순간이 ${tierName}${iga(tierName)} 됐어요`;
  const desc = isWrapped
    ? '한 달 동안 멈춘 자리마다 별 하나 - 내 우주도 만들어보기'
    : '멈춰서 남긴 한 줄이 별이 되는 곳 - 내 우주도 만들어보기';

  // OG 썸네일: 회고는 책 표지, 오브는 티어 카드(og/{tier}.jpg).
  // 예전엔 og:image가 맨 구슬 사진이라 카톡 미리보기에 보라색 공만 떴다.
  let ogImg = supabase.storage.from('share_cards')
    .getPublicUrl(`og/${tier}.jpg`).data.publicUrl;
  if (isWrapped && payload && payload.cover_url) ogImg = String(payload.cover_url);


  const idx = TIERS.indexOf(tier as typeof TIERS[number]);
  const nextTier = idx < TIERS.length - 1 ? TIERS[idx + 1] : null;
  // 앱의 진행바와 같은 계산: 현재 구간에서 얼마나 왔나.
  let band = 1;
  if (hasStats && nextTier) {
    const pts = memos * 3 + books;
    const lo = TIER_LO[tier];
    const hi = TIER_LO[nextTier];
    band = Math.min(1, Math.max(0.04, (pts - lo) / (hi - lo)));
  }

  const pageUrl = `${origin}/s/${hasCode ? code : ''}`;
  const iosScheme = hasCode ? `milkyway://card/${code}` : 'milkyway://';
  const andIntent = `intent://card/${hasCode ? code : ''}#Intent;scheme=milkyway;` +
    `package=${ANDROID_PACKAGE};S.browser_fallback_url=${encodeURIComponent(PLAY_BASE)};end`;

  const statCell = (value: string, unit: string, label: string, color: string) =>
    `<div class="cell"><div class="v" style="color:${color}">${esc(value)}<span class="u">${esc(unit)}</span></div>
     <div class="l">${esc(label)}</div></div>`;

  const body = isWrapped
    ? `${ogImg ? `<img class="cover" src="${esc(ogImg)}" alt="${esc(title)}">` : ''}
       <h1>${esc(title)}</h1><p class="sub">${esc(desc)}</p>`
    : `<div class="orbwrap">${orbImg ? `<img class="orb" src="${esc(orbImg)}" alt="${esc(tierName)} 오브">` : ''}</div>
       <div class="badge" style="color:${accent};border-color:${accent}80;background:${accent}22">
         <span class="dot" style="background:${accent}"></span>${esc(tierName)} 단계</div>
       <h1>지금은 <b style="color:${accent}">${esc(tierName)}</b></h1>
       ${hasStats ? `<div class="stats">
         ${statCell(String(books), '권', '읽은 책', '#ECECEC')}<div class="div"></div>
         ${statCell(String(memos), '개', '남긴 메모', '#ECECEC')}<div class="div"></div>
         ${statCell(topPercent === null ? '-' : String(topPercent), '%', '상위', accent)}<div class="div"></div>
         ${statCell(String(streakDays), '일', '연속', '#ECECEC')}
       </div>
       <div class="bar"><span style="width:${(band * 100).toFixed(1)}%;background:${accent}"></span></div>
       <p class="next">${nextTier && pointsToNext !== null
        ? `다음 단계 ${esc(TIER_KO[nextTier])}까지 <b style="color:${accent}">${pointsToNext}</b>`
        : '가장 깊은 우주에 도달'}</p>` : `<p class="sub">${esc(desc)}</p>`}`;

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
${ogImg ? `<meta property="og:image" content="${esc(ogImg)}">
<meta property="og:image:secure_url" content="${esc(ogImg)}">
${isWrapped ? '' : `<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">`}
<meta property="og:image:alt" content="${esc(title)}">` : ''}
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="${esc(title)}">
<meta name="twitter:description" content="${esc(desc)}">
${ogImg ? `<meta name="twitter:image" content="${esc(ogImg)}">` : ''}
<style>
  *{box-sizing:border-box}
  body{margin:0;background:#08080E;color:#ECECEC;min-height:100vh;
    font-family:-apple-system,'Apple SD Gothic Neo','Pretendard','Noto Sans KR',sans-serif;
    display:flex;flex-direction:column;align-items:center;position:relative;overflow-x:hidden}
  .sky{position:fixed;inset:0;pointer-events:none}
  .sky i{position:absolute;background:#fff;border-radius:50%}
  main{position:relative;width:100%;max-width:420px;padding:28px 20px 40px;text-align:center}
  .wm{font-weight:800;letter-spacing:.2em;font-size:12px;color:#8A8A98;margin-bottom:18px}
  .orbwrap{display:flex;justify-content:center}
  /* 오브 jpg는 배경이 투명이 아니라서 그냥 얹으면 사각 테두리가 보인다.
     원형 마스크로 가장자리를 페이드아웃시켜 배경에 녹인다.
     (screen 블렌드는 jpg 배경이 순수 검정이 아니라 오히려 더 밝아진다) */
  .orb{width:min(330px,80vw);height:auto;display:block;
    -webkit-mask-image:radial-gradient(circle at 50% 50%,#000 60%,transparent 72%);
    mask-image:radial-gradient(circle at 50% 50%,#000 60%,transparent 72%)}
  .cover{width:min(240px,62vw);border-radius:16px;box-shadow:0 20px 60px rgba(0,0,0,.5)}
  .badge{display:inline-flex;align-items:center;gap:8px;margin-top:14px;padding:6px 14px;
    border-radius:999px;border:1px solid;font-size:13px;font-weight:700}
  .dot{width:7px;height:7px;border-radius:50%}
  h1{margin:12px 0 0;font-size:29px;font-weight:800;letter-spacing:-.03em;line-height:1.15}
  h1 b{font-weight:800}
  p.sub{margin:10px 0 0;color:#9A9AA8;font-size:14px}
  .stats{display:flex;align-items:center;margin-top:20px;padding:16px 4px;border-radius:18px;
    background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08)}
  .cell{flex:1}
  .v{font-size:24px;font-weight:800;letter-spacing:-.03em;line-height:1.05}
  .v .u{font-size:13px;font-weight:700;color:#B9B9C6;margin-left:2px}
  .l{margin-top:6px;font-size:12px;color:#8A8A98}
  .div{width:1px;height:32px;background:rgba(255,255,255,.08)}
  .bar{margin-top:16px;height:8px;border-radius:999px;background:rgba(255,255,255,.08);overflow:hidden}
  .bar span{display:block;height:100%;border-radius:999px}
  .next{margin:12px 0 0;font-size:13px;color:#9A9AA8}
  .open{display:block;margin-top:26px;padding:16px;border-radius:16px;background:#8A7CFF;color:#fff;
    text-decoration:none;font-weight:800;font-size:16px}
  .hint{display:none;margin-top:12px;font-size:12.5px;color:#8A8A98;line-height:1.6}
  .st{display:flex;gap:18px;justify-content:center;margin-top:18px;font-size:13px}
  .st a{color:#8A7CFF;text-decoration:none;font-weight:700}
</style></head>
<body>
<div class="sky">${starField(hasCode ? code : 'milkyway')}</div>
<main>
  <div class="wm">MILKYWAY</div>
  ${body}
  <a class="open" id="open" href="${esc(iosScheme)}">앱에서 열기</a>
  <div class="hint" id="hint">카카오톡 안에서는 앱이 바로 안 열릴 수 있어요<br>오른쪽 아래 메뉴에서 다른 브라우저로 열어주세요</div>
  <div class="st"><a href="${esc(APP_STORE)}">App Store</a><a href="${esc(PLAY_BASE)}">Google Play</a></div>
</main>
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
    if (!isIOS && !isAnd) return;

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
      'content-type': 'text/html; charset=utf-8',
      'cache-control': 'public, max-age=300',
    },
  });
});
