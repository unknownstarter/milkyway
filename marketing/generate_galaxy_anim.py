#!/usr/bin/env python3
# 은하 오브 애니메이션 - 제자리 자전 + 뒤 글로우 펄스 -> GIF.
# 유리구/스펙큘러 고정, 내부 은하(galaxy)만 회전. 아우라 opacity가 사인으로 호흡.
import os, sys, math, subprocess
from PIL import Image
from generate_galaxy_tiers import build_orb_html, TIER_BY_KEY, STAGE, OUT, CHROME

def render_frame(html, out):
    tmp = out.replace(".png", ".html")
    with open(tmp, "w") as f:
        f.write(html)
    subprocess.run([CHROME, "--headless", "--disable-gpu", "--hide-scrollbars",
                    "--default-background-color=00000000", "--force-device-scale-factor=1",
                    f"--window-size={STAGE},{STAGE}", f"--screenshot={out}", f"file://{tmp}"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.remove(tmp)

def make_gif(key, N=40, size=440, duration=110, bg=(10, 10, 14)):
    t = TIER_BY_KEY[key]
    frames = []
    for i in range(N):
        ang = 360.0 * i / N
        glow = 0.80 + 0.20 * math.sin(2 * math.pi * i / N)
        fp = os.path.join(OUT, f"_frame_{key}_{i:02d}.png")
        render_frame(build_orb_html(t, angle=ang, glow=glow), fp)
        im = Image.open(fp).convert("RGBA").resize((size, size), Image.LANCZOS)
        base = Image.new("RGBA", (size, size), bg + (255,))
        base.alpha_composite(im)
        frames.append(base.convert("RGB").convert("P", palette=Image.ADAPTIVE, colors=256))
        os.remove(fp)
        print("frame", i + 1, "/", N)
    out = os.path.join(OUT, f"galaxy_{key}_anim.gif")
    frames[0].save(out, save_all=True, append_images=frames[1:], duration=duration,
                   loop=0, optimize=True, disposal=2)
    print("wrote", out)
    return out

if __name__ == "__main__":
    key = sys.argv[1] if len(sys.argv) > 1 else "t5"
    make_gif(key)
