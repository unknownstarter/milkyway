#!/usr/bin/env python3
# 밀키웨이 인스타 광고 - POP 시스템(그로스커리어 공식). 팔레트/컨셉 파라미터화.
# 컨셉 stopped(멈춘 순간, 메모그리드) / mission(메모 습관, 스트릭 그리드).
# 카피 룰: em/en-dash, 중간점, 곡선따옴표, 말줄임 금지. "당신" 금지. 느낌표 금지.
import os, subprocess

OUT = os.path.dirname(os.path.abspath(__file__))
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
if not os.path.exists(CHROME):
    CHROME = subprocess.check_output(
        ["bash", "-lc", "ls /Applications/Google\\ Chrome*.app/Contents/MacOS/Google\\ Chrome | head -1"]
    ).decode().strip()
INK = "#0B0B14"

PALETTES = {
  "violet": ("#8A7CFF", "138,124,255"),
  "cyan":   ("#3DE0D0", "61,224,208"),
  "coral":  ("#FF7A6B", "255,122,107"),
  "pink":   ("#FF4D97", "255,77,151"),
  "amber":  ("#FFC24D", "255,194,77"),
}

CONCEPTS = {
  "stopped": dict(
    kick="책에서 멈춘 순간 <span class='ac'>/ milkyway</span>",
    head="그 문장에서,<br><span class='mark'>왜 멈췄을까요</span>",
    sub="그 자리에서 멈춘 사람들의 이야기",
    motif="grid"),
  "mission": dict(
    kick="하루 한 개, 메모 습관 <span class='ac'>/ milkyway</span>",
    head="하루에 메모 하나,<br><span class='mark'>남기는 습관</span>",
    sub="그렇게 쌓이는 가장 좋은 독서 기록",
    motif="streak"),
}

def _cell(lit, size, r):
    cls = "cell lit" if lit else "cell"
    return f"<div class='{cls}' style='width:{size}px;height:{size}px;border-radius:{r}px'></div>"

def grid_html(cols, rows, lit, cell, gap, cell_r):
    o = [_cell(i == lit, cell, cell_r) for i in range(cols * rows)]
    return (f"<div class='grid' style='grid-template-columns:repeat({cols},{cell}px);"
            f"gap:{gap}px'>" + "".join(o) + "</div>")

def streak_html(on, total, cell, gap, cell_r, lab):
    o = [_cell(i < on, cell, cell_r) for i in range(total)]
    row = (f"<div class='grid' style='grid-template-columns:repeat({total},{cell}px);"
           f"gap:{gap}px'>" + "".join(o) + "</div>")
    return f"<div class='slab'>{lab}</div>{row}"

def html(W, H, L, ACC, ARGB, C):
    if C["motif"] == "grid":
        motif = grid_html(L['cols'], L['rows'], L['lit'], L['cell'], L['gap'], L['cell_r'])
    else:
        motif = streak_html(5, 7, L['scell'], L['sgap'], L['scell_r'], "이번 주 메모 남긴 날 <b>5일째</b>")
    return f"""<!doctype html><html><head><meta charset='utf-8'><style>
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:{W}px;height:{H}px;overflow:hidden}}
body{{font-family:'Apple SD Gothic Neo','Pretendard',sans-serif;color:#fff;
 background:
  radial-gradient(70% 55% at 88% 8%, rgba({ARGB},.20), rgba(9,9,16,0) 60%),
  linear-gradient(180deg,#0a0a12 0%,#0b0b14 60%,#090910 100%);}}
.stage{{position:relative;width:{W}px;height:{H}px;overflow:hidden;padding:0 {L['mx']}px}}
.kick{{position:absolute;left:{L['mx']}px;top:{L['kick_t']}px;display:flex;align-items:center;
 gap:14px;color:#AEB2BF;font-weight:700;font-size:{L['kick']}px;letter-spacing:.02em}}
.kick .bar{{width:6px;height:{L['kick']+6}px;background:{ACC};border-radius:3px}}
.kick .ac{{color:{ACC}}}
.head{{position:absolute;left:{L['mx']}px;top:{L['head_t']}px;font-weight:800;
 line-height:1.14;letter-spacing:-.04em;font-size:{L['head']}px}}
.mark{{display:inline-block;background:{ACC};color:{INK};
 padding:.02em .16em;border-radius:{L['mark_r']}px;box-shadow:0 10px 34px rgba({ARGB},.4)}}
.sub{{position:absolute;left:{L['mx']}px;top:{L['sub_t']}px;color:#A6ABB7;
 font-weight:600;font-size:{L['sub']}px;letter-spacing:-.01em;line-height:1.4}}
.slab{{position:absolute;left:{L['mx']}px;top:{L['grid_t']-L['slab_up']}px;color:#AEB2BF;
 font-weight:700;font-size:{L['slab']}px;letter-spacing:.01em}}
.slab b{{color:{ACC}}}
.grid{{position:absolute;left:{L['mx']}px;top:{L['grid_t']}px;display:grid}}
.cell{{background:#161722;border:1px solid #23252F}}
.cell.lit{{background:{ACC};border-color:{ACC};
 box-shadow:0 0 0 6px rgba({ARGB},.14),0 10px 30px rgba({ARGB},.5)}}
.brand{{position:absolute;left:{L['mx']}px;bottom:{L['foot_b']}px;color:#ECECEC;
 font-weight:800;letter-spacing:.06em;font-size:{L['brand']}px}}
.brand .d{{color:{ACC}}}
.cta{{position:absolute;right:{L['mx']}px;bottom:{L['foot_b']-L['cta_lift']}px;
 display:inline-flex;align-items:center;gap:10px;background:{ACC};color:{INK};
 font-weight:800;font-size:{L['cta']}px;padding:{L['cta_py']}px {L['cta_px']}px;
 border-radius:999px;box-shadow:0 12px 36px rgba({ARGB},.32)}}
</style></head><body>
<div class='stage'>
  <div class='kick'><span class='bar'></span>{C['kick']}</div>
  <div class='head'>{C['head']}</div>
  <div class='sub'>{C['sub']}</div>
  {motif}
  <div class='brand'>milkyway<span class='d'>.</span></div>
  <div class='cta'>무료로 시작하기 &rsaquo;</div>
</div>
</body></html>"""

SQ = dict(W=1080, H=1080, mx=84,
    kick_t=78, kick=25, head_t=150, head=118, mark_r=14, sub_t=430, sub=38,
    cols=9, rows=3, cell=84, gap=18, cell_r=16, lit=13, grid_t=560,
    scell=114, sgap=16, scell_r=22, slab=26, slab_up=54,
    foot_b=70, brand=30, cta=30, cta_py=22, cta_px=40, cta_lift=8)

# 비교용 스퀘어: stopped 색상 4종 + mission(amber)
JOBS = [
  ("stopped", "violet"), ("stopped", "cyan"), ("stopped", "coral"), ("stopped", "pink"),
  ("mission", "amber"),
]

for concept, pal in JOBS:
    ACC, ARGB = PALETTES[pal]
    C = CONCEPTS[concept]
    L = dict(SQ)
    out = os.path.join(OUT, f"pop_{concept}_{pal}_square.png")
    tmp = os.path.join(OUT, f"_pop_{concept}_{pal}.html")
    with open(tmp, "w") as f:
        f.write(html(L["W"], L["H"], L, ACC, ARGB, C))
    subprocess.run([CHROME, "--headless", "--disable-gpu", "--hide-scrollbars",
                    "--force-device-scale-factor=1", f"--window-size={L['W']},{L['H']}",
                    f"--screenshot={out}", f"file://{tmp}"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.remove(tmp)
    print("wrote", out)
