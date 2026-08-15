#!/usr/bin/env python3
"""Generate original Tetherbound item/UI icons.

Owner's spec sec21 sanctions "simple generated vector icons for game-specific
concepts": filled silhouette + small cutouts, a 2-3px equivalent stroke, 64x64
source. This script draws each icon as flat polygons/ellipses/arcs (no text,
no photographic source, no vendored glyph) in a single coherent language --
solid white silhouette (#F2F5F2) on a transparent background, with a handful
of same-colour-background "cutout" strokes standing in for the ink line that
a hand-drawn icon would use to separate parts of one shape.

Everything is drawn at SUPERSAMPLE=256px and downscaled to the 64px target
with LANCZOS, which is what gives the silhouette edges (and the cutout
strokes) their antialiasing -- PIL's own polygon/ellipse fills are hard-edged
at native resolution.

Run:
    python3 tools/gen_item_icons.py

Overwrites the PNGs in-place at the paths items.json and the UI already
point at; no filenames change.
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
ITEMS_DIR = ROOT / "assets/ui/icons/items"
UI_DIR = ROOT / "assets/ui/icons/ui"

S = 256  # supersample canvas size
FINAL = 64  # exported size, matches the existing files this replaces
FG = (242, 245, 242, 255)  # #F2F5F2, matches the existing white icon set
CLEAR = (0, 0, 0, 0)

# Cutout stroke width in *final* 64px pixels, expressed in supersample space.
STROKE = int(S / FINAL * 2.5)  # ~2-3px equivalent at 64px, per spec sec21


def new_canvas() -> Image.Image:
    return Image.new("RGBA", (S, S), CLEAR)


def save(img: Image.Image, path: Path) -> None:
    small = img.resize((FINAL, FINAL), Image.LANCZOS)
    path.parent.mkdir(parents=True, exist_ok=True)
    small.save(path)
    print(f"wrote {path.relative_to(ROOT)}")


def cutout_line(draw: ImageDraw.ImageDraw, xy, width=STROKE) -> None:
    """A same-background 'ink' line, punched through a filled silhouette."""
    draw.line(xy, fill=CLEAR, width=width, joint="curve")


def cutout_ellipse(draw: ImageDraw.ImageDraw, bbox) -> None:
    draw.ellipse(bbox, fill=CLEAR)


def cutout_arc(draw: ImageDraw.ImageDraw, bbox, start, end, width=STROKE) -> None:
    draw.arc(bbox, start, end, fill=CLEAR, width=width)


# ---------------------------------------------------------------------------
# Items
# ---------------------------------------------------------------------------


def icon_wood() -> Image.Image:
    """A small woodpile: log ends stacked in a triangle, each disc showing
    a bark-ring cutout. Reads as stacked logs rather than a side-by-side
    pair, which at 64px was easy to mistake for a pair of eyes."""
    img = new_canvas()
    d = ImageDraw.Draw(img)
    logs = [(80, 176, 60), (176, 176, 60), (128, 88, 60)]
    for cx, cy, r in logs:
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=FG)
    for cx, cy, r in logs:
        # bark-ring cutout, then re-fill the pith so it doesn't hollow out
        cutout_ellipse(d, (cx - r * 0.62, cy - r * 0.62, cx + r * 0.62, cy + r * 0.62))
        r2 = r * 0.4
        d.ellipse((cx - r2, cy - r2, cx + r2, cy + r2), fill=FG)
    return img


def icon_stone() -> Image.Image:
    """A faceted rock silhouette with facet-line cutouts."""
    img = new_canvas()
    d = ImageDraw.Draw(img)
    pts = [
        (58, 108), (100, 44), (168, 40), (214, 92),
        (222, 158), (176, 214), (96, 218), (40, 168),
    ]
    d.polygon(pts, fill=FG)
    # Facet lines from a couple of interior "vertices" to break up the mass.
    cutout_line(d, [(100, 44), (128, 130)])
    cutout_line(d, [(128, 130), (58, 108)])
    cutout_line(d, [(128, 130), (214, 92)])
    cutout_line(d, [(128, 130), (176, 214)])
    cutout_line(d, [(128, 130), (96, 218)])
    return img


def icon_fiber() -> Image.Image:
    """Three curved strands, side by side, cinched with a tie band at the
    waist -- a bundle of stripped fiber/grass, not a coil -- the most
    literal reading of "three curved strands" and unambiguous at 64px."""
    img = new_canvas()
    d = ImageDraw.Draw(img)

    def strand(cx: float, amp: float, phase: float) -> list[tuple[float, float]]:
        pts = []
        for i in range(11):
            t = i / 10
            y = 34 + t * 190
            x = cx + amp * math.sin(t * math.pi * 1.15 + phase)
            pts.append((x, y))
        return pts

    w = 24
    for cx, amp, phase in ((80, 16, 0.0), (128, 12, 1.1), (176, 16, 2.2)):
        pts = strand(cx, amp, phase)
        d.line(pts, fill=FG, width=w, joint="curve")
        for p in (pts[0], pts[-1]):
            d.ellipse((p[0] - w / 2, p[1] - w / 2, p[0] + w / 2, p[1] + w / 2), fill=FG)

    # tie band binding the bundle at the waist
    d.rounded_rectangle((44, 116, 212, 146), radius=15, fill=FG)
    return img


def icon_berries() -> Image.Image:
    """A cluster of 3 berries plus a small leaf."""
    img = new_canvas()
    d = ImageDraw.Draw(img)
    berries = [(96, 150, 52), (168, 148, 52), (132, 88, 50)]
    for cx, cy, r in berries:
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=FG)
    # small highlight dimples (cutout) so each circle doesn't read as a coin
    for cx, cy, r in berries:
        hr = r * 0.16
        hx, hy = cx - r * 0.32, cy - r * 0.32
        cutout_ellipse(d, (hx - hr, hy - hr, hx + hr, hy + hr))
    # leaf: a pointed ellipse with a centre-vein cutout, perched top-right
    leaf = [(150, 46), (198, 40), (176, 84), (150, 46)]
    d.polygon(leaf, fill=FG)
    cutout_line(d, [(152, 50), (182, 62)], width=max(3, STROKE // 2))
    return img


def icon_orb_basic() -> Image.Image:
    """The game's own tether-orb language, deliberately NOT a pokeball: two
    tilted wrap-bands crossing the sphere (a bound/tethered look) rather
    than one flat equatorial seam, with a diamond tether-gem at the centre
    where the bands cross."""
    img = new_canvas()
    d = ImageDraw.Draw(img)
    cx, cy, r = 128, 128, 96
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=FG)

    band_w = 15
    # Two tilted bands crossing above/below centre, like a wrapped tether
    # cord -- distinct from a single flat pokeball seam.
    d.line([(cx - r, cy - 32), (cx + r, cy + 4)], fill=CLEAR, width=band_w, joint="curve")
    d.line([(cx - r, cy + 32), (cx + r, cy - 4)], fill=CLEAR, width=band_w, joint="curve")

    # Clip everything back to the sphere's silhouette (the diagonal cutout
    # lines above overshoot the circle; that overshoot is transparent
    # already outside the circle so no clip is strictly needed, but the
    # centre gem below is filled again so re-clip to keep it circular).
    dr = 30
    d.polygon(
        [(cx, cy - dr), (cx + dr * 0.72, cy), (cx, cy + dr), (cx - dr * 0.72, cy)],
        fill=FG,
    )
    mask = Image.new("L", (S, S), 0)
    md = ImageDraw.Draw(mask)
    md.ellipse((cx - r, cy - r, cx + r, cy + r), fill=255)
    img = Image.composite(img, Image.new("RGBA", (S, S), CLEAR), mask)
    return img


def icon_orb_greater() -> Image.Image:
    """R4.9: the second orb tier. Same sphere-and-tether-bands language as
    `icon_orb_basic` (same family, not a different object) plus one outer
    ring cutout -- a reinforcing band -- so a fuller satchel slot reads as
    'the better one' at a glance rather than needing the count/name text to
    tell tiers apart."""
    img = icon_orb_basic()
    d = ImageDraw.Draw(img)
    cx, cy, r = 128, 128, 96
    ring_r = r * 0.78
    d.ellipse(
        (cx - ring_r, cy - ring_r, cx + ring_r, cy + ring_r),
        outline=CLEAR, width=int(STROKE * 0.8),
    )
    return img


def icon_potion_small() -> Image.Image:
    """Round-bottom flask, cork, liquid line."""
    img = new_canvas()
    d = ImageDraw.Draw(img)
    cx = 128
    # neck
    d.rectangle((cx - 18, 50, cx + 18, 96), fill=FG)
    # cork (slightly wider, short) sat on top of the neck
    d.rectangle((cx - 24, 34, cx + 24, 58), fill=FG)
    cutout_line(d, [(cx - 24, 46), (cx + 24, 46)], width=max(3, STROKE // 2))
    # round flask body
    body_r = 82
    body_cy = 168
    d.ellipse((cx - body_r, body_cy - body_r, cx + body_r, body_cy + body_r), fill=FG)
    # square off the top of the body so the neck meets it cleanly
    d.rectangle((cx - body_r, body_cy - body_r, cx + body_r, 96), fill=CLEAR)
    d.rectangle((cx - 18, 90, cx + 18, 104), fill=FG)
    # liquid line cutout across the lower body (glass above the line reads
    # empty/clear)
    cutout_arc(d, (cx - body_r, body_cy - body_r, cx + body_r, body_cy + body_r), 200, 340, width=STROKE)
    return img


def icon_revive() -> Image.Image:
    """OF32/D40. Same flask silhouette as `icon_potion_small` -- deliberately
    the same object language, since a Revive reads on the belt as 'a
    consumable, same family' -- but a plus-mark cutout on the body stands in
    for the liquid-line, the same 'same base shape, one marker added' trick
    `icon_orb_greater` already uses to tell a tier apart from `icon_orb_basic`
    without a second silhouette. The plus is the one symbol a 64px glyph can
    carry that reads as 'revival' rather than 'a drink' at a glance."""
    img = icon_potion_small()
    d = ImageDraw.Draw(img)
    cx, body_cy = 128, 168
    arm = 34
    thick = 16
    # a cutout plus-mark, punched through the flask body
    d.rectangle((cx - thick / 2, body_cy - arm, cx + thick / 2, body_cy + arm), fill=CLEAR)
    d.rectangle((cx - arm, body_cy - thick / 2, cx + arm, body_cy + thick / 2), fill=CLEAR)
    return img


def icon_axe() -> Image.Image:
    """Hafted axe: a vertical haft with a D-shaped blade (a half-disc)
    bulging to one side -- the plainest, most legible axe-head silhouette,
    and unambiguous at 64px."""
    img = new_canvas()
    d = ImageDraw.Draw(img)
    cx, hy = 128, 92
    d.rectangle((cx - 12, 60, cx + 12, 224), fill=FG)  # haft
    d.ellipse((cx - 16, 212, cx + 16, 236), fill=FG)  # pommel
    # A double-headed axe: a wedge blade on BOTH sides of the haft. A single
    # one-sided wedge on a stick reads as a flag/pennant no matter how its
    # edge is shaped; mass on both sides of the handle is what only a tool
    # head (not a flag) ever has.
    for sign in (1, -1):
        blade = [
            (cx + sign * 4, hy - 46), (cx + sign * 96, hy - 8),
            (cx + sign * 4, hy + 46),
        ]
        d.polygon(blade, fill=FG)
    return img


def icon_pickaxe() -> Image.Image:
    """A horizontal double-pointed spindle head (two sharp tips, left and
    right) crossing a vertical haft -- unambiguous as a two-point pick,
    where a single tapered chevron kept reading as an arrow."""
    img = new_canvas()
    d = ImageDraw.Draw(img)
    cx, hy = 128, 92
    d.rectangle((cx - 12, hy - 6, cx + 12, 224), fill=FG)  # haft
    d.ellipse((cx - 14, 212, cx + 14, 236), fill=FG)  # pommel
    # lens-shaped head: sharp points left and right, thickest at the haft
    d.polygon(
        [(14, hy), (cx - 4, hy - 30), (cx + 4, hy - 30), (242, hy),
         (cx + 4, hy + 30), (cx - 4, hy + 30)],
        fill=FG,
    )
    d.ellipse((cx - 22, hy - 24, cx + 22, hy + 24), fill=FG)  # eye at the haft
    return img


def icon_hammer() -> Image.Image:
    """Mallet: a wide rectangular head centred over a vertical haft."""
    img = new_canvas()
    d = ImageDraw.Draw(img)
    cx = 128
    d.rectangle((cx - 14, 92, cx + 14, 224), fill=FG)  # haft
    d.ellipse((cx - 16, 212, cx + 16, 236), fill=FG)  # pommel
    d.rounded_rectangle((cx - 84, 32, cx + 84, 104), radius=16, fill=FG)  # head
    return img


def icon_knife() -> Image.Image:
    """Blade + crossguard + grip."""
    img = new_canvas()
    d = ImageDraw.Draw(img)
    cx = 128
    # blade: tapered polygon pointing up
    blade = [(cx, 26), (cx + 26, 130), (cx - 26, 130)]
    d.polygon(blade, fill=FG)
    cutout_line(d, [(cx, 46), (cx, 118)], width=max(3, STROKE // 2))  # blood groove
    # guard
    d.rounded_rectangle((cx - 46, 130, cx + 46, 150), radius=8, fill=FG)
    # grip
    d.rounded_rectangle((cx - 16, 150, cx + 16, 224), radius=10, fill=FG)
    d.ellipse((cx - 18, 216, cx + 18, 236), fill=FG)  # pommel
    return img


def icon_fishing_rod() -> Image.Image:
    """A tapered rod (wide grip to a fine tip), a taut line, and a hook."""
    img = new_canvas()
    d = ImageDraw.Draw(img)
    grip_a, grip_b, tip = (24, 238), (58, 208), (218, 46)
    d.polygon([grip_a, grip_b, tip], fill=FG)
    d.ellipse((12, 224, 40, 252), fill=FG)  # grip cap, anchored on the rod itself
    hook_top = (150, 198)
    d.line([tip, hook_top], fill=FG, width=5)
    d.arc((128, 188, 176, 230), 20, 200, fill=FG, width=9)  # hook curl
    return img


def icon_castle_gate_key() -> Image.Image:
    """A classic ward key: ring bow, shaft, notched teeth."""
    img = new_canvas()
    d = ImageDraw.Draw(img)
    cx, cy, r = 92, 92, 54
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=FG)
    cutout_ellipse(d, (cx - r * 0.55, cy - r * 0.55, cx + r * 0.55, cy + r * 0.55))
    # shaft
    d.rectangle((cx - 12, cy, cx + 12, 210), fill=FG)
    # ward teeth at the bottom, stepped rectangles
    d.rectangle((cx - 12, 178, cx + 40, 194), fill=FG)
    d.rectangle((cx - 12, 196, cx + 28, 212), fill=FG)
    d.rectangle((cx - 12, 194, cx + 12, 224), fill=FG)
    return img


def _punch(base: Image.Image, mark: Image.Image, box) -> Image.Image:
    """Punch `mark`'s silhouette out of `base`, scaled into `box`.

    The same 'same base shape, one marker added' trick `icon_orb_greater` and
    `icon_revive` already use to tell two members of one family apart -- but
    reusing an EXISTING icon function as the marker rather than redrawing its
    shape by hand, so the mark on a TM disc is literally the same glyph the
    move list shows for that slot.
    """
    x0, y0, x1, y1 = box
    scaled = mark.resize((int(x1 - x0), int(y1 - y0)), Image.LANCZOS)
    base.paste(CLEAR, (int(x0), int(y0)), scaled)
    return base


def _icon_tm(mark: Image.Image) -> Image.Image:
    """OF29. A TM is a held item now, not a flag, so it needs a satchel icon.

    A keyed disc: a circle with a flat chord cut off the bottom (so it is a
    disc/chip, not another sphere -- `icon_orb_basic` already owns the plain
    circle silhouette) and a rim groove, with the taught move's own slot glyph
    punched through the middle. `stone_rush` is a charged move and
    `burrow_strike` a quick one, so the two shipped TMs never render the same
    icon without either of them needing a bespoke drawing.
    """
    img = new_canvas()
    d = ImageDraw.Draw(img)
    cx, cy, r = 128, 122, 102
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=FG)
    # flat chord off the bottom -- the silhouette cue that says "disc", not
    # "ball", at 64px where the rim groove alone would blur away
    d.rectangle((cx - r, cy + r * 0.74, cx + r, S), fill=CLEAR)
    # rim groove
    d.ellipse(
        (cx - r * 0.86, cy - r * 0.86, cx + r * 0.86, cy + r * 0.86),
        outline=CLEAR, width=int(STROKE * 0.8),
    )
    return _punch(img, mark, (cx - 52, cy - 52, cx + 52, cy + 52))


def icon_tm_stone_rush() -> Image.Image:
    """TM disc stamped with the charged-move starburst (`stone_rush`)."""
    return _icon_tm(icon_move_charged())


def icon_tm_burrow_strike() -> Image.Image:
    """TM disc stamped with the quick-move bolt (`burrow_strike`)."""
    return _icon_tm(icon_move_quick())


ITEM_ICONS = {
    "wood.png": icon_wood,
    "stone.png": icon_stone,
    "fiber.png": icon_fiber,
    "berries.png": icon_berries,
    "orb_basic.png": icon_orb_basic,
    "orb_greater.png": icon_orb_greater,
    "potion_small.png": icon_potion_small,
    "revive.png": icon_revive,
    "axe.png": icon_axe,
    "pickaxe.png": icon_pickaxe,
    "hammer.png": icon_hammer,
    "knife.png": icon_knife,
    "fishing_rod.png": icon_fishing_rod,
    "castle_gate_key.png": icon_castle_gate_key,
    "tm_stone_rush.png": icon_tm_stone_rush,
    "tm_burrow_strike.png": icon_tm_burrow_strike,
}


# ---------------------------------------------------------------------------
# Shared UI icons
# ---------------------------------------------------------------------------


def icon_type_ground() -> Image.Image:
    """Three-peak mountain."""
    img = new_canvas()
    d = ImageDraw.Draw(img)
    base_y = 194
    d.polygon([(30, base_y), (92, 70), (140, 150), (154, 128), (226, base_y)], fill=FG)
    d.rectangle((20, base_y, 236, base_y + 16), fill=FG)
    # snow-cap cutout notch on the tallest peak
    cutout_line(d, [(78, 92), (92, 70), (106, 92)], width=max(3, STROKE // 2))
    return img


def icon_type_water() -> Image.Image:
    """A single droplet: pointed top, round bottom."""
    img = new_canvas()
    d = ImageDraw.Draw(img)
    cx = 128
    r = 78
    cy = 158
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=FG)
    d.polygon([(cx, 30), (cx + 62, cy - 20), (cx - 62, cy - 20)], fill=FG)
    # small rim highlight (a shine, not a centred pupil-like dot)
    cutout_ellipse(d, (cx - 38, cy - 46, cx - 22, cy - 30))
    return img


def icon_type_air() -> Image.Image:
    """Three wind-swoosh lines."""
    img = new_canvas()
    d = ImageDraw.Draw(img)
    specs = [
        (40, 76, 190, 60, 34),
        (26, 128, 220, 108, 44),
        (56, 180, 186, 168, 28),
    ]
    for x0, y0, x1, y1, width in specs:
        d.line([(x0, y0), (x1, y1)], fill=FG, width=width, joint="curve")
        d.ellipse((x0 - width / 2, y0 - width / 2, x0 + width / 2, y0 + width / 2), fill=FG)
        d.ellipse((x1 - width / 2, y1 - width / 2, x1 + width / 2, y1 + width / 2), fill=FG)
    return img


def icon_bond() -> Image.Image:
    """Two interlocked rings."""
    img = new_canvas()
    d = ImageDraw.Draw(img)
    w = 22
    r = 58
    c1 = (96, 128)
    c2 = (160, 128)
    for cx, cy in (c1, c2):
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=FG)
        d.ellipse((cx - r + w, cy - r + w, cx + r - w, cy + r - w), fill=CLEAR)
    # re-fill the overlap lens so the second ring's hole doesn't eat the
    # first ring's band where they cross, keeping a true woven-link look:
    # punch ring2's hole, then re-solidify ring1 on top, then re-open ring1's
    # own hole again so both remain rings.
    cx, cy = c1
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=FG)
    d.ellipse((cx - r + w, cy - r + w, cx + r - w, cy + r - w), fill=CLEAR)
    return img


def icon_move_quick() -> Image.Image:
    """A lightning bolt."""
    img = new_canvas()
    d = ImageDraw.Draw(img)
    bolt = [
        (150, 24), (76, 140), (118, 140), (98, 232),
        (188, 108), (142, 108),
    ]
    d.polygon(bolt, fill=FG)
    return img


def icon_move_charged() -> Image.Image:
    """A starburst."""
    img = new_canvas()
    d = ImageDraw.Draw(img)
    cx, cy = 128, 128
    points = []
    n = 8
    r_out = 108
    r_in = 42
    for i in range(n * 2):
        ang = math.pi * i / n - math.pi / 2
        r = r_out if i % 2 == 0 else r_in
        points.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
    d.polygon(points, fill=FG)
    return img


UI_ICONS = {
    "type_ground.png": icon_type_ground,
    "type_water.png": icon_type_water,
    "type_air.png": icon_type_air,
    "bond.png": icon_bond,
    "move_quick.png": icon_move_quick,
    "move_charged.png": icon_move_charged,
}


def main() -> None:
    for name, fn in ITEM_ICONS.items():
        save(fn(), ITEMS_DIR / name)
    for name, fn in UI_ICONS.items():
        save(fn(), UI_DIR / name)


if __name__ == "__main__":
    main()
