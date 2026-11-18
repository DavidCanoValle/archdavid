#!/usr/bin/env python3
"""Renderiza todos los assets de un tema (GRUB, Plymouth, SDDM, waybar, rofi, hypr)."""
import hashlib
import os
import re
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFilter

W, H = 1920, 1080
HOME = os.path.expanduser("~")
ASSETS = os.path.join(HOME, ".cache", "theme-switcher", "assets")
CACHE = os.path.join(HOME, ".cache", "theme-switcher", "cache")
SDDM_TEMPLATE = "/usr/share/sddm/themes/sddm-astronaut-theme/Themes/david.conf"
ARCH_LOGO = "/usr/share/pixmaps/archlinux-logo.png"

FONT_REG = "/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf"
FONT_BOLD = "/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Bold.ttf"


def load_conf(path):
    conf = {}
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, val = line.split("=", 1)
            raw = val.strip().strip('"')
            conf[key.strip()] = os.path.expanduser(os.path.expandvars(raw))
    return conf


def rgb(hexstr):
    hexstr = hexstr.lstrip("#")
    return tuple(int(hexstr[i:i + 2], 16) for i in (0, 2, 4))


def rgba(hexstr, alpha=255):
    return rgb(hexstr) + (alpha,)


def blend(c1, c2, amount):
    a = rgb(c1)
    b = rgb(c2)
    return tuple(round(x + (y - x) * amount) for x, y in zip(a, b))


def cover(img, w, h, zoom=1.0):
    iw, ih = img.size
    scale = max(w / iw, h / ih) * zoom
    nw, nh = max(1, round(iw * scale)), max(1, round(ih * scale))
    img = img.resize((nw, nh), Image.Resampling.LANCZOS)
    left = (nw - w) // 2
    top = (nh - h) // 2
    return img.crop((left, top, left + w, top + h))


def vignette(w, h, strength=0.55):
    grad = Image.radial_gradient("L").resize((w, h), Image.Resampling.BICUBIC)
    mask = grad.point(lambda p: int((p / 255) ** 2 * 255 * strength))
    black = Image.new("RGB", (w, h), (0, 0, 0))
    return black, mask


def blurred_wallpaper(path, blur=60, zoom=1.12):
    wall = Image.open(path).convert("RGB")
    return cover(wall, W, H, zoom).filter(ImageFilter.GaussianBlur(blur))


def pf2_name(path):
    data = open(path, "rb").read()
    idx = data.find(b"PFF2NAME")
    if idx < 0:
        return None
    length = int.from_bytes(data[idx + 8:idx + 12], "big")
    raw = data[idx + 12:idx + 12 + length]
    return raw.split(b"\0")[0].decode("utf-8", "replace")


def ensure_fonts():
    fonts = os.path.join(ASSETS, "fonts")
    os.makedirs(fonts, exist_ok=True)
    specs = {
        "item.pf2": (FONT_REG, 20),
        "item-bold.pf2": (FONT_BOLD, 20),
        "title.pf2": (FONT_BOLD, 30),
        "small.pf2": (FONT_REG, 15),
    }
    names = {}
    for fname, (ttf, size) in specs.items():
        out = os.path.join(fonts, fname)
        if not os.path.exists(out):
            subprocess.run(["grub-mkfont", "-s", str(size), "-o", out, ttf], check=True)
        names[fname] = pf2_name(out)
    return fonts, names


def save_rounded_corner(radius, fill):
    r2 = radius * 2
    tile = Image.new("RGBA", (r2, r2), (0, 0, 0, 0))
    ImageDraw.Draw(tile).rounded_rectangle([0, 0, r2 - 1, r2 - 1], radius=radius, fill=fill)
    return {
        "nw": tile.crop((0, 0, radius, radius)),
        "ne": tile.crop((radius, 0, r2, radius)),
        "sw": tile.crop((0, radius, radius, r2)),
        "se": tile.crop((radius, radius, r2, r2)),
    }


def render_grub(conf, out):
    os.makedirs(out, exist_ok=True)
    base = Image.new("RGB", (W, H), rgb(conf["BG"]))
    wp = blurred_wallpaper(conf["WALLPAPER"])
    bg = Image.blend(base, wp, 0.30)
    bg = Image.blend(bg, Image.new("RGB", (W, H), (0, 0, 0)), 0.16)
    black, mask = vignette(W, H, 0.45)
    bg = Image.composite(black, bg, mask)
    bg.save(os.path.join(out, "background.jpg"), quality=92)

    fonts, names = ensure_fonts()
    for fname in names:
        src = os.path.join(fonts, fname)
        dst = os.path.join(out, fname)
        if not os.path.exists(dst) or os.path.getmtime(src) > os.path.getmtime(dst):
            with open(src, "rb") as fsrc, open(dst, "wb") as fdst:
                fdst.write(fsrc.read())

    radius = 12
    highlight = blend(conf["PANEL2"], conf["ACCENT"], 0.28) + (255,)
    corners = save_rounded_corner(radius, highlight)
    for side, img in corners.items():
        img.save(os.path.join(out, f"sel_{side}.png"))
    one = Image.new("RGBA", (1, 1), highlight)
    for side in ("n", "s", "e", "w", "c"):
        one.save(os.path.join(out, f"sel_{side}.png"))

    Image.new("RGBA", (1, 1), rgba(conf["BORDER"])).save(os.path.join(out, "tb_c.png"))
    for side in ("n", "s", "e", "w", "ne", "nw", "se", "sw"):
        Image.new("RGBA", (1, 1), rgba(conf["BORDER"])).save(os.path.join(out, f"tb_{side}.png"))
    for side in ("c", "n", "s", "e", "w", "ne", "nw", "se", "sw"):
        Image.new("RGBA", (1, 1), rgba(conf["ACCENT"])).save(os.path.join(out, f"th_{side}.png"))

    theme = f"""desktop-image: "background.jpg"
desktop-color: "{conf['BG']}"
terminal-font: "{names['small.pf2']}"
message-font: "{names['small.pf2']}"
message-color: "{conf['TEXT']}"
message-bg-color: "{conf['BG']}"

+ label {{
    top = 352
    left = 0
    width = 100%
    height = 48
    align = "center"
    text = "Arch Linux"
    font = "{names['title.pf2']}"
    color = "{conf['ACCENT']}"
}}

+ boot_menu {{
    left = 680
    top = 418
    width = 560
    height = 300
    item_font = "{names['item.pf2']}"
    item_color = "{conf['TEXT']}"
    selected_item_font = "{names['item-bold.pf2']}"
    selected_item_color = "{conf['ACCENT']}"
    selected_item_pixmap_style = "sel_*.png"
    item_height = 48
    item_padding = 20
    item_spacing = 10
    scrollbar = true
}}

+ progress_bar {{
    id = "__timeout__"
    left = 680
    top = 800
    width = 560
    height = 6
    show_text = false
    bar_style = "tb_*.png"
    highlight_style = "th_*.png"
}}
"""
    with open(os.path.join(out, "theme.txt"), "w", encoding="utf-8") as fh:
        fh.write(theme)


def render_plymouth(conf, out):
    os.makedirs(os.path.join(out, "frames"), exist_ok=True)

    base = Image.new("RGB", (W, H), rgb(conf["BG"]))
    wp = blurred_wallpaper(conf["WALLPAPER"], blur=70)
    bg = Image.blend(base, wp, 0.20)
    black, mask = vignette(W, H, 0.62)
    bg = Image.composite(black, bg, mask)
    bg.save(os.path.join(out, "background.png"))

    src = Image.open(ARCH_LOGO).convert("RGBA")
    alpha = src.getchannel("A").point(lambda p: 255 if p > 128 else 0)
    pw, ph = alpha.size
    ap = alpha.load()
    seen = set()
    best = []
    for sy in range(ph):
        for sx in range(pw):
            if ap[sx, sy] and (sx, sy) not in seen:
                stack, comp = [(sx, sy)], []
                seen.add((sx, sy))
                while stack:
                    cx, cy = stack.pop()
                    comp.append((cx, cy))
                    for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                        if 0 <= nx < pw and 0 <= ny < ph and ap[nx, ny] and (nx, ny) not in seen:
                            seen.add((nx, ny))
                            stack.append((nx, ny))
                if len(comp) > len(best):
                    best = comp
    mask_logo = Image.new("L", src.size, 0)
    mp = mask_logo.load()
    for cx, cy in best:
        mp[cx, cy] = 255
    logo = mask_logo.crop(mask_logo.getbbox())
    target_h = 230
    target_w = round(logo.width * target_h / logo.height)
    logo = logo.resize((target_w, target_h), Image.Resampling.LANCZOS)
    solid = Image.new("RGBA", logo.size, rgba(conf["TEXT"]))
    solid.putalpha(logo)

    glow = Image.new("RGBA", logo.size, rgba(conf["ACCENT"]))
    glow.putalpha(logo.point(lambda p: int(p * 0.40)))
    glow = glow.filter(ImageFilter.GaussianBlur(13))

    canvas = 760
    logo_img = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    logo_img.alpha_composite(glow, ((canvas - glow.width) // 2, (canvas - glow.height) // 2))
    logo_img.alpha_composite(solid, ((canvas - solid.width) // 2, (canvas - solid.height) // 2))
    logo_img.save(os.path.join(out, "logo.png"))

    frames = 72
    ss = 2
    c = (canvas // 2) * ss
    accent = rgba(conf["ACCENT"])
    for i in range(frames):
        im = Image.new("RGBA", (canvas * ss, canvas * ss), (0, 0, 0, 0))
        draw = ImageDraw.Draw(im)
        for offset in (0.0, 0.5):
            p = ((i / frames) + offset) % 1.0
            radius = (150 + p * 220) * ss
            alpha = int(190 * (1 - p))
            draw.ellipse(
                [c - radius, c - radius, c + radius, c + radius],
                outline=accent[:3] + (alpha,),
                width=max(1, int(3.2 * ss)),
            )
        im.resize((canvas, canvas), Image.Resampling.LANCZOS).save(
            os.path.join(out, "frames", f"{i:03d}.png"))
        im.close()

    with open(os.path.join(out, "david.plymouth"), "w", encoding="utf-8") as fh:
        fh.write(f"""[Plymouth Theme]
Name=David {conf['NAME']}
Description=Animacion de apertura minimalista
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/david
ScriptFile=/usr/share/plymouth/themes/david/david.script
""")

    frame_imgs = ",\n".join(
        f'    Image("frames/{i:03d}.png")' for i in range(frames))
    script = f"""background.image = Image("background.png");
background.sprite = Sprite(background.image);
background.sprite.SetZ(0);
background.last_width = 0;
background.last_height = 0;

logo.image = Image("logo.png");
logo.sprite = Sprite(logo.image);
logo.sprite.SetZ(10);

ripple.images = [
{frame_imgs}
];
ripple.sprite = Sprite(ripple.images[0]);
ripple.sprite.SetZ(5);
ripple.frame = 0;
tick = 0;

fun refresh_callback()
{{
    local w = Window.GetWidth();
    local h = Window.GetHeight();
    local x = Window.GetX();
    local y = Window.GetY();

    if (w != background.last_width || h != background.last_height)
      {{
        background.image = Image("background.png").Scale(w, h);
        background.sprite.SetImage(background.image);
        background.last_width = w;
        background.last_height = h;
        background.sprite.SetX(x);
        background.sprite.SetY(y);
      }}

    local cx = x + w / 2;
    local cy = y + h * 0.40;

    logo.sprite.SetX(cx - logo.image.GetWidth() / 2);
    logo.sprite.SetY(cy - logo.image.GetHeight() / 2);
    ripple.sprite.SetX(cx - ripple.images[0].GetWidth() / 2);
    ripple.sprite.SetY(cy - ripple.images[0].GetHeight() / 2);

    tick = tick + 1;
    if (tick < 40)
      {{
        logo.sprite.SetOpacity(tick * 0.025);
      }}
    else
      {{
        logo.sprite.SetOpacity(1);
      }}

    if (tick % 2 == 0)
      {{
        ripple.frame = ripple.frame + 1;
        if (ripple.frame >= {frames})
          {{
            ripple.frame = 0;
          }}
        ripple.sprite.SetImage(ripple.images[ripple.frame]);
      }}
}}

Plymouth.SetRefreshFunction(refresh_callback);
"""
    with open(os.path.join(out, "david.script"), "w", encoding="utf-8") as fh:
        fh.write(script)


def wallpaper_hash(path):
    st = os.stat(path)
    return hashlib.sha1(f"{path}:{st.st_size}:{st.st_mtime_ns}".encode()).hexdigest()[:10]


def sddm_video(wallpaper, out, tid):
    os.makedirs(CACHE, exist_ok=True)
    cached = os.path.join(CACHE, f"sddm-{tid}-{wallpaper_hash(wallpaper)}.mp4")
    if not os.path.exists(cached):
        cmd = [
            "ffmpeg", "-y", "-loglevel", "error", "-loop", "1", "-i", wallpaper,
            "-vf",
            "scale=2112:1188:force_original_aspect_ratio=increase,crop=2112:1188,"
            "zoompan=z='min(1.10,1+0.0003*on)':x='(iw-iw/zoom)/2':y='(ih-ih/zoom)/2'"
            ":d=300:s=1920x1080:fps=25,format=yuv420p",
            "-t", "12", "-c:v", "libx264", "-preset", "veryfast", "-crf", "26",
            "-movflags", "+faststart", cached,
        ]
        subprocess.run(cmd, check=True)
    return cached


def render_sddm(conf, out):
    os.makedirs(out, exist_ok=True)
    tid = conf["ID"]
    cover(Image.open(conf["WALLPAPER"]).convert("RGB"), W, H).save(
        os.path.join(out, f"{tid}.jpg"), quality=92)

    video_ok = True
    try:
        vid = sddm_video(conf["WALLPAPER"], out, tid)
        with open(vid, "rb") as src, open(os.path.join(out, f"{tid}.mp4"), "wb") as dst:
            dst.write(src.read())
    except Exception:
        video_ok = False

    text = open(SDDM_TEMPLATE, encoding="utf-8").read()
    colors = {
        "HeaderTextColor": conf["TEXT"],
        "DateTextColor": conf["ACCENT"],
        "TimeTextColor": conf["TEXT"],
        "FormBackgroundColor": conf["PANEL"],
        "BackgroundColor": conf["BG"],
        "DimBackgroundColor": conf["BG"],
        "LoginFieldBackgroundColor": conf["PANEL2"],
        "PasswordFieldBackgroundColor": conf["PANEL2"],
        "LoginFieldTextColor": conf["TEXT"],
        "PasswordFieldTextColor": conf["TEXT"],
        "UserIconColor": conf["ACCENT"],
        "PasswordIconColor": conf["ACCENT"],
        "PlaceholderTextColor": conf["DIM"],
        "WarningColor": conf["WARN"],
        "LoginButtonTextColor": conf["BG"],
        "LoginButtonBackgroundColor": conf["ACCENT"],
        "SystemButtonsIconsColor": conf["TEXT"],
        "SessionButtonTextColor": conf["TEXT"],
        "VirtualKeyboardButtonTextColor": conf["TEXT"],
        "DropdownTextColor": conf["TEXT"],
        "DropdownSelectedBackgroundColor": conf["ACCENT"],
        "DropdownBackgroundColor": conf["PANEL2"],
        "HighlightTextColor": conf["BG"],
        "HighlightBackgroundColor": conf["ACCENT"],
        "HighlightBorderColor": conf["ACCENT"],
        "HoverUserIconColor": conf["ACCENT"],
        "HoverPasswordIconColor": conf["ACCENT"],
        "HoverSystemButtonsIconsColor": conf["ACCENT"],
        "HoverSessionButtonTextColor": conf["ACCENT"],
        "HoverVirtualKeyboardButtonTextColor": conf["ACCENT"],
    }
    for key, value in colors.items():
        text = re.sub(rf'^{key}="[^"]*"', f'{key}="{value}"', text, flags=re.M)
    text = re.sub(r'^BackgroundPlaceholder="[^"]*"',
                  f'BackgroundPlaceholder="Backgrounds/{tid}.jpg"', text, flags=re.M)
    if video_ok:
        bg = f"Backgrounds/{tid}.mp4"
    else:
        bg = f"Backgrounds/{tid}.jpg"
    text = re.sub(r'^Background="[^"]*"', f'Background="{bg}"', text, flags=re.M)
    with open(os.path.join(out, "david.conf"), "w", encoding="utf-8") as fh:
        fh.write(text)


NVIM_SCHEMES = {
    "david": "onedark",
    "tokyonight": "tokyonight-night",
    "nord": "nord",
    "gruvbox": "gruvbox",
    "catppuccin": "catppuccin-mocha",
    "dracula": "dracula",
}


def render_user(conf, out):
    os.makedirs(out, exist_ok=True)
    accent = conf["ACCENT"]
    bg = conf["BG"]

    with open(os.path.join(out, "waybar-colors.css"), "w", encoding="utf-8") as fh:
        fh.write(f"""@define-color bg {conf['BG']};
@define-color panel {conf['PANEL']};
@define-color panel2 {conf['PANEL2']};
@define-color border {conf['BORDER']};
@define-color accent {conf['ACCENT']};
@define-color text {conf['TEXT']};
@define-color dim {conf['DIM']};
@define-color warning {conf['WARN']};
""")

    palette = f"""* {{
    background:     {bg}FF;
    background-alt: {conf['PANEL']}FF;
    foreground:     {conf['TEXT']}FF;
    selected:       {accent}FF;
    active:         {conf['PANEL2']}FF;
    urgent:         {conf['WARN']}FF;
    border:         {conf['BORDER']}FF;
    dim:            {conf['DIM']}FF;
    accent:         {accent}FF;
}}
"""
    with open(os.path.join(out, "palette.rasi"), "w", encoding="utf-8") as fh:
        fh.write(palette)
    with open(os.path.join(out, "launcher-colors.rasi"), "w", encoding="utf-8") as fh:
        fh.write(palette)

    inactive = conf["BORDER"] + "aa"
    theme_lua = f"""hl.config({{
    general = {{
        col = {{
            active_border = {{
                colors = {{ "rgba({accent.lstrip('#')}ee)", "rgba({conf['DIM'].lstrip('#')}ee)" }},
                angle = 45,
            }},
            inactive_border = "rgba({inactive.lstrip('#')})",
        }},
    }},
    decoration = {{
        shadow = {{ color = 0xee{bg.lstrip('#')} }},
    }},
}})
"""
    with open(os.path.join(out, "theme.lua"), "w", encoding="utf-8") as fh:
        fh.write(theme_lua)

    fallback = [conf["PANEL2"], conf["WARN"], conf["TEXT"], conf["DIM"],
                conf["ACCENT"], conf["ACCENT"], conf["TEXT"], conf["TEXT"]]
    ansi = []
    for i in range(16):
        value = conf.get(f"C{i}")
        ansi.append(value if value else fallback[i % len(fallback)].lstrip("#"))

    kitty = [
        "# generado por theme-switcher",
        f"foreground {conf['TEXT']}",
        f"background {conf['BG']}",
        f"cursor {accent}",
        f"cursor_text_color {bg}",
        f"cursor_trail_color {accent}",
        f"selection_foreground {conf['TEXT']}",
        f"selection_background {conf['BORDER']}",
        f"scrollbar_handle_color {accent}",
        f"scrollbar_track_color {conf['PANEL2']}",
        f"url_color {accent}",
        f"active_border_color {conf['BORDER']}",
        f"inactive_border_color {conf['PANEL2']}",
    ]
    for i, value in enumerate(ansi):
        kitty.append(f"color{i} #{value}")
    with open(os.path.join(out, "kitty-theme.conf"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(kitty) + "\n")

    scheme = NVIM_SCHEMES.get(conf["ID"], "tokyonight-night")
    with open(os.path.join(out, "theme_current.lua"), "w", encoding="utf-8") as fh:
        fh.write(f'-- Generado por theme-switcher\nreturn {{ scheme = "{scheme}", accent = "{accent}" }}\n')

    with open(os.path.join(out, "meta"), "w", encoding="utf-8") as fh:
        fh.write(f"ID={conf['ID']}\nNAME={conf['NAME']}\nACCENT={accent}\n")


def main():
    os.umask(0o022)
    if len(sys.argv) != 3:
        sys.exit("uso: render.py <tema.conf> <dir-salida>")
    conf = load_conf(sys.argv[1])
    for key in ("ID", "NAME", "BG", "PANEL", "PANEL2", "BORDER", "ACCENT", "TEXT", "DIM", "WARN", "WALLPAPER"):
        if key not in conf:
            sys.exit(f"falta {key} en {sys.argv[1]}")
    if not os.path.isfile(conf["WALLPAPER"]):
        sys.exit(f"no existe el fondo: {conf['WALLPAPER']}")
    out = sys.argv[2]
    os.makedirs(out, exist_ok=True)
    render_grub(conf, os.path.join(out, "grub"))
    render_plymouth(conf, os.path.join(out, "plymouth"))
    render_sddm(conf, os.path.join(out, "sddm"))
    render_user(conf, os.path.join(out, "user"))
    print(f"render ok: {conf['NAME']} -> {out}")


if __name__ == "__main__":
    main()
