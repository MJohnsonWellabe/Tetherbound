"""
Generate tileable stylised ground textures (albedo + normal) from a numeric
specification, instead of sourcing photographic scans.

WHY THIS EXISTS

The Meadows ground shipped on photographic PBR scans (ambientCG Grass008,
Ground003, Ground030, Rock030). Two independent lines of evidence say that was
the wrong KIND of material for this project, not merely the wrong settings:

1. A blind critic, judging rendered frames against the project's own key art and
   the Palworld reference set, reported the ground as "a stylised world standing
   on a muddy photograph" -- realistic centimetre speckle under flat-shaded toon
   trees and characters -- and put the ground's value and saturation among the
   top three things separating the build from its references. It measured the
   frames at V 0.14-0.33 / S 0.78-0.94 against the references' V 0.40-0.78 /
   S 0.36-0.50.

2. The arithmetic says that gap cannot be closed by tinting. Godot's
   `albedo_color` MULTIPLIES, so every channel of a tint is capped at 1.0 and a
   multiply can only ever LOWER a channel. Grass008's mean blue is 0.168, so
   every reference palette target -- all of which need more blue than that to
   reach their saturation -- requires a tint above 1.0 on at least one channel
   and is therefore unreachable from that photo at ANY settings. Not a tuning
   failure; a property of the source.

Five separate rounds of work in this repo went into fighting these photos
through tints and in-place pixel edits (`desaturate_soil_texture.py`,
`brighten_rock_texture.py`, `contrast_rock_texture.py`, plus the lavender grass
tint R9.4 had to invent to desaturate a green by multiplying). Generating the
surface makes the palette an input rather than something to be recovered.

WHAT THIS PRODUCES

Per surface: a 1024x1024 albedo and matching normal map, both seamlessly
tileable. Tileability is exact rather than approximate: all noise is band-limited
and synthesised in the frequency domain, which is periodic on the sampling grid
by construction, and the cellular and spot layers wrap explicitly. Opposite
edges match to the bit -- no mirroring, no blend seams, no offset-and-heal.

THE DETAIL BUDGET IS THE ART STYLE

The specification's amplitudes are far below photographic. Measured high-pass
luminance on the reference grounds is 2.0-3.5% at pixel scale rising to only
5.5-11% at ~8px, so the style carries almost no texel-scale noise and puts its
largest amplitudes at 1-4 METRES. That is an inverted detail pyramid relative to
a scan. The ground plane here is a calm colour field with soft metre-scale
patching; crispness is supposed to come from the scattered prop layer, and a
ground texture busy enough to compete with the props is the recorded failure
mode this whole rewrite exists to avoid.

So: do not evaluate a surface on a bare plane and add contrast until it looks
finished on its own. `--stats` prints the measured high-pass std at three scales
so the tiles can be validated numerically against the spec instead.

USAGE

    python3 tools/art_pipeline/make_stylised_ground.py             # write all
    python3 tools/art_pipeline/make_stylised_ground.py --list      # show spec
    python3 tools/art_pipeline/make_stylised_ground.py --stats     # validate
    python3 tools/art_pipeline/make_stylised_ground.py --only meadow_grass

Deterministic: the same spec always writes the same bytes, so a re-run is a
no-op in git and a spec change is a reviewable diff.

Re-run `godot --headless --path . --import` afterwards -- a capture reads the
IMPORTED texture, not the file on disk (docs/AGENT_WORKFLOW.md, "Art pipeline
traps").
"""

import argparse
import colorsys
import sys
from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parents[2]
OUT_DIR = REPO / "assets" / "environment" / "terrain" / "stylised"
SIZE = 1024


# ---------------------------------------------------------------------------
# Noise primitives. Everything here is periodic on the tile by construction.
# ---------------------------------------------------------------------------

def periodic_noise(rng, low_cycles, high_cycles, size=SIZE):
    """Band-limited noise that tiles exactly.

    White noise filtered in the frequency domain and transformed back. Every
    surviving component completes a whole number of cycles across the tile, so
    the result is periodic to machine precision. `low_cycles`/`high_cycles` are
    the pass band in cycles per tile.
    """
    spectrum = np.fft.fft2(rng.normal(size=(size, size)))
    f = np.fft.fftfreq(size) * size
    radius = np.sqrt(f[:, None] ** 2 + f[None, :] ** 2)

    centre = (low_cycles + high_cycles) * 0.5
    width = max(1e-6, (high_cycles - low_cycles) * 0.5)
    # Smooth shoulders, not a brick wall: a hard cutoff in frequency rings in
    # space, which shows as faint concentric halos around every blob -- lost in
    # a photograph, obvious on a flat stylised colour.
    band = np.exp(-((radius - centre) ** 2) / (2.0 * width ** 2))
    band[0, 0] = 0.0  # drop DC; these layers are deviations, not levels

    out = np.real(np.fft.ifft2(spectrum * band))
    # Normalised to unit STANDARD DEVIATION, not to peak. The spec's amplitudes
    # are the amount of variation a viewer perceives across the surface, which
    # is a std; dividing by peak instead makes every band land at roughly a
    # third of its requested amplitude, because a band-limited Gaussian field
    # peaks around 3-4 sigma. That error is invisible per-band and compounds
    # across octaves into a texture an order of magnitude flatter than asked
    # for -- which is exactly what the first generated set measured as.
    sd = out.std()
    return out / sd if sd > 1e-9 else out


def octave_field(rng, octaves, size=SIZE):
    """Sum of (low_cycles, high_cycles, amplitude) bands, amplitudes as given.

    NOT normalised afterwards: the amplitudes in the spec are absolute fractions
    of base value, and renormalising here would silently discard the whole
    detail budget the spec is built around.
    """
    total = np.zeros((size, size), dtype=np.float64)
    for low, high, amp in octaves:
        total += periodic_noise(rng, low, high, size) * amp
    return total


def cellular(rng, cells_across, size=SIZE):
    """Periodic jittered-grid cellular noise -> (cell_value, edge_distance).

    One jittered point per grid cell means the nearest-point search only has to
    look at the 3x3 neighbourhood, which keeps this a handful of full-image
    array ops instead of a search over every point. The grid wraps, so the
    result tiles.

    Returns a per-pixel random value for the owning cell (flat facets) and a
    normalised distance to the nearest cell boundary (for bevelled edges).
    """
    g = int(max(2, round(cells_across)))
    pts = (np.stack(np.meshgrid(np.arange(g), np.arange(g), indexing="ij"), axis=2)
           + rng.random((g, g, 2))) * (size / g)
    vals = rng.random((g, g))

    ys, xs = np.mgrid[0:size, 0:size].astype(np.float64)
    cell_y = (ys / (size / g)).astype(np.int32)
    cell_x = (xs / (size / g)).astype(np.int32)

    best = np.full((size, size), np.inf)
    second = np.full((size, size), np.inf)
    owner = np.zeros((size, size), dtype=np.float64)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            iy = (cell_y + dy) % g
            ix = (cell_x + dx) % g
            py = pts[iy, ix, 0] + dy * 0.0
            px = pts[iy, ix, 1]
            # Wrap the offset into [-size/2, size/2] so distance is toroidal.
            dyy = (ys - (pts[iy, ix, 0] + (cell_y + dy - cell_y) * 0.0))
            dyy = ((ys - py + size * 0.5) % size) - size * 0.5
            dxx = ((xs - px + size * 0.5) % size) - size * 0.5
            d = dyy * dyy + dxx * dxx
            closer = d < best
            second = np.where(closer, best, np.minimum(second, d))
            owner = np.where(closer, vals[iy, ix], owner)
            best = np.where(closer, d, best)
    edge = np.sqrt(second) - np.sqrt(best)
    edge = edge / max(1e-6, edge.max())
    return owner - 0.5, edge


def spots(rng, count, radius_px_range, size=SIZE):
    """`count` soft round blobs at random positions, wrapping at the edges.

    Used for the discrete features the spec calls out by number rather than by
    frequency -- embedded stones in the path, moss patches on the forest floor.
    Returns a 0..1 coverage mask.
    """
    mask = np.zeros((size, size), dtype=np.float64)
    ys, xs = np.mgrid[0:size, 0:size].astype(np.float64)
    for _ in range(int(count)):
        cy, cx = rng.random(2) * size
        r = rng.uniform(*radius_px_range)
        dy = ((ys - cy + size * 0.5) % size) - size * 0.5
        dx = ((xs - cx + size * 0.5) % size) - size * 0.5
        d = np.sqrt(dy * dy + dx * dx) / r
        mask = np.maximum(mask, np.clip(1.0 - d * d, 0.0, 1.0))
    return mask


# ---------------------------------------------------------------------------
# Composition
# ---------------------------------------------------------------------------

def hsv_to_rgb_arrays(h, s, v):
    """Vectorised HSV->RGB. colorsys is scalar-only and a million calls is
    minutes; this is the same conversion done over whole arrays."""
    hp = (h / 60.0) % 6.0
    c = v * s
    x = c * (1.0 - np.abs((hp % 2.0) - 1.0))
    m = v - c
    z = np.zeros_like(v)
    i = hp.astype(np.int32)
    sel = [i == 0, i == 1, i == 2, i == 3, i == 4, i == 5]
    r = np.select(sel, [c, x, z, z, x, c])
    g = np.select(sel, [x, c, c, x, z, z])
    b = np.select(sel, [z, z, x, c, c, x])
    return np.clip(np.stack([r + m, g + m, b + m], axis=2), 0.0, 1.0)


def metres_to_cycles(tile_m, feature_m):
    return tile_m / max(1e-6, feature_m)


def build(spec, rng):
    """Compose one surface. Returns (albedo rgb, height field for normals)."""
    tile_m = spec["tile_metres"]
    base_h, base_s, base_v = spec["hue"], spec["sat"], spec["val"]

    # Octaves given in metres; converted here so the spec stays readable in the
    # units the art direction was written in.
    octaves = []
    for lo_m, hi_m, amp in spec["octaves"]:
        octaves.append((metres_to_cycles(tile_m, hi_m),
                        metres_to_cycles(tile_m, lo_m), amp))
    field = octave_field(rng, octaves)

    # The COARSEST octave alone drives hue and saturation drift. Letting the
    # fine layers move hue produces per-texel colour confetti, which is exactly
    # the "digital confetti" read this project has already been criticised for
    # on its foliage.
    lo_m, hi_m, _ = spec["octaves"][0]
    coarse = periodic_noise(rng, metres_to_cycles(tile_m, hi_m),
                            metres_to_cycles(tile_m, lo_m))

    h = base_h + coarse * spec.get("hue_drift_deg", 0.0)
    s = np.clip(base_s + coarse * spec.get("sat_drift", 0.0), 0.0, 1.0)
    v = np.clip(base_v * (1.0 + field), 0.0, 1.0)

    height = field.copy()

    # Angular fractured cells (rock only).
    if spec.get("cells"):
        cell_m, cell_amp, warm_deg, warm_frac = spec["cells"]
        owner, edge = cellular(rng, metres_to_cycles(tile_m, cell_m))
        v = np.clip(v * (1.0 + owner * 2.0 * cell_amp), 0.0, 1.0)
        s = np.clip(s + owner * 2.0 * spec.get("cell_sat_amp", 0.0), 0.0, 1.0)
        h = h + np.where(owner > (0.5 - warm_frac), warm_deg, 0.0)
        # Bevelled, not knife-sharp: the spec asks for edges you could run a
        # hand over, so the relief follows a smoothed edge distance.
        height = height + (np.clip(edge * 3.0, 0.0, 1.0) - 0.5) * spec.get("cell_relief", 0.0)

    # Discrete embedded features, given by count in the spec.
    for feat in spec.get("spots", []):
        count, r_lo_m, r_hi_m, dv, dh, ds = feat
        px = SIZE / tile_m
        mask = spots(rng, count, (r_lo_m * px * 0.5, r_hi_m * px * 0.5))
        v = np.clip(v + mask * dv, 0.0, 1.0)
        h = h + mask * dh
        s = np.clip(s + mask * ds, 0.0, 1.0)
        height = height + mask * spec.get("spot_relief", 0.0)

    return hsv_to_rgb_arrays(h, s, v), height


def build_normal(height, strength):
    """Gentle normal from the same field the albedo uses, so relief and colour
    agree instead of contradicting each other.

    Deliberately shallow. This project has already measured what a strong
    photographic normal does here: at a 52-degree sun it turns most texels away
    from the light and the near ground crushes to black
    (terrain_playground.json's own `_comment_normal_depth`). A stylised surface
    takes its shape from the terrain, not from the tile.
    """
    gy = (np.roll(height, -1, axis=0) - np.roll(height, 1, axis=0)) * 0.5
    gx = (np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)) * 0.5
    nx, ny, nz = -gx * strength, -gy * strength, np.ones_like(height)
    n = np.sqrt(nx * nx + ny * ny + nz * nz)
    # OpenGL convention (+Y up) to match the NormalGL suffix the terrain
    # textures already use and which Godot is configured for.
    return np.stack([nx / n * 0.5 + 0.5, ny / n * 0.5 + 0.5, nz / n * 0.5 + 0.5], axis=2)


def highpass_std(rgb, sigma_px):
    """High-pass luminance std at a given scale, as a percentage.

    This is the spec's own acceptance test for the detail budget, so it is
    measured rather than eyeballed. Blur is a periodic box chain, which matches
    the tile's wraparound.

    NOTE the scales this is called at. The spec's reference numbers were
    measured on 588px-wide screenshots where one pixel is roughly 1-3cm of
    world. A 1024px tile covering 5m is about 0.5cm per pixel, so comparing at
    equal PIXEL radius would be comparing detail four to six times finer than
    the reference and would always report a texture that looks far too flat.
    The caller converts the reference's pixel scales into world centimetres and
    back into this tile's pixels, so the two are measured at the same real size.
    """
    lum = rgb.mean(axis=2)
    blur = lum.copy()
    k = max(1, int(sigma_px))
    for _ in range(3):
        blur = (np.roll(blur, k, 0) + np.roll(blur, -k, 0)
                + np.roll(blur, k, 1) + np.roll(blur, -k, 1) + blur) / 5.0
    return float((lum - blur).std() * 100.0)


def write_surface(name, spec, out_dir, show_stats=False):
    rng = np.random.default_rng(spec["seed"])
    albedo, height = build(spec, rng)
    normal = build_normal(height, spec.get("normal_strength", 5.0))

    out_dir.mkdir(parents=True, exist_ok=True)
    a_path = out_dir / ("%s_Color.png" % name)
    n_path = out_dir / ("%s_NormalGL.png" % name)
    Image.fromarray((albedo * 255.0 + 0.5).astype(np.uint8)).save(a_path)
    Image.fromarray((normal * 255.0 + 0.5).astype(np.uint8)).save(n_path)

    mean = albedo.reshape(-1, 3).mean(axis=0)
    h, s, v = colorsys.rgb_to_hsv(*mean)
    # Seam check stated rather than assumed: a correctly periodic tile differs
    # across the wrap only by the one-pixel gradient there.
    seam = max(float(np.abs(albedo[:, 0] - albedo[:, -1]).mean()),
               float(np.abs(albedo[0, :] - albedo[-1, :]).mean()))
    line = ("  %-14s albedo H%5.1f S%.3f V%.3f   target H%5.1f S%.3f V%.3f   seam %.4f"
            % (name, h * 360.0, s, v, spec["hue"], spec["sat"], spec["val"], seam))
    print(line)
    if show_stats:
        # Reference scales are ~2cm, ~6cm and ~16cm of world; convert to this
        # tile's pixels so like is compared with like.
        # Reported RELATIVE to the surface's own base value, because that is
        # what the spec's per-octave amplitudes are fractions of, and because an
        # absolute figure makes a dark surface look flatter than a light one at
        # identical variation.
        #
        # These are NOT directly comparable to the spec's 2.0-3.5 / 4-8 / 5.5-11
        # reference figures, and chasing those numbers here would be a mistake.
        # Those were measured on reference SCREENSHOTS, whose ground includes 3D
        # grass, scattered props and cast shadows -- and the same spec says
        # about 60% of the underfoot read should come from the prop layer. So
        # the reference figure is mostly props, while this measures a bare
        # albedo tile. Matching it here would mean baking prop-level detail into
        # the surface, which is precisely the failure the spec's own "Mistake 2"
        # warns against. The right place to check those numbers is a rendered
        # frame with props present.
        px_per_cm = SIZE / (spec["tile_metres"] * 100.0)
        s2, s6, s16 = (max(1, int(round(cm * px_per_cm))) for cm in (2, 6, 16))
        base = max(1e-6, spec["val"])
        print("      surface detail, %% of base value:  ~2cm %.1f%%  ~6cm %.1f%%  ~16cm %.1f%%"
              % (highpass_std(albedo, s2) / base, highpass_std(albedo, s6) / base,
                 highpass_std(albedo, s16) / base))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--stats", action="store_true", help="print the detail-budget measurements")
    ap.add_argument("--out", default=str(OUT_DIR))
    args = ap.parse_args()

    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from stylised_ground_spec import SPEC

    if args.list:
        for name, s in SPEC.items():
            print("%-14s H%5.1f S%.3f V%.3f  %.1f m/tile  %s"
                  % (name, s["hue"], s["sat"], s["val"], s["tile_metres"], s.get("note", "")))
        return 0

    out_dir = Path(args.out)
    print("writing stylised ground surfaces to %s" % out_dir)
    for name, s in SPEC.items():
        if args.only and name != args.only:
            continue
        write_surface(name, s, out_dir, args.stats)
    print()
    print("Now run: godot --headless --path . --import")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
