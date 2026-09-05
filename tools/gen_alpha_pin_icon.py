#!/usr/bin/env python3
"""Generate the alpha map pin glyph, `assets/ui/icons/map/alpha.png`.

CL-W1 / D-0904B-1: an alpha within 300 m pins itself to the map, and the pin
needs a mark that is unmistakably NOT one of the twelve place icons already in
`assets/ui/icons/map/`. Those are all buildings, terrain or objects; this one is
a *rank* mark, so it is drawn as one -- a bold upward chevron over a single pip,
the oldest "this one outranks the others" shorthand there is, and the only shape
in this set that survives being drawn at 30 px on a handheld without turning
into a blob.

Drawn in `tools/gen_item_icons.py`'s language and nothing else: flat polygons,
solid #F2F5F2 on transparent, supersampled and downscaled with LANCZOS so the
edges antialias (PIL's own polygon fill is hard-edged at native size). No text,
no photographic source, no vendored glyph -- the owner's spec sec21 allowance
for "simple generated vector icons for game-specific concepts".

100 px output, not the 64 px `gen_item_icons.py` uses: every existing file in
`assets/ui/icons/map/` is 100x100 and a map icon is scaled by `tab_map.gd`'s own
`ICON_SIZE`, so matching the neighbours costs nothing and avoids one icon in the
set softening differently from the other twelve.

Run:
    python3 tools/gen_alpha_pin_icon.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
MAP_DIR = ROOT / "assets/ui/icons/map"

S = 400  # supersample canvas
FINAL = 100  # matches every other file in assets/ui/icons/map/
FG = (242, 245, 242, 255)  # #F2F5F2, the icon set's own white
CLEAR = (0, 0, 0, 0)


def _chevron(draw: ImageDraw.ImageDraw) -> None:
    """A single thick upward chevron, drawn as one closed polygon.

    Proportions are chosen against the smallest size it is ever drawn at
    (`tab_map.gd::ICON_SIZE`, 30 px, and 0.66x again under the project's
    canvas_items stretch on a 1280x800 handheld): the arm is ~0.17 of the icon
    width thick, which stays at least 3 px even there, and the apex angle is
    kept wide (~90 degrees) so the two arms never fuse at the top.
    """
    apex_y = 0.15 * S
    outer_y = 0.49 * S
    inner_y = 0.76 * S
    left_x = 0.13 * S
    right_x = 0.87 * S
    mid_x = 0.50 * S
    thickness = 0.155 * S
    draw.polygon(
        [
            (mid_x, apex_y),
            (right_x, outer_y),
            (right_x - thickness, inner_y),
            (mid_x, apex_y + thickness * 1.05),
            (left_x + thickness, inner_y),
            (left_x, outer_y),
        ],
        fill=FG,
    )


def _pip(draw: ImageDraw.ImageDraw) -> None:
    """The pip under the chevron. Separated from it by clear space, which is
    what keeps the whole mark from reading as a solid triangle once the
    downscale softens it."""
    r = 0.095 * S
    cy = 0.855 * S
    draw.ellipse([(0.5 * S - r, cy - r), (0.5 * S + r, cy + r)], fill=FG)


def main() -> int:
    image = Image.new("RGBA", (S, S), CLEAR)
    draw = ImageDraw.Draw(image)
    _chevron(draw)
    _pip(draw)
    out = MAP_DIR / "alpha.png"
    image.resize((FINAL, FINAL), Image.LANCZOS).save(out)
    print("wrote %s" % out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
