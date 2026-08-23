"""
Generate tileable stylised ground textures (albedo + normal) from a numeric
specification, instead of sourcing photographic scans.

WHY THIS EXISTS

The Meadows ground shipped on photographic PBR scans (ambientCG Grass008,
Ground003, Ground030, Rock030). Two independent lines of evidence say that was
the wrong kind of material for this project, not merely the wrong settings:

1. A blind critic, judging rendered frames against the project's own key art and
   the Palworld reference set, reported the ground as "a stylised world standing
   on a muddy photograph" -- realistic centimetre speckle under flat-shaded
   toon trees and characters -- and put the ground's value and saturation among
   the top three things separating the build from its references. It measured
   the frames at V 0.14-0.33 / S 0.78-0.94 against the references' V 0.40-0.78 /
   S 0.36-0.50.

2. The arithmetic says that gap cannot be closed by tinting. Godot's
   `albedo_color` MULTIPLIES, so every channel of a tint must be <= 1.0, and a
   multiply can only ever lower a channel. Grass008's mean blue is 0.168, so
   every reference palette target -- all of which need more blue than that to
   reach their saturation -- requires a tint above 1.0 on at least one channel
   and is therefore unreachable from that photo at ANY settings. That is not a
   tuning failure; it is a property of the source.

Five separate rounds of work in this repo went into fighting these photos
through tints and pixel edits (`desaturate_soil_texture.py`,
`brighten_rock_texture.py`, `contrast_rock_texture.py`, plus the lavender grass
tint R9.4 had to invent to desaturate a green by multiplying). Generating the
surface instead makes the palette an input rather than something to be
recovered.

WHAT THIS PRODUCES

Per surface: a 1024x1024 albedo and a matching normal map, both seamlessly
tileable. Tileability is exact rather than approximate: all variation is built
from band-limited noise synthesised in the frequency domain, which is periodic
on the sampling grid by construction, so opposite edges match to the bit. No
mirroring, no blend seams, no offset-and-heal.

The generator deliberately produces LESS fine detail than a photograph. A
stylised ground reads through broad colour shapes, not through per-texel grain;
the reference frames' ground holds up at 30% zoom precisely because there is
nothing at texel scale competing with the silhouettes standing on it.

USAGE

    python3 tools/art_pipeline/make_stylised_ground.py            # write all
    python3 tools/art_pipeline/make_stylised_ground.py --list     # show the spec
    python3 tools/art_pipeline/make_stylised_ground.py --only grass

Deterministic: the same SPEC always writes the same bytes, so a re-run is a
no-op in git and a change to the spec is a reviewable diff in the render.

Re-run `godot --headless --path . --import` afterwards -- a capture reads the
IMPORTED texture, not the file on disk (ralph/conventions.md, "Art pipeline
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

# Metres the texture spans is set per-surface in terrain_playground.json via
# uv_scale; the generator only needs to know it to convert a requested feature
# size in METRES into cycles across the tile.
DEFAULT_TILE_METRES = 2.0


def periodic_noise(rng, low_cycles, high_cycles, size=SIZE):
    """Band-limited noise that tiles exactly.

    White noise is filtered in the frequency domain and transformed back. Every
    surviving component completes a whole number of cycles across the tile, so
    the result is periodic to machine precision -- which is what makes the
    output seamless without any edge treatment. `low_cycles`/`high_cycles` are
    the pass band in cycles per tile.
    """
    white = rng.normal(size=(size, size))
    spectrum = np.fft.fft2(white)

    fy = np.fft.fftfreq(size) * size
    fx = np.fft.fftfreq(size) * size
    radius = np.sqrt(fy[:, None] ** 2 + fx[None, :] ** 2)

    # Smooth shoulders rather than a brick wall: a hard cutoff in frequency
    # rings in space, which shows up as faint concentric halos around every
    # blob -- subtle in a photograph, obvious on a flat stylised colour.
    band = np.exp(-((radius - (low_cycles + high_cycles) * 0.5) ** 2)
                  / (2.0 * max(1e-6, (high_cycles - low_cycles) * 0.5) ** 2))
    band[0, 0] = 0.0  # drop DC so the field is zero-mean

    out = np.real(np.fft.ifft2(spectrum * band))
    peak = np.abs(out).max()
    return out / peak if peak > 1e-9 else out


def fbm(rng, octaves, size=SIZE):
    """Sum of periodic bands, each half the size and half the amplitude of the
    last. `octaves` is a list of (low_cycles, high_cycles, amplitude)."""
    total = np.zeros((size, size), dtype=np.float64)
    for low, high, amp in octaves:
        total += periodic_noise(rng, low, high, size) * amp
    peak = np.abs(total).max()
    return total / peak if peak > 1e-9 else total


def hsv_to_rgb_array(h, s, v):
    return np.array(colorsys.hsv_to_rgb(h / 360.0, s, v), dtype=np.float64)


def build_albedo(spec, rng):
    """Compose a surface albedo from its spec.

    Three layers, in descending spatial scale, because that is the order a
    viewer reads them:
      - `blotch`  broad tonal shapes, the thing visible at 5-30m
      - `mottle`  mid-scale break-up so a tile does not read as flat colour
      - `grain`   a whisper of texel noise, kept low on purpose

    Hue is allowed to drift with the blotch field as well as value: real
    grassland changes colour as it changes brightness, and varying value alone
    reads as a lighting artefact painted into the albedo.
    """
    base = hsv_to_rgb_array(spec["hue"], spec["sat"], spec["val"])

    blotch = fbm(rng, spec["blotch_octaves"])
    mottle = fbm(rng, spec["mottle_octaves"])
    grain = periodic_noise(rng, SIZE * 0.20, SIZE * 0.42)

    field = (blotch * spec["blotch_amp"]
             + mottle * spec["mottle_amp"]
             + grain * spec["grain_amp"])

    # Value moves with the field; hue and saturation move with the BLOTCH only,
    # so the fine layers do not produce per-texel hue confetti.
    h = spec["hue"] + blotch * spec.get("hue_drift", 0.0)
    s = np.clip(spec["sat"] + blotch * spec.get("sat_drift", 0.0), 0.0, 1.0)
    v = np.clip(spec["val"] * (1.0 + field), 0.0, 1.0)

    # Vectorised HSV->RGB. colorsys is scalar-only and 1M calls is minutes.
    hp = (h / 60.0) % 6.0
    c = v * s
    x = c * (1.0 - np.abs((hp % 2.0) - 1.0))
    m = v - c
    zeros = np.zeros_like(v)
    idx = hp.astype(np.int32)
    r = np.select([idx == 0, idx == 1, idx == 2, idx == 3, idx == 4, idx == 5],
                  [c, x, zeros, zeros, x, c])
    g = np.select([idx == 0, idx == 1, idx == 2, idx == 3, idx == 4, idx == 5],
                  [x, c, c, x, zeros, zeros])
    b = np.select([idx == 0, idx == 1, idx == 2, idx == 3, idx == 4, idx == 5],
                  [zeros, zeros, x, c, c, x])
    rgb = np.stack([r + m, g + m, b + m], axis=2)
    return np.clip(rgb, 0.0, 1.0), field


def build_normal(field, strength):
    """A gentle normal map derived from the same field the albedo uses, so the
    relief agrees with the colour instead of contradicting it.

    Deliberately shallow. This project has already measured what a strong
    photographic normal does to this ground: at a 52-degree sun it turns most
    texels away from the light and the near field crushes to black
    (terrain_playground.json's own `_comment_normal_depth`). A stylised surface
    wants shape from the terrain, not from the texture.
    """
    # np.gradient with wraparound so the normal map tiles like the albedo.
    gy = (np.roll(field, -1, axis=0) - np.roll(field, 1, axis=0)) * 0.5
    gx = (np.roll(field, -1, axis=1) - np.roll(field, 1, axis=1)) * 0.5
    nx = -gx * strength
    ny = -gy * strength
    nz = np.ones_like(field)
    length = np.sqrt(nx * nx + ny * ny + nz * nz)
    # OpenGL convention (+Y up) to match the NormalGL suffix the existing
    # terrain textures use; Godot is configured for that already.
    return np.stack([nx / length * 0.5 + 0.5,
                     ny / length * 0.5 + 0.5,
                     nz / length * 0.5 + 0.5], axis=2)


def write_surface(name, spec, out_dir):
    rng = np.random.default_rng(spec["seed"])
    albedo, field = build_albedo(spec, rng)
    normal = build_normal(field, spec.get("normal_strength", 6.0))

    out_dir.mkdir(parents=True, exist_ok=True)
    a_path = out_dir / ("%s_Color.png" % name)
    n_path = out_dir / ("%s_NormalGL.png" % name)
    Image.fromarray((albedo * 255.0 + 0.5).astype(np.uint8)).save(a_path)
    Image.fromarray((normal * 255.0 + 0.5).astype(np.uint8)).save(n_path)

    mean = albedo.reshape(-1, 3).mean(axis=0)
    h, s, v = colorsys.rgb_to_hsv(*mean)
    # Seam check, stated rather than assumed: opposite edges of a correctly
    # periodic texture differ only by the one-pixel gradient across the wrap.
    seam_x = float(np.abs(albedo[:, 0] - albedo[:, -1]).mean())
    seam_y = float(np.abs(albedo[0, :] - albedo[-1, :]).mean())
    print("  %-10s mean H%5.1f S%.3f V%.3f   seam x %.4f y %.4f   -> %s"
          % (name, h * 360.0, s, v, seam_x, seam_y, a_path.name))
    return {"albedo": a_path, "normal": n_path, "hsv": (h * 360.0, s, v)}


def load_spec():
    """The surface set. Numbers here are the design input; see the module
    docstring for why they are authored rather than sampled from photographs."""
    from stylised_ground_spec import SPEC  # noqa: F401
    return SPEC


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="", help="generate one surface by name")
    ap.add_argument("--list", action="store_true", help="print the spec and exit")
    ap.add_argument("--out", default=str(OUT_DIR))
    args = ap.parse_args()

    sys.path.insert(0, str(Path(__file__).resolve().parent))
    spec = load_spec()

    if args.list:
        for name, s in spec.items():
            print("%-10s H%5.1f S%.3f V%.3f  %s"
                  % (name, s["hue"], s["sat"], s["val"], s.get("note", "")))
        return 0

    out_dir = Path(args.out)
    print("writing stylised ground surfaces to %s" % out_dir)
    for name, s in spec.items():
        if args.only and name != args.only:
            continue
        write_surface(name, s, out_dir)
    print()
    print("Now run: godot --headless --path . --import")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
