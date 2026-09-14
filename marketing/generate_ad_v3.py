#!/usr/bin/env python3
# 밀키웨이 인스타 광고 v3 - 컨셉: "책을 멈춘 순간을 저장 -> 나중에 나를 알아가는 은하수".
# Lyra 강조 X. 밤하늘/은하수 정체성 + 저장한 생각(메모 카드)이 별이 되어 나를 이룬다.
# 카피 룰: em/en-dash, 중간점, 곡선따옴표, 말줄임 금지. "당신" 금지. 구분자 - 또는 /.
import os, subprocess, random

OUT = os.path.dirname(os.path.abspath(__file__))
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
if not os.path.exists(CHROME):
    CHROME = subprocess.check_output(
        ["bash", "-lc", "ls /Applications/Google\\ Chrome*.app/Contents/MacOS/Google\\ Chrome | head -1"]
    ).decode().strip()

GREEN = "#7DE7A0"

def stars(n, w, h, band=True):
    random.seed(11)
    o = []
    for _ in range(n):
        x = random.randint(0, w); y = random.randint(0, h)
        # 은하수 밴드: 좌상->우하 대각선 근처일수록 밀도/밝기 up
        d = abs((y / h) - (x / w) - 0.05)
        near = d < 0.16
        if band and not near and random.random() < 0.55:
            continue
        r = random.choice([1, 1, 1, 2, 2, 3] + ([3, 4] if near else []))
        op = random.choice([0.3, 0.45, 0.6, 0.8] + ([0.95] if near else []))
        col = "#CFE8FF" if random.random() < 0.15 else "#FFFFFF"
        glow = f";box-shadow:0 0 {r*3}px rgba(180,210,255,.7)" if r >= 3 else ""
        o.append(f"<div class='st' style='left:{x}px;top:{y}px;width:{r}px;height:{r}px;opacity:{op};background:{col}{glow}'></div>")
    return "".join(o)

# 은하수를 이루는 '연결된 생각-별' 몇 개(성좌)
def constellation(pts, w, h):
    dots = "".join(
        f"<div class='cst' style='left:{x}px;top:{y}px'></div>" for x, y in pts
    )
    lines = ""
    for i in range(len(pts) - 1):
        x1, y1 = pts[i]; x2, y2 = pts[i + 1]
        import math
        dx, dy = x2 - x1, y2 - y1
        length = math.hypot(dx, dy); ang = math.degrees(math.atan2(dy, dx))
        lines += (f"<div class='cln' style='left:{x1}px;top:{y1}px;width:{length}px;"
                  f"transform:rotate({ang}deg)'></div>")
    return lines + dots

def html(W, H, layout):
    # 사이즈별 레이아웃 파라미터
    L = layout
    st = stars(int(W * H / 900), W, H)
    cst = constellation(L["pts"], W, H)
    return f"""<!doctype html><html><head><meta charset='utf-8'><style>
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:{W}px;height:{H}px;overflow:hidden}}
body{{font-family:'Apple SD Gothic Neo','Pretendard',sans-serif;
  background:
   radial-gradient(120% 70% at 82% 6%, rgba(70,95,190,.34), rgba(12,13,20,0) 55%),
   radial-gradient(95% 55% at 14% 40%, rgba(70,160,130,.14), rgba(12,13,20,0) 60%),
   linear-gradient(180deg,#0b0c12 0%,#0f1016 52%,#121319 100%);}}
.st{{position:absolute;border-radius:50%}}
.cln{{position:absolute;height:1.5px;transform-origin:left center;
  background:linear-gradient(90deg,rgba(125,231,160,.0),rgba(125,231,160,.55),rgba(125,231,160,0))}}
.cst{{position:absolute;width:7px;height:7px;margin:-3.5px;border-radius:50%;
  background:{GREEN};box-shadow:0 0 14px rgba(125,231,160,.9)}}
.wm{{position:absolute;left:0;right:0;text-align:center;color:#ECECEC;
  font-weight:700;letter-spacing:.34em;top:{L['wm_top']}px;font-size:{L['wm']}px}}
.copy{{position:absolute;left:0;right:0;text-align:center;padding:0 {L['pad']}px;top:{L['copy_top']}px}}
.head{{color:#fff;font-weight:800;line-height:1.24;letter-spacing:-.03em;font-size:{L['head']}px}}
.accent{{color:{GREEN}}}
.sub{{color:#AAB0B6;font-weight:500;line-height:1.5;margin-top:{L['subgap']}px;font-size:{L['sub']}px}}
.card{{position:absolute;left:50%;transform:translateX(-50%);top:{L['card_top']}px;
  width:{L['card_w']}px;background:#191A1F;border:1px solid #2A2C33;border-radius:22px;
  padding:{L['card_pad']}px;box-shadow:0 30px 90px rgba(0,0,0,.55),0 0 0 6px rgba(125,231,160,.05);}}
.card .tag{{display:flex;align-items:center;gap:8px;color:{GREEN};font-weight:700;font-size:{L['tag']}px}}
.card .tag .dot{{width:8px;height:8px;border-radius:50%;background:{GREEN}}}
.card .thought{{color:#EDEDED;font-weight:600;line-height:1.55;margin-top:{L['tgap']}px;
  font-size:{L['thought']}px;letter-spacing:-.01em}}
.chip{{display:inline-flex;align-items:center;gap:9px;margin-top:{L['chipgap']}px;
  background:#232429;border:1px solid #33353c;border-radius:999px;padding:{L['chip_py']}px {L['chip_px']}px;}}
.chip .cov{{width:{L['cov']}px;height:{int(L['cov']*1.4)}px;border-radius:4px;
  background:linear-gradient(160deg,#3a4a86,#20264a)}}
.chip .bt{{color:#C9CDD2;font-weight:600;font-size:{L['chiptext']}px}}
.foot{{position:absolute;left:0;right:0;text-align:center;bottom:{L['foot_bot']}px;
  color:#7C828A;font-weight:600;font-size:{L['foot']}px;letter-spacing:.02em}}
</style></head><body>
{st}{cst}
<div class='wm'>milkyway</div>
<div class='copy'>
  <div class='head'>{L['head_html']}</div>
  <div class='sub'>{L['sub_html']}</div>
</div>
<div class='card'>
  <div class='tag'><span class='dot'></span>저장한 생각</div>
  <div class='thought'>{L['thought_html']}</div>
  <div class='chip'><span class='cov'></span><span class='bt'>타이탄의 도구들</span></div>
</div>
<div class='foot'>App Store / Google Play</div>
</body></html>"""

THOUGHT = "누군가에겐 무가치할 수 있지만, 스스로가 생각하는 가치에 따라 내 행동이 달라진다"

LAYOUTS = {
  "square": dict(  # 1080x1080
    W=1080, H=1080, pts=[(150,150),(360,90),(560,180),(760,120),(930,230)],
    wm=30, wm_top=64, pad=120, copy_top=120,
    head=62, head_html="책을 멈춘 순간을<br>저장해",
    sub=27, subgap=22, sub_html="남긴 생각들이 모여<br>나를 알아가는 <span class='accent'>은하수</span>가 돼",
    card_top=470, card_w=560, card_pad=34, tag=22, tgap=16, thought=27,
    chipgap=20, chip_py=9, chip_px=14, cov=22, chiptext=20, chiptext_=0,
    foot=22, foot_bot=54),
  "portrait": dict(  # 1080x1350 (4:5)
    W=1080, H=1350, pts=[(150,170),(380,110),(600,210),(820,140),(960,270)],
    wm=32, wm_top=86, pad=120, copy_top=160,
    head=68, head_html="책을 멈춘 순간을<br>저장해",
    sub=29, subgap=26, sub_html="남긴 생각들이 모여<br>나를 알아가는 <span class='accent'>은하수</span>가 돼",
    card_top=560, card_w=580, card_pad=36, tag=23, tgap=18, thought=29,
    chipgap=22, chip_py=10, chip_px=15, cov=24, chiptext=21,
    foot=23, foot_bot=80),
  "story": dict(  # 1080x1920
    W=1080, H=1920, pts=[(150,260),(400,180),(640,300),(860,210),(980,360)],
    wm=34, wm_top=180, pad=130, copy_top=290,
    head=76, head_html="책을 멈춘 순간을<br>저장해",
    sub=32, subgap=30, sub_html="남긴 생각들이 모여<br>나를 알아가는 <span class='accent'>은하수</span>가 돼",
    card_top=830, card_w=600, card_pad=38, tag=24, tgap=20, thought=31,
    chipgap=24, chip_py=11, chip_px=16, cov=26, chiptext=22,
    foot=25, foot_bot=170),
}

for name, L in LAYOUTS.items():
    L = dict(L); L["thought_html"] = THOUGHT
    tmp = os.path.join(OUT, f"_ad_{name}.html")
    out = os.path.join(OUT, f"v3_instagram_ad_{name}.png")
    with open(tmp, "w") as f:
        f.write(html(L["W"], L["H"], L))
    subprocess.run([CHROME, "--headless", "--disable-gpu", "--hide-scrollbars",
                    "--force-device-scale-factor=1",
                    f"--window-size={L['W']},{L['H']}",
                    f"--screenshot={out}", f"file://{tmp}"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.remove(tmp)
    print("wrote", out)
