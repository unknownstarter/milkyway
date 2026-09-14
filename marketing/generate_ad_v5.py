#!/usr/bin/env python3
# 밀키웨이 인스타 광고 v5 - 왼쪽 정렬/큰 타이포 + 은하수 오른편 집중 + CTA 버튼.
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
    # 오른편(은하수 밴드)에 집중. 대각선 우측 밴드 + 우측 산포.
    random.seed(7); o = []
    n = int(w * h / 620)
    for _ in range(n):
        x = random.randint(0, w); y = random.randint(0, h)
        # 우상->우하 대각선 밴드(중심선 x ~ 0.62~0.92)
        band_center = 0.60 + 0.30 * (y / h)
        d = abs((x / w) - band_center)
        in_band = d < 0.16
        right = (x / w) > 0.42
        # 왼쪽/밴드 밖은 확 줄임(카피 가독성)
        keep = in_band or (right and random.random() < 0.28) or random.random() < 0.05
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
  radial-gradient(85% 75% at 90% 26%, rgba(96,124,224,.42), rgba(10,11,18,0) 56%),
  radial-gradient(62% 55% at 74% 66%, rgba(74,176,142,.18), rgba(10,11,18,0) 60%),
  radial-gradient(55% 45% at 82% 92%, rgba(120,90,200,.16), rgba(10,11,18,0) 60%),
  linear-gradient(180deg,#0a0b11 0%,#0d0e14 55%,#0f1017 100%);}}
.st{{position:absolute;border-radius:50%}}
/* 은하수 코어 광채(오른편) */
.core{{position:absolute;right:{L['core_r']}px;top:{L['core_t']}px;
 width:{L['core']}px;height:{L['core']}px;border-radius:50%;
 background:radial-gradient(circle,rgba(190,205,255,.5),rgba(125,231,160,.10) 45%,rgba(10,11,18,0) 70%);
 filter:blur(6px)}}
.hero{{position:absolute;right:{L['hero_r']}px;top:{L['hero_t']}px;width:12px;height:12px;
 border-radius:50%;background:#fff;
 box-shadow:0 0 22px 6px rgba(125,231,160,.9),0 0 60px 16px rgba(125,231,160,.35)}}
/* 왼쪽 정렬 카피 */
.wm{{position:absolute;left:{L['x']}px;top:{L['wm_top']}px;color:#ECECEC;font-weight:700;
 letter-spacing:.32em;font-size:{L['wm']}px}}
.head{{position:absolute;left:{L['x']}px;top:{L['head_top']}px;color:#fff;font-weight:800;
 line-height:1.18;letter-spacing:-.035em;font-size:{L['head']}px}}
.sub{{position:absolute;left:{L['x']}px;top:{L['sub_top']}px;color:#C2C7CD;font-weight:600;
 line-height:1.45;letter-spacing:-.01em;font-size:{L['sub']}px;max-width:{L['subw']}px}}
.accent{{color:{GREEN}}}
.cta{{position:absolute;left:{L['x']}px;top:{L['cta_top']}px;display:inline-flex;align-items:center;
 gap:12px;background:{GREEN};color:#0c130f;font-weight:800;font-size:{L['cta']}px;
 padding:{L['cta_py']}px {L['cta_px']}px;border-radius:999px;
 box-shadow:0 12px 40px rgba(125,231,160,.28)}}
.cta .arw{{font-weight:800}}
.store{{position:absolute;left:{L['x']}px;top:{L['store_top']}px;color:#8A9098;
 font-weight:600;font-size:{L['store']}px;letter-spacing:.01em}}
</style></head><body>
{stars(W,H)}
<div class='core'></div><div class='hero'></div>
<div class='wm'>milkyway</div>
<div class='head'>{L['head_html']}</div>
<div class='sub'>{L['sub_html']}</div>
<div class='cta'>무료로 시작하기 <span class='arw'>&rsaquo;</span></div>
<div class='store'>App Store / Google Play</div>
</body></html>"""

HEAD = "그 문장에서,<br>왜 멈췄을까요"
SUB = "그 자리에서<br><span class='accent'>남들은 모르는 나</span>를 만나요"

LAYOUTS = {
  "square": dict(W=1080, H=1080, x=96, wm=28, wm_top=96,
    head=96, head_top=250, sub=34, sub_top=520, subw=620,
    cta=32, cta_py=26, cta_px=46, cta_top=690, store=22, store_top=800,
    core=520, core_r=-120, core_t=90, hero=0, hero_r=250, hero_t=300),
  "portrait": dict(W=1080, H=1350, x=100, wm=30, wm_top=150,
    head=104, head_top=360, sub=36, sub_top=660, subw=640,
    cta=34, cta_py=28, cta_px=50, cta_top=860, store=23, store_top=980,
    core=560, core_r=-130, core_t=140, hero=0, hero_r=270, hero_t=380),
  "story": dict(W=1080, H=1920, x=110, wm=34, wm_top=360,
    head=118, head_top=640, sub=40, sub_top=1000, subw=680,
    cta=38, cta_py=32, cta_px=58, cta_top=1240, store=26, store_top=1380,
    core=620, core_r=-150, core_t=430, hero=0, hero_r=300, hero_t=700),
}

for name, L in LAYOUTS.items():
    L = dict(L); L["head_html"] = HEAD; L["sub_html"] = SUB
    tmp = os.path.join(OUT, f"_adv5_{name}.html")
    out = os.path.join(OUT, f"v5_instagram_ad_{name}.png")
    with open(tmp, "w") as f:
        f.write(html(L["W"], L["H"], L))
    subprocess.run([CHROME, "--headless", "--disable-gpu", "--hide-scrollbars",
                    "--force-device-scale-factor=1", f"--window-size={L['W']},{L['H']}",
                    f"--screenshot={out}", f"file://{tmp}"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.remove(tmp)
    print("wrote", out)
