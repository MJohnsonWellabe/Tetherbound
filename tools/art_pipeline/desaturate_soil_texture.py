"""
Desaturate Ground003_Color.jpg (the hillside "soil" band texture) toward its
own local luminance, in place.

Written for EV4-hillside-seam-remainder-2: two prior rounds tried to reach a
visible tan soil band purely through configured tint/relief and both failed
or regressed (see terrain_playground.json's own
_comment_ev4_hillside_seam_remainder). Direct measurement showed why:
Ground003_Color.jpg's own raw saturation (mean 0.45) is roughly 4.5x every
other ground texture already shipped in this project (Ground030, the path
texture, measures 0.099; Rock030 measures 0.126) -- the photo itself is
oversaturated across nearly its whole area, not merely in isolated green
blobs the way Ground030's moss was. No tint multiply, however strong, can
turn a photo this saturated into a believable soil tan without either
under-shooting (round 1) or blowing into rust/orange (round 2) -- amplifying
chroma that is already too high just moves where it lands, not how much
there is.

Same technique EV4-textures used for Ground030's moss blobs (a feathered
blend toward local luminance, done to the pixels rather than fought through
a multiplier), scaled to this photo's actual defect: a broad, whole-image
saturation trim rather than a narrow hue-masked patch. Pixels in the
green/grass-tuft hue range get pulled hardest toward neutral (they read as
grass, not soil, regardless of tint); every other pixel gets a milder trim
so the photo's baseline lands near its siblings' ~0.10-0.15 mean, letting
the existing warm tint (#c9a874) multiply it toward tan cleanly instead of
fighting leftover chroma.

Usage:
    python3 tools/art_pipeline/desaturate_soil_texture.py
"""
import numpy as np
from PIL import Image, ImageFilter

SRC = "assets/environment/terrain/Ground003_Color.jpg"

GREEN_HUE_LO, GREEN_HUE_HI = 60.0, 160.0
GREEN_SAT_THRESH = 0.12
GREEN_PULL = 0.85   # how far green-hued pixels move toward their own local luminance
BASE_PULL = 0.55    # how far every other pixel moves toward its own local luminance
FEATHER_PX = 12      # gaussian blur radius on the green mask, in source pixels


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

    h_deg, s, v = rgb_to_hsv(arr)
    before_mean_sat = float(s.mean())

    # The pixel's own value, so texture/shading survives the desaturation
    # instead of getting flattened to a flat grey.
    luminance = 0.299 * arr[..., 0] + 0.587 * arr[..., 1] + 0.114 * arr[..., 2]
    neutral = np.stack([luminance] * 3, axis=-1)

    green_mask = ((h_deg > GREEN_HUE_LO) & (h_deg < GREEN_HUE_HI) & (s > GREEN_SAT_THRESH)).astype(np.float32)
    green_mask_img = Image.fromarray((green_mask * 255).astype(np.uint8))
    green_mask_soft = np.asarray(
        green_mask_img.filter(ImageFilter.GaussianBlur(FEATHER_PX))
    ).astype(np.float32) / 255.0

    pull = BASE_PULL + (GREEN_PULL - BASE_PULL) * green_mask_soft
    pull = pull[..., None]

    corrected = arr * (1.0 - pull) + neutral * pull
    corrected = np.clip(corrected, 0.0, 1.0)

    h2, s2, v2 = rgb_to_hsv(corrected)
    green_bool = green_mask > 0.5
    print(f"mean saturation: {before_mean_sat:.3f} -> {float(s2.mean()):.3f}")
    if green_bool.any():
        print(
            f"green-region mean saturation: {float(s[green_bool].mean()):.3f} -> "
            f"{float(s2[green_bool].mean()):.3f}"
        )
    print(f"green pixel fraction: {float(green_mask.mean()):.3f}")

    out = Image.fromarray((corrected * 255).astype(np.uint8))
    out.save(SRC, quality=95)
    print(f"saved {SRC}")


if __name__ == "__main__":
    main()
