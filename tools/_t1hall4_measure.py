#!/usr/bin/env python3
"""T1-HALL-4 — measure the JUDGE-6 defects that carry numbers.

JUDGE-6's top finding is a *measurement*, not an opinion, and it is the one
this lane is judged on:

    fortress mass (600,350)-(720,420)          mean L = 137.6
    bald hill right of it (760,430)-(900,500)  mean L = 162.5
    -> the fortress is 25 points DARKER-than-nothing: within 5 points of the
       ground and darker than the hill, i.e. no figure/ground separation.

    keyart stronghold panel, measured the same way: 72 against 104
    -> a 32-point separation with the fortress as the DARK shape.

So the lane's headline number is `separation = hill - fortress`, signed, and
the target is "the fortress is the dark shape by a clear margin", i.e. a
positive separation of roughly the keyart's 32.

Run it the way the judge did — same frame, same boxes, no eyeballing:

    python3 tools/_t1hall4_measure.py <after_dir> [before_dir]

`before_dir` defaults to the committed T1-HALL-3 stand so "did it move" is
always answerable against the exact frames JUDGE-6 read.
"""
import os
import sys

import numpy as np
from PIL import Image

BEFORE_DEFAULT = "ralph/reports/T1-HALL-3/shots"

# JUDGE-6 §1, quoted verbatim from the report's own table. Boxes are
# (x0, y0, x1, y1) on the 1280x800 frame.
J6_FORTRESS = (600, 350, 720, 420)
J6_HILL = (760, 430, 900, 500)
J6_MIDGROUND_LEFT = (200, 420, 500, 500)
J6_FOREGROUND = (0, 600, 400, 800)

# JUDGE-6 §2: "from the treeline outward ... no grass, no bushes, no rocks, no
# props of any kind", and "not a single tree above y ~= 560 across the whole
# 1280px width". Measured as: how much of the mid-distance band is NOT bare
# ground. A bare-ground pixel here is bright and low-chroma; scatter is darker
# and greener. This is a content measure, not a colour one -- it goes up when
# the band gains objects and stays put when the band is merely recoloured.
MID_BAND = (0, 380, 1280, 560)


def load(d, name):
    p = os.path.join(d, name + ".png")
    if not os.path.exists(p):
        return None
    return np.asarray(Image.open(p).convert("RGB")).astype(float)


def lum(patch):
    """Plain channel mean, which is how JUDGE-6's table was computed -- its
    fortress/hill/foreground numbers reproduce on the committed frames under
    this definition and not under a Rec.709 weighting, so this file uses the
    judge's definition rather than a more correct one it could not be
    compared against."""
    return patch.mean(axis=2)


def box(im, b):
    x0, y0, x1, y1 = b
    return im[y0:y1, x0:x1]


def report_separation(tag, im):
    """The lane's headline number, and it is deliberately the HARSH reading.

    JUDGE-6's table gives the fortress three neighbours, and its verdict sentence
    uses two of them at once: "within 5 luminance points of the ground beside it
    and is darker than the hill to its right". The fortress is already 25 points
    below the *hill* on the judged frames -- reproduced here -- so quoting only
    that pair would let this lane claim a win it had not earned. The defect lives
    in the other pair: the mid-ground the fortress is actually seen against sits
    at 143 to its 138, and a landmark five points off its own background has no
    silhouette however dark some other region of the frame is.

    So the headline is `min(hill, midground) - fortress`: the fortress has to be
    clearly the dark shape against EVERY ground region beside it, not just the
    brightest one. On the judged frames that number is +2.9, which is exactly the
    "no figure/ground separation at all" the judge saw. The keyart's +32 is the
    target."""
    f = lum(box(im, J6_FORTRESS))
    h = lum(box(im, J6_HILL))
    ml = lum(box(im, J6_MIDGROUND_LEFT))
    fg = lum(box(im, J6_FOREGROUND))
    sep_hill = h.mean() - f.mean()
    sep_mid = ml.mean() - f.mean()
    sep = min(sep_hill, sep_mid)
    print("  %-30s fortress L=%5.1f (sd %4.1f)" % (tag, f.mean(), f.std()))
    print("  %-30s hill     L=%5.1f (sd %4.1f)   -> %+.1f" % ("", h.mean(), h.std(), sep_hill))
    print("  %-30s midgrnd  L=%5.1f (sd %4.1f)   -> %+.1f" % ("", ml.mean(), ml.std(), sep_mid))
    print("  %-30s foreground L=%5.1f" % ("", fg.mean()))
    verdict = "fortress is the DARK shape" if sep > 12.0 else \
              ("no separation" if abs(sep) <= 12.0 else "fortress is the LIGHT shape")
    print("  %-30s SEPARATION (worst neighbour) = %+.1f  -> %s"
          % ("", sep, verdict))
    print("  %-30s (T1-HALL-3 judged frames %+.1f; keyart %+.1f)" % ("", 2.9, 32.0))
    return sep


def report_midband_content(tag, im):
    """Fraction of the mid-distance band that is NOT bare pale ground, and the
    band's own luminance. JUDGE-6: 'a uniform, near-white, desaturated
    yellow-green ... with no grass, no bushes, no rocks, no props of any
    kind'."""
    sub = box(im, MID_BAND)
    r, g, b = sub[..., 0], sub[..., 1], sub[..., 2]
    mx = np.maximum(np.maximum(r, g), b)
    mn = np.minimum(np.minimum(r, g), b)
    chroma = (mx - mn) / np.maximum(mx, 1.0)
    l = sub.mean(axis=2)
    bare = (l > 140.0) & (chroma < 0.26)
    print("  %-30s band L=%5.1f sd=%4.1f, bare pale ground %.1f%% of band"
          % (tag, l.mean(), l.std(), 100.0 * bare.mean()))
    # The hard cull line: the highest row that still holds dark (vegetation)
    # pixels, scanned across the full width. A hard line shows as a row index
    # well below the horizon with nothing above it.
    dark = (lum(im) < 90.0)
    rows = np.nonzero(dark[:600].sum(axis=1) > 12)[0]
    if len(rows):
        print("  %-30s topmost row holding vegetation-dark pixels: y=%d"
              % ("", rows.min()))


def report_frame_structure(tag, im):
    l = lum(im)
    print("  %-30s whole-frame L sd=%4.1f  p5=%3.0f p50=%3.0f p95=%3.0f"
          % (tag, l.std(), np.percentile(l, 5), np.percentile(l, 50),
             np.percentile(l, 95)))


def report_darkest(tag, im, thresh=26.0):
    """JUDGE-6 §6: 'about a quarter of the frame is a flat near-black slab'
    (H-06) and the near-black tree in H-05. Both are 'shadow equals black'."""
    l = lum(im)
    print("  %-30s near-black (<%d) = %.1f%% of frame" % (tag, thresh,
                                                          100.0 * (l < thresh).mean()))


def report_cyan_vs_oxblood(tag, im):
    """JUDGE-6 §9: 'the most saturated, highest-chroma objects in the entire
    frame are the cyan tether pylons ... they pull the eye harder than the
    fortress does'. Compare peak chroma of cyan-family pixels against
    oxblood-family pixels."""
    p = im.reshape(-1, 3)
    r, g, b = p[:, 0], p[:, 1], p[:, 2]
    mx = np.maximum(np.maximum(r, g), b)
    mn = np.minimum(np.minimum(r, g), b)
    chroma = mx - mn
    # Sky is blue-dominant too and fills a third of an exterior frame, so the
    # cyan test has to be a CHROMA test, not a hue test: the tether crystals are
    # near-white-cyan objects with a large max-min spread, the sky is a low-spread
    # gradient. Without the chroma floor this measure just reports the weather.
    cyan = (b > r * 1.15) & (g > r * 1.10) & (mx > 90) & (chroma > 45)
    ox = (r > g * 1.35) & (r > 60)
    c_n, o_n = int(cyan.sum()), int(ox.sum())
    c_c = float(chroma[cyan].mean()) if c_n > 200 else float("nan")
    o_c = float(chroma[ox].mean()) if o_n > 200 else float("nan")
    print("  %-30s cyan n=%6d chroma=%5.1f | oxblood n=%6d chroma=%5.1f  %s"
          % (tag, c_n, c_c, o_n, o_c,
             "cyan LOUDER than oxblood" if c_c > o_c else "oxblood leads"))


def report_uv_seams(tag, im, y0=100, y1=700):
    """JUDGE-6 §3: 'three UV scales meeting at two hard vertical seams'. A UV
    seam is a column where the horizontal texture frequency changes abruptly.
    Measured as the per-column mean absolute horizontal gradient, then the
    biggest step in that profile -- a material at one scale everywhere gives a
    flat profile, three scales give two cliffs."""
    l = lum(im)[y0:y1]
    gx = np.abs(np.diff(l, axis=1)).mean(axis=0)
    # Smooth over 9 columns so single-pixel geometry edges do not dominate.
    k = np.ones(9) / 9.0
    prof = np.convolve(gx, k, mode="same")
    # Step between the mean of the 40 columns either side of each candidate.
    w = 40
    steps = []
    for x in range(w, len(prof) - w, 4):
        steps.append(abs(prof[x:x + w].mean() - prof[x - w:x].mean()))
    steps = np.array(steps) if steps else np.array([0.0])
    print("  %-30s texture-frequency profile: mean=%.2f, largest scale step=%.2f"
          % (tag, prof.mean(), steps.max()))


def run(label, d):
    print("\n=== %s  (%s) ===" % (label, d))

    im = load(d, "H-02b-sigil-gate-raised")
    if im is not None:
        print(" D1 silhouette contrast, H-02b-sigil-gate-raised:")
        sep = report_separation("luminance", im)
        print(" D2 mid-distance content, H-02b:")
        report_midband_content("mid band y380-560", im)
        report_frame_structure("value structure", im)
        report_cyan_vs_oxblood("colour hierarchy", im)
    else:
        sep = None

    im = load(d, "H-01-approach-400")
    if im is not None:
        print(" D1 at 400m, H-01-approach-400:")
        report_frame_structure("value structure", im)
        report_midband_content("mid band y380-560", im)

    im = load(d, "H-05-east-flank")
    if im is not None:
        print(" D5 near-black tree, H-05-east-flank:")
        report_darkest("near-black", im)
        report_frame_structure("value structure", im)

    im = load(d, "H-06-west-keep")
    if im is not None:
        print(" D5 near-black keep face, H-06-west-keep:")
        report_darkest("near-black", im)

    im = load(d, "H-08-wall-close")
    if im is not None:
        print(" D3 stone UV scale, H-08-wall-close:")
        report_uv_seams("seam profile", im)
        report_frame_structure("value structure", im)

    im = load(d, "H-04-gate-mouth")
    if im is not None:
        print(" D3 stone UV scale, H-04-gate-mouth:")
        report_uv_seams("seam profile", im)

    im = load(d, "H-07-courtyard")
    if im is not None:
        print(" D9 colour hierarchy, H-07-courtyard:")
        report_cyan_vs_oxblood("colour hierarchy", im)
        report_frame_structure("value structure", im)

    return sep


def main():
    after = sys.argv[1]
    before = sys.argv[2] if len(sys.argv) > 2 else BEFORE_DEFAULT
    b = run("BEFORE", before) if os.path.isdir(before) else None
    a = run("AFTER", after)
    if a is not None and b is not None:
        print("\n=== HEADLINE ===")
        print("  fortress-vs-hill separation: %+.1f -> %+.1f  (%+.1f)"
              % (b, a, a - b))


if __name__ == "__main__":
    main()
