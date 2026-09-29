"""Derive Tidewake's dune atlas from the installed stylized-nature Grass.png.

No source asset is overwritten. Palette comes from water_dune_cover.json;
the enabled flag is a runtime gate, not a generation gate. Source UV layout,
neutral pixels and alpha are retained. Uses no external reference pixels.
Run with --check to verify the committed result without writing files.
Godot import/compression remains owned by texture_import_policy.py.
"""

from __future__ import annotations

import argparse
import colorsys
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageColor

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/environment/stylized_nature/Grass.png"
CONFIG = ROOT / "data/config/water_dune_cover.json"


def derive(source: Image.Image, palette: dict[str, str]) -> Image.Image:
    """Same HSV transform as the candidate's former runtime image pass."""
    targets = {
        key: colorsys.rgb_to_hsv(*(c / 255.0 for c in ImageColor.getrgb(palette[key])))
        for key in ("sage", "straw")
    }
    output = source.convert("RGBA").copy()
    pixels = output.load()
    for y in range(output.height):
        for x in range(output.width):
            r, g, b, alpha = pixels[x, y]
            hue, saturation, value = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
            if saturation < 0.12 or alpha == 0:
                continue
            target_hue, target_saturation, _ = targets["sage" if hue > 0.20 else "straw"]
            rgb = colorsys.hsv_to_rgb(target_hue, target_saturation, min(1.0, value * 0.9 + 0.08))
            pixels[x, y] = (*[int(component * 255.0 + 0.5) for component in rgb], alpha)
    return output


def verify_invariants(source: Image.Image, candidate: Image.Image) -> None:
    original = source.convert("RGBA")
    assert original.size == candidate.size, "UV atlas dimensions changed"
    assert original.getchannel("A").tobytes() == candidate.getchannel("A").tobytes(), "alpha changed"
    original_pixels, candidate_pixels = original.load(), candidate.load()
    for y in range(original.height):
        for x in range(original.width):
            before, after = original_pixels[x, y], candidate_pixels[x, y]
            saturation = colorsys.rgb_to_hsv(*(component / 255.0 for component in before[:3]))[1]
            if saturation < 0.12 or before[3] == 0:
                assert before == after, "neutral or transparent source pixel changed"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    settings = json.loads(CONFIG.read_text(encoding="utf-8"))
    output = ROOT / settings["grass_texture"].removeprefix("res://")
    source_hash = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
    with Image.open(SOURCE) as source:
        candidate = derive(source, settings["grass_palette"])
        verify_invariants(source, candidate)
    if args.check:
        with Image.open(output) as committed:
            assert candidate.size == committed.size
            assert candidate.tobytes() == committed.convert("RGBA").tobytes(), "derived atlas is stale"
    else:
        output.parent.mkdir(parents=True, exist_ok=True)
        candidate.save(output, optimize=True)
    assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == source_hash, "source atlas modified"
    print(f"{'Verified' if args.check else 'Wrote'} {output.relative_to(ROOT)}; source SHA256={source_hash}")


if __name__ == "__main__":
    main()
