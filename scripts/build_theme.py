#!/usr/bin/env python3
"""Build a Godot UI theme for a game from a recipe built on Kenney CC0 packs.

  build_theme.py <project> <recipe.json>

Writes <project>/ui/theme.tres, copies the used textures/fonts to <project>/assets/ui/<recipe name>/,
points project.godot at the new theme, and records every file in ASSETS.md.
Recipe fields (see data/themes/*.json): pack, accent colors, button/panel textures with 9-slice margins,
optional upscale (textures are enlarged with ffmpeg so corners match a 1080-wide canvas), font, palette.
Extras: `tint` on any button state (recolour a grey Kenney button), font `{local, author, license, url}` for non-Kenney fonts,
`label_outline` {color, size} for outlined text.
"""
import datetime, json, re, shutil, struct, subprocess, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import kenney

MARK_BEGIN, MARK_END = "<!-- ui-assets:begin -->", "<!-- ui-assets:end -->"


def is_variable_font(path):
    """True when the TrueType file has an `fvar` table (a variable font)."""
    with open(path, "rb") as f:
        head = f.read(12)
        tables = struct.unpack(">H", head[4:6])[0]
        directory = f.read(16 * tables)
    return any(directory[i:i + 4] == b"fvar" for i in range(0, len(directory), 16))


def png_size(path):
    with open(path, "rb") as f:
        head = f.read(24)
    return struct.unpack(">II", head[16:24])


def color(hexstr, alpha=1.0):
    h = hexstr.lstrip("#")
    if len(h) == 8:   # #rrggbbaa
        alpha = int(h[6:8], 16) / 255
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return f"Color({r:.3f}, {g:.3f}, {b:.3f}, {alpha})"


class Builder:
    def __init__(self, project, recipe):
        self.project, self.r = project, recipe
        self.name = recipe["name"]
        self.dest = project / "assets" / "ui" / self.name
        self.dest.mkdir(parents=True, exist_ok=True)
        self.ext = []      # ext_resource lines
        self.sub = []      # sub_resource blocks
        self.files = []    # (project-relative path, pack, source file)
        self.copied = {}
        self.extra_rows = []  # full ASSETS.md rows for files that are not Kenney packs
        self.recipe_dir = Path.cwd()

    def asset(self, pack, rel, scale=1, kind="Texture2D"):
        """Copy (and optionally upscale) a pack file into the project; return its ExtResource id."""
        key = (pack, rel, scale)
        if key in self.copied:
            return self.copied[key]
        src = kenney.fetch(pack) / rel
        if not src.is_file():
            raise FileNotFoundError(f"{rel} not in pack {pack}")
        # include the parent folders: Blue/ and Grey/ hold files with identical names
        unique = "_".join(Path(rel).parts[-3:-1] + (src.stem,)).replace(" ", "_")
        out = self.dest / (unique + (f"_x{scale}" if scale != 1 else "") + src.suffix.lower())
        if kind == "Texture2D" and scale != 1:
            # scale color and alpha separately: scaling RGBA directly leaves a dark halo around transparent edges
            graph = ("[0:v]format=rgba,split[c][a];"
                     f"[a]alphaextract,scale=iw*{scale}:ih*{scale}:flags=lanczos[al];"
                     f"[c]format=rgb24,scale=iw*{scale}:ih*{scale}:flags=lanczos[rgb];[rgb][al]alphamerge")
            subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(src), "-filter_complex", graph, str(out)], check=True)
        else:
            shutil.copyfile(src, out)
        rid = f"res_{len(self.ext) + 1}"
        res_path = "res://" + str(out.relative_to(self.project)).replace("\\", "/")
        self.ext.append(f'[ext_resource type="{kind}" path="{res_path}" id="{rid}"]')
        self.files.append((str(out.relative_to(self.project)), pack, rel))
        self.copied[key] = rid
        return rid

    def local_font(self, spec):
        """A font that is not from Kenney: {"local": path relative to the recipe, "author", "license", "url"}."""
        src = (self.recipe_dir / spec["local"]).resolve()
        if is_variable_font(src):
            sys.exit(f"{src.name} is a variable font. Variable fonts stalled Movie Maker recordings (lesson 0031): "
                     "make a static instance first (fontTools.varLib.instancer, wght=600).")
        out = self.dest / src.name
        shutil.copyfile(src, out)
        rid = f"res_{len(self.ext) + 1}"
        rel = str(out.relative_to(self.project)).replace("\\", "/")
        self.ext.append(f'[ext_resource type="FontFile" path="res://{rel}" id="{rid}"]')
        self.extra_rows.append(f"| {rel} | ui font | {spec['url']} | {spec['author']} | {spec['license']} | "
                               f"{datetime.date.today().isoformat()} | theme '{self.name}' |")
        return rid

    def stylebox_texture(self, sid, spec, scale, tint=None, content=None):
        rid = self.asset(spec["pack"], spec["file"], scale)
        m = [v * scale for v in spec["margins"]]
        c = [v for v in (content or spec.get("content", spec["margins"]))]
        lines = [f'[sub_resource type="StyleBoxTexture" id="{sid}"]', f'texture = ExtResource("{rid}")',
                 f"texture_margin_left = {m[0]}", f"texture_margin_top = {m[1]}",
                 f"texture_margin_right = {m[2]}", f"texture_margin_bottom = {m[3]}",
                 f"content_margin_left = {c[0]}", f"content_margin_top = {c[1]}",
                 f"content_margin_right = {c[2]}", f"content_margin_bottom = {c[3]}"]
        if tint:
            lines.append(f"modulate_color = {tint}")
        self.sub.append("\n".join(lines))

    def flat(self, sid, bg, radius=12, margin_v=12.0):
        self.sub.append(f'[sub_resource type="StyleBoxFlat" id="{sid}"]\nbg_color = {bg}\n'
                        + "".join(f"corner_radius_{c} = {radius}\n" for c in ("top_left", "top_right", "bottom_right", "bottom_left"))
                        + f"content_margin_top = {margin_v}\ncontent_margin_bottom = {margin_v}")

    def outline_lines(self):
        """Optional recipe field "label_outline": {"color": "#5B4B8A", "size": 10} for chunky game-style text."""
        o = self.r.get("label_outline")
        if not o:
            return []
        c = color(o["color"])
        return [f"Label/colors/font_outline_color = {c}", f"Label/constants/outline_size = {o['size']}",
                f"Button/colors/font_outline_color = {c}", f"Button/constants/outline_size = {o['size']}"]

    def glass_button(self, sid, fill, border, alpha, border_width, glow, radius, margins=(44, 20)):
        """Translucent button with a bright rim and a soft glow: no textures, nothing heavy or solid."""
        self.sub.append(f'[sub_resource type="StyleBoxFlat" id="{sid}"]\nbg_color = {color(fill, alpha)}\nborder_color = {border}\n'
                        + "".join(f"border_width_{e} = {border_width}\n" for e in ("left", "top", "right", "bottom"))
                        + "".join(f"corner_radius_{c} = {radius}\n" for c in ("top_left", "top_right", "bottom_right", "bottom_left"))
                        + f"shadow_color = {glow}\nshadow_size = 12\nanti_aliasing = true\n"
                        + f"content_margin_left = {margins[0]}\ncontent_margin_right = {margins[0]}\n"
                        + f"content_margin_top = {margins[1]}\ncontent_margin_bottom = {margins[1]}")

    def build_glass(self):
        g = self.r["glass"]
        rim, fill, rad = g["border"], g["fill"], g.get("radius", 34)
        glow = color(rim, g.get("glow", 0.28))
        self.glass_button("btn_normal", fill, color(rim, 0.85), 0.26, 3, glow, rad)
        self.glass_button("btn_hover", fill, color("#FFFFFF", 0.95), 0.38, 3, color(rim, 0.45), rad)
        self.glass_button("btn_pressed", fill, color("#FFFFFF", 1.0), 0.6, 4, color(rim, 0.6), rad, margins=(44, 24))
        self.glass_button("btn_disabled", g.get("disabled_fill", "#2B3260"), color(g.get("disabled_fill", "#2B3260"), 0.8), 0.25, 2, color("#000000", 0.0), rad)

    def build(self):
        r, scale, pal = self.r, self.r.get("upscale", 1), self.r["palette"]
        panel = r["panel"]
        if "glass" in r:
            self.build_glass()
        else:
            btn = r["button"]
            self._texture_buttons(btn, scale)
        self._rest(r, scale, pal, panel)

    def _texture_buttons(self, btn, scale):
        self.stylebox_texture("btn_normal", btn["normal"], scale, tint=color(btn["normal"]["tint"]) if "tint" in btn["normal"] else None)
        self.stylebox_texture("btn_hover", btn.get("hover", btn["normal"]), scale,
                              tint=color(btn.get("hover", btn["normal"])["tint"]) if "tint" in btn.get("hover", btn["normal"]) else None)
        self.stylebox_texture("btn_pressed", btn["pressed"], scale, tint=color(btn["pressed"]["tint"]) if "tint" in btn["pressed"] else None)
        self.stylebox_texture("btn_disabled", btn["disabled"], scale, tint=color(btn["disabled"]["tint"]) if "tint" in btn["disabled"] else None)

    def _rest(self, r, scale, pal, panel):
        if "flat" in panel:
            f = panel["flat"]
            self.sub.append(f'[sub_resource type="StyleBoxFlat" id="panel"]\nbg_color = {color(f["bg"])}\n'
                            f'border_color = {color(f["border"])}\n'
                            + "".join(f"border_width_{e} = {f['border_width']}\n" for e in ("left", "top", "right", "bottom"))
                            + "".join(f"corner_radius_{c} = {f['radius']}\n" for c in ("top_left", "top_right", "bottom_right", "bottom_left"))
                            + "".join(f"content_margin_{e} = 56.0\n" for e in ("left", "top", "right", "bottom")).rstrip("\n"))
        else:
            self.stylebox_texture("panel", panel, scale, tint=color(pal["panel_tint"]) if "panel_tint" in pal else None)
        self.sub.append('[sub_resource type="StyleBoxEmpty" id="empty"]')
        self.flat("slider_track", color(pal["slider_track"]))
        self.flat("slider_fill", color(pal["slider_fill"]))
        self.flat("backdrop", color(pal["background"]), radius=0, margin_v=0.0)
        self.sub.append('[sub_resource type="Gradient" id="knob_gradient"]\noffsets = PackedFloat32Array(0.9, 1)\n'
                        f'colors = PackedColorArray({", ".join(c for c in color(pal["slider_knob"]).strip("Color()").split(", ")[:3])}, 1, '
                        f'{", ".join(c for c in color(pal["slider_knob"]).strip("Color()").split(", ")[:3])}, 0)')
        self.sub.append('[sub_resource type="GradientTexture2D" id="knob"]\ngradient = SubResource("knob_gradient")\n'
                        "width = 72\nheight = 72\nfill = 1\nfill_from = Vector2(0.5, 0.5)\nfill_to = Vector2(1, 0.5)")
        font_line = ""
        if "font" in r:
            fid = self.local_font(r["font"]) if "local" in r["font"] else self.asset(r["font"]["pack"], r["font"]["file"], kind="FontFile")
            font_line = f'default_font = ExtResource("{fid}")\n'
        fc = color(pal["text"])
        bc = color(pal.get("button_text", pal["text"]))
        body = [f'[gd_resource type="Theme" load_steps={len(self.ext) + len(self.sub) + 1} format=3]', ""]
        body += self.ext + [""] + [b + "\n" for b in self.sub]
        body += ["[resource]", f'resource_name = "{self.name}"', font_line + f"default_font_size = {r.get('font_size', 48)}",
                 f"Button/colors/font_color = {bc}", f"Button/colors/font_hover_color = {bc}",
                 f"Button/colors/font_pressed_color = {bc}", f"Button/colors/font_focus_color = {bc}",
                 f"Button/colors/font_disabled_color = {color(pal.get('button_text', pal['text']), 0.5)}",
                 f"Label/colors/font_color = {fc}",
                 *self.outline_lines(),
                 "Button/styles/disabled = SubResource(\"btn_disabled\")", 'Button/styles/focus = SubResource("empty")',
                 'Button/styles/hover = SubResource("btn_hover")', 'Button/styles/hover_pressed = SubResource("btn_pressed")',
                 'Button/styles/normal = SubResource("btn_normal")', 'Button/styles/pressed = SubResource("btn_pressed")',
                 'HSlider/icons/grabber = SubResource("knob")', 'HSlider/icons/grabber_highlight = SubResource("knob")',
                 'HSlider/styles/grabber_area = SubResource("slider_fill")',
                 'HSlider/styles/grabber_area_highlight = SubResource("slider_fill")',
                 'HSlider/styles/slider = SubResource("slider_track")',
                 'PanelContainer/styles/panel = SubResource("panel")',
                 'Backdrop/base_type = &"Panel"', 'Backdrop/styles/panel = SubResource("backdrop")', ""]
        (self.project / "ui").mkdir(exist_ok=True)
        (self.project / "ui" / "theme.tres").write_text("\n".join(body))
        pg = self.project / "project.godot"
        text = pg.read_text()
        pg.write_text(re.sub(r'theme/custom="[^"]*"', 'theme/custom="res://ui/theme.tres"', text))
        self.record_assets()
        print(f"theme '{self.name}': {len(self.files)} files, ui/theme.tres")

    def record_assets(self):
        today = datetime.date.today().isoformat()
        rows = [f"| {p} | ui | https://kenney.nl/assets/{pack} | Kenney | CC0 | {today} | {src}, theme '{self.name}' |"
                for p, pack, src in self.files]
        block = f"{MARK_BEGIN}\n" + "\n".join(rows + self.extra_rows) + f"\n{MARK_END}"
        path = self.project / "ASSETS.md"
        text = path.read_text() if path.exists() else "# Assets\n\n| File(s) | Type | Source URL | Author | License | Date added | Notes |\n|---|---|---|---|---|---|---|\n"
        if MARK_BEGIN in text:
            head, rest = text.split(MARK_BEGIN, 1)
            text = head + block + rest.split(MARK_END, 1)[1]
        else:
            text = text.rstrip("\n") + "\n" + block + "\n"
        path.write_text(text)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    b = Builder(Path(sys.argv[1]).resolve(), json.loads(Path(sys.argv[2]).read_text()))
    b.recipe_dir = Path(sys.argv[2]).resolve().parent
    b.build()
