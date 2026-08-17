#!/usr/bin/env python3
"""Convert captured PNG frames into the website's committed JPEGs.

The mapping lives here rather than in `site/README.md` because the README's
copy of it drifted: it named `shots/combat/06-charged-attack-lands.png` long
after the tool started writing `06-charged-attack-lands-offaxis.png`, so the
documented refresh recipe failed outright for anyone who followed it. A script
that runs is harder to get wrong than a code block that is read.

Capture at 1280x720 (see `site/README.md`); this downscales the small figures
to 960 wide. Sources that are missing are reported and skipped, not fatal — the
page falls back through layered CSS backgrounds, so a partial refresh degrades
it rather than breaking it.

    python3 tools/site_images.py

Run `godot --headless --path . --import` BEFORE capturing anything, or the
frames render last week's textures.
"""

from pathlib import Path
import sys

try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow is required: pip install pillow")

ROOT = Path(__file__).resolve().parent.parent
QUALITY = 82

# (source png, output jpg, width) — width None keeps the capture size.
# The wide/parallax frames stay 1280 because they are shown large; the figures
# in a three-up row never render wider than ~600 CSS px, so 960 is plenty.
MAPPING = [
    # Authored page shots — tools/capture_site_shots.gd
    ("shots/site/hero-meadow.png",             "site/img/hero-meadow.jpg",            1280),
    ("shots/site/village-square.png",          "site/img/village-square.jpg",          960),
    ("shots/site/opening-bedroom.png",         "site/img/opening-bedroom.jpg",         960),
    ("shots/site/starters-by-the-door.png",    "site/img/starters-by-the-door.jpg",    960),
    ("shots/site/camp-dusk.png",               "site/img/camp-dusk.jpg",               960),
    # Captured since R7.2 and never used on the page until 2026-08-16.
    ("shots/site/village-npcs.png",            "site/img/village-npcs.jpg",            960),
    ("shots/site/house-interior-dressed.png",  "site/img/house-interior.jpg",          960),

    # Exploration frames — tools/survey.sh
    ("shots/01-spawn-outward.png",             "site/img/01-spawn-outward.jpg",       1280),
    ("shots/03-rise-overlook.png",             "site/img/03-rise-overlook.jpg",       1280),
    ("shots/05-spawn-low-sun.png",             "site/img/05-spawn-low-sun.jpg",       1280),

    # Combat frames — tools/survey_combat.sh. Note the `-offaxis` suffix: the
    # tool moved the camera off the attack axis so the swing reads.
    ("shots/combat/02-arena-opens.png",                    "site/img/02-arena-opens.jpg",          1280),
    ("shots/combat/06-charged-attack-lands-offaxis.png",   "site/img/06-charged-attack-lands.jpg", 1280),
    ("shots/combat/08-orb-in-flight.png",                  "site/img/08-orb-in-flight.jpg",        1280),

    # The catch arc. `.s-aim` fell through to a frame with no visible arc for
    # months; this is the slot that finally shows what the caption promises.
    # OF18-found: the old source name, "shots/catch/03-aiming.png", is not
    # written by any capture tool in this repo any more -- grepped for it
    # across tools/*.gd and tools/*.py and found nothing. tools/
    # capture_catch_sequence.gd (OF1) writes "catch_low.png"/"catch_high.png"
    # from `_capture_chance_frames()`, spec section10.2/D31's own aim-state
    # stills with the reticle and a real percentage on screen -- exactly what
    # the page's caption promises, and unlike the sequence frames these two
    # are captured unconditionally, before either dice-dependent sequence
    # runs, so they are never missing from a completed capture run.
    # catch_high (a near-certain catch) reads better as a promotional shot
    # than catch_low (a near-miss) for the same reason a store page leads
    # with success rather than failure.
    ("shots/catch/catch_high.png",             "site/img/aim-arc.jpg",                 960),

    # The roster grid — tools/capture_shiny_pairs.gd (OF28, all 17 species).
    ("shots/_shiny_pairs.png",                 "site/img/roster.jpg",                 1280),

    # Weather and night, neither of which the page covered before.
    ("shots/weather/rain.png",                 "site/img/weather-rain.jpg",            960),
    ("shots/_diag/torch_night_on.png",         "site/img/night-torch.jpg",             960),
]


def main() -> int:
    written, missing = 0, []
    for src_rel, out_rel, width in MAPPING:
        src, out = ROOT / src_rel, ROOT / out_rel
        if not src.exists():
            missing.append(src_rel)
            continue
        img = Image.open(src).convert("RGB")
        if width and img.width > width:
            height = round(img.height * width / img.width)
            img = img.resize((width, height), Image.LANCZOS)
        out.parent.mkdir(parents=True, exist_ok=True)
        img.save(out, quality=QUALITY, optimize=True)
        print(f"  {out_rel}  {img.width}x{img.height}  {out.stat().st_size // 1024} KB")
        written += 1

    print(f"\n{written} written, {len(missing)} missing")
    if missing:
        print("missing sources (the page falls back for these):")
        for m in missing:
            print(f"  {m}")
    total = sum(p.stat().st_size for p in (ROOT / "site/img").glob("*.jpg"))
    print(f"site/img total: {total // 1024} KB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
