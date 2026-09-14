#!/usr/bin/env python3
# 밀키웨이 인스타 광고 v6 - v5 카피/컨셉 유지, 컴포지션만 정석으로 재정렬.
# 원칙(리서치): 일관된 간격 스케일 · 안전여백 · 하단 앵커 카피블록(flex) · 네거티브스페이스 · 스토리 하단 세이프존 회피.
# 카피 룰: em/en-dash, 중간점, 곡선따옴표, 말줄임 금지. "당신" 금지. 느낌표 금지.
import os, subprocess, random

OUT = os.path.dirname(os.path.abspath(__file__))
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
if not os.path.exists(CHROME):
    CHROME = subprocess.check_output(
        ["bash", "-lc", "ls /Applications/Google\\ Chrome*.app/Contents/MacOS/Google\\ Chrome | head -1"]
    ).decode().strip()

GREEN = "#7DE7A0"

def stars(w, h):
    # 은하수는 오른편 밴드에 집중, 하단-왼쪽(카피 영역)은 비워 가독성 확보.
    random.seed(7); o = []
    n = int(w * h / 620)
    for _ in range(n):
        x = random.randint(0, w); y = random.randint(0, h)
        band_center = 0.60 + 0.30 * (y / h)
        d = abs((x / w) - band_center)
        in_band = d < 0.16
        right = (x / w) > 0.44
        keep = in_band or (right and random.random() < 0.26) or random.random() < 0.04
        if not keep:
            continue
        r = random.choice([1, 1, 1, 2, 2] + ([3, 3, 4] if in_band else []))
        op = random.choice([0.25, 0.4, 0.55, 0.72] + ([0.95] if in_band else []))
        col = "#CFE8FF" if random.random() < 0.16 else "#FFFFFF"
        glow = f";box-shadow:0 0 {r*3}px rgba(180,210,255,.65)" if r >= 3 else ""
        o.append(f"<div class='st' style='left:{x}px;top:{y}px;width:{r}px;height:{r}px;opacity:{op};background:{col}{glow}'></div>")
    return "".join(o)

def html(W, H, L):
    return f"""<!doctype html><html><head><meta charset='utf-8'><style>
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:{W}px;height:{H}px;overflow:hidden}}
body{{font-family:'Apple SD Gothic Neo','Pretendard',sans-serif;
 background:
  radial-gradient(85% 75% at 90% 24%, rgba(96,124,224,.42), rgba(10,11,18,0) 56%),
  radial-gradient(62% 55% at 76% 62%, rgba(74,176,142,.18), rgba(10,11,18,0) 60%),
  radial-gradient(55% 45% at 84% 90%, rgba(120,90,200,.16), rgba(10,11,18,0) 60%),
  linear-gradient(180deg,#0a0b11 0%,#0d0e14 55%,#0f1017 100%);}}
.stage{{position:relative;width:{W}px;height:{H}px;overflow:hidden}}
.st{{position:absolute;border-radius:50%}}
/* 하단-왼쪽 스크림: 카피 대비 확보 */
.scrim{{position:absolute;left:0;bottom:0;width:78%;height:66%;
 background:radial-gradient(115% 100% at 0% 100%, rgba(8,9,14,.86), rgba(8,9,14,0) 62%)}}
/* 은하수 코어 광채(오른편) */
.core{{position:absolute;right:{L['core_r']}px;top:{L['core_t']}px;
 width:{L['core']}px;height:{L['core']}px;border-radius:50%;
 background:radial-gradient(circle,rgba(190,205,255,.5),rgba(125,231,160,.10) 45%,rgba(10,11,18,0) 70%);
 filter:blur(6px)}}
.hero{{position:absolute;right:{L['hero_r']}px;top:{L['hero_t']}px;width:12px;height:12px;
 border-radius:50%;background:#fff;
 box-shadow:0 0 22px 6px rgba(125,231,160,.9),0 0 60px 16px rgba(125,231,160,.35)}}
/* 워드마크: 상단-왼쪽 세이프여백 앵커 */
.wm{{position:absolute;left:{L['mx']}px;top:{L['top']}px;color:#ECECEC;font-weight:700;
 letter-spacing:.32em;font-size:{L['wm']}px}}
/* 상단 카피 블록 - 헤드/서브를 위로 올려 앵커 */
.copytop{{position:absolute;left:{L['mx']}px;top:{L['copytop']}px;
 display:flex;flex-direction:column;align-items:flex-start;max-width:{L['maxw']}px}}
.head{{color:#fff;font-weight:800;line-height:1.13;letter-spacing:-.04em;
 font-size:{L['head']}px;margin-bottom:{L['g_hs']}px}}
.sub{{color:#C6CBD1;font-weight:600;line-height:1.42;letter-spacing:-.01em;
 font-size:{L['sub']}px}}
.accent{{color:{GREEN}}}
/* 하단 액션 블록 - 스토어 검색 유도 CTA */
.copybot{{position:absolute;left:{L['mx']}px;bottom:{L['bottom']}px;
 display:flex;flex-direction:column;align-items:flex-start}}
.cta{{display:inline-flex;align-items:center;gap:{L['cta_gap']}px;background:{GREEN};color:#0c130f;
 font-weight:800;font-size:{L['cta']}px;padding:{L['cta_py']}px {L['cta_px']}px;
 border-radius:999px;box-shadow:0 14px 44px rgba(125,231,160,.28);
 margin-bottom:{L['g_cs']}px}}
.arw{{font-weight:800}}
.hint{{display:inline-flex;align-items:center;gap:10px;color:#9199A1;
 font-weight:600;font-size:{L['store']}px;letter-spacing:.01em}}
.hint svg{{display:block}}
.hint .b{{color:#C6CBD1;font-weight:700}}
.hint .s{{color:#5C636B;padding:0 7px}}
</style></head><body>
<div class='stage'>
{stars(W,H)}
<div class='core'></div><div class='hero'></div>
<div class='scrim'></div>
<div class='wm'>milkyway</div>
<div class='copytop'>
  <div class='head'>{L['head_html']}</div>
  <div class='sub'>{L['sub_html']}</div>
</div>
<div class='copybot'>
  <div class='cta'>무료로 이용하기 <span class='arw'>&rsaquo;</span></div>
  <div class='hint'>{L['mag']}<span class='b'>App Store</span><span class='s'>/</span><span class='b'>Google Play</span> 에 milkyway 검색</div>
</div>
</div>
</body></html>"""

HEAD = "그 문장에서,<br>왜 멈췄을까요"
SUB = "그 자리에서 멈춘<br><span class='accent'>사람들의 이야기</span>"

# 간격 스케일: g_hs(헤드->서브 작게, 한 덩어리), g_cs(CTA->힌트 작게)
# copytop = 헤드 시작 y(위로 올림). 하단 CTA는 bottom 앵커.
def mag(sz, col="#9199A1"):  # 돋보기 아이콘
    s = sz
    return (f"<svg width='{s}' height='{s}' viewBox='0 0 24 24' fill='none' "
            f"stroke='{col}' stroke-width='2.4' stroke-linecap='round'>"
            f"<circle cx='11' cy='11' r='7'/><line x1='20.5' y1='20.5' x2='16.5' y2='16.5'/></svg>")

LAYOUTS = {
  "square": dict(W=1080, H=1080, mx=90, top=80, copytop=228, bottom=128, maxw=900,
    wm=26, head=126, sub=48, cta=36, store=23,
    g_hs=32, g_cs=22, cta_py=28, cta_px=52, cta_gap=14, mag=mag(26),
    core=520, core_r=-120, core_t=70, hero_r=250, hero_t=280),
  "portrait": dict(W=1080, H=1350, mx=98, top=104, copytop=310, bottom=193, maxw=920,
    wm=28, head=140, sub=52, cta=38, store=24,
    g_hs=36, g_cs=24, cta_py=30, cta_px=56, cta_gap=15, mag=mag(28),
    core=560, core_r=-130, core_t=150, hero_r=270, hero_t=370),
  # 스토리: 상단 14%(269)/하단 35%(672) 세이프존 회피
  "story": dict(W=1080, H=1920, mx=104, top=300, copytop=540, bottom=600, maxw=960,
    wm=32, head=154, sub=58, cta=42, store=27,
    g_hs=40, g_cs=26, cta_py=34, cta_px=64, cta_gap=16, mag=mag(30),
    core=620, core_r=-150, core_t=560, hero_r=300, hero_t=800),
}

for name, L in LAYOUTS.items():
    L = dict(L); L["head_html"] = HEAD; L["sub_html"] = SUB
    tmp = os.path.join(OUT, f"_adv6_{name}.html")
    out = os.path.join(OUT, f"v6_instagram_ad_{name}.png")
    with open(tmp, "w") as f:
        f.write(html(L["W"], L["H"], L))
    subprocess.run([CHROME, "--headless", "--disable-gpu", "--hide-scrollbars",
                    "--force-device-scale-factor=1", f"--window-size={L['W']},{L['H']}",
                    f"--screenshot={out}", f"file://{tmp}"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.remove(tmp)
    print("wrote", out)
