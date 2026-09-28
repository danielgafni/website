"""Generate a social (Open Graph) card for every page in docs/.

Zensical can't render per-page social cards yet, so this runs before
`zensical build`. Each card shows the round photo, the page title and the page
description, and is written to docs/assets/social/<page url>.png, the path
overrides/main.html links to from `og:image`.
"""

import re
import tomllib
from pathlib import Path

import yaml
from PIL import Image, ImageDraw, ImageFont

WWW = Path(__file__).resolve().parent.parent
DOCS = WWW / "docs"
OUT = DOCS / "assets" / "social"
FONTS = WWW / "scripts" / "fonts"

WIDTH, HEIGHT = 1200, 630
BACKGROUND = "#f386a1"
INK = "#1e1e1e"
PHOTO_SIZE = 380
TEXT_X = 520
TEXT_WIDTH = WIDTH - TEXT_X - 70

CONFIG = tomllib.loads((WWW / "zensical.toml").read_text())["project"]
SITE_NAME = CONFIG["site_name"]
POST_URL_FORMAT = CONFIG["plugins"]["blog"]["post_url_format"]

# (font file, named style of the variable font); fonts from
# https://github.com/danielgafni/nixos#fonts
SITE_FONT = ("MapleMono-Medium", None)
TITLE_FONT = ("Recursive", "Sans Linear Bold")
DESCRIPTION_FONT = ("Cabin", "Regular")


def font(spec, size):
    name, style = spec
    f = ImageFont.truetype(str(FONTS / f"{name}.ttf"), size)
    if style:
        f.set_variation_by_name(style)
    return f


def front_matter(path):
    text = path.read_text()
    m = re.match(r"---\n(.*?)\n---\n", text, re.DOTALL)
    meta = yaml.safe_load(m.group(1)) if m else {}
    h1 = re.search(r"^# (.+)$", text[m.end() if m else 0 :], re.MULTILINE)
    return meta or {}, h1.group(1).strip() if h1 else None


def page_url(path, meta):
    """The page's URL, matching `page.url` in templates."""
    rel = path.relative_to(DOCS)
    if rel.parts[0] == "posts":
        return POST_URL_FORMAT.format(slug=meta["slug"]) + "/"
    parts = rel.with_suffix("").parts
    if parts[-1] == "index":
        parts = parts[:-1]
    return "/".join(parts) + "/" if parts else ""


def wrap(draw, text, spec, size, min_size, max_lines):
    """Wrap text into at most `max_lines`, shrinking the font down to `min_size`."""
    while True:
        f = font(spec, size)
        lines = []
        for word in text.split():
            if lines and draw.textlength(f"{lines[-1]} {word}", font=f) <= TEXT_WIDTH:
                lines[-1] += f" {word}"
            else:
                lines.append(word)
        if len(lines) <= max_lines or size <= min_size:
            if len(lines) > max_lines:
                lines = lines[:max_lines]
                lines[-1] = lines[-1].rstrip(" .,;:") + "…"
            return f, lines
        size -= 4


def render(title, description, photo):
    card = Image.new("RGB", (WIDTH, HEIGHT), BACKGROUND)
    card.paste(photo, (70, (HEIGHT - PHOTO_SIZE) // 2), photo)
    draw = ImageDraw.Draw(card)

    site = font(SITE_FONT, 30)
    title_font, title_lines = wrap(draw, title, TITLE_FONT, 64, 44, 3)
    desc_font, desc_lines = wrap(draw, description, DESCRIPTION_FONT, 34, 28, 4)

    title_step = int(title_font.size * 1.15)
    desc_step = int(desc_font.size * 1.4)
    block = 30 + 36 + title_step * len(title_lines) + 24 + desc_step * len(desc_lines)
    y = (HEIGHT - block) // 2

    draw.text((TEXT_X, y), SITE_NAME, font=site, fill=INK)
    y += 30 + 36
    for line in title_lines:
        draw.text((TEXT_X, y), line, font=title_font, fill=INK)
        y += title_step
    y += 24
    for line in desc_lines:
        draw.text((TEXT_X, y), line, font=desc_font, fill=INK)
        y += desc_step
    return card


def main():
    photo = Image.open(DOCS / "assets" / "images" / "me.png").convert("RGBA")
    photo = photo.resize((PHOTO_SIZE, PHOTO_SIZE), Image.LANCZOS)
    for path in sorted(DOCS.rglob("*.md")):
        meta, h1 = front_matter(path)
        if not meta.get("description"):
            continue
        url = page_url(path, meta)
        out = OUT / f"{url.strip('/') or 'index'}.png"
        out.parent.mkdir(parents=True, exist_ok=True)
        render(h1 or meta["title"], meta["description"], photo).save(out, optimize=True)
        print(f"{out.relative_to(WWW)}")


if __name__ == "__main__":
    main()
