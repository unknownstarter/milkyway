#!/usr/bin/env python3
# 밀키웨이 진화 은하 오브 - 레이어 분리 출력.
#   core = 회전하는 은하(구 베이스 + 성운 + 코어 + 별 + 나선먼지). 방사형이라 회전해도 형태 유지.
#   glass = 고정 유리(방향성 하이라이트 spec/rim/sheen/edge + 방향 음영). 광원 고정.
#   aura(뒤 글로우)는 앱에서 네이티브로 호흡 -> 자산에 안 구움.
# OrbView가 Stack(aura펄스 + RotationTransition(core) + glass고정)로 합성.
import os, subprocess, random, math

OUT = os.path.dirname(os.path.abspath(__file__))
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
if not os.path.exists(CHROME):
    CHROME = subprocess.check_output(
        ["bash", "-lc", "ls /Applications/Google\\ Chrome*.app/Contents/MacOS/Google\\ Chrome | head -1"]
    ).decode().strip()

STAGE = 820

TIERS = [
  dict(key="t1", name="작은 성운", seed=11, orb=430, stars=28,  arms=0, spiral=0.0, spread=0.0, dust=None,
       core="#CFE0FF", core_a=.55, aura="120,150,255", spec_a=.72, rim_a=.26, spark=False,
       neb=[(.5,.5,300,"90,120,255",.16)]),
  dict(key="t2", name="별무리",   seed=22, orb=468, stars=70,  arms=0, spiral=0.0, spread=0.0, dust=None,
       core="#DCD6FF", core_a=.6,  aura="130,120,255", spec_a=.76, rim_a=.30, spark=False,
       neb=[(.5,.5,340,"110,110,255",.18),(.42,.44,180,"150,120,255",.14)]),
  dict(key="t3", name="별자리",   seed=33, orb=506, stars=135, arms=2, spiral=1.05, spread=0.30, dust="150,120,255",
       core="#E6DDFF", core_a=.7,  aura="138,124,255", spec_a=.80, rim_a=.34, spark=False,
       neb=[(.5,.5,360,"120,110,255",.20),(.62,.6,200,"160,110,240",.14)]),
  dict(key="t4", name="성단",     seed=44, orb=544, stars=210, arms=2, spiral=1.15, spread=0.25, dust="185,100,230",
       core="#EFE0FF", core_a=.78, aura="170,100,225", spec_a=.84, rim_a=.38, spark=True,
       neb=[(.5,.5,380,"140,90,235",.22),(.36,.6,220,"200,80,200",.16),(.66,.4,200,"120,110,255",.14)]),
  dict(key="t5", name="은하",     seed=55, orb=590, stars=320, arms=3, spiral=1.25, spread=0.21, dust="220,110,180",
       core="#FFE9C6", core_a=.85, aura="215,110,180", spec_a=.88, rim_a=.42, spark=True,
       neb=[(.5,.5,400,"200,90,180",.22),(.4,.58,240,"150,80,235",.18),(.6,.42,240,"255,150,90",.16)]),
  dict(key="t6", name="대은하",   seed=66, orb=648, stars=480, arms=4, spiral=1.35, spread=0.17, dust="255,170,110",
       core="#FFF3D6", core_a=.95, aura="255,175,95",  spec_a=.93, rim_a=.46, spark=True,
       neb=[(.5,.5,420,"255,160,90",.24),(.38,.6,260,"220,80,190",.20),(.64,.4,260,"120,120,255",.16),(.5,.5,180,"255,220,180",.20)]),
]
TIER_BY_KEY = {t["key"]: t for t in TIERS}

def stars_html(t, c, R):
    random.seed(t["seed"]); o = []
    arms, spiral, spread = t["arms"], t["spiral"], t["spread"]
    for _ in range(t["stars"]):
        if arms > 0 and random.random() < 0.86:
            arm = random.randint(0, arms - 1)
            rr = R * (random.random() ** 0.5)
            base = arm * (2 * math.pi / arms) + spiral * (rr / R) * 2 * math.pi
            th = base + random.gauss(0, spread)
        else:
            rr = R * (random.random() ** 0.72)
            th = random.random() * 2 * math.pi
        x = c + rr * math.cos(th); y = c + rr * math.sin(th)
        prox = 1 - rr / R
        sz = random.choice([1, 1, 1, 2, 2, 3]) + (1 if prox > 0.72 else 0)
        op = min(1, 0.32 + random.random() * (0.55 + 0.45 * prox))
        roll = random.random()
        col = "#FFD9A0" if (roll < 0.10 and t["key"] in ("t5", "t6")) else ("#CFE0FF" if roll < 0.16 else "#FFFFFF")
        glow = f";box-shadow:0 0 {sz*3}px rgba(200,215,255,.7)" if sz >= 3 else ""
        o.append(f"<i style='left:{x:.0f}px;top:{y:.0f}px;width:{sz}px;height:{sz}px;opacity:{op:.2f};background:{col}{glow}'></i>")
    return "".join(o)

def dust_html(t, c, R):
    if t["arms"] == 0 or not t["dust"]:
        return ""
    o = []
    for arm in range(t["arms"]):
        for frac in (0.40, 0.62, 0.84):
            r = R * frac
            ang = arm * (2 * math.pi / t["arms"]) + t["spiral"] * (r / R) * 2 * math.pi
            x = c + r * math.cos(ang); y = c + r * math.sin(ang)
            s = t["orb"] * 0.22
            a = 0.14 * (1 - frac * 0.4)
            o.append(f"<b style='left:{x-s/2:.0f}px;top:{y-s/2:.0f}px;width:{s:.0f}px;height:{s:.0f}px;"
                     f"background:radial-gradient(circle,rgba({t['dust']},{a:.3f}),rgba(0,0,0,0) 70%)'></b>")
    return "".join(o)

def neb_html(t, orb, f):
    o = []
    for (xf, yf, size, rgb, a) in t["neb"]:
        s = size * f
        x = xf * orb - s / 2; y = yf * orb - s / 2
        o.append(f"<b style='left:{x:.0f}px;top:{y:.0f}px;width:{s:.0f}px;height:{s:.0f}px;"
                 f"background:radial-gradient(circle,rgba({rgb},{a}),rgba(0,0,0,0) 68%)'></b>")
    return "".join(o)

def build_layer_html(t, layer):
    """layer = 'core' (회전 은하) | 'glass' (고정 유리)"""
    orb = t["orb"]; off = (STAGE - orb) / 2; c = orb / 2; R = c - 14; f = orb / 520.0
    core_s = 250 * f
    if layer == "core":
        inner = f"""
   {neb_html(t, orb, f)}
   {dust_html(t, c, R)}
   <div class='core'></div>
   {stars_html(t, c, R)}"""
        orb_css = f"""background:
  radial-gradient(circle at 50% 44%, rgba(255,255,255,.05), rgba(0,0,0,0) 60%),
  radial-gradient(circle at 50% 50%, #14101f 0%, #0c0a16 66%, #08060f 100%);
 box-shadow: inset 0 0 {70*f:.0f}px {14*f:.0f}px rgba(0,0,0,.55);"""
    else:  # glass
        spark = ("<div class='spec2'></div><div class='flare'></div>") if t["spark"] else ""
        inner = f"""
   <div class='rim'></div>
   <div class='sheen'></div>
   <div class='spec'></div>
   {spark}
   <div class='edge'></div>"""
        orb_css = f"""background:transparent;
 box-shadow:
  inset {20*f:.0f}px {24*f:.0f}px {70*f:.0f}px rgba(255,255,255,.10),
  inset {-34*f:.0f}px {-34*f:.0f}px {80*f:.0f}px rgba(0,0,0,.6);"""
    return f"""<!doctype html><html><head><meta charset='utf-8'><style>
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:{STAGE}px;height:{STAGE}px;background:transparent;overflow:hidden}}
.stage{{position:relative;width:{STAGE}px;height:{STAGE}px}}
.orb{{position:absolute;left:{off:.0f}px;top:{off:.0f}px;width:{orb}px;height:{orb}px;border-radius:50%;overflow:hidden;{orb_css}}}
.orb b{{position:absolute;border-radius:50%;filter:blur({26*f:.0f}px);mix-blend-mode:screen}}
.orb i{{position:absolute;border-radius:50%}}
.core{{position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);width:{core_s:.0f}px;height:{core_s:.0f}px;
 border-radius:50%;mix-blend-mode:screen;opacity:{t['core_a']};
 background:radial-gradient(circle,{t['core']} 0%,rgba({t['aura']},{t['core_a']*0.5}) 26%,rgba(0,0,0,0) 64%)}}
.spec{{position:absolute;left:0;top:0;width:100%;height:100%;border-radius:50%;
 background:radial-gradient(ellipse 42% 28% at 33% 22%, rgba(255,255,255,{t['spec_a']}), rgba(255,255,255,0) 60%)}}
.spec2{{position:absolute;left:0;top:0;width:100%;height:100%;border-radius:50%;
 background:radial-gradient(ellipse 12% 9% at 30% 20%, rgba(255,255,255,.95), rgba(255,255,255,0) 60%)}}
.flare{{position:absolute;left:30%;top:19%;width:{max(4,6*f):.0f}px;height:{max(4,6*f):.0f}px;border-radius:50%;
 background:#fff;box-shadow:0 0 {14*f:.0f}px {4*f:.0f}px rgba(255,255,255,.7)}}
.rim{{position:absolute;left:0;top:0;width:100%;height:100%;border-radius:50%;
 background:radial-gradient(ellipse 60% 40% at 74% 82%, rgba({t['aura']},{t['rim_a']}), rgba(0,0,0,0) 55%);mix-blend-mode:screen}}
.edge{{position:absolute;left:0;top:0;width:100%;height:100%;border-radius:50%;
 box-shadow:inset 0 0 0 2px rgba(255,255,255,.10), inset 0 6px 18px rgba(255,255,255,.14)}}
.sheen{{position:absolute;left:0;top:0;width:100%;height:100%;border-radius:50%;opacity:.10;mix-blend-mode:screen;
 background:conic-gradient(from 210deg, #7a5cff, #ff6bd0, #ffd06b, #6bf0ff, #7a5cff)}}
</style></head><body>
<div class='stage'><div class='orb'>{inner}
</div></div>
</body></html>"""

def render(html, out):
    tmp = out.replace(".png", ".html")
    with open(tmp, "w") as f:
        f.write(html)
    subprocess.run([CHROME, "--headless", "--disable-gpu", "--hide-scrollbars",
                    "--default-background-color=00000000", "--force-device-scale-factor=1",
                    f"--window-size={STAGE},{STAGE}", f"--screenshot={out}", f"file://{tmp}"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.remove(tmp)

if __name__ == "__main__":
    for t in TIERS:
        for layer in ("core", "glass"):
            out = os.path.join(OUT, f"galaxy_{t['key']}_{layer}.png")
            render(build_layer_html(t, layer), out)
            print("wrote", out)
