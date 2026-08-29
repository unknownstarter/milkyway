#!/usr/bin/env python3
# 공유 카드(연결형) - constellation의 '그때 vs 지금 + Lyra 근거'를 토스풍 카드로.
# 데이터: get_constellation RPC(본인 노드+엣지, rationale). 공유자=본인.
# 카피 룰: em/en-dash, 중간점, 곡선따옴표, 말줄임 금지. "당신" 금지. 느낌표 금지.
import os, subprocess

OUT = os.path.dirname(os.path.abspath(__file__))
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
if not os.path.exists(CHROME):
    CHROME = subprocess.check_output(
        ["bash", "-lc", "ls /Applications/Google\\ Chrome*.app/Contents/MacOS/Google\\ Chrome | head -1"]
    ).decode().strip()

def card_html(d):
    acc, aura = d["acc"], d["aura"]
    orb = f"file://{OUT}/galaxy_{d['key']}.png"
    W, H, mx = 1080, 1350, 80
    return f"""<!doctype html><html><head><meta charset='utf-8'><style>
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:{W}px;height:{H}px;overflow:hidden}}
body{{font-family:'Apple SD Gothic Neo','Pretendard',sans-serif;color:#fff;
 background:
  radial-gradient(70% 40% at 50% 14%, rgba({aura},.22), rgba(8,8,12,0) 60%),
  linear-gradient(180deg,#0a0a10 0%,#0b0b12 62%,#08080e 100%);}}
.stage{{position:relative;width:{W}px;height:{H}px;padding:0 {mx}px}}
.top{{position:absolute;left:{mx}px;right:{mx}px;top:54px;display:flex;align-items:center;justify-content:space-between}}
.wm{{color:#EDEDED;font-weight:800;letter-spacing:.28em;font-size:29px}}
.badge{{display:inline-flex;align-items:center;gap:10px;color:{acc};font-weight:700;font-size:24px;
 background:rgba({aura},.14);border:1.5px solid rgba({aura},.55);padding:10px 19px;border-radius:999px}}
.badge .dot{{width:9px;height:9px;border-radius:50%;background:{acc};box-shadow:0 0 10px rgba({aura},.9)}}
.orb{{position:absolute;left:50%;top:78px;transform:translateX(-50%);width:420px;height:420px}}
.head{{position:absolute;left:0;right:0;top:500px;text-align:center;font-weight:800;font-size:56px;letter-spacing:-.03em}}
.head .ac{{color:{acc}}}
.sub{{position:absolute;left:0;right:0;top:576px;text-align:center;color:#9096A0;font-weight:600;font-size:28px}}
/* 연결 블록 */
.mm{{position:absolute;left:{mx}px;right:{mx}px;background:rgba(255,255,255,.045);
 border:1.5px solid rgba(255,255,255,.09);border-radius:24px;padding:22px 26px}}
.mm .when{{color:#8A9098;font-weight:700;font-size:24px;letter-spacing:.02em}}
.mm .txt{{margin-top:10px;color:#F0F1F3;font-weight:700;font-size:36px;line-height:1.4;letter-spacing:-.02em}}
.past{{top:648px}}
.now{{top:846px;border-color:rgba({aura},.5);background:rgba({aura},.08)}}
.now .when{{color:{acc}}}
/* 관계 칩(두 카드 사이) */
.rel{{position:absolute;left:50%;top:806px;transform:translate(-50%,-50%);z-index:2;
 display:inline-flex;align-items:center;gap:9px;background:#15151d;border:1.5px solid rgba({aura},.6);
 color:{acc};font-weight:800;font-size:25px;padding:9px 20px;border-radius:999px;
 box-shadow:0 8px 24px rgba(0,0,0,.5)}}
.rel .a{{font-size:20px}}
/* Lyra 근거 */
.lyra{{position:absolute;left:{mx}px;right:{mx}px;top:1024px;display:flex;gap:12px;align-items:flex-start}}
.lyra .ic{{color:{acc};font-size:26px;line-height:1.4}}
.lyra .t{{color:#C7CCD4;font-weight:600;font-size:28px;line-height:1.5;letter-spacing:-.01em}}
/* 푸터 */
.foot{{position:absolute;left:0;right:0;bottom:52px;text-align:center}}
.foot .hook{{color:#EDEDED;font-weight:700;font-size:30px}}
.foot .store{{margin-top:11px;color:#7C828A;font-weight:600;font-size:23px}}
.foot .store b{{color:#AEB2BB;font-weight:700}}
</style></head><body>
<div class='stage'>
  <div class='top'><div class='wm'>milkyway</div><div class='badge'><span class='dot'></span>{d['tier']} 단계</div></div>
  <img class='orb' src='{orb}'/>
  <div class='head'>생각이 <span class='ac'>{d['rel']}</span></div>
  <div class='sub'>그때의 나와 지금의 나</div>
  <div class='mm past'><div class='when'>그때 {d['past_date']}</div><div class='txt'>{d['past']}</div></div>
  <div class='rel'><span class='a'>&darr;</span>{d['rel']}</div>
  <div class='mm now'><div class='when'>지금 {d['now_date']}</div><div class='txt'>{d['now']}</div></div>
  <div class='lyra'><div class='ic'>&#10022;</div><div class='t'>{d['rationale']}</div></div>
  <div class='foot'>
    <div class='hook'>너의 우주는 어떤 모양일까</div>
    <div class='store'><b>App Store / Google Play</b> 에 milkyway</div>
  </div>
</div>
</body></html>"""

D = dict(
  key="t4", tier="성단", acc="#C48CFF", aura="170,100,225",
  rel="달라졌어요",
  past_date="2026.03", past="사랑은 내가 얼마나 맞춰주느냐의 문제라고 믿었다",
  now_date="2026.08", now="맞추려 애쓸수록 나를 잃는다는 걸 이제 안다",
  rationale="반년 전의 믿음이 정반대로 뒤집혔어요. 그 사이 어떤 문장들을 지나온 걸까요",
)

out = os.path.join(OUT, "card_connection.png")
tmp = os.path.join(OUT, "_card_connection.html")
with open(tmp, "w") as f:
    f.write(card_html(D))
subprocess.run([CHROME, "--headless", "--disable-gpu", "--hide-scrollbars",
                "--force-device-scale-factor=1", "--window-size=1080,1350",
                f"--screenshot={out}", f"file://{tmp}"],
               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
os.remove(tmp)
print("wrote", out)
