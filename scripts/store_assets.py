#!/usr/bin/env python3
"""Store listing graphics for a game, driven by <game>/store/store.json (see skills/store-release).

  store_assets.py icons   <game>      iOS 1024 (no alpha) and Google Play 512 icons
  store_assets.py feature <game>      Google Play feature graphic 1024x500 (the "banner")
  store_assets.py shots   <game>      captioned screenshots per store and locale from raw gameplay frames
  store_assets.py all     <game>      all of the above

Output goes to <game>/store/out/. Sizes follow the stores' own spec pages (checked 2026-10-21):
  Google Play: icon 512x512 PNG (<=1024 KB), feature graphic 1024x500 no alpha, phone screenshots 2-8,
               320-3840 px per side, long side at most twice the short side.
  App Store:   iPhone needs one 6.3" (1206x2622 or 1179x2556) shot; 6.9" (1320x2868) is optional but scales best.
               1-10 per size, PNG/JPEG, no alpha.
"""
import json, sys, textwrap
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

APPLE_SIZES = {"iphone_6.9": (1320, 2868), "iphone_6.3": (1206, 2622)}
PLAY_SIZES = {"phone": (1080, 1920)}


def load(game: Path) -> dict:
    cfg = json.loads((game / "store" / "store.json").read_text())
    cfg["_game"] = game
    return cfg


def rgb(h: str):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def gradient(size, top, bottom):
    w, h = size
    im = Image.new("RGB", size, top)
    px = ImageDraw.Draw(im)
    t, b = rgb(top), rgb(bottom)
    for y in range(h):
        k = y / max(h - 1, 1)
        px.line([(0, y), (w, y)], fill=tuple(round(t[i] + (b[i] - t[i]) * k) for i in range(3)))
    return im


def font(cfg, size, locale="en"):
    """Per-locale font: style.fonts {"default": path, "tr": path}, optional style.variation {"tr": "Bold"} for variable fonts."""
    st = cfg["style"]
    path = st.get("fonts", {}).get(locale) or st.get("fonts", {}).get("default") or st["font"]
    f = ImageFont.truetype(str(cfg["_game"] / path), size)
    var = st.get("variation", {}).get(locale)
    if var:
        f.set_variation_by_name(var)
    return f


def _glyph_sig(f, ch):
    m = f.getmask(ch)
    return (m.size, bytes(m)) if m.getbbox() else None


def missing_glyphs(f, text):
    """Characters the font cannot draw. A missing glyph renders as blank or as the font's "tofu" box, so each character is
    compared with the picture of U+FFFF (never in a font) instead of only testing for blank."""
    notdef = _glyph_sig(f, "\uffff")
    return sorted({c for c in text if not c.isspace() and _glyph_sig(f, c) == notdef})


def draw_centered(im, text, box, cfg, max_size, min_size=24, locale="en"):
    """Fit `text` into box=(x0,y0,x1,y1): wrap on words, shrink until it fits, centre."""
    st = cfg["style"]
    x0, y0, x1, y1 = box
    d = ImageDraw.Draw(im)
    bad = missing_glyphs(font(cfg, 40, locale), text)
    if bad:
        sys.exit(f"font for locale '{locale}' has no glyph for {bad} in \"{text}\": set style.fonts.{locale} in store.json")
    for size in range(max_size, min_size - 1, -4):
        f = font(cfg, size, locale)
        width_chars = max(8, int((x1 - x0) / (size * 0.52)))
        lines = textwrap.wrap(text, width=width_chars) or [text]
        line_h = int(size * 1.12)
        total = line_h * len(lines)
        widest = max(d.textlength(l, font=f) for l in lines)
        if total <= y1 - y0 and widest <= x1 - x0:
            break
    y = y0 + (y1 - y0 - total) / 2
    for l in lines:
        w = d.textlength(l, font=f)
        d.text(((x0 + x1 - w) / 2, y), l, font=f, fill=st["text"], stroke_width=max(2, size // 14), stroke_fill=st["outline"])
        y += line_h


def rounded(im, radius):
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, im.size[0] - 1, im.size[1] - 1], radius=radius, fill=255)
    out = im.convert("RGBA")
    out.putalpha(mask)
    return out


def icons(cfg):
    out = cfg["_game"] / "store" / "out" / "icons"
    out.mkdir(parents=True, exist_ok=True)
    src = Image.open(cfg["_game"] / cfg["icon"]).convert("RGB")
    src.resize((1024, 1024), Image.LANCZOS).save(out / "ios_1024.png")
    p = src.resize((512, 512), Image.LANCZOS).convert("RGBA")
    p.save(out / "play_512.png", optimize=True)
    size_kb = (out / "play_512.png").stat().st_size / 1024
    print(f"icons: ios_1024.png, play_512.png ({size_kb:.0f} KB, limit 1024)")
    assert size_kb <= 1024, "Play icon over 1024 KB"


def feature(cfg):
    g = cfg["_game"]
    f = cfg["feature"]
    st = cfg["style"]
    W, H = 1024, 500
    im = gradient((W, H), st["bg_top"], st["bg_bottom"]).convert("RGBA")
    if st.get("feature_bg"):
        im = backdrop(cfg, st["feature_bg"], (W, H), top_shade=0.0)
    # soft blobs
    blobs = st.get("blobs") or [(120, 80, 260, "#FFC8D8"), (900, 420, 300, "#BFE6FF"), (520, 520, 220, "#C9F2DD")]   # style.blobs: [[x, y, r, "#hex"], ...]
    for cx, cy, r, col in blobs:
        blob = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(blob).ellipse([cx - r, cy - r, cx + r, cy + r], fill=rgb(col) + (st.get("blob_alpha", 90),))
        im = Image.alpha_composite(im, blob.filter(ImageFilter.GaussianBlur(40)))
    for item in f["hero"]:
        art = Image.open(g / item["img"]).convert("RGBA")
        s = item["size"]
        art = art.resize((s, int(art.size[1] * s / art.size[0])), Image.NEAREST if item.get("nearest") else Image.LANCZOS)   # "nearest": true keeps pixel art crisp
        art = art.rotate(item.get("rot", 0), resample=Image.BICUBIC, expand=True)
        shadow = Image.new("RGBA", im.size, (0, 0, 0, 0))
        sh = Image.new("RGBA", art.size, (60, 40, 100, 90))
        sh.putalpha(art.getchannel("A").point(lambda v: v * 90 // 255))
        shadow.paste(sh, (item["x"] - art.size[0] // 2 + 6, item["y"] - art.size[1] // 2 + 10), sh)
        im = Image.alpha_composite(im, shadow.filter(ImageFilter.GaussianBlur(6)))
        layer = Image.new("RGBA", im.size, (0, 0, 0, 0))
        layer.paste(art, (item["x"] - art.size[0] // 2, item["y"] - art.size[1] // 2), art)
        im = Image.alpha_composite(im, layer)
    draw_centered(im, f["title"], (40, 110, 520, 290), cfg, 150)
    draw_centered(im, f["tagline"], (40, 300, 520, 400), cfg, 54)
    out = g / "store" / "out"
    out.mkdir(parents=True, exist_ok=True)
    im.convert("RGB").save(out / "play_feature_1024x500.png")
    print("feature: play_feature_1024x500.png")


def backdrop(cfg, rel, size, top_shade=0.55):
    """Game artwork as the store background (lesson 0047): cover-fit, pixel-crisp, darker towards the caption area."""
    src = Image.open(cfg["_game"] / rel).convert("RGB")
    W, H = size
    k = max(W / src.size[0], H / src.size[1])
    src = src.resize((round(src.size[0] * k), round(src.size[1] * k)), Image.NEAREST)
    x, y = (src.size[0] - W) // 2, (src.size[1] - H) // 2
    im = src.crop((x, y, x + W, y + H)).convert("RGBA")
    shade = Image.new("L", size, 0)
    px = ImageDraw.Draw(shade)
    for yy in range(H):
        px.line([(0, yy), (W, yy)], fill=int(255 * top_shade * max(0.0, 1 - yy / (H * 0.35))))
    dark = Image.new("RGBA", size, (6, 4, 20, 255))
    dark.putalpha(shade)
    return Image.alpha_composite(im, dark)


def compose_shot(cfg, frame: Path, caption: str, size, locale="en", bg=None):
    st = cfg["style"]
    W, H = size
    bg = bg or st.get("bg_image")
    im = backdrop(cfg, bg, size) if bg else gradient(size, st["bg_top"], st["bg_bottom"]).convert("RGBA")
    cap_h = int(H * 0.21)
    draw_centered(im, caption, (int(W * 0.06), int(H * 0.03), int(W * 0.94), cap_h), cfg, int(W * 0.095), locale=locale)
    shot = Image.open(frame).convert("RGB")
    avail_h = H - cap_h - int(H * 0.035)
    avail_w = int(W * 0.9)
    k = min(avail_w / shot.size[0], avail_h / shot.size[1])
    shot = shot.resize((int(shot.size[0] * k), int(shot.size[1] * k)), Image.LANCZOS)
    card = rounded(shot, int(W * 0.045))
    x, y = (W - card.size[0]) // 2, cap_h + (avail_h - card.size[1]) // 2 + int(H * 0.005)
    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([x + 8, y + 18, x + card.size[0] + 8, y + card.size[1] + 18], radius=int(W * 0.045), fill=(60, 40, 100, 110))
    im = Image.alpha_composite(im, shadow.filter(ImageFilter.GaussianBlur(18)))
    im.paste(card, (x, y), card)
    return im.convert("RGB")


def shots(cfg):
    g = cfg["_game"]
    spec = cfg["shots"]
    out = g / "store" / "out"
    n = 0
    for locale in cfg["locales"]:
        for store, sizes in (("apple", APPLE_SIZES), ("play", PLAY_SIZES)):
            for name, size in sizes.items():
                d = out / store / locale / name
                d.mkdir(parents=True, exist_ok=True)
                for i, s in enumerate(spec, 1):
                    frame = g / s.get("frame_" + locale, s["frame"])
                    if not frame.is_file():
                        sys.exit(f"missing raw frame {frame} (run the capture playtests, see skills/store-release)")
                    img = compose_shot(cfg, frame, s["caption"][locale], size, locale, s.get("bg"))
                    img.save(d / f"{i:02d}.png")
                    n += 1
    print(f"shots: {n} images in {out}")


if __name__ == "__main__":
    if len(sys.argv) < 3 or sys.argv[1] not in {"icons", "feature", "shots", "all"}:
        sys.exit(__doc__)
    c = load(Path(sys.argv[2]).resolve())
    for step in (["icons", "feature", "shots"] if sys.argv[1] == "all" else [sys.argv[1]]):
        globals()[step](c)
