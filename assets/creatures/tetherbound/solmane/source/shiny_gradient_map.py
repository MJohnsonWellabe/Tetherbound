#!/usr/bin/env python3
"""P2-018 Solmane (and Pebbik) shiny: a clean luminance gradient map over the base texture.

GPU pass (22 Oct): the thresholded hue-swap shiny read as cyan/yellow camouflage
blotches. A gradient map keeps the base texture's value pattern (feather lines,
eyes, mane strands) and gives one designed colour ramp: no per-texel hue noise.
Writes <species>_extracted_base_color_shiny_gm.png beside the model (candidate, OFF).
"""
import sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
RAMPS = {
    # moon mane: deep indigo -> periwinkle -> silver -> warm white
    # (r2: the r1 full-range ramp turned the feather texture into busy blue-and-white
    # noise; the body now spans silver to pale lavender and only the darkest marks,
    # eyes and nose, reach indigo.)
    'solmane': [(0.0, (24, 26, 64)), (0.06, (90, 100, 160)), (0.2, (168, 178, 222)), (0.6, (204, 212, 240)), (1.0, (246, 246, 252))],
    # mint quartz: the warm fur goes deep teal -> jade -> mint -> pale cream ...
    'pebbik': [(0.0, (14, 34, 40)), (0.12, (60, 140, 130)), (0.45, (130, 200, 180)), (0.8, (206, 238, 222)), (1.0, (250, 248, 236))],
}
# ... and its blue stone plates take a second ramp (gold quartz), so the two-tone
# design survives as two clean blocks instead of collapsing into one value map.
SECOND = {
    'pebbik': ((0.5, 0.75), [(0.0, (40, 30, 12)), (0.4, (132, 98, 30)), (0.75, (226, 184, 82)), (1.0, (255, 240, 190))]),
}


def ramp(stops, x):
    xs = np.array([s[0] for s in stops])
    out = np.zeros(x.shape + (3,))
    for c in range(3):
        out[..., c] = np.interp(x, xs, [s[1][c] for s in stops])
    return out


def main(species):
    models = ROOT / species / 'models'
    src = Image.open(models / f'creature_{species}_lod0_Image_0.jpg').convert('RGB')
    a = np.asarray(src).astype(np.float64) / 255.0
    lum = 0.2126 * a[..., 0] + 0.7152 * a[..., 1] + 0.0722 * a[..., 2]
    # Stretch to the texture's own 2-98% range so the ramp spans the whole body.
    lo, hi = np.percentile(lum, 2), np.percentile(lum, 98)
    x = np.clip((lum - lo) / max(hi - lo, 1e-3), 0, 1)
    out = ramp(RAMPS[species], x)
    if species in SECOND:
        (h0, h1), stops = SECOND[species]
        hsv = np.asarray(src.convert('HSV')).astype(np.float64) / 255.0
        mask = ((hsv[..., 0] >= h0) & (hsv[..., 0] <= h1) & (hsv[..., 1] > 0.18)).astype(np.float64)
        mask = np.asarray(Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.5))) / 255.0
        out = out * (1 - mask[..., None]) + ramp(stops, x) * mask[..., None]
    Image.fromarray(out.clip(0, 255).astype(np.uint8)).save(models / f'{species}_extracted_base_color_shiny_gm.png')


if __name__ == '__main__':
    for s in sys.argv[1:] or RAMPS:
        main(s)
