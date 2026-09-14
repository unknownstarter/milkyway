#!/usr/bin/env python3
# 밀키웨이 인스타 광고 v8 - 그로스커리어 카드 공식 이식(눈에 띄게).
# 핵심: 키워드 솔리드 하이라이트 블록 + 채도 높은 액센트 + 초대형 헤드 + 키커바 + 메모그리드(한칸만 빛남) + 깔끔한 푸터.
# 다크 정체성 유지. 스퀘어 우선 시안.
# 카피 룰: em/en-dash, 중간점, 곡선따옴표, 말줄임 금지. "당신" 금지. 느낌표 금지.
import os, subprocess

OUT = os.path.dirname(os.path.abspath(__file__))
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
if not os.path.exists(CHROME):
    CHROME = subprocess.check_output(
        ["bash", "-lc", "ls /Applications/Google\\ Chrome*.app/Contents/MacOS/Google\\ Chrome | head -1"]
    ).decode().strip()

# 채도 높은 액센트(페리윙클/코스믹 바이올렛) - 다크 위에서 확 튐
ACC = "#8A7CFF"
ARGB = "138,124,255"
INK = "#0B0B14"

def grid(cols, rows, lit, cell, gap):
    o = []
    for i in range(cols * rows):
        cls = "cell lit" if i == lit else "cell"
        o.append(f"<div class='{cls}'></div>")
    return (f"<div class='grid' style='grid-template-columns:repeat({cols},{cell}px);"
            f"gap:{gap}px'>" + "".join(o) + "</div>")

def html(W, H, L):
    g = grid(L['cols'], L['rows'], L['lit'], L['cell'], L['gap'])
    return f"""<!doctype html><html><head><meta charset='utf-8'><style>
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:{W}px;height:{H}px;overflow:hidden}}
body{{font-family:'Apple SD Gothic Neo','Pretendard',sans-serif;color:#fff;
 background:
  radial-gradient(70% 55% at 88% 8%, rgba({ARGB},.20), rgba(9,9,16,0) 60%),
  linear-gradient(180deg,#0a0a12 0%,#0b0b14 60%,#090910 100%);}}
.stage{{position:relative;width:{W}px;height:{H}px;overflow:hidden;padding:0 {L['mx']}px}}
/* 키커 */
.kick{{position:absolute;left:{L['mx']}px;top:{L['kick_t']}px;display:flex;align-items:center;
 gap:14px;color:#AEB2BF;font-weight:700;font-size:{L['kick']}px;letter-spacing:.02em}}
.kick .bar{{width:6px;height:{L['kick']+6}px;background:{ACC};border-radius:3px}}
.kick .ac{{color:{ACC}}}
/* 헤드 */
.head{{position:absolute;left:{L['mx']}px;top:{L['head_t']}px;font-weight:800;
 line-height:1.14;letter-spacing:-.04em;font-size:{L['head']}px}}
.mark{{display:inline-block;background:{ACC};color:{INK};
 padding:.02em .16em;border-radius:{L['mark_r']}px;box-shadow:0 10px 34px rgba({ARGB},.4)}}
/* 서브 */
.sub{{position:absolute;left:{L['mx']}px;top:{L['sub_t']}px;color:#A6ABB7;
 font-weight:600;font-size:{L['sub']}px;letter-spacing:-.01em;line-height:1.4}}
/* 메모 그리드 모티프 */
.grid{{position:absolute;left:{L['mx']}px;top:{L['grid_t']}px;display:grid}}
.cell{{width:{L['cell']}px;height:{L['cell']}px;border-radius:{L['cell_r']}px;
 background:#161722;border:1px solid #23252F}}
.cell.lit{{background:{ACC};border-color:{ACC};
 box-shadow:0 0 0 6px rgba({ARGB},.14),0 10px 30px rgba({ARGB},.5)}}
/* 푸터 */
.brand{{position:absolute;left:{L['mx']}px;bottom:{L['foot_b']}px;color:#ECECEC;
 font-weight:800;letter-spacing:.06em;font-size:{L['brand']}px}}
.brand .d{{color:{ACC}}}
.cta{{position:absolute;right:{L['mx']}px;bottom:{L['foot_b']-L['cta_lift']}px;
 display:inline-flex;align-items:center;gap:10px;background:{ACC};color:{INK};
 font-weight:800;font-size:{L['cta']}px;padding:{L['cta_py']}px {L['cta_px']}px;
 border-radius:999px;box-shadow:0 12px 36px rgba({ARGB},.32)}}
</style></head><body>
<div class='stage'>
  <div class='kick'><span class='bar'></span>책에서 멈춘 순간 <span class='ac'>/ milkyway</span></div>
  <div class='head'>{L['head_html']}</div>
  <div class='sub'>{L['sub_html']}</div>
  {g}
  <div class='brand'>milkyway<span class='d'>.</span></div>
  <div class='cta'>무료로 시작하기 &rsaquo;</div>
</div>
</body></html>"""

HEAD = "그 문장에서,<br><span class='mark'>왜 멈췄을까요</span>"
SUB = "그 자리에서 멈춘 사람들의 이야기"

LAYOUTS = {
  "square": dict(W=1080, H=1080, mx=84,
    kick_t=78, kick=25,
    head_t=150, head=118, mark_r=14,
    sub_t=430, sub=38,
    cols=9, rows=3, cell=84, gap=18, cell_r=16, lit=13, grid_t=560,
    foot_b=70, brand=30, cta=30, cta_py=22, cta_px=40, cta_lift=8),
  "portrait": dict(W=1080, H=1350, mx=88,
    kick_t=96, kick=26,
    head_t=180, head=128, mark_r=15,
    sub_t=500, sub=40,
    cols=9, rows=4, cell=84, gap=18, cell_r=16, lit=22, grid_t=630,
    foot_b=92, brand=32, cta=32, cta_py=23, cta_px=42, cta_lift=8),
  # 스토리: 상단 14%(269)/하단 35%(672) 세이프존 - 콘텐츠를 가운데 밴드에
  "story": dict(W=1080, H=1920, mx=90,
    kick_t=300, kick=28,
    head_t=380, head=140, mark_r=16,
    sub_t=740, sub=44,
    cols=9, rows=3, cell=84, gap=18, cell_r=17, lit=13, grid_t=850,
    foot_b=700, brand=34, cta=34, cta_py=24, cta_px=46, cta_lift=8),
}

for name, L in LAYOUTS.items():
    L = dict(L); L["head_html"] = HEAD; L["sub_html"] = SUB
    tmp = os.path.join(OUT, f"_adv8_{name}.html")
    out = os.path.join(OUT, f"v8_instagram_ad_{name}.png")
    with open(tmp, "w") as f:
        f.write(html(L["W"], L["H"], L))
    subprocess.run([CHROME, "--headless", "--disable-gpu", "--hide-scrollbars",
                    "--force-device-scale-factor=1", f"--window-size={L['W']},{L['H']}",
                    f"--screenshot={out}", f"file://{tmp}"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.remove(tmp)
    print("wrote", out)
