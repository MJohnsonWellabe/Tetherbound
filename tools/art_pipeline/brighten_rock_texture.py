"""
Lift Rock030_Color.jpg (the hillside "rock" band texture) off its own dark
floor, in place.

Written for EV4-hillside-seam-remainder-3. EV4-hillside-seam-remainder-2
fixed the soil band's own colour (an oversaturated source photo, then a
compounding tint/colour-map multiply) and confirmed the fix landed in the
rendered frame -- but a third blind critic still reported no visible third
material, this time describing rock as reading like "near-black... shadow
holes" rather than stone. Direct pixel sampling of the rendered frame found
why: soil and rock share almost the same hue (46-52 degrees, the same warm
family) and differ mainly in VALUE -- and rock's own native brightness
(Rock030_Color.jpg mean value 0.312, measured directly) is low enough that
this scene's grazing sun, plus the material's own normal_depth/ao_strength,
crushes it toward black rather than reading as a mid-tone stone.

A tint multiply has no headroom left to fix this: `tint` is already
`#fafafa`, ~2% of the way to pure white, so multiplying by an even brighter
tint moves almost nothing. The photo's own floor has to move, the same
reasoning EV4-hillside-seam-remainder-2 applied to soil's saturation rather
than fighting it through a multiplier.

A screen-blend lift (`new = 1 - (1-old)*(1-amount)`) raises the darks more
than the lights, which is what "floor" means here, and -- verified directly
below -- it does not shift hue (a uniform per-channel nonlinear transform
applied identically to R, G and B): rock's mean hue measures 47.6 degrees
both before and after. It does, as a side effect, pull saturation down
(0.126 -> 0.073), which is a second real improvement in this item's own
terms: rock reading as a desaturated grey stone rather than a saturated dark
patch sharing soil's own warm cast is exactly the extra separation the third
material band needs, since hue alone cannot supply it (soil and rock's hue
distributions overlap almost entirely, per this item's own analysis).

amount=0.18 was chosen by simulating the full render multiply chain (photo x
texture tint x terrain_playground.json's `colour.rock`) rather than eyeballed:
it takes rock from (value 0.248, saturation 0.172) to (value 0.346,
saturation 0.121) in that full chain, narrowing the value gap against soil's
own chain (~0.46) from 0.209 to 0.092 -- still a real, visible difference,
not eliminated -- while roughly halving rock's saturation relative to soil's
newly-warmed tint. See terrain_playground.json's own comment on the paired
`tint`/`normal_depth`/`ao_strength` changes this script's fix is meant to run
alongside.

Usage:
    python3 tools/art_pipeline/brighten_rock_texture.py
"""
import numpy as np
from PIL import Image

SRC = "assets/environment/terrain/Rock030_Color.jpg"

LIFT_AMOUNT = 0.18  # screen-blend amount; see module docstring for how this was chosen


def rgb_to_hsv(arr):
    r, g, b = arr[..., 0], arr[..., 1], arr[..., 2]
    maxc = np.max(arr, axis=-1)
    minc = np.min(arr, axis=-1)
    v = maxc
    delta = maxc - minc
    s = np.where(maxc == 0, 0.0, delta / np.maximum(maxc, 1e-6))
    h = np.zeros_like(maxc)
    mask = delta > 1e-6
    rc = np.zeros_like(maxc)
    gc = np.zeros_like(maxc)
    bc = np.zeros_like(maxc)
    rc[mask] = (maxc[mask] - r[mask]) / delta[mask]
    gc[mask] = (maxc[mask] - g[mask]) / delta[mask]
    bc[mask] = (maxc[mask] - b[mask]) / delta[mask]
    is_r = (maxc == r) & mask
    is_g = (maxc == g) & mask
    is_b = (maxc == b) & mask
    h[is_r] = bc[is_r] - gc[is_r]
    h[is_g] = 2.0 + (rc[is_g] - bc[is_g])
    h[is_b] = 4.0 + (gc[is_b] - rc[is_b])
    h = (h / 6.0) % 1.0
    return h * 360.0, s, v


def main():
    img = Image.open(SRC).convert("RGB")
    arr = np.asarray(img).astype(np.float32) / 255.0

    before_h, before_s, before_v = rgb_to_hsv(arr)

    lifted = 1.0 - (1.0 - arr) * (1.0 - LIFT_AMOUNT)

    after_h, after_s, after_v = rgb_to_hsv(lifted)

    print(f"{SRC}")
    print(f"  hue:   {before_h.mean():.1f} -> {after_h.mean():.1f}")
    print(f"  sat:   {before_s.mean():.3f} -> {after_s.mean():.3f}")
    print(f"  value: {before_v.mean():.3f} -> {after_v.mean():.3f}")

    out = Image.fromarray((np.clip(lifted, 0.0, 1.0) * 255.0).round().astype(np.uint8), mode="RGB")
    out.save(SRC, quality=95)
    print(f"  saved -> {SRC}")


if __name__ == "__main__":
    main()
