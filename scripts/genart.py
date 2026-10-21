#!/usr/bin/env python3
"""Generate one flat/clean 2D game asset with the Gemini image API, then cut it out for the game.

  genart.py --set-limit USD           # REQUIRED once: hard spending cap for all generations
  genart.py --status                  # spent / limit / remaining
  genart.py <out.png> "<prompt>" [--ref anchor.png ...] [--size 256] [--model NAME] [--keep-bg] [--raw]

Credit limit: every call is refused when no limit is set or when (spent + estimated cost) would exceed it.
Spend is an estimate (conservative per-image prices below) kept in ~/.game-factory/genart_ledger.json;
check the real balance at https://ai.dev/spend. Raising the limit is the user's decision, never Claude's.

Needs GEMINI_API_KEY in the environment (never printed) and Pillow (pip3 install --user pillow).
The prompt is wrapped so the model draws the subject on a flat magenta (#FF00FF) background; the
background is then keyed out (soft edge + despill), the image is trimmed to the subject and fitted
into a square canvas of --size pixels with a small margin. Pass the approved anchor with --ref so
every asset of a game shares one style. --raw also saves the untouched model output next to the result.
"""
import argparse, base64, contextlib, fcntl, json, os, sys, urllib.error, urllib.request
from io import BytesIO
from pathlib import Path

DEFAULT_MODEL = "gemini-3.1-flash-image"
# Conservative USD estimate per generated image (rounded up; verify against the real bill).
COST_USD = {"gemini-3.1-flash-image": 0.08, "gemini-3.1-flash-image-preview": 0.08,
            "gemini-3.1-flash-lite-image": 0.05, "gemini-2.5-flash-image": 0.05,
            "gemini-3-pro-image": 0.25, "gemini-3-pro-image-preview": 0.25}
UNKNOWN_COST = 0.25
LEDGER = Path.home() / ".game-factory" / "genart_ledger.json"
KEY_RGB = (255, 0, 255)
WRAP = (
    "{prompt}\n\nDraw exactly one centered game asset, nothing else. Background: perfectly flat solid "
    "magenta #FF00FF, no gradient, no shadow on the background, no ground, no text. The subject itself "
    "must not contain magenta. Clean edges, whole subject visible with space around it."
)


@contextlib.contextmanager
def ledger_lock():
    LEDGER.parent.mkdir(parents=True, exist_ok=True)
    with open(LEDGER.with_suffix(".lock"), "w") as f:
        fcntl.flock(f, fcntl.LOCK_EX)
        yield


def load_ledger():
    try:
        return json.loads(LEDGER.read_text())
    except (OSError, ValueError):
        return {"limit_usd": None, "entries": []}


def save_ledger(led):
    LEDGER.parent.mkdir(parents=True, exist_ok=True)
    LEDGER.write_text(json.dumps(led, indent=1))


def spent(led):
    return sum(e["usd"] for e in led["entries"])


def check_budget(model):
    led = load_ledger()
    cost = COST_USD.get(model, UNKNOWN_COST)
    if led["limit_usd"] is None:
        sys.exit("No credit limit set. Ask the user for a limit, then run: genart.py --set-limit USD")
    if spent(led) + cost > led["limit_usd"]:
        sys.exit(f"Credit limit reached: spent ~${spent(led):.2f} of ${led['limit_usd']:.2f}, next image ~${cost:.2f}. "
                 "Stop and tell the user; only the user may raise the limit (--set-limit).")
    return led, cost


def call_api(model, prompt, refs, aspect=None):
    key = os.environ.get("GEMINI_API_KEY")
    if not key:
        sys.exit("GEMINI_API_KEY is not set (add it to ~/.zshrc and restart the shell)")
    parts = [{"text": prompt}]
    for r in refs:
        parts.append({"inline_data": {"mime_type": "image/png", "data": base64.b64encode(Path(r).read_bytes()).decode()}})
    gen = {"responseModalities": ["IMAGE"]}
    if aspect:
        gen["imageConfig"] = {"aspectRatio": aspect}
    body = json.dumps({"contents": [{"parts": parts}], "generationConfig": gen}).encode()
    req = urllib.request.Request(
        f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent",
        data=body, headers={"Content-Type": "application/json", "x-goog-api-key": key})
    try:
        with urllib.request.urlopen(req, timeout=180) as resp:
            data = json.load(resp)
    except urllib.error.HTTPError as e:
        msg = json.loads(e.read() or b"{}").get("error", {}).get("message", "")
        sys.exit(f"API error {e.code}: {msg[:300]}")
    for cand in data.get("candidates", []):
        for part in cand.get("content", {}).get("parts", []):
            inline = part.get("inlineData") or part.get("inline_data")
            if inline:
                return base64.b64decode(inline["data"])
    sys.exit("no image in response: " + json.dumps(data)[:300])


def key_out(img, lo=60, hi=140):
    """Make the magenta background transparent: fully inside `lo`, soft ramp up to `hi` (RGB distance)."""
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    kr, kg, kb = KEY_RGB
    for y in range(h):
        for x in range(w):
            r, g, b, _ = px[x, y]
            d = ((r - kr) ** 2 + (g - kg) ** 2 + (b - kb) ** 2) ** 0.5
            if d <= lo:
                px[x, y] = (0, 0, 0, 0)
            elif d < hi:
                a = int(255 * (d - lo) / (hi - lo))
                # despill: pull the magenta tint out of edge pixels
                m = min(r, b)
                r2, b2 = (r - max(0, m - g) * 0.8, b - max(0, m - g) * 0.8)
                px[x, y] = (int(max(0, r2)), g, int(max(0, b2)), a)
    return img


def fit(img, size, margin=0.06):
    bbox = img.getchannel("A").getbbox()
    if not bbox:
        sys.exit("nothing left after background removal (subject may be magenta)")
    from PIL import Image
    img = img.crop(bbox)
    inner = int(size * (1 - 2 * margin))
    scale = inner / max(img.size)
    new = (max(1, round(img.width * scale)), max(1, round(img.height * scale)))
    img = img.resize(new, Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(img, ((size - new[0]) // 2, (size - new[1]) // 2), img)
    return canvas


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("out", nargs="?"); ap.add_argument("prompt", nargs="?")
    ap.add_argument("--set-limit", type=float, help="hard USD cap for all generations (user's decision)")
    ap.add_argument("--status", action="store_true")
    ap.add_argument("--ref", action="append", default=[], help="style anchor image(s)")
    ap.add_argument("--size", type=int, default=256)
    ap.add_argument("--model", default=DEFAULT_MODEL)
    ap.add_argument("--keep-bg", action="store_true", help="skip background removal and resizing")
    ap.add_argument("--aspect", help="e.g. 1:1 or 9:16 (image API aspect ratio)")
    ap.add_argument("--raw", action="store_true", help="also save the untouched model output as <out>.raw.png")
    a = ap.parse_args()
    led = load_ledger()
    if a.set_limit is not None:
        led["limit_usd"] = a.set_limit; save_ledger(led)
    if a.status or a.set_limit is not None:
        lim = led["limit_usd"]
        print(f"spent ~${spent(led):.2f} of limit " + ("NOT SET" if lim is None else f"${lim:.2f} (remaining ~${lim - spent(led):.2f})")
              + f", {len(led['entries'])} images")
        return
    if not (a.out and a.prompt):
        ap.error("out and prompt are required")
    try:
        from PIL import Image
    except ImportError:
        sys.exit("Pillow missing: pip3 install --user pillow")

    prompt = a.prompt if a.keep_bg else WRAP.format(prompt=a.prompt)
    if a.ref:
        prompt += "\n\nMatch the art style, palette, line weight and shading of the attached reference image(s) exactly."
    with ledger_lock():  # reserve the cost before calling, so parallel runs cannot overspend or lose entries
        led, cost = check_budget(a.model)
        led["entries"].append({"t": __import__("time").strftime("%Y-%m-%d %H:%M:%S"), "model": a.model, "usd": cost, "out": a.out})
        save_ledger(led)
    try:
        raw = call_api(a.model, prompt, a.ref, a.aspect)
    except SystemExit:
        with ledger_lock():  # API refused: nothing was generated, release the reservation
            led = load_ledger(); led["entries"].pop(next(i for i in range(len(led["entries"]) - 1, -1, -1) if led["entries"][i]["out"] == a.out)); save_ledger(led)
        raise
    out = Path(a.out); out.parent.mkdir(parents=True, exist_ok=True)
    img = Image.open(BytesIO(raw))
    if a.raw or a.keep_bg:
        img.save(out if a.keep_bg else out.with_suffix(".raw.png"))
    if not a.keep_bg:
        fit(key_out(img), a.size).save(out)
    print(out)


if __name__ == "__main__":
    main()
