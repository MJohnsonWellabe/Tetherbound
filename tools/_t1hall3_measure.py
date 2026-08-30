#!/usr/bin/env python3
"""T1-HALL-3 — measure the JUDGE-5 defects that have numbers attached.

The judge gave pixel coordinates on 1280x800 frames and, for several defects,
a measurable quantity. This re-measures the same quantities on a new set so
"did it move" is answerable with a number rather than an opinion, and so the
handover can state what changed rather than assert it.

    python3 tools/_t1hall3_measure.py <after_dir> [before_dir]
"""
import sys
import os
import numpy as np
from PIL import Image


def load(d, name):
    p = os.path.join(d, name + ".png")
    if not os.path.exists(p):
        return None
    return np.asarray(Image.open(p).convert("RGB")).astype(float)


def banner_pixels(im):
    """Cloth is the reddest thing in a Hall frame: red clearly above green,
    and bright enough not to be shadowed stone."""
    p = im.reshape(-1, 3)
    m = (p[:, 0] > p[:, 1] * 1.45) & (p[:, 0] > 70)
    return p[m]


def report_banner(tag, im):
    q = banner_pixels(im)
    if len(q) < 200:
        print("  %-26s no cloth found (n=%d)" % (tag, len(q)))
        return
    r, g, b = q.mean(axis=0)
    # B>G is the relationship that makes the eye read magenta rather than
    # oxblood -- see stronghold.gd's BANNER_COLOUR header.
    verdict = "MAGENTA-LEANING (B>G)" if b > g else "oxblood (B<=G)"
    print("  %-26s n=%6d mean=(%3.0f,%3.0f,%3.0f)  %s" % (tag, len(q), r, g, b, verdict))


def report_silhouette(tag, im, band=(250, 440)):
    """D3: 'the entire stronghold is a pale ~60px smudge at (620-700,375-405)'
    -- i.e. ~80px wide by ~30px tall at 400m.

    Measured the same way the judge read it: find the BUILT STONE in the
    horizon band and report its bounding box. Stone at this range is warm and
    desaturated (r >= g >= b, low chroma) and mid-value -- which separates it
    from sky (blue-dominant), from grass and trees (green-dominant), and from
    the storm slabs (blue-grey).

    KNOWN LIMIT, stated so nobody reads more into this number than it carries:
    warm cirrus shares stone's signature (warm, desaturated, mid-value), so the
    band is clipped below the cloud deck at y=250. A mass that breaks ABOVE
    y=250 will therefore be under-reported by this metric, not over-reported --
    it is a floor on the improvement, not a measurement of it. The frame itself
    and the massing arithmetic in the handover are the primary evidence for
    D3; this is a corroborating number."""
    y0, y1 = band
    # The Hall sits on the approach bearing, near frame centre; the ground
    # below the horizon is excluded by the band, because dry grass and the
    # dirt path share stone's warm desaturated signature and would otherwise
    # dominate the measurement.
    x0, x1 = 470, 900
    sub = im[y0:y1, x0:x1]
    r, g, b = sub[..., 0], sub[..., 1], sub[..., 2]
    mx = np.maximum(np.maximum(r, g), b)
    mn = np.minimum(np.minimum(r, g), b)
    chroma = (mx - mn) / np.maximum(mx, 1.0)
    lum = sub.mean(axis=2)
    stone = (r >= g - 2) & (g >= b - 2) & (chroma < 0.30) & (lum > 70) & (lum < 215)
    ys, xs = np.nonzero(stone)
    if len(ys) < 40:
        print("  %-26s no built stone found on the approach bearing" % tag)
        return
    top = y0 + ys.min()
    print("  %-26s stone px=%d in x[%d-%d]; skyline TOP at y=%d, base y=%d "
          "-> %dpx of built mass standing against sky"
          % (tag, len(ys), x0, x1, top, y0 + ys.max(), ys.max() - ys.min()))


def report_wall_patch(tag, im, box):
    x0, y0, x1, y1 = box
    patch = im[y0:y1, x0:x1]
    lum = patch.mean(axis=2)
    print("  %-26s mean=%.1f  std=%.1f  (design sec5 wants std >= 35)"
          % (tag, lum.mean(), lum.std()))


def report_seethrough(tag, im, box):
    """D8: sky and grass visible THROUGH the wall at the frame's far-left
    edge. Sky is blue and bright; a wall at 6m is neither."""
    x0, y0, x1, y1 = box
    patch = im[y0:y1, x0:x1].reshape(-1, 3)
    r, g, b = patch[:, 0], patch[:, 1], patch[:, 2]
    sky = (b > r * 1.05) & (b > 110)
    print("  %-26s sky-like pixels in the wall strip: %d / %d (%.1f%%)"
          % (tag, sky.sum(), len(patch), 100.0 * sky.sum() / max(1, len(patch))))


def main():
    after = sys.argv[1]
    before = sys.argv[2] if len(sys.argv) > 2 else None
    for label, d in (("BEFORE", before), ("AFTER", after)):
        if d is None:
            continue
        print("\n=== %s  (%s) ===" % (label, d))

        im = load(d, "H-01-approach-400")
        if im is not None:
            print(" D3 landmark silhouette, H-01-approach-400:")
            report_silhouette("built mass vs sky", im)

        im = load(d, "H-05-east-flank")
        if im is not None:
            print(" D6 banner hue / D5 wall patch, H-05-east-flank:")
            report_banner("cloth", im)
            report_wall_patch("wall patch (400-600,220-380)", im, (400, 220, 600, 380))

        im = load(d, "H-08-wall-close")
        if im is not None:
            print(" D8 see-through wall, H-08-wall-close:")
            report_seethrough("far-left strip (0-16,270-790)", im, (0, 270, 16, 790))

        im = load(d, "H-04-gate-mouth")
        if im is not None:
            print(" D1 gate mouth, H-04-gate-mouth:")
            h, w, _ = im.shape
            lum = im.mean(axis=2)
            dark = (lum < 26).mean()
            skyish = ((im[..., 2] > im[..., 0] * 1.05) & (im[..., 2] > 110)).mean()
            print("  %-26s near-black %.1f%% of frame, sky %.1f%% "
                  "(a buried camera is nearly all dark and has no sky)"
                  % ("frame content", 100 * dark, 100 * skyish))

        im = load(d, "H-07-courtyard")
        if im is not None:
            print(" D2 courtyard, H-07-courtyard:")
            report_banner("cloth in room", im)
            lum = im.mean(axis=2)
            print("  %-26s value range p5=%.0f p95=%.0f (JUDGE-5: 'no true "
                  "darks and no true lights')" % ("tonal spread",
                                                  np.percentile(lum, 5),
                                                  np.percentile(lum, 95)))


if __name__ == "__main__":
    main()
