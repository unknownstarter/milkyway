#!/usr/bin/env python3
# 밀키웨이 공유 카드 - 토스풍 + 진화 은하 오브 + "나도 하고싶다" 장치.
# 장치: (1) 다음 단계까지 게이지(목표 그래디언트) (2) 관찰자 대상 훅 카피 (3) 상위% 희소성.
# 카피 룰: em/en-dash, 중간점, 곡선따옴표, 말줄임 금지. "당신" 금지. 느낌표 금지.
import os, subprocess

OUT = os.path.dirname(os.path.abspath(__file__))
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
if not os.path.exists(CHROME):
    CHROME = subprocess.check_output(
        ["bash", "-lc", "ls /Applications/Google\\ Chrome*.app/Contents/MacOS/Google\\ Chrome | head -1"]
    ).decode().strip()

# (이름, 텍스트 액센트, 아우라 rgb)
TIER_META = {
  "t1": ("작은 성운", "#9DB4FF", "120,150,255"),
  "t2": ("별무리",   "#A99CFF", "130,120,255"),
  "t3": ("별자리",   "#9A8CFF", "138,124,255"),
  "t4": ("성단",     "#C48CFF", "170,100,225"),
  "t5": ("은하",     "#FF9ECB", "215,110,180"),
  "t6": ("대은하",   "#FFC24D", "255,175,95"),
}
ORDER = ["t1", "t2", "t3", "t4", "t5", "t6"]
LO = {"t1": 0, "t2": 30, "t3": 90, "t4": 200, "t5": 500, "t6": 1000}

def resolve(books, memos):
    pts = memos * 3 + books
    for key in reversed(ORDER):
        if pts >= LO[key]:
            return key, pts
    return "t1", pts

def card_html(d):
    key, pts = resolve(d["books"], d["memos"])
    name, acc, aura = TIER_META[key]
    idx = ORDER.index(key)
    nxt = ORDER[idx + 1] if idx < 5 else None
    if nxt:
        nname = TIER_META[nxt][0]
        remain = LO[nxt] - pts
        prog = max(0.04, min(1, (pts - LO[key]) / (LO[nxt] - LO[key])))
        prog_html = (f"<div class='bar'><span style='width:{prog*100:.0f}%'></span></div>"
                     f"<div class='lab'>다음 단계 {nname}까지 <b>{remain}</b></div>")
    else:
        prog_html = ("<div class='bar'><span style='width:100%'></span></div>"
                     "<div class='lab'>가장 깊은 우주에 도달</div>")
    orb = f"file://{OUT}/galaxy_{key}.png"
    W, H, mx = 1080, 1350, 80
    return f"""<!doctype html><html><head><meta charset='utf-8'><style>
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:{W}px;height:{H}px;overflow:hidden}}
body{{font-family:'Apple SD Gothic Neo','Pretendard',sans-serif;color:#fff;
 background:
  radial-gradient(72% 42% at 50% 18%, rgba({aura},.22), rgba(8,8,12,0) 62%),
  linear-gradient(180deg,#0a0a10 0%,#0b0b12 62%,#08080e 100%);}}
.stage{{position:relative;width:{W}px;height:{H}px;padding:0 {mx}px}}
.top{{position:absolute;left:{mx}px;right:{mx}px;top:56px;display:flex;align-items:center;justify-content:space-between}}
.wm{{color:#EDEDED;font-weight:800;letter-spacing:.28em;font-size:29px}}
.badge{{display:inline-flex;align-items:center;gap:10px;color:{acc};font-weight:700;font-size:24px;
 background:rgba({aura},.13);border:1.5px solid rgba({aura},.5);padding:10px 19px;border-radius:999px}}
.badge .dot{{width:9px;height:9px;border-radius:50%;background:{acc};box-shadow:0 0 10px rgba({aura},.9)}}
.orb{{position:absolute;left:50%;top:92px;transform:translateX(-50%);width:680px;height:680px}}
.kick{{position:absolute;left:0;right:0;top:742px;text-align:center;color:#9AA0AC;font-weight:600;font-size:29px}}
.tier{{position:absolute;left:0;right:0;top:782px;text-align:center;font-weight:800;font-size:64px;letter-spacing:-.03em}}
.tier .ac{{color:{acc}}}
.panel{{position:absolute;left:{mx}px;right:{mx}px;top:888px;height:188px;
 background:rgba(255,255,255,.045);border:1.5px solid rgba(255,255,255,.09);border-radius:28px;
 display:grid;grid-template-columns:repeat(4,1fr);align-items:center}}
.cell{{position:relative;text-align:center;padding:0 8px}}
.cell + .cell::before{{content:'';position:absolute;left:0;top:50%;transform:translateY(-50%);width:1px;height:70px;background:rgba(255,255,255,.09)}}
.cell .v{{font-weight:800;font-size:48px;letter-spacing:-.03em;line-height:1}}
.cell .v .u{{font-size:27px;font-weight:700;color:#C7CCD4;margin-left:3px}}
.cell .l{{margin-top:12px;color:#8A9098;font-weight:600;font-size:25px}}
.cell.hl .v{{color:{acc}}}
/* 다음 단계 게이지(목표 그래디언트) */
.prog{{position:absolute;left:{mx}px;right:{mx}px;top:1108px}}
.prog .bar{{height:12px;border-radius:999px;background:rgba(255,255,255,.08);overflow:hidden}}
.prog .bar span{{display:block;height:100%;border-radius:999px;background:linear-gradient(90deg,rgba({aura},.5),{acc})}}
.prog .lab{{margin-top:14px;text-align:center;color:#9096A0;font-weight:600;font-size:26px}}
.prog .lab b{{color:{acc};font-weight:800}}
/* 관찰자 대상 훅 */
.foot{{position:absolute;left:0;right:0;bottom:58px;text-align:center}}
.foot .hook{{color:#EDEDED;font-weight:700;font-size:31px;letter-spacing:-.01em}}
.foot .store{{margin-top:12px;color:#7C828A;font-weight:600;font-size:23px}}
.foot .store b{{color:#AEB2BB;font-weight:700}}
</style></head><body>
<div class='stage'>
  <div class='top'><div class='wm'>milkyway</div><div class='badge'><span class='dot'></span>{name} 단계</div></div>
  <img class='orb' src='{orb}'/>
  <div class='kick'>{d.get('nick','나')}의 우주</div>
  <div class='tier'>지금은 <span class='ac'>{name}</span></div>
  <div class='panel'>
    <div class='cell'><div class='v'>{d['books']}<span class='u'>권</span></div><div class='l'>읽은 책</div></div>
    <div class='cell'><div class='v'>{d['memos']}<span class='u'>개</span></div><div class='l'>남긴 메모</div></div>
    <div class='cell hl'><div class='v'>{d['pct']}<span class='u'>%</span></div><div class='l'>상위</div></div>
    <div class='cell'><div class='v'>{d['streak']}<span class='u'>일</span></div><div class='l'>연속</div></div>
  </div>
  <div class='prog'>{prog_html}</div>
  <div class='foot'>
    <div class='hook'>너의 우주는 어떤 모양일까</div>
    <div class='store'><b>App Store / Google Play</b> 에 milkyway</div>
  </div>
</div>
</body></html>"""

SAMPLES = [
  dict(name="newbie", nick="나", books=2,  memos=7,   pct=88, streak=2),
  dict(name="mid",    nick="나", books=14, memos=62,  pct=23, streak=9),
  dict(name="whale",  nick="나", books=58, memos=340, pct=3,  streak=21),
]

for s in SAMPLES:
    out = os.path.join(OUT, f"card_{s['name']}.png")
    tmp = os.path.join(OUT, f"_card_{s['name']}.html")
    with open(tmp, "w") as f:
        f.write(card_html(s))
    subprocess.run([CHROME, "--headless", "--disable-gpu", "--hide-scrollbars",
                    "--force-device-scale-factor=1", "--window-size=1080,1350",
                    f"--screenshot={out}", f"file://{tmp}"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.remove(tmp)
    k, _ = resolve(s["books"], s["memos"])
    print("wrote", out, "->", TIER_META[k][0])
