#!/usr/bin/env python3
"""Build the source-locked craftsperson garment value-cleanup texture.

Only the measured cool-green garment selector is changed. Hue and saturation
are copied byte-for-byte through HSV; value gets a restrained median/banded
cleanup to reduce source speckle while retaining the garment's mean value.
"""
from __future__ import annotations

import colorsys
import hashlib
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/characters/craftsperson/craftsperson_lod0_texture_0.png"
OUTPUT = ROOT / "assets/characters/craftsperson/craftsperson_cloth_clean.png"
SOURCE_SHA256 = "a260159b4ffab4ded76497e4bd7e85ff5838dc43e1bfa044489e816712578e70"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    actual = sha256(SOURCE)
    if actual != SOURCE_SHA256:
        raise SystemExit(f"source hash mismatch: expected {SOURCE_SHA256}, got {actual}")

    source_image = Image.open(SOURCE).convert("RGBA")
    # Keep HSV in float64. The attribution proof used exact 8-bit fractions;
    # float32 rounds the hue-65 boundary just below 65 for some pixels and
    # would silently drop part of the already-proven garment selector.
    rgb = np.asarray(source_image, dtype=np.float64)[..., :3] / 255.0
    flat = rgb.reshape(-1, 3)
    hsv = np.asarray([colorsys.rgb_to_hsv(*pixel) for pixel in flat], dtype=np.float64).reshape((*rgb.shape[:2], 3))
    hue_deg = hsv[..., 0] * 360.0
    mask = ((hue_deg >= 65.0) & (hue_deg <= 165.0)
            & (hsv[..., 1] >= 0.14) & (hsv[..., 2] >= 0.07)
            & (hsv[..., 2] <= 0.55))

    value = hsv[..., 2]
    value_u8 = Image.fromarray(np.round(value * 255.0).astype(np.uint8), "L")
    median = np.asarray(value_u8.filter(ImageFilter.MedianFilter(size=9)), dtype=np.float64) / 255.0
    banded = np.round(median * 7.0) / 7.0
    cleanup = median * 0.65 + banded * 0.35
    candidate_value = value * 0.35 + cleanup * 0.65

    # Preserve the selected region's mean value so this pass changes hierarchy,
    # not brightness. Clipping is immaterial for this dark selector, but kept
    # explicit for deterministic behavior.
    mean_shift = float(value[mask].mean() - candidate_value[mask].mean())
    candidate_value = np.clip(candidate_value + mean_shift, 0.0, 1.0)
    out_hsv = hsv.copy()
    out_hsv[..., 2][mask] = candidate_value[mask]
    out_rgb = np.asarray([colorsys.hsv_to_rgb(*pixel) for pixel in out_hsv.reshape(-1, 3)], dtype=np.float32).reshape(rgb.shape)
    out_rgba = np.asarray(source_image).copy()
    out_rgba[..., :3] = np.round(np.clip(out_rgb, 0.0, 1.0) * 255.0).astype(np.uint8)
    Image.fromarray(out_rgba, "RGBA").save(OUTPUT, optimize=False)

    def neighbor_delta(values: np.ndarray) -> float:
        horizontal = mask[:, 1:] & mask[:, :-1]
        vertical = mask[1:, :] & mask[:-1, :]
        diffs = np.concatenate((
            np.abs(values[:, 1:] - values[:, :-1])[horizontal],
            np.abs(values[1:, :] - values[:-1, :])[vertical],
        ))
        return float(diffs.mean())

    changed = np.any(out_rgba[..., :3] != np.asarray(source_image)[..., :3], axis=2)
    print(f"source_sha256={actual}")
    print(f"output_sha256={sha256(OUTPUT)}")
    print(f"selector_pixels={int(mask.sum())}/{mask.size} ({mask.mean() * 100.0:.4f}%)")
    print(f"changed_outside_selector={int((changed & ~mask).sum())}")
    print(f"mean_hue={hsv[..., 0][mask].mean() * 360.0:.6f}->{out_hsv[..., 0][mask].mean() * 360.0:.6f}")
    print(f"mean_saturation={hsv[..., 1][mask].mean():.8f}->{out_hsv[..., 1][mask].mean():.8f}")
    print(f"mean_value={value[mask].mean():.8f}->{out_hsv[..., 2][mask].mean():.8f}")
    print(f"neighbor_value_delta={neighbor_delta(value):.8f}->{neighbor_delta(out_hsv[..., 2]):.8f}")


if __name__ == "__main__":
    main()
