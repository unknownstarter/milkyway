#!/usr/bin/env python3
# 밀키웨이 인스타 광고 v7 - 미션형. 컨셉: "하루에 메모 하나 남기기 = 가장 좋은 독서 습관".
# 연속 스트릭(미션 진행) 배지 + 따뜻한 앰버/새벽빛 배경(v6 파란 은하수와 차별).
# 컴포지션 원칙 v6 계승: 상단/하단 앵커 + 일관 간격 스케일 + 안전여백 + 세이프존.
# 카피 룰: em/en-dash, 중간점, 곡선따옴표, 말줄임 금지. "당신" 금지. 느낌표 금지.
import os, subprocess, random

OUT = os.path.dirname(os.path.abspath(__file__))
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
if not os.path.exists(CHROME):
    CHROME = subprocess.check_output(
        ["bash", "-lc", "ls /Applications/Google\\ Chrome*.app/Contents/MacOS/Google\\ Chrome | head -1"]
    ).decode().strip()

ACCENT = "#FFC978"       # 따뜻한 앰버
ARGB = "255,201,120"
INK = "#1d1406"          # CTA 위 진한 텍스트

def stars(w, h):
    random.seed(5); o = []
    n = int(w * h / 1400)
    for _ in range(n):
        x = random.randint(0, w); y = random.randint(0, h)
        if not ((x / w) > 0.5 and (y / h) < 0.5):
            if random.random() < 0.7:
                continue
        r = random.choice([1, 1, 2])
        op = random.choice([0.2, 0.32, 0.45])
        col = "#FFE6C0" if random.random() < 0.4 else "#FFFFFF"
        o.append(f"<div class='st' style='left:{x}px;top:{y}px;width:{r}px;height:{r}px;opacity:{op};background:{col}'></div>")
    return "".join(o)

def mag(sz, col="#A8988A"):
    s = sz
    return (f"<svg width='{s}' height='{s}' viewBox='0 0 24 24' fill='none' "
            f"stroke='{col}' stroke-width='2.4' stroke-linecap='round'>"
            f"<circle cx='11' cy='11' r='7'/><line x1='20.5' y1='20.5' x2='16.5' y2='16.5'/></svg>")

def dots(on, total, d):
    o = []
    for i in range(total):
        cls = "dot on" if i < on else "dot"
        o.append(f"<span class='{cls}' style='width:{d}px;height:{d}px'></span>")
    return "".join(o)

def html(W, H, L):
    return f"""<!doctype html><html><head><meta charset='utf-8'><style>
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:{W}px;height:{H}px;overflow:hidden}}
body{{font-family:'Apple SD Gothic Neo','Pretendard',sans-serif;
 background:
  radial-gradient(88% 66% at 84% 10%, rgba(224,160,74,.32), rgba(15,12,10,0) 58%),
  radial-gradient(70% 50% at 16% 98%, rgba(120,90,200,.10), rgba(15,12,10,0) 60%),
  linear-gradient(180deg,#100c0a 0%,#120e0b 55%,#0f0c0b 100%);}}
.stage{{position:relative;width:{W}px;height:{H}px;overflow:hidden}}
.st{{position:absolute;border-radius:50%}}
.scrim{{position:absolute;left:0;bottom:0;width:80%;height:64%;
 background:radial-gradient(115% 100% at 0% 100%, rgba(12,9,7,.86), rgba(12,9,7,0) 62%)}}
.glow{{position:absolute;right:{L['glow_r']}px;top:{L['glow_t']}px;
 width:{L['glow']}px;height:{L['glow']}px;border-radius:50%;
 background:radial-gradient(circle,rgba({ARGB},.34),rgba(224,160,74,.10) 46%,rgba(15,12,10,0) 70%);
 filter:blur(8px)}}
.wm{{position:absolute;left:{L['mx']}px;top:{L['top']}px;color:#EFE7DD;font-weight:700;
 letter-spacing:.32em;font-size:{L['wm']}px}}
.copytop{{position:absolute;left:{L['mx']}px;top:{L['copytop']}px;
 display:flex;flex-direction:column;align-items:flex-start;max-width:{L['maxw']}px}}
.mission{{display:flex;align-items:center;gap:{L['mgap']}px;margin-bottom:{L['g_mh']}px}}
.mtag{{color:{ACCENT};font-weight:700;font-size:{L['tag']}px;letter-spacing:.01em;
 background:rgba({ARGB},.12);border:1.5px solid rgba({ARGB},.4);
 padding:{L['tag_py']}px {L['tag_px']}px;border-radius:999px}}
.dotrow{{display:inline-flex;align-items:center;gap:{L['dotgap']}px}}
.dot{{border-radius:50%;border:1.5px solid rgba(255,255,255,.22)}}
.dot.on{{background:{ACCENT};border-color:{ACCENT};box-shadow:0 0 10px rgba({ARGB},.55)}}
.mcount{{color:#D8CDBE;font-weight:700;font-size:{L['tag']}px}}
.head{{color:#fff;font-weight:800;line-height:1.13;letter-spacing:-.04em;
 font-size:{L['head']}px;margin-bottom:{L['g_hs']}px}}
.sub{{color:#C6BBAD;font-weight:600;line-height:1.42;letter-spacing:-.01em;font-size:{L['sub']}px}}
.accent{{color:{ACCENT}}}
.copybot{{position:absolute;left:{L['mx']}px;bottom:{L['bottom']}px;
 display:flex;flex-direction:column;align-items:flex-start}}
.cta{{display:inline-flex;align-items:center;gap:{L['cta_gap']}px;background:{ACCENT};color:{INK};
 font-weight:800;font-size:{L['cta']}px;padding:{L['cta_py']}px {L['cta_px']}px;
 border-radius:999px;box-shadow:0 14px 44px rgba({ARGB},.28);margin-bottom:{L['g_cs']}px}}
.arw{{font-weight:800}}
.hint{{display:inline-flex;align-items:center;gap:10px;color:#A8988A;
 font-weight:600;font-size:{L['store']}px;letter-spacing:.01em}}
.hint svg{{display:block}}
.hint .b{{color:#CBC0B2;font-weight:700}}
.hint .s{{color:#6b6055;padding:0 7px}}
</style></head><body>
<div class='stage'>
{stars(W,H)}
<div class='glow'></div>
<div class='scrim'></div>
<div class='wm'>milkyway</div>
<div class='copytop'>
  <div class='mission'>
    <span class='mtag'>이번 주 메모 남긴 날</span>
    <span class='dotrow'>{dots(5,7,L['dot'])}</span>
    <span class='mcount'>5일</span>
  </div>
  <div class='head'>{L['head_html']}</div>
  <div class='sub'>{L['sub_html']}</div>
</div>
<div class='copybot'>
  <div class='cta'>무료로 시작하기 <span class='arw'>&rsaquo;</span></div>
  <div class='hint'>{L['mag']}<span class='b'>App Store</span><span class='s'>/</span><span class='b'>Google Play</span> 에 milkyway 검색</div>
</div>
</div>
</body></html>"""

HEAD = "하루에 메모 하나,<br>남기기"
SUB = "그렇게 쌓이는<br><span class='accent'>가장 좋은 독서 습관</span>"

LAYOUTS = {
  "square": dict(W=1080, H=1080, mx=90, top=80, copytop=214, bottom=107, maxw=900,
    wm=26, head=120, sub=46, cta=36, store=23,
    mgap=14, g_mh=34, tag=22, tag_py=9, tag_px=18, dot=14, dotgap=9,
    g_hs=32, g_cs=22, cta_py=28, cta_px=52, cta_gap=14, mag=mag(26),
    glow=520, glow_r=-110, glow_t=60),
  "portrait": dict(W=1080, H=1350, mx=98, top=104, copytop=300, bottom=171, maxw=920,
    wm=28, head=132, sub=50, cta=38, store=24,
    mgap=15, g_mh=38, tag=23, tag_py=10, tag_px=19, dot=15, dotgap=10,
    g_hs=36, g_cs=24, cta_py=30, cta_px=56, cta_gap=15, mag=mag(28),
    glow=560, glow_r=-120, glow_t=120),
  "story": dict(W=1080, H=1920, mx=104, top=300, copytop=520, bottom=560, maxw=960,
    wm=32, head=146, sub=56, cta=42, store=27,
    mgap=16, g_mh=42, tag=26, tag_py=11, tag_px=22, dot=17, dotgap=11,
    g_hs=40, g_cs=26, cta_py=34, cta_px=64, cta_gap=16, mag=mag(30),
    glow=620, glow_r=-140, glow_t=540),
}

for name, L in LAYOUTS.items():
    L = dict(L); L["head_html"] = HEAD; L["sub_html"] = SUB
    tmp = os.path.join(OUT, f"_adv7_{name}.html")
    out = os.path.join(OUT, f"v7_instagram_ad_{name}.png")
    with open(tmp, "w") as f:
        f.write(html(L["W"], L["H"], L))
    subprocess.run([CHROME, "--headless", "--disable-gpu", "--hide-scrollbars",
                    "--force-device-scale-factor=1", f"--window-size={L['W']},{L['H']}",
                    f"--screenshot={out}", f"file://{tmp}"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.remove(tmp)
    print("wrote", out)
