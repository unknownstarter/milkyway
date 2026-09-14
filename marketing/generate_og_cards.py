#!/usr/bin/env python3
"""공유 링크 OG 썸네일 6장(티어별) 생성.

왜 필요한가: og:image가 텍스트 없는 맨 구슬 사진이라 카톡 미리보기에 보라색 공만
덩그러니 떠서 "아무 정보 없다"는 인상을 준다. 오브 + 단계명 + 워드마크가 얹힌
카드로 바꾼다. 사용자마다 만들지 않고 티어당 1장씩 한 번만 굽는다.

출력: marketing/og_{tier}.jpg (1200x630, OG 표준 비율)
업로드: share_cards/og/{tier}.jpg  (scripts/upload_og_cards.sh)

오브는 앱과 같은 자산을 쓴다(core + glass 합성, 투명 배경).
폰트는 리포의 NotoSansKR. 색은 orb_palette.dart 와 동일해야 한다.
"""
import os
import random
import urllib.request

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORB_DIR = os.path.join(ROOT, 'assets', 'images', 'orb')
FONT_DIR = os.path.join(ROOT, 'assets', 'fonts')
OUT = os.path.dirname(os.path.abspath(__file__))

W, H = 1200, 630
BG = (8, 8, 14)

# lib/features/orb/presentation/widgets/orb_palette.dart 와 동일.
TIERS = [
    ('t1', '작은 성운', (0x9D, 0xB4, 0xFF)),
    ('t2', '별무리', (0xA9, 0x9C, 0xFF)),
    ('t3', '별자리', (0x9A, 0x8C, 0xFF)),
    ('t4', '성단', (0xC4, 0x8C, 0xFF)),
    ('t5', '은하', (0xFF, 0x9E, 0xCB)),
    ('t6', '대은하', (0xFF, 0xC2, 0x4D)),
]

TAGLINE = '책을 멈춘 순간이 모여 만든 우주'

# 랜딩 페이지가 보여주는 바로 그 오브를 쓴다(카드와 페이지가 달라 보이면 안 된다).
ORB_CDN = ('https://hyjgfgzexvxhgfmqgiqu.supabase.co'
           '/storage/v1/object/public/share_cards/orb/{tier}.jpg')
CACHE = os.path.join(OUT, '.cache_og')


def font(name, size):
    return ImageFont.truetype(os.path.join(FONT_DIR, name), size)


def star_layer(seed: int) -> Image.Image:
    """별 배경. 티어마다 다른 하늘이지만 실행할 때마다 같게(seed 고정)."""
    rnd = random.Random(seed)
    layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for _ in range(220):
        x, y = rnd.uniform(0, W), rnd.uniform(0, H)
        r = rnd.uniform(0.6, 1.9)
        a = int(rnd.uniform(0.12, 0.75) * 255)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 255, a))
    return layer


def glow(color, size, alpha=0.30) -> Image.Image:
    """오브 뒤 아우라. 큰 원 하나를 흐려서 만든다.
    캔버스 여백(pad)이 블러 반경보다 넉넉해야 한다. 좁으면 캔버스 경계에서
    알파가 0이 되기 전에 잘려 **사각형 자국**이 남는다(실제로 그랬다)."""
    g = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(g)
    pad = size * 0.27
    d.ellipse([pad, pad, size - pad, size - pad],
              fill=(*color, int(alpha * 255)))
    return g.filter(ImageFilter.GaussianBlur(size * 0.075))


def fetch_orb(tier: str) -> str:
    """랜딩이 쓰는 공개 오브 이미지를 받아 캐시한다."""
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, f'{tier}.jpg')
    if not os.path.exists(path):
        urllib.request.urlretrieve(ORB_CDN.format(tier=tier), path)
    return path


def orb_image(tier: str, size: int) -> Image.Image:
    """공개 오브 jpg는 배경이 투명이 아니라 그냥 얹으면 사각 테두리가 보인다.
    랜딩의 CSS 마스크와 같은 방식으로 가장자리를 원형 페이드아웃시킨다."""
    im = Image.open(fetch_orb(tier)).convert('RGB').resize((size, size), Image.LANCZOS)
    mask = Image.new('L', (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.ellipse([0, 0, size, size], fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(size * 0.035))
    out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out


def build(tier: str, name: str, accent, idx: int) -> str:
    card = Image.new('RGBA', (W, H), (*BG, 255))
    card.alpha_composite(star_layer(1000 + idx))

    orb_size = 430
    ox, oy = 92, (H - orb_size) // 2

    g = glow(accent, int(orb_size * 2.1))
    card.alpha_composite(g, (ox - (g.width - orb_size) // 2,
                             oy - (g.height - orb_size) // 2))
    card.alpha_composite(orb_image(tier, orb_size), (ox, oy))

    d = ImageDraw.Draw(card)
    tx = ox + orb_size + 78

    # 워드마크. 자간을 직접 벌린다(PIL은 letter-spacing이 없다).
    wm_font = font('NotoSansKR-Bold.ttf', 24)
    cx = tx
    for ch in 'MILKYWAY':
        d.text((cx, 196), ch, font=wm_font, fill=(170, 170, 186, 255))
        cx += d.textlength(ch, font=wm_font) + 7

    d.text((tx, 248), name, font=font('NotoSansKR-Black.ttf', 96),
           fill=(*accent, 255))
    d.text((tx, 372), '단계의 우주', font=font('NotoSansKR-Bold.ttf', 42),
           fill=(236, 236, 236, 255))
    d.text((tx, 448), TAGLINE, font=font('NotoSansKR-Regular.ttf', 26),
           fill=(154, 154, 168, 255))

    path = os.path.join(OUT, f'og_{tier}.jpg')
    card.convert('RGB').save(path, 'JPEG', quality=88, optimize=True)
    return path


if __name__ == '__main__':
    for i, (tier, name, accent) in enumerate(TIERS):
        p = build(tier, name, accent, i)
        print(f'{os.path.basename(p):14} {os.path.getsize(p) / 1024:6.0f} KB  {name}')
