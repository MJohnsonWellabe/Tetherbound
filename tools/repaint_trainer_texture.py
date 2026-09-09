#!/usr/bin/env python3
"""Build Arlo's bounded teal-cloth readability variant from the installed texture."""

from __future__ import annotations

import colorsys
import hashlib
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/characters/trainer/trainer_lod0_texture_0.png"
OUTPUT = ROOT / "assets/characters/trainer/trainer_teal_accent.png"
SOURCE_SHA256 = "49814ee0259b54ef93e435e0b2be37214b8f2a05c511e27fac6428e4d683e447"


def _selected(hue_deg: float, saturation: float, value: float) -> bool:
    return 175.0 <= hue_deg <= 220.0 and saturation >= 0.20 and value >= 0.10


def main() -> None:
    source_bytes = SOURCE.read_bytes()
    actual_hash = hashlib.sha256(source_bytes).hexdigest()
    if actual_hash != SOURCE_SHA256:
        raise SystemExit(
            f"refusing unknown Arlo source: expected {SOURCE_SHA256}, got {actual_hash}"
        )

    image = Image.open(SOURCE).convert("RGBA")
    output_pixels: list[tuple[int, int, int, int]] = []
    changed = 0
    skin_exclusion = 0
    brown_exclusion = 0
    neutral_exclusion = 0
    exclusion_overlap = 0
    for red, green, blue, alpha in image.get_flattened_data():
        hue, saturation, value = colorsys.rgb_to_hsv(
            red / 255.0, green / 255.0, blue / 255.0
        )
        hue_deg = hue * 360.0
        selected = _selected(hue_deg, saturation, value)
        # These audit masks are deliberately broader than the visible regions:
        # skin includes warm peach; brown includes hair and every leather family;
        # neutral includes white cloth and charcoal. A changed/excluded overlap is
        # a generator failure, not something accepted by visual inspection later.
        skin = 0.0 <= hue_deg <= 45.0 and 0.12 <= saturation <= 0.75 and value >= 0.35
        brown = 5.0 <= hue_deg <= 65.0 and saturation >= 0.15
        neutral = saturation < 0.12
        skin_exclusion += int(skin)
        brown_exclusion += int(brown)
        neutral_exclusion += int(neutral)
        exclusion_overlap += int(selected and (skin or brown or neutral))
        if selected:
            changed += 1
            hue = 195.0 / 360.0
            saturation = max(saturation, 0.55)
            value = min(1.0, value * 1.18)
            red_f, green_f, blue_f = colorsys.hsv_to_rgb(hue, saturation, value)
            red, green, blue = (round(channel * 255.0) for channel in (red_f, green_f, blue_f))
        output_pixels.append((red, green, blue, alpha))

    if exclusion_overlap != 0:
        raise SystemExit(f"teal selector overlaps protected audit masks: {exclusion_overlap}")
    output = Image.new("RGBA", image.size)
    output.putdata(output_pixels)
    output.save(OUTPUT, optimize=False)
    output_hash = hashlib.sha256(OUTPUT.read_bytes()).hexdigest()
    print(
        "ARLO_TEAL_REPAINT "
        f"changed={changed}/{image.width * image.height} "
        f"skin_exclusion={skin_exclusion} brown_exclusion={brown_exclusion} "
        f"neutral_exclusion={neutral_exclusion} overlap={exclusion_overlap} "
        f"sha256={output_hash} output={OUTPUT}"
    )


if __name__ == "__main__":
    main()
