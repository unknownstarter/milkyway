#!/usr/bin/env python3
# 밀키웨이 은하 회고(Milky Wrapped) 카드 프로토타입. 기존 데이터 재조합, 공유용.
# 카피 룰: em/en-dash, 중간점, 곡선따옴표, 말줄임 금지. "당신" 금지. 느낌표 금지.
import os, subprocess, random

OUT = os.path.dirname(os.path.abspath(__file__))
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
if not os.path.exists(CHROME):
    CHROME = subprocess.check_output(
        ["bash", "-lc", "ls /Applications/Google\\ Chrome*.app/Contents/MacOS/Google\\ Chrome | head -1"]
    ).decode().strip()

ACC = "#8A7CFF"

def stars(w, h):
    random.seed(9); o = []
    n = int(w * h / 1600)
    for _ in range(n):
        x = random.randint(0, w); y = random.randint(0, h)
        r = random.choice([1, 1, 2])
        op = random.choice([0.18, 0.3, 0.45])
        o.append(f"<i style='left:{x}px;top:{y}px;width:{r}px;height:{r}px;opacity:{op}'></i>")
    return "".join(o)

def html(d):
    W, H, mx = 1080, 1350, 84
    return f"""<!doctype html><html><head><meta charset='utf-8'><style>
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:{W}px;height:{H}px;overflow:hidden}}
body{{font-family:'Apple SD Gothic Neo','Pretendard',sans-serif;color:#fff;
 background:
  radial-gradient(70% 45% at 50% 14%, rgba(138,124,255,.20), rgba(8,8,12,0) 60%),
  radial-gradient(60% 40% at 80% 84%, rgba(90,120,220,.12), rgba(8,8,12,0) 60%),
  linear-gradient(180deg,#08080e 0%,#0a0a12 60%,#070710 100%)}}
.stage{{position:relative;width:{W}px;height:{H}px;padding:0 {mx}px;overflow:hidden}}
i{{position:absolute;border-radius:50%;background:#fff}}
.top{{position:absolute;left:{mx}px;right:{mx}px;top:60px;display:flex;align-items:center;justify-content:space-between}}
.wm{{color:#EDEDED;font-weight:800;letter-spacing:.28em;font-size:29px}}
.per{{color:{ACC};font-weight:700;font-size:26px;background:rgba(138,124,255,.13);
 border:1.5px solid rgba(138,124,255,.5);padding:9px 18px;border-radius:999px}}
.head{{position:absolute;left:{mx}px;top:150px;font-weight:800;font-size:72px;letter-spacing:-.04em;line-height:1.12}}
.head .ac{{color:{ACC}}}
.sub{{position:absolute;left:{mx}px;top:310px;color:#9AA0AC;font-weight:600;font-size:30px}}
/* 3 스탯 */
.stats{{position:absolute;left:{mx}px;right:{mx}px;top:392px;display:grid;grid-template-columns:repeat(3,1fr)}}
.st{{position:relative;text-align:center}}
.st + .st::before{{content:'';position:absolute;left:0;top:8px;bottom:8px;width:1px;background:rgba(255,255,255,.09)}}
.st .v{{font-weight:800;font-size:58px;letter-spacing:-.03em;line-height:1}}
.st .v .u{{font-size:30px;color:#C7CCD4;margin-left:3px}}
.st.hl .v{{color:{ACC}}}
.st .l{{margin-top:14px;color:#8A9098;font-weight:600;font-size:25px}}
/* 최애 책 + 인용 */
.book{{position:absolute;left:{mx}px;right:{mx}px;top:560px;
 background:rgba(255,255,255,.045);border:1.5px solid rgba(255,255,255,.09);border-radius:26px;
 padding:30px 32px;display:flex;gap:26px;align-items:center}}
.cov{{width:120px;height:174px;border-radius:10px;flex:none;
 background:linear-gradient(155deg,#3a4a86,#20264a);box-shadow:0 14px 30px rgba(0,0,0,.5)}}
.bmeta .tag{{color:{ACC};font-weight:700;font-size:24px}}
.bmeta .bt{{margin-top:10px;color:#F0F1F3;font-weight:800;font-size:40px;letter-spacing:-.02em;line-height:1.25}}
.bmeta .ba{{margin-top:8px;color:#9096A0;font-weight:600;font-size:25px}}
/* 그 달의 문장 */
.quote{{position:absolute;left:{mx}px;right:{mx}px;top:800px}}
.quote .q{{color:#EDEDED;font-weight:700;font-size:40px;line-height:1.5;letter-spacing:-.02em}}
.quote .qm{{margin-top:16px;color:#8A9098;font-weight:600;font-size:24px}}
/* Lyra 물음 */
.lyra{{position:absolute;left:{mx}px;right:{mx}px;top:1010px;display:flex;gap:14px;align-items:flex-start}}
.lyra .ic{{color:{ACC};font-size:30px;line-height:1.3}}
.lyra .t{{color:#C7CCD4;font-weight:600;font-size:28px;line-height:1.5}}
/* 푸터 */
.foot{{position:absolute;left:0;right:0;bottom:56px;text-align:center}}
.foot .hook{{color:#EDEDED;font-weight:700;font-size:30px}}
.foot .store{{margin-top:11px;color:#7C828A;font-weight:600;font-size:23px}}
.foot .store b{{color:#AEB2BB}}
</style></head><body>
<div class='stage'>
{stars(W,H)}
<div class='top'><div class='wm'>milkyway</div><div class='per'>{d['period']}</div></div>
<div class='head'>{d['head']}</div>
<div class='sub'>{d['sub']}</div>
<div class='stats'>
 <div class='st'><div class='v'>{d['memos']}<span class='u'>개</span></div><div class='l'>멈춘 문장</div></div>
 <div class='st'><div class='v'>{d['days']}<span class='u'>일</span></div><div class='l'>읽은 날</div></div>
 <div class='st hl'><div class='v'>{d['pct']}<span class='u'>%</span></div><div class='l'>상위</div></div>
</div>
<div class='book'>
 <div class='cov'></div>
 <div class='bmeta'><div class='tag'>가장 오래 머문 책</div>
  <div class='bt'>{d['book']}</div><div class='ba'>{d['author']}</div></div>
</div>
<div class='quote'><div class='q'>{d['quote']}</div><div class='qm'>{d['quote_book']}</div></div>
<div class='lyra'><div class='ic'>&#10022;</div><div class='t'>{d['lyra']}</div></div>
<div class='foot'><div class='hook'>너의 우주는 어떤 모양일까</div>
 <div class='store'><b>App Store / Google Play</b> 에 milkyway</div></div>
</div>
</body></html>"""

D = dict(
  period="2026.08",
  head="8월, 네가<br><span class='ac'>멈춘 순간들</span>",
  sub="그 자리에 남은 34개의 별",
  memos=34, days=21, pct=7,
  book="미움받을 용기", author="기시미 이치로",
  quote="타인의 기대를 채우려<br>살지 않아도 된다",
  quote_book="미움받을 용기에서",
  lyra="그 문장이 왜 8월 내내 너에게 남았을까",
)

out = os.path.join(OUT, "wrapped_card.png")
tmp = os.path.join(OUT, "_wrapped.html")
with open(tmp, "w") as f:
    f.write(html(D))
subprocess.run([CHROME, "--headless", "--disable-gpu", "--hide-scrollbars",
                "--force-device-scale-factor=1", "--window-size=1080,1350",
                f"--screenshot={out}", f"file://{tmp}"],
               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
os.remove(tmp)
print("wrote", out)
