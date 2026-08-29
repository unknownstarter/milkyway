#!/usr/bin/env python3
# 홈 활성화 배너(토스풍) - 메모 7개 미만 유저에게 "오브 생성" 액션 유도.
# resting(홈 배너) + tapped(눌렀을 때 오브 자전 + n개 더) 두 상태 목업.
# 카피 룰 준수. "당신" 금지, 느낌표 금지.
import os, subprocess, math

OUT = os.path.dirname(os.path.abspath(__file__))
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
if not os.path.exists(CHROME):
    CHROME = subprocess.check_output(
        ["bash", "-lc", "ls /Applications/Google\\ Chrome*.app/Contents/MacOS/Google\\ Chrome | head -1"]
    ).decode().strip()

ACC = "#8A7CFF"; AURA = "138,124,255"
GATE = 7

def ring(pct, size):
    deg = pct * 360
    return (f"conic-gradient({ACC} 0deg {deg:.0f}deg, rgba(255,255,255,.10) {deg:.0f}deg 360deg)")

def banner_html(done):
    remain = GATE - done
    pct = done / GATE
    orb = f"file://{OUT}/galaxy_t1.png"
    W, H = 1080, 300
    return f"""<!doctype html><html><head><meta charset='utf-8'><style>
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:{W}px;height:{H}px;background:#0a0a10;overflow:hidden}}
body{{font-family:'Apple SD Gothic Neo','Pretendard',sans-serif;color:#fff}}
.banner{{position:absolute;left:40px;top:30px;right:40px;bottom:30px;
 background:radial-gradient(120% 160% at 90% 10%, rgba({AURA},.20), rgba(20,20,28,0) 60%),#16161f;
 border:1.5px solid rgba({AURA},.28);border-radius:30px;display:flex;align-items:center;
 padding:0 40px;overflow:hidden}}
.left{{flex:1}}
.kick{{color:{ACC};font-weight:800;font-size:23px;letter-spacing:.02em}}
.title{{margin-top:8px;color:#fff;font-weight:800;font-size:40px;letter-spacing:-.03em}}
.sub{{margin-top:10px;color:#AEB2BF;font-weight:600;font-size:26px}}
.sub b{{color:{ACC};font-weight:800}}
.bar{{margin-top:18px;width:420px;height:12px;border-radius:999px;background:rgba(255,255,255,.09);overflow:hidden}}
.bar span{{display:block;height:100%;width:{pct*100:.0f}%;border-radius:999px;
 background:linear-gradient(90deg,rgba({AURA},.5),{ACC})}}
.count{{margin-top:10px;color:#8A9098;font-weight:700;font-size:22px}}
.count b{{color:#D8DBE2}}
.right{{position:relative;width:210px;height:210px;margin-right:24px;display:flex;align-items:center;justify-content:center}}
.ring{{position:absolute;width:210px;height:210px;border-radius:50%;background:{ring(pct,210)};
 -webkit-mask:radial-gradient(circle, transparent 92px, #000 94px);
 mask:radial-gradient(circle, transparent 92px, #000 94px)}}
.orbimg{{width:184px;height:184px;object-fit:cover;opacity:.5;filter:saturate(.7)}}
.chev{{color:#7C828A;font-weight:700;font-size:40px;margin-left:4px}}
</style></head><body>
<div class='banner'>
  <div class='left'>
    <div class='kick'>나만의 은하수</div>
    <div class='title'>첫 오브를 만들어보세요</div>
    <div class='sub'>메모 <b>{remain}개</b>만 더 남기면 오브가 생겨요</div>
    <div class='bar'><span></span></div>
    <div class='count'><b>{done}</b> / {GATE}</div>
  </div>
  <div class='right'>
    <div class='ring'></div>
    <img class='orbimg' src='{orb}'/>
  </div>
  <div class='chev'>&rsaquo;</div>
</div>
</body></html>"""

def tapped_html(done):
    remain = GATE - done
    pct = done / GATE
    orb = f"file://{OUT}/galaxy_t1.png"
    W, H = 1080, 700
    return f"""<!doctype html><html><head><meta charset='utf-8'><style>
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:{W}px;height:{H}px;background:#0a0a10;overflow:hidden}}
body{{font-family:'Apple SD Gothic Neo','Pretendard',sans-serif;color:#fff}}
.sheet{{position:absolute;inset:36px;background:radial-gradient(90% 70% at 50% 6%, rgba({AURA},.20), rgba(18,18,26,0) 60%),#141420;
 border:1.5px solid rgba({AURA},.28);border-radius:34px;display:flex;flex-direction:column;
 align-items:center;padding:44px 40px 40px}}
.ringwrap{{position:relative;width:280px;height:280px;display:flex;align-items:center;justify-content:center}}
.ring{{position:absolute;width:280px;height:280px;border-radius:50%;background:{ring(pct,280)};
 -webkit-mask:radial-gradient(circle, transparent 124px, #000 126px);
 mask:radial-gradient(circle, transparent 124px, #000 126px)}}
.orbimg{{width:248px;height:248px;object-fit:cover;opacity:.55;filter:saturate(.7)}}
.spin{{position:absolute;bottom:-2px;color:{ACC};font-weight:700;font-size:22px}}
.title{{margin-top:30px;color:#fff;font-weight:800;font-size:44px;letter-spacing:-.03em;text-align:center}}
.title .ac{{color:{ACC}}}
.sub{{margin-top:14px;color:#AEB2BF;font-weight:600;font-size:28px;text-align:center;line-height:1.45}}
.count{{margin-top:20px;color:#8A9098;font-weight:700;font-size:24px}}
.count b{{color:#D8DBE2}}
.btn{{margin-top:30px;background:{ACC};color:#0c0c14;font-weight:800;font-size:30px;
 padding:20px 46px;border-radius:999px;box-shadow:0 14px 40px rgba({AURA},.3)}}
</style></head><body>
<div class='sheet'>
  <div class='ringwrap'><div class='ring'></div><img class='orbimg' src='{orb}'/>
    <div class='spin'>천천히 자전 중</div></div>
  <div class='title'>오브가 <span class='ac'>{remain}개</span> 남았어요</div>
  <div class='sub'>메모를 {remain}개 더 남기면<br>너만의 은하수 오브가 완성돼요</div>
  <div class='count'><b>{done}</b> / {GATE}</div>
  <div class='btn'>지금 메모 쓰기</div>
</div>
</body></html>"""

for fn, html in [("home_banner", banner_html(3)), ("home_banner_tapped", tapped_html(3))]:
    W, Hh = (1080, 300) if fn == "home_banner" else (1080, 700)
    out = os.path.join(OUT, f"{fn}.png")
    tmp = os.path.join(OUT, f"_{fn}.html")
    with open(tmp, "w") as f:
        f.write(html)
    subprocess.run([CHROME, "--headless", "--disable-gpu", "--hide-scrollbars",
                    "--force-device-scale-factor=1", f"--window-size={W},{Hh}",
                    f"--screenshot={out}", f"file://{tmp}"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.remove(tmp)
    print("wrote", out)
