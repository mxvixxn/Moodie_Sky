#!/usr/bin/env python3
"""Generate the Moodie Sky app icon: night sky + cream crescent moon + minimal stars.

Concept "C · minimal" — a deep midnight→indigo vertical sky, a large cream
crescent with a soft moon-glow halo and gentle vertical shading, and a few
tastefully placed stars. Replaces the old washed-out pastel card/cloud/pencil.

Run from the repo root:
  python3 scripts/gen_icon.py            # writes Default / Dark / Tinted appicon PNGs
  python3 scripts/gen_icon.py --layers   # writes Icon Composer layer inputs (docs/icon-layers)
"""
import math
import os
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageChops

SS = 4
SIZE = 1024
ASSET = "Moodie Sky/Assets.xcassets/AppIcon.appiconset"
LAYERS_DIR = "docs/icon-layers"

# --- palette ---------------------------------------------------------------
SKY = [(0.0, (10, 14, 42)), (0.5, (22, 28, 70)), (1.0, (42, 42, 94))]   # midnight -> indigo
MOON_TOP = (251, 246, 230)
MOON_BOT = (231, 220, 190)
GLOW = (251, 244, 222)
STAR = (246, 242, 226)

# geometry (fractions of canvas)
MOON_CX, MOON_CY, MOON_R = 0.48, 0.46, 0.196
CRESC_DX, CRESC_DY, CRESC_R = 0.50, -0.12, 0.97   # relative to MOON_R
STARS = [   # (x, y, radius, kind) kind: 's' sparkle, 'd' dot ; radius in canvas frac
    (0.74, 0.28, 0.032, 's'),
    (0.29, 0.61, 0.026, 's'),
    (0.81, 0.54, 0.021, 's'),
    (0.65, 0.21, 0.011, 'd'),
    (0.24, 0.42, 0.010, 'd'),
    (0.86, 0.385, 0.010, 'd'),
    (0.55, 0.81, 0.010, 'd'),
    (0.40, 0.72, 0.008, 'd'),
    (0.70, 0.70, 0.008, 'd'),
]


def vgrad(size, stops):
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        t = y / (size - 1)
        for i in range(len(stops) - 1):
            t0, c0 = stops[i]; t1, c1 = stops[i + 1]
            if t0 <= t <= t1:
                f = (t - t0) / (t1 - t0)
                col = tuple(int(c0[j] + (c1[j] - c0[j]) * f) for j in range(3))
                break
        else:
            col = stops[-1][1]
        for x in range(size):
            px[x, y] = col
    return img


def paste_glow(img, cx, cy, r, color, peak=110):
    """Soft radial halo via a blurred disc used as alpha."""
    s = img.size[0]
    a = Image.new("L", (s, s), 0)
    ImageDraw.Draw(a).ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
    a = a.filter(ImageFilter.GaussianBlur(r * 0.85))
    a = a.point(lambda v: int(v * peak / 255))
    tint = Image.new("RGB", (s, s), color)
    img.paste(tint, (0, 0), a)


def sparkle(draw, x, y, r, color):
    k = 0.24
    draw.polygon([(x, y - r), (x + k * r, y - k * r), (x + r, y), (x + k * r, y + k * r),
                  (x, y + r), (x - k * r, y + k * r), (x - r, y), (x - k * r, y - k * r)],
                 fill=color)


def draw_stars(img, color, glow=True):
    s = img.size[0]
    if glow:
        g = Image.new("L", (s, s), 0)
        gd = ImageDraw.Draw(g)
        for (fx, fy, fr, kind) in STARS:
            if kind == 's':
                x, y, r = fx * s, fy * s, fr * s
                gd.ellipse([x - r * 1.6, y - r * 1.6, x + r * 1.6, y + r * 1.6], fill=90)
        g = g.filter(ImageFilter.GaussianBlur(s * 0.01))
        img.paste(Image.new("RGB", (s, s), color), (0, 0), g)
    d = ImageDraw.Draw(img)
    for (fx, fy, fr, kind) in STARS:
        x, y, r = fx * s, fy * s, fr * s
        if kind == 's':
            sparkle(d, x, y, r, color)
        else:
            d.ellipse([x - r, y - r, x + r, y + r], fill=color)


def crescent_mask(s, cx, cy, r):
    m = Image.new("L", (s, s), 0)
    md = ImageDraw.Draw(m)
    md.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
    ox, oy, orr = cx + CRESC_DX * r, cy + CRESC_DY * r, CRESC_R * r
    md.ellipse([ox - orr, oy - orr, ox + orr, oy + orr], fill=0)
    return m


def paste_moon(img, cx, cy, r, top, bot):
    s = img.size[0]
    fill = vgrad(s, [(0.0, top), (1.0, bot)])  # vertical shading
    img.paste(fill, (0, 0), crescent_mask(s, cx, cy, r))


def render(kind="default"):
    s = SIZE * SS
    cx, cy, r = MOON_CX * s, MOON_CY * s, MOON_R * s

    if kind == "tinted":
        # Grayscale luminance image: dark bg + light foreground; system applies the tint.
        img = Image.new("RGB", (s, s), (14, 14, 18))
        draw_stars(img, (235, 235, 235), glow=False)
        paste_moon(img, cx, cy, r, (240, 240, 240), (205, 205, 205))
        return img.resize((SIZE, SIZE), Image.LANCZOS)

    img = vgrad(s, SKY)
    # faint horizon lift for depth
    hz = Image.new("L", (s, s), 0)
    ImageDraw.Draw(hz).ellipse([-s * 0.2, s * 0.82, s * 1.2, s * 1.35], fill=70)
    hz = hz.filter(ImageFilter.GaussianBlur(s * 0.06))
    img.paste(Image.new("RGB", (s, s), (58, 60, 118)), (0, 0), hz)

    draw_stars(img, STAR, glow=True)
    paste_glow(img, cx, cy, r * 1.15, GLOW, peak=95)
    paste_moon(img, cx, cy, r, MOON_TOP, MOON_BOT)
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def export_layers(dirpath):
    os.makedirs(dirpath, exist_ok=True)
    s = SIZE * SS
    cx, cy, r = MOON_CX * s, MOON_CY * s, MOON_R * s

    vgrad(s, SKY).resize((SIZE, SIZE), Image.LANCZOS).save(os.path.join(dirpath, "background.png"))

    stars = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    sd = ImageDraw.Draw(stars)
    for (fx, fy, fr, kind) in STARS:
        x, y, rr = fx * s, fy * s, fr * s
        if kind == 's':
            sparkle(sd, x, y, rr, STAR + (255,))
        else:
            sd.ellipse([x - rr, y - rr, x + rr, y + rr], fill=STAR + (255,))
    stars.resize((SIZE, SIZE), Image.LANCZOS).save(os.path.join(dirpath, "stars.png"))

    moon = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    fill = vgrad(s, [(0.0, MOON_TOP), (1.0, MOON_BOT)]).convert("RGBA")
    moon.paste(fill, (0, 0), crescent_mask(s, cx, cy, r))
    moon.resize((SIZE, SIZE), Image.LANCZOS).save(os.path.join(dirpath, "moon.png"))
    for n in ("background.png", "stars.png", "moon.png"):
        print("wrote", os.path.join(dirpath, n))


def main():
    if "--layers" in sys.argv:
        export_layers(LAYERS_DIR)
        return
    os.makedirs(ASSET, exist_ok=True)
    render("default").save(os.path.join(ASSET, "MoodieSky-AppIcon.png"))
    render("default").save(os.path.join(ASSET, "MoodieSky-AppIcon-Dark.png"))
    render("tinted").save(os.path.join(ASSET, "MoodieSky-AppIcon-Tinted.png"))
    for n in ("MoodieSky-AppIcon.png", "MoodieSky-AppIcon-Dark.png", "MoodieSky-AppIcon-Tinted.png"):
        print("wrote", os.path.join(ASSET, n))


if __name__ == "__main__":
    main()
