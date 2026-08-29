#!/usr/bin/env python3
# 공유 카드 변형: (A) habsida 웜 팔레트 (B) 값서사 카피 + 최근 공개메모 인용(실현성 목업).
# 카피 룰 준수. 성단(t4) 티어 기준.
import os, subprocess

OUT = os.path.dirname(os.path.abspath(__file__))
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
if not os.path.exists(CHROME):
    CHROME = subprocess.check_output(
        ["bash", "-lc", "ls /Applications/Google\\ Chrome*.app/Contents/MacOS/Google\\ Chrome | head -1"]
    ).decode().strip()

# 팔레트: cosmic(다크) / warm(habsida 브론즈+그린)
PALETTES = {
  "cosmic": dict(acc="#C48CFF", aura="170,100,225",
    bg="radial-gradient(72% 42% at 50% 16%, rgba(170,100,225,.22), rgba(8,8,12,0) 60%),"
       "linear-gradient(180deg,#0a0a10 0%,#0b0b12 62%,#08080e 100%)"),
  "warm": dict(acc="#3BD98A", aura="59,217,138",
    bg="radial-gradient(74% 44% at 50% 14%, rgba(210,130,60,.24), rgba(15,11,9,0) 60%),"
       "radial-gradient(60% 40% at 82% 78%, rgba(150,90,40,.12), rgba(15,11,9,0) 60%),"
       "linear-gradient(180deg,#100c09 0%,#0e0a08 62%,#0b0908 100%)"),
}

def card_html(d):
    name = d["name"]; p = PALETTES[d["palette"]]; acc = p["acc"]; aura = p["aura"]
    orb = f"file://{OUT}/galaxy_{d['key']}.png"
    W, H, mx = 1080, 1350, 80
    orb_top, orb_w = (86, 640) if d.get("quote") else (92, 680)
    # 헤드라인: tier(지금은 X) or value(N개의 생각이 X가 됐어요)
    if d["mode"] == "value":
        head = f"<span class='ac'>{d['memos']}개</span>의 생각이<br>{name}가 됐어요"
        head_fs = 58; head_top = orb_top + orb_w - 30
    else:
        head = f"지금은 <span class='ac'>{name}</span>"
        head_fs = 64; head_top = orb_top + orb_w - 20
    quote_html = ""
    if d.get("quote"):
        q = d["quote"]
        quote_html = f"""<div class='quote'>
          <div class='qmark'>&ldquo;</div>
          <div class='qt'>{q['text']}</div>
          <div class='qb'>{q['book']}</div>
        </div>"""
    # 레이아웃 y좌표(quote 유무로 분기)
    if d.get("quote"):
        head_top = 690; quote_top = 812; panel_top = 1044; prog_top = None; foot_hook = True
    else:
        panel_top = 888; prog_top = 1108
    return f"""<!doctype html><html><head><meta charset='utf-8'><style>
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:{W}px;height:{H}px;overflow:hidden}}
body{{font-family:'Apple SD Gothic Neo','Pretendard',sans-serif;color:#fff;background:{p['bg']}}}
.stage{{position:relative;width:{W}px;height:{H}px;padding:0 {mx}px}}
.top{{position:absolute;left:{mx}px;right:{mx}px;top:56px;display:flex;align-items:center;justify-content:space-between}}
.wm{{color:#EDEDED;font-weight:800;letter-spacing:.28em;font-size:29px}}
.badge{{display:inline-flex;align-items:center;gap:10px;color:{acc};font-weight:700;font-size:24px;
 background:rgba({aura},.14);border:1.5px solid rgba({aura},.55);padding:10px 19px;border-radius:999px}}
.badge .dot{{width:9px;height:9px;border-radius:50%;background:{acc};box-shadow:0 0 10px rgba({aura},.9)}}
.orb{{position:absolute;left:50%;top:{orb_top}px;transform:translateX(-50%);width:{orb_w}px;height:{orb_w}px}}
.head{{position:absolute;left:0;right:0;top:{head_top}px;text-align:center;font-weight:800;
 font-size:{head_fs}px;letter-spacing:-.03em;line-height:1.2}}
.head .ac{{color:{acc}}}
/* 메모 인용 카드 */
.quote{{position:absolute;left:{mx}px;right:{mx}px;top:{quote_top if d.get('quote') else 0}px;
 background:rgba(255,255,255,.05);border:1.5px solid rgba(255,255,255,.10);border-radius:26px;
 padding:30px 36px 28px;text-align:left}}
.quote .qmark{{color:{acc};font-weight:800;font-size:64px;line-height:.4;height:34px}}
.quote .qt{{color:#F2F2F4;font-weight:700;font-size:40px;line-height:1.4;letter-spacing:-.02em;margin-top:6px}}
.quote .qb{{margin-top:18px;color:#9096A0;font-weight:600;font-size:26px}}
.panel{{position:absolute;left:{mx}px;right:{mx}px;top:{panel_top}px;height:172px;
 background:rgba(255,255,255,.045);border:1.5px solid rgba(255,255,255,.09);border-radius:26px;
 display:grid;grid-template-columns:repeat(4,1fr);align-items:center}}
.cell{{position:relative;text-align:center;padding:0 6px}}
.cell + .cell::before{{content:'';position:absolute;left:0;top:50%;transform:translateY(-50%);width:1px;height:64px;background:rgba(255,255,255,.09)}}
.cell .v{{font-weight:800;font-size:44px;letter-spacing:-.03em;line-height:1}}
.cell .v .u{{font-size:25px;font-weight:700;color:#C7CCD4;margin-left:2px}}
.cell .l{{margin-top:11px;color:#8A9098;font-weight:600;font-size:24px}}
.cell.hl .v{{color:{acc}}}
.prog{{position:absolute;left:{mx}px;right:{mx}px;top:{prog_top if prog_top else 0}px;{'display:none' if not prog_top else ''}}}
.prog .bar{{height:12px;border-radius:999px;background:rgba(255,255,255,.08);overflow:hidden}}
.prog .bar span{{display:block;height:100%;width:62%;border-radius:999px;background:linear-gradient(90deg,rgba({aura},.5),{acc})}}
.prog .lab{{margin-top:14px;text-align:center;color:#9096A0;font-weight:600;font-size:26px}}
.prog .lab b{{color:{acc};font-weight:800}}
.foot{{position:absolute;left:0;right:0;bottom:56px;text-align:center}}
.foot .hook{{color:#EDEDED;font-weight:700;font-size:31px;letter-spacing:-.01em}}
.foot .store{{margin-top:12px;color:#7C828A;font-weight:600;font-size:23px}}
.foot .store b{{color:#AEB2BB;font-weight:700}}
</style></head><body>
<div class='stage'>
  <div class='top'><div class='wm'>milkyway</div><div class='badge'><span class='dot'></span>{name} 단계</div></div>
  <img class='orb' src='{orb}'/>
  <div class='head'>{head}</div>
  {quote_html}
  <div class='panel'>
    <div class='cell'><div class='v'>{d['books']}<span class='u'>권</span></div><div class='l'>읽은 책</div></div>
    <div class='cell'><div class='v'>{d['memos']}<span class='u'>개</span></div><div class='l'>남긴 메모</div></div>
    <div class='cell hl'><div class='v'>{d['pct']}<span class='u'>%</span></div><div class='l'>상위</div></div>
    <div class='cell'><div class='v'>{d['streak']}<span class='u'>일</span></div><div class='l'>연속</div></div>
  </div>
  <div class='prog'><div class='bar'><span></span></div><div class='lab'>다음 단계 은하까지 <b>138</b></div></div>
  <div class='foot'>
    <div class='hook'>너의 우주는 어떤 모양일까</div>
    <div class='store'><b>App Store / Google Play</b> 에 milkyway</div>
  </div>
</div>
</body></html>"""

CARDS = [
  dict(fn="card_warm", key="t4", name="성단", palette="warm", mode="tier",
       books=14, memos=62, pct=23, streak=9),
  dict(fn="card_quote", key="t4", name="성단", palette="cosmic", mode="value",
       books=14, memos=62, pct=23, streak=9,
       quote=dict(text="좋아하는 마음은 왜 자꾸<br>증명하고 싶어질까", book="여름의 문장들")),
]

for c in CARDS:
    out = os.path.join(OUT, f"{c['fn']}.png")
    tmp = os.path.join(OUT, f"_{c['fn']}.html")
    with open(tmp, "w") as f:
        f.write(card_html(c))
    subprocess.run([CHROME, "--headless", "--disable-gpu", "--hide-scrollbars",
                    "--force-device-scale-factor=1", "--window-size=1080,1350",
                    f"--screenshot={out}", f"file://{tmp}"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.remove(tmp)
    print("wrote", out)
