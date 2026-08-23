#!/usr/bin/env python3
# 밀키웨이 스토어/광고 이미지 생성기. HTML/CSS -> Chrome 헤드리스 렌더.
# 카피 룰 준수: em/en-dash·중간점·곡선따옴표·말줄임 금지, "당신" 금지, 이모지 적당히.
import os, subprocess, random

OUT = os.path.dirname(os.path.abspath(__file__))
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
random.seed(7)

# ── 별(은하수) 배경 ──────────────────────────────────────────────
def stars(n, w, h):
    out = []
    for _ in range(n):
        x, y = random.randint(0, w), random.randint(0, int(h*0.62))
        r = random.choice([1,1,1,2,2,3])
        o = random.choice([0.25,0.4,0.55,0.7,0.9])
        out.append(f"<div class='st' style='left:{x}px;top:{y}px;width:{r}px;height:{r}px;opacity:{o}'></div>")
    return "".join(out)

GREEN = "#7DE7A0"
BG = "#141416"

CSS = f"""
*{{margin:0;padding:0;box-sizing:border-box;-webkit-font-smoothing:antialiased}}
body{{font-family:'Apple SD Gothic Neo','Pretendard',sans-serif;background:{BG};overflow:hidden}}
.frame{{position:relative;width:100vw;height:100vh;overflow:hidden;
  background:
    radial-gradient(120% 60% at 78% 8%, rgba(70,90,180,.30), rgba(20,20,25,0) 55%),
    radial-gradient(90% 45% at 18% 30%, rgba(60,150,120,.16), rgba(20,20,25,0) 60%),
    linear-gradient(180deg,#0d0d12 0%,#141416 46%,#141416 100%);}}
.st{{position:absolute;background:#fff;border-radius:50%}}
.wordmark{{position:absolute;top:6.2%;left:0;right:0;text-align:center;color:#ECECEC;
  font-size:2.2vh;font-weight:700;letter-spacing:.28em}}
.copy{{position:absolute;top:10.5%;left:0;right:0;text-align:center;padding:0 7%}}
.head{{color:#fff;font-weight:800;line-height:1.22;letter-spacing:-.02em}}
.sub{{color:#9AA0A6;font-weight:500;margin-top:2.1vh;line-height:1.4}}
.accent{{color:{GREEN}}}
.phone-wrap{{position:absolute;left:50%;transform:translateX(-50%);}}
.phone{{position:relative;background:#000;border-radius:11%/5.3%;
  box-shadow:0 4vh 12vh rgba(0,0,0,.55),0 0 0 .35vh #232326;overflow:hidden}}
.screen{{position:absolute;inset:1.5%;border-radius:9.4%/4.6%;background:{BG};overflow:hidden}}
/* ── 앱 화면 공통 ── */
.sbar{{display:flex;justify-content:space-between;align-items:center;padding:3.2% 6% 0;color:#ECECEC;font-size:2.7vh;font-weight:600}}
.appbar{{text-align:center;color:#fff;font-size:2.5vh;font-weight:700;padding:2.4% 0 1.4%}}
.pad{{padding:0 6%}}
.card{{background:#1c1c1f;border:1px solid #262629;border-radius:5.5%;padding:6% 6%;}}
.lyra-dot{{width:1.3vh;height:1.3vh;border-radius:50%;background:{GREEN};display:inline-block;margin-right:1.6vh;box-shadow:0 0 1.6vh {GREEN}}}
.lyra-label{{color:{GREEN};font-weight:700;font-size:2.4vh}}
.lyra-q{{color:#ECECEC;font-size:2.85vh;line-height:1.5;margin-top:2.4vh;font-weight:500}}
.lyra-cta{{color:{GREEN};font-weight:700;font-size:2.4vh;margin-top:3vh;display:flex;align-items:center;gap:1.4vh}}
.avatar{{width:5vh;height:5vh;border-radius:50%;background:linear-gradient(135deg,#2f6f57,#8fd0a8)}}
.mrow{{display:flex;align-items:center;gap:2vh}}
.mname{{color:#ECECEC;font-weight:600;font-size:2.4vh}}
.mdate{{color:#646464;font-size:2vh;margin-top:.4vh}}
.mtag{{color:{GREEN};font-weight:700;font-size:2.3vh;margin-top:3vh}}
.mtext{{color:#DcDcDc;font-size:2.5vh;line-height:1.55;margin-top:1.2vh}}
.mmeta{{color:#646464;font-size:2vh;margin-top:2.6vh}}
.chip{{display:inline-block;background:#1f1f22;border:1px solid #2c2c30;color:#c9c9cf;
  font-size:2.1vh;font-weight:600;padding:1.3vh 3vh;border-radius:99px;margin-right:1.4vh}}
.chip.on{{background:#ECECEC;color:#111;border-color:#ECECEC}}
.relchip{{display:inline-block;background:rgba(125,231,160,.14);color:{GREEN};
  font-size:2.1vh;font-weight:700;padding:1vh 2.6vh;border-radius:99px}}
.mini{{background:#1a1a1d;border:1px solid #242427;border-radius:4%;padding:4% 5%;margin-top:2.4vh}}
.mini .l{{color:#7a7a80;font-size:1.9vh;font-weight:600}}
.mini .t{{color:#cfcfd4;font-size:2.15vh;line-height:1.45;margin-top:1vh}}
.grid{{display:grid;grid-template-columns:repeat(3,1fr);gap:3.5%;}}
.bk{{aspect-ratio:.7;border-radius:6%;display:flex;align-items:flex-end;padding:8%;
  font-size:1.9vh;font-weight:700;color:#fff;line-height:1.2}}
.navbar{{position:absolute;left:8%;right:8%;bottom:3.5%;height:8.5vh;background:rgba(255,255,255,.06);
  border:1px solid rgba(255,255,255,.09);border-radius:6vh;display:flex;justify-content:space-around;align-items:center;
  color:#8a8a90;font-size:1.9vh}}
.navbar .a{{color:#fff}}
.sicons{{display:flex;align-items:center;gap:1.5vh}}
.sig{{display:flex;align-items:flex-end;gap:.5vh;height:2.1vh}}
.sig i{{width:.75vh;background:#ECECEC;border-radius:1px}}
.bat{{width:4.4vh;height:2.1vh;border:.35vh solid #ECECEC;border-radius:.7vh;position:relative}}
.bat::after{{content:'';position:absolute;left:.4vh;top:.4vh;bottom:.4vh;right:1.2vh;background:#ECECEC;border-radius:.2vh}}
.bat::before{{content:'';position:absolute;right:-.85vh;top:.6vh;bottom:.6vh;width:.5vh;background:#ECECEC;border-radius:1px}}
"""

STATUS = ("<div class='sicons'>"
  "<div class='sig'><i style='height:35%'></i><i style='height:55%'></i>"
  "<i style='height:78%'></i><i style='height:100%'></i></div>"
  "<div class='bat'></div></div>")

# ── 앱 화면 목업들 ───────────────────────────────────────────────
def screen_lyra():
    return f"""
    <div class='sbar'><span>9:41</span>{STATUS}</div>
    <div class='appbar'>홈</div>
    <div class='pad' style='margin-top:2vh'>
      <div style='color:#838383;font-size:2.2vh;margin:1vh 0 3vh'>오늘은 어떤 문장에 멈췄어?</div>
      <div class='card' style='border-color:rgba(125,231,160,.35)'>
        <div class='mrow'><span class='lyra-dot'></span><span class='lyra-label'>Lyra의 물음</span></div>
        <div class='lyra-q'>돈을 쓸 때 없어서 불안한 마음과 지금 가지고 있어서 좋은 마음, 최근에 뭔가를 살 때 어느 쪽이 더 컸어?</div>
        <div class='lyra-cta'>✎ 이 물음에 메모 남기기</div>
      </div>
    </div>"""

def screen_memo():
    return f"""
    <div class='sbar'><span>9:41</span>{STATUS}</div>
    <div class='appbar'>메모</div>
    <div class='pad' style='margin-top:1vh'>
      <div class='card' style='padding:6% 6% 6%'>
        <div class='mrow'><div class='avatar'></div><div><div class='mname'>밀키웨이</div><div class='mdate'>2026.08.12</div></div></div>
        <div class='mtag'>I have</div>
        <div class='mtext'>아침 출근길에 생각을 돌아보게 하는 책을 가지고 있다</div>
        <div class='mtag'>I feel</div>
        <div class='mtext'>스스로를 돌아보고 지금의 나를 더 넓은 폭에서 생각하게 된다. 다음 스텝에 대한 용기도 얻는다 😊</div>
        <div class='mmeta'>더 해빙 The Having / 42쪽</div>
      </div>
    </div>"""

def screen_constellation():
    return f"""
    <div class='sbar'><span>9:41</span>{STATUS}</div>
    <div class='appbar'>별자리</div>
    <div class='pad' style='margin-top:1vh'>
      <div class='card'>
        <span class='relchip'>다시 떠오름</span>
        <div class='mtext' style='margin-top:2.6vh'>과거엔 why를 발굴하는 게 진행형이라 했는데, 지금은 그 why가 어디서 오는지까지 더 깊이 밀고 나갔네</div>
        <div class='mini'><div class='l'>그때 / 3월</div><div class='t'>내가 진짜 원하는 게 뭔지 계속 찾는 중이다</div></div>
        <div class='mini'><div class='l'>지금 / 8월</div><div class='t'>원하는 이유의 뿌리까지 내려가 보니 조금 선명해졌다</div></div>
      </div>
    </div>"""

def screen_books():
    covers = [("#EAE3D2","더 해빙"),("#1b1b1e","타이탄의 도구"),("#0E2A6B","트라이브즈"),
              ("#E7ECEF","아이디어 불패"),("#111","퓨처 셀프"),("#F2C94C","넛지"),
              ("#Efe7d8","Same as Ever"),("#E8542A","페이머스"),("#20355f","제로 투 원")]
    cells = "".join(f"<div class='bk' style='background:{c}'>{t}</div>" for c,t in covers)
    return f"""
    <div class='sbar'><span>9:41</span>{STATUS}</div>
    <div class='appbar'>책</div>
    <div class='pad'><div style='margin:1vh 0 3vh'><span class='chip on'>모든 책</span><span class='chip'>읽는 중</span><span class='chip'>완독</span></div>
      <div class='grid'>{cells}</div></div>"""

def screen_together():
    return f"""
    <div class='sbar'><span>9:41</span>{STATUS}</div>
    <div class='appbar'>메모</div>
    <div class='pad' style='margin-top:1vh'>
      <div style='margin-bottom:2.4vh'><span class='chip'>내 메모</span><span class='chip on'>공개</span></div>
      <div class='card'>
        <div class='mrow'><div class='avatar'></div><div><div class='mname'>은하수 여행자</div><div class='mdate'>어제</div></div></div>
        <div class='mtext' style='margin-top:2.4vh'>둘 다 불안감이 있었지만 결국 내가 사고 마음이 편했던 걸 더 오래 쓰더라</div>
        <div class='mmeta'>💬 3 / 더 해빙 The Having</div>
      </div>
    </div>"""

SCREENS = {"lyra":screen_lyra,"memo":screen_memo,"con":screen_constellation,"books":screen_books,"tog":screen_together}

# ── 슬라이드(카피 + 화면) ────────────────────────────────────────
SLIDES = [
  dict(name="01_hook", screen="memo",
       head="책을 읽다<br>멈춘 <span class='accent'>순간</span>", sub="밑줄 대신 마음을 기록하는 독서 메모"),
  dict(name="02_lyra", screen="lyra",
       head="Lyra가 문장에<br><span class='accent'>질문</span>을 건네", sub="혼자 읽어도 대화하듯 더 깊이"),
  dict(name="03_connect", screen="con",
       head="메모가 모여<br><span class='accent'>별자리</span>가 돼", sub="닮음 / 확장 / 다시 떠오름"),
  dict(name="04_together", screen="tog",
       head="같은 책에 멈춘<br><span class='accent'>사람들</span>과 나눠", sub="생각을 잇는 조용한 독서 모임"),
  dict(name="05_universe", screen="books",
       head="읽은 만큼<br>넓어지는 <span class='accent'>우주</span>", sub="담은 책 / 메모 / 완독까지 한눈에"),
]

def page(size, slide):
    w,h = size
    head_fs = h*0.046; sub_fs = h*0.023
    # 폰 크기: 화면 하단을 채우게
    pw = w*0.72; ph = pw*2.04
    ptop = h*0.325
    return f"""<!doctype html><html><head><meta charset='utf-8'><style>{CSS}
    .head{{font-size:{head_fs}px}} .sub{{font-size:{sub_fs}px}}
    .phone-wrap{{top:{ptop}px}} .phone{{width:{pw}px;height:{ph}px}}
    </style></head><body><div class='frame'>
      {stars(90,w,h)}
      <div class='wordmark'>M I L K Y W A Y</div>
      <div class='copy'><div class='head'>{slide['head']}</div><div class='sub'>{slide['sub']}</div></div>
      <div class='phone-wrap'><div class='phone'><div class='screen'>{SCREENS[slide['screen']]()}</div></div></div>
    </div></body></html>"""

def render(html, out, w, h):
    f = os.path.join(OUT, "_tmp.html")
    open(f,"w").write(html)
    subprocess.run([CHROME,"--headless=new","--disable-gpu","--hide-scrollbars",
      f"--force-device-scale-factor=1",f"--screenshot={out}",f"--window-size={w},{h}",
      f"file://{f}"], capture_output=True)
    print("rendered", os.path.basename(out))

def insta(w,h):
    head_fs=h*0.056; sub_fs=h*0.026
    pw=w*0.56; ph=pw*2.04; ptop=h*0.40
    return f"""<!doctype html><html><head><meta charset='utf-8'><style>{CSS}
    .head{{font-size:{head_fs}px}} .sub{{font-size:{sub_fs}px}}
    .copy{{top:9%}} .wordmark{{top:5%}}
    .phone-wrap{{top:{ptop}px}} .phone{{width:{pw}px;height:{ph}px}}
    .cta{{position:absolute;bottom:6%;left:0;right:0;text-align:center}}
    .cta b{{background:{GREEN};color:#0d0d12;font-size:{h*0.026}px;font-weight:800;
      padding:2vh 5vh;border-radius:99px}}
    .cta .n{{color:#9AA0A6;font-size:{h*0.02}px;margin-top:2.4vh}}
    </style></head><body><div class='frame'>
      {stars(70,w,h)}
      <div class='wordmark'>M I L K Y W A Y</div>
      <div class='copy'><div class='head'>책 읽다 멈춘 순간,<br><span class='accent'>어디에</span> 담아?</div>
        <div class='sub'>여운을 담는 독서 메모</div></div>
      <div class='phone-wrap'><div class='phone'><div class='screen'>{screen_lyra()}</div></div></div>
      <div class='cta'><b>지금 무료로 시작</b><div class='n'>밀키웨이 / App Store / Google Play</div></div>
    </div></body></html>"""

def feature(w,h):
    pw=h*0.92; ph=pw*2.04
    return f"""<!doctype html><html><head><meta charset='utf-8'><style>{CSS}
    .frame{{display:flex;align-items:center}}
    .fg-left{{position:absolute;left:7%;top:0;bottom:0;width:52%;display:flex;flex-direction:column;justify-content:center}}
    .fg-mark{{color:#ECECEC;font-size:{h*0.05}px;font-weight:700;letter-spacing:.28em}}
    .fg-head{{color:#fff;font-size:{h*0.115}px;font-weight:800;line-height:1.2;letter-spacing:-.02em;margin-top:{h*0.05}px}}
    .fg-sub{{color:#9AA0A6;font-size:{h*0.045}px;margin-top:{h*0.045}px}}
    .phone{{position:absolute;right:5%;top:{h*0.16}px;width:{pw}px;height:{ph}px;transform:rotate(-6deg)}}
    </style></head><body><div class='frame'>
      {stars(40,w,h)}
      <div class='fg-left'>
        <div class='fg-mark'>M I L K Y W A Y</div>
        <div class='fg-head'>책 읽다 멈춘<br>순간을 담다</div>
        <div class='fg-sub'>메모 / Lyra의 물음 / 함께 읽기</div>
      </div>
      <div class='phone'><div class='screen'>{screen_lyra()}</div></div>
    </div></body></html>"""

SIZES = {"appstore":(1320,2868), "play":(1080,1920)}

if __name__ == "__main__":
    for store,(w,h) in SIZES.items():
        for s in SLIDES:
            render(page((w,h),s), os.path.join(OUT,f"{store}_{s['name']}.png"), w, h)
    render(insta(1080,1350), os.path.join(OUT,"instagram_ad.png"), 1080,1350)
    render(feature(1024,500), os.path.join(OUT,"play_feature_graphic.png"), 1024,500)
    print("done")
