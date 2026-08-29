#!/usr/bin/env python3
# 6단계 은하 오브 자전+글로우 몽타주 GIF(2x3). 미리보기용.
import os, sys, math, subprocess
from PIL import Image, ImageDraw
from generate_galaxy_tiers import build_orb_html, TIERS, STAGE, OUT, CHROME

def render_frame(html, out):
    tmp = out.replace(".png", ".html")
    with open(tmp, "w") as f:
        f.write(html)
    subprocess.run([CHROME, "--headless", "--disable-gpu", "--hide-scrollbars",
                    "--default-background-color=00000000", "--force-device-scale-factor=1",
                    f"--window-size={STAGE},{STAGE}", f"--screenshot={out}", f"file://{tmp}"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.remove(tmp)

def make(N=24, cell=250, gap=8, duration=120, bg=(10, 10, 14)):
    cols, rows = 3, 2
    W = cols * cell + (cols + 1) * gap
    H = rows * cell + (rows + 1) * gap
    frames = []
    for i in range(N):
        ang = 360.0 * i / N
        glow = 0.80 + 0.20 * math.sin(2 * math.pi * i / N)
        sheet = Image.new("RGBA", (W, H), bg + (255,))
        for idx, t in enumerate(TIERS):
            fp = os.path.join(OUT, f"_af_{t['key']}_{i:02d}.png")
            render_frame(build_orb_html(t, angle=ang, glow=glow), fp)
            im = Image.open(fp).convert("RGBA").resize((cell, cell), Image.LANCZOS)
            os.remove(fp)
            cx = gap + (idx % cols) * (cell + gap)
            cy = gap + (idx // cols) * (cell + gap)
            sheet.alpha_composite(im, (cx, cy))
        frames.append(sheet.convert("RGB").convert("P", palette=Image.ADAPTIVE, colors=256))
        print("frame", i + 1, "/", N)
    out = os.path.join(OUT, "galaxy_all_anim.gif")
    frames[0].save(out, save_all=True, append_images=frames[1:], duration=duration,
                   loop=0, optimize=True, disposal=2)
    print("wrote", out)

if __name__ == "__main__":
    make()
