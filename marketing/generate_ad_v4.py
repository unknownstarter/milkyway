#!/usr/bin/env python3
# 밀키웨이 인스타 광고 v4 - 컨셉: "그 문장에서 왜 멈췄을까 / 그 자리에 남들은 모르는 내가 있어요".
# 행동 서술 X. 어두운 페이지에 한 문장만 빛나고, 그 자리에서 별이 은하수로 피어오른다.
# 카피 룰: em/en-dash, 중간점, 곡선따옴표, 말줄임 금지. "당신" 금지.
import os, subprocess, random, math

OUT = os.path.dirname(os.path.abspath(__file__))
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
if not os.path.exists(CHROME):
    CHROME = subprocess.check_output(
        ["bash", "-lc", "ls /Applications/Google\\ Chrome*.app/Contents/MacOS/Google\\ Chrome | head -1"]
    ).decode().strip()

GREEN = "#7DE7A0"

def stars(w, h):
    random.seed(11); o = []
    n = int(w * h / 850)
    for _ in range(n):
        x = random.randint(0, w); y = random.randint(0, h)
        d = abs((y / h) - (x / w) - 0.02)
        near = d < 0.15
        if not near and random.random() < 0.5:
            continue
        r = random.choice([1, 1, 1, 2, 2] + ([3] if near else []))
        op = random.choice([0.28, 0.42, 0.58, 0.75] + ([0.92] if near else []))
        col = "#CFE8FF" if random.random() < 0.14 else "#FFFFFF"
        glow = f";box-shadow:0 0 {r*3}px rgba(180,210,255,.6)" if r >= 3 else ""
        o.append(f"<div class='st' style='left:{x}px;top:{y}px;width:{r}px;height:{r}px;opacity:{op};background:{col}{glow}'></div>")
    return "".join(o)

PAGE = ("매일 무언가를 읽지만 대부분은 흘러가요. 그런데 어떤 문장은 "
        "<span class='hl'>나를 멈춰 세워요</span>. "
        "그 자리에서 오래 머물던 마음이, 밤하늘의 별처럼 남아요.")

def html(W, H, L):
    return f"""<!doctype html><html><head><meta charset='utf-8'><style>
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:{W}px;height:{H}px;overflow:hidden}}
body{{font-family:'Apple SD Gothic Neo','Pretendard',sans-serif;
 background:
  radial-gradient(120% 70% at 82% 4%, rgba(70,95,190,.32), rgba(10,11,18,0) 55%),
  radial-gradient(95% 55% at 16% 44%, rgba(70,160,130,.12), rgba(10,11,18,0) 60%),
  linear-gradient(180deg,#0a0b11 0%,#0e0f15 54%,#101118 100%);}}
.st{{position:absolute;border-radius:50%}}
.wm{{position:absolute;left:0;right:0;text-align:center;color:#ECECEC;font-weight:700;
 letter-spacing:.34em;top:{L['wm_top']}px;font-size:{L['wm']}px}}
.copy{{position:absolute;left:0;right:0;text-align:center;padding:0 {L['pad']}px;top:{L['copy_top']}px}}
.head{{color:#fff;font-weight:800;line-height:1.26;letter-spacing:-.03em;font-size:{L['head']}px}}
.sub{{color:#B4BAC0;font-weight:500;line-height:1.5;margin-top:{L['subgap']}px;font-size:{L['sub']}px}}
.accent{{color:{GREEN}}}
/* 어두운 페이지 - 한 문장만 빛남 */
.page{{position:absolute;left:50%;transform:translateX(-50%);top:{L['page_top']}px;
 width:{L['page_w']}px;text-align:left;color:#4C525C;font-weight:500;
 line-height:2.05;font-size:{L['pagefs']}px;letter-spacing:-.01em}}
.hl{{color:#EAF6EE;position:relative;background:linear-gradient(180deg,transparent 62%,rgba(125,231,160,.20) 62%);
 padding:0 2px}}
/* 빛나는 문장 자리에서 피어오르는 별 + 위로 뻗는 은하수 빛줄기 */
.spark{{position:absolute;left:50%;transform:translateX(-50%);top:{L['spark_top']}px;
 width:9px;height:9px;border-radius:50%;background:#fff;
 box-shadow:0 0 18px 4px rgba(125,231,160,.85),0 0 46px 10px rgba(125,231,160,.35)}}
.trail{{position:absolute;left:50%;transform:translateX(-50%);top:{L['trail_top']}px;
 width:2px;height:{L['trail_h']}px;
 background:linear-gradient(180deg,rgba(125,231,160,0),rgba(125,231,160,.5) 60%,rgba(125,231,160,.85))}}
.foot{{position:absolute;left:0;right:0;text-align:center;bottom:{L['foot_bot']}px;
 color:#7C828A;font-weight:600;font-size:{L['foot']}px;letter-spacing:.02em}}
</style></head><body>
{stars(W,H)}
<div class='trail'></div><div class='spark'></div>
<div class='wm'>milkyway</div>
<div class='copy'>
  <div class='head'>{L['head_html']}</div>
  <div class='sub'>{L['sub_html']}</div>
</div>
<div class='page'>{PAGE}</div>
<div class='foot'>App Store / Google Play</div>
</body></html>"""

HEAD = "그 문장에서,<br>왜 멈췄을까요"
SUB = "그 자리에서, <span class='accent'>남들은 모르는 나</span>를 만나요"

LAYOUTS = {
  "square": dict(W=1080, H=1080, wm=28, wm_top=70, pad=110, copy_top=138,
    head=60, sub=27, subgap=22, page_top=560, page_w=560, pagefs=25,
    trail_top=430, trail_h=150, spark_top=424, foot=22, foot_bot=52),
  "portrait": dict(W=1080, H=1350, wm=30, wm_top=100, pad=110, copy_top=190,
    head=66, sub=29, subgap=26, page_top=720, page_w=600, pagefs=27,
    trail_top=540, trail_h=190, spark_top=534, foot=23, foot_bot=78),
  "story": dict(W=1080, H=1920, wm=32, wm_top=210, pad=120, copy_top=330,
    head=74, sub=32, subgap=30, page_top=1060, page_w=640, pagefs=30,
    trail_top=830, trail_h=240, spark_top=824, foot=25, foot_bot=170),
}

for name, L in LAYOUTS.items():
    L = dict(L); L["head_html"] = HEAD; L["sub_html"] = SUB
    tmp = os.path.join(OUT, f"_adv4_{name}.html")
    out = os.path.join(OUT, f"v4_instagram_ad_{name}.png")
    with open(tmp, "w") as f:
        f.write(html(L["W"], L["H"], L))
    subprocess.run([CHROME, "--headless", "--disable-gpu", "--hide-scrollbars",
                    "--force-device-scale-factor=1", f"--window-size={L['W']},{L['H']}",
                    f"--screenshot={out}", f"file://{tmp}"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.remove(tmp)
    print("wrote", out)
