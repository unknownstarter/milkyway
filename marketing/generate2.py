#!/usr/bin/env python3
# 밀키웨이 스토어/광고 이미지 v2 - 실제 스크린샷(shots/) 폰 프레임 합성.
# 카피 룰: em/en-dash, 중간점, 곡선따옴표, 말줄임 금지. "당신" 금지. 구분자 - 또는 /.
import os, subprocess, random
OUT = os.path.dirname(os.path.abspath(__file__))
SHOT = os.path.join(OUT, "shots")
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
random.seed(7)
GREEN = "#7DE7A0"; BG = "#141416"

def stars(n, w, h):
    o=[]
    for _ in range(n):
        x,y=random.randint(0,w),random.randint(0,int(h*0.6))
        r=random.choice([1,1,1,2,2,3]); op=random.choice([0.25,0.4,0.55,0.7,0.9])
        o.append(f"<div class='st' style='left:{x}px;top:{y}px;width:{r}px;height:{r}px;opacity:{op}'></div>")
    return "".join(o)

CSS = f"""
*{{margin:0;padding:0;box-sizing:border-box}}
body{{font-family:'Apple SD Gothic Neo','Pretendard',sans-serif;background:{BG};overflow:hidden}}
.frame{{position:relative;width:100vw;height:100vh;overflow:hidden;background:
  radial-gradient(120% 60% at 78% 8%, rgba(70,90,180,.30), rgba(20,20,25,0) 55%),
  radial-gradient(90% 45% at 18% 30%, rgba(60,150,120,.16), rgba(20,20,25,0) 60%),
  linear-gradient(180deg,#0d0d12 0%,#141416 46%,#141416 100%);}}
.st{{position:absolute;background:#fff;border-radius:50%}}
.wordmark{{position:absolute;top:5.6%;left:0;right:0;text-align:center;color:#ECECEC;
  font-size:2.1vh;font-weight:700;letter-spacing:.3em}}
.copy{{position:absolute;top:9.5%;left:0;right:0;text-align:center;padding:0 7%}}
.head{{color:#fff;font-weight:800;line-height:1.22;letter-spacing:-.02em}}
.sub{{color:#9AA0A6;font-weight:500;margin-top:2vh;line-height:1.4}}
.accent{{color:{GREEN}}}
.phone{{position:absolute;left:50%;transform:translateX(-50%);background:#0a0a0a;
  border-radius:12%/5.4%;padding:1.5%;box-shadow:0 4vh 13vh rgba(0,0,0,.6),0 0 0 .3vh #2a2a2e;}}
.phone img{{width:100%;display:block;border-radius:10.5%/4.9%}}
"""

SLIDES = [
  dict(name="01_lyra", shot="6364.png",
       head="책 읽다 멈춘 순간<br><span class='accent'>Lyra</span>가 물어", sub="혼자 읽어도 대화하듯 더 깊이"),
  dict(name="02_detail", shot="6365.png",
       head="책마다 건네는<br><span class='accent'>Lyra의 물음</span>", sub="그 책에 대한 내 생각을 남겨"),
  dict(name="03_shelf", shot="6366.png",
       head="담은 책이<br>나의 <span class='accent'>서재</span>가 돼", sub="읽고 싶은 / 읽는 중 / 완독 한눈에"),
  dict(name="04_grow", shot="6369.png",
       head="읽을수록 자라는<br>나의 <span class='accent'>기록</span>", sub="상위 백분위 / 연속 읽은 날"),
  dict(name="05_calendar", shot="6368.png",
       head="메모가 쌓이는<br><span class='accent'>날들</span>", sub="언제 무엇을 읽었는지 한눈에"),
]

def page(w,h,slide):
    head_fs=h*0.046; sub_fs=h*0.023
    pw=w*0.72; ptop=h*0.30
    shot=os.path.join(SHOT, slide["shot"])
    return f"""<!doctype html><html><head><meta charset='utf-8'><style>{CSS}
    .head{{font-size:{head_fs}px}} .sub{{font-size:{sub_fs}px}}
    .phone{{width:{pw}px;top:{ptop}px}}
    </style></head><body><div class='frame'>{stars(85,w,h)}
    <div class='wordmark'>M I L K Y W A Y</div>
    <div class='copy'><div class='head'>{slide['head']}</div><div class='sub'>{slide['sub']}</div></div>
    <div class='phone'><img src='file://{shot}'></div>
    </div></body></html>"""

def insta(w,h):
    head_fs=h*0.055; pw=w*0.60; ptop=h*0.36
    shot=os.path.join(SHOT,"6364.png")
    return f"""<!doctype html><html><head><meta charset='utf-8'><style>{CSS}
    .head{{font-size:{head_fs}px}} .sub{{font-size:{h*0.026}px}}
    .copy{{top:8.5%}} .wordmark{{top:4.6%}}
    .phone{{width:{pw}px;top:{ptop}px}}
    .cta{{position:absolute;bottom:5.5%;left:0;right:0;text-align:center}}
    .cta b{{background:{GREEN};color:#0d0d12;font-size:{h*0.026}px;font-weight:800;padding:2vh 5vh;border-radius:99px}}
    .cta .n{{color:#9AA0A6;font-size:{h*0.019}px;margin-top:2.2vh}}
    </style></head><body><div class='frame'>{stars(60,w,h)}
    <div class='wordmark'>M I L K Y W A Y</div>
    <div class='copy'><div class='head'>책 읽다 멈춘 순간,<br><span class='accent'>Lyra</span>와 함께</div>
      <div class='sub'>여운을 담는 독서 메모</div></div>
    <div class='phone'><img src='file://{shot}'></div>
    <div class='cta'><b>지금 무료로 시작</b><div class='n'>밀키웨이 / App Store / Google Play</div></div>
    </div></body></html>"""

def feature(w,h):
    pw=h*1.02; shot=os.path.join(SHOT,"6364.png")
    return f"""<!doctype html><html><head><meta charset='utf-8'><style>{CSS}
    .fg-left{{position:absolute;left:7%;top:0;bottom:0;width:52%;display:flex;flex-direction:column;justify-content:center}}
    .fg-mark{{color:#ECECEC;font-size:{h*0.05}px;font-weight:700;letter-spacing:.28em}}
    .fg-head{{color:#fff;font-size:{h*0.112}px;font-weight:800;line-height:1.2;letter-spacing:-.02em;margin-top:{h*0.05}px}}
    .fg-sub{{color:#9AA0A6;font-size:{h*0.044}px;margin-top:{h*0.045}px}}
    .phone{{left:auto;right:4%;transform:rotate(-6deg);width:{pw}px;top:{h*0.20}px}}
    </style></head><body><div class='frame'>{stars(40,w,h)}
    <div class='fg-left'><div class='fg-mark'>M I L K Y W A Y</div>
      <div class='fg-head'>책 읽다 멈춘<br>순간을 담다</div>
      <div class='fg-sub'>메모 / Lyra의 물음 / 함께 읽기</div></div>
    <div class='phone'><img src='file://{shot}'></div>
    </div></body></html>"""

def ipad(w,h,slide):
    # 13" iPad 2064x2752(세로). 넓은 캔버스라 폰은 좁게 중앙, 카피 크게.
    head_fs=h*0.044; sub_fs=h*0.022; pw=w*0.50; ptop=h*0.31
    shot=os.path.join(SHOT, slide["shot"])
    return f"""<!doctype html><html><head><meta charset='utf-8'><style>{CSS}
    .head{{font-size:{head_fs}px}} .sub{{font-size:{sub_fs}px}}
    .wordmark{{top:6%;font-size:{h*0.018}px}} .copy{{top:10%}}
    .phone{{width:{pw}px;top:{ptop}px}}
    </style></head><body><div class='frame'>{stars(110,w,h)}
    <div class='wordmark'>M I L K Y W A Y</div>
    <div class='copy'><div class='head'>{slide['head']}</div><div class='sub'>{slide['sub']}</div></div>
    <div class='phone'><img src='file://{shot}'></div>
    </div></body></html>"""

def render(html,out,w,h):
    f=os.path.join(OUT,"_t2.html"); open(f,"w").write(html)
    subprocess.run([CHROME,"--headless=new","--disable-gpu","--hide-scrollbars",
      "--force-device-scale-factor=1",f"--screenshot={out}",f"--window-size={w},{h}",
      "--allow-file-access-from-files",f"file://{f}"],capture_output=True)
    print("rendered",os.path.basename(out))

if __name__=="__main__":
    for store,(w,h) in {"appstore":(1320,2868),"play":(1080,1920)}.items():
        for s in SLIDES:
            render(page(w,h,s),os.path.join(OUT,f"v2_{store}_{s['name']}.png"),w,h)
    for s in SLIDES[:4]:  # iPad 4장 (lyra/detail/shelf/grow)
        render(ipad(2064,2752,s),os.path.join(OUT,f"v2_ipad_{s['name']}.png"),2064,2752)
    render(insta(1080,1350),os.path.join(OUT,"v2_instagram_ad.png"),1080,1350)
    render(feature(1024,500),os.path.join(OUT,"v2_play_feature_graphic.png"),1024,500)
    print("done")
