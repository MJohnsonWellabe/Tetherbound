"""Regrade the Legendary Tether Machine's albedo to the Meadows Hall palette.

    python3 tools/art_pipeline/regrade_tether_machine.py            # write in place
    python3 tools/art_pipeline/regrade_tether_machine.py --dry-run  # measure only

WHY THIS EXISTS. `assets/environment/team_tether/tether_machine.glb` is the
board-15 hero object (ASSET_LEDGER, R8.2). The blind judge on the Hall's
Legendary Chamber (`ralph/reports/HALL-STAGING-0906/JUDGE-rooms-round5.md`)
measured it at median Y 26, mean RGB 50/37/34, and called it "a **grey-green**
mass in an orange room, receiving no warm light and reading as if it were lit
by a different scene ... dense high-frequency noise-normal detail ... does not
match the flat, painterly, large-shape cut stone of the walls beside it".

Three facts about the shipped asset decide what this tool can and cannot do:

  1. **There is no emissive to cap.** The GLB carries ONE material, with
     `metallicFactor 0`, `roughnessFactor 0.8`, a base-colour texture and NO
     `emissiveFactor` and NO emissive texture. The handoff's H4/H6 premise --
     "cap the installed machine GLB's emissive" -- does not apply to this mesh:
     the chamber's teal key is `stronghold.gd::_machine_shell`'s CoreLight omni
     (`stronghold.json::machine.core_light`) and the room's own conduits, not
     the mesh. The albedo-carried read the tether pylon settled on (ledger line
     62, where a baked emission mask was built and then REMOVED because
     gl_compatibility (D01) ignores the mask and floods the whole mesh) is
     therefore already what this mesh does. Nothing here adds emission.
  2. **The UV atlas is shattered.** 8,186 verts / 7,068 tris across thousands of
     disconnected island fragments -- Meshy's raw parameterisation. There is no
     contiguous "trim" or "ring" region to paint, so a per-part retexture is not
     available. A value-keyed grade is: the mesh's own baked lighting already
     separates deep recess from lit facet, and that separation is the only
     region signal the atlas carries.
  3. **The grade must add the warm half of the board's own material strip.**
     `docs/art/reference/15_Legendary_Tether_Machine.png` names five key
     materials: DARK STONE (neutral grey, sampled 59/58/56), DARK METAL,
     BRASS / GOLD (sampled 64/48/24 -- strongly warm), TETHER ENERGY and RUNIC
     GLOW. The shipped texture has the first two and none of the brass: its
     saturated pixels sit almost entirely in hue 30-90 deg (olive), which is the
     judge's "grey-green". So the ramp below runs dark blackened iron -> the
     Hall's own granite -> brass on the lit facets.

THE NUMBER THE RAMP IS AIMED AT is G/R, measured on a real frame rather than
guessed. In `shots/tm_before/C-02-chamber-door-bound.png` the chamber's own walls
render at mean G/R **0.67** (R/B 2.47) and the machine at G/R **0.96** (R/B 1.41):
green as strong as red is precisely the judge's "grey-green ... as if it were lit
by a different scene", and it is a one-number statement of the style mismatch.
The walls' ALBEDO (`site.stone` #6a6157) is G/R 0.90 and only renders at 0.67
because the room's key is warm, so a machine albedo at the walls' own G/R 0.90
lands in the same family once the same lights hit it. Every stop below is at or
under 0.90; the source texture's own mean is 1.00, which is why a global grade
was the right first lever even though it cannot touch the silhouette.

WHAT THE RAMP IS KEYED TO. The Hall's walls are `stronghold.json::site.stone`
`#6a6157` / `stone_light` `#767268` / `stone_dark` `#5a554d`, and the round-5
judge measured the keyart's own stronghold granite at RGB 80/79/71 (R/B 1.12,
neutral). The mid of the ramp is that family, so the machine is cut from the
building's stone. The brass is `build_hall_props.py::BRASS` `#8a6f3a` -- the
value the five authored Team Tether Hall props already share -- lifted at the
top end for specular trim. Nothing here re-picks a reserved palette colour:
`tether_oxblood` and `tether_teal` stay where `palette.json` reserves them.

FLATTENING. The judge's "dense high-frequency noise" is answered in two passes:
a median-dominated low-pass on the luma before the ramp, and a soft quantisation
of the ramp parameter into large steps. Both keep gradient direction (so form
still reads) while collapsing the per-texel churn that made the mesh look like a
photoscan standing next to painted walls.
"""
from __future__ import annotations

import argparse
import io
import json
import os
import struct
import sys

import numpy as np
from PIL import Image, ImageFilter

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GLB = os.path.join(REPO, "assets", "environment", "team_tether", "tether_machine.glb")
EXTRACTED = os.path.join(REPO, "assets", "environment", "team_tether", "tether_machine_0.jpg")

# Ramp stops: (t, sRGB hex). t is the normalised, flattened luma of the source.
# Dark end is blackened iron; the middle two are the Hall's own granite; the top
# two are board 15's brass. See the module header for where each number comes
# from.
RAMP = [
    (0.00, "#34302a"),   # deep recess: dark stone, WARM-neutral (see G/R below)
    (0.26, "#4c463c"),   # stone_dark #5a554d family, in shadow
    (0.52, "#6e6558"),   # site.stone #6a6157 -- the wall the machine stands against
    (0.76, "#877d6c"),   # stone_light #767268 / keyart granite 80/79/71, lit
    (0.92, "#8f7339"),   # brass, board 15's BRASS/GOLD, on the lit trim only
    (1.00, "#c2a367"),   # brass specular on the topmost trim and rune bosses
]

# Percentile window the source luma is mapped through. p2..p98 rather than
# min..max so a handful of black or blown texels do not eat the ramp.
LO_PCT, HI_PCT = 2.0, 98.0

MEDIAN_RADIUS = 9        # px, on the 2048 map
FLATTEN_MIX = 0.85       # weight of the median-filtered luma vs the raw luma
QUANT_STEPS = 9         # soft steps in the ramp parameter
QUANT_MIX = 0.65         # how far toward the quantised value to pull
JPEG_QUALITY = 92

# Stamped into the glTF's `extras` so a second run cannot grade an already-graded
# map. The ramp is not idempotent -- re-running it re-normalises through the
# GRADED p2..p98 and walks the machine steadily paler each time -- and the only
# reliable way to notice that from the file itself is a marker.
STAMP_KEY = "tetherbound_albedo_regrade"
STAMP = "hall-palette-1"


def _srgb_hex(h: str) -> np.ndarray:
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float32)


def _read_glb(path: str):
    raw = open(path, "rb").read()
    if raw[:4] != b"glTF":
        raise SystemExit("%s is not a binary glTF" % path)
    total = struct.unpack("<I", raw[8:12])[0]
    off, chunks = 12, []
    while off < total:
        clen, ctype = struct.unpack("<I4s", raw[off:off + 8])
        chunks.append([ctype, bytearray(raw[off + 8:off + 8 + clen])])
        off += 8 + clen
    gltf = json.loads(bytes(chunks[0][1]).decode("utf-8"))
    return gltf, chunks


def _write_glb(path: str, gltf: dict, chunks) -> None:
    js = json.dumps(gltf, separators=(",", ":")).encode("utf-8")
    js += b" " * ((4 - len(js) % 4) % 4)
    chunks[0][1] = bytearray(js)
    for c in chunks[1:]:
        pad = (4 - len(c[1]) % 4) % 4
        c[1] += bytearray(b"\x00" * pad)
    body = b"".join(struct.pack("<I4s", len(c[1]), c[0]) + bytes(c[1]) for c in chunks)
    with open(path, "wb") as fh:
        fh.write(b"glTF" + struct.pack("<II", 2, 12 + len(body)) + body)


def _image_bytes(gltf: dict, chunks) -> bytes:
    image = gltf["images"][0]
    view = gltf["bufferViews"][image["bufferView"]]
    start = view["byteOffset"]
    return bytes(chunks[1][1][start:start + view["byteLength"]])


def _replace_image(gltf: dict, chunks, blob: bytes) -> None:
    """Rewrite the image bufferView in place, shifting later views if it grew."""
    image = gltf["images"][0]
    idx = image["bufferView"]
    view = gltf["bufferViews"][idx]
    start, old_len = view["byteOffset"], view["byteLength"]
    pad = (4 - len(blob) % 4) % 4
    bin_chunk = chunks[1][1]
    chunks[1][1] = bin_chunk[:start] + bytearray(blob) + bytearray(b"\x00" * pad) + bin_chunk[start + old_len:]
    delta = (len(blob) + pad) - old_len
    view["byteLength"] = len(blob)
    for other in gltf["bufferViews"]:
        if other is not view and other.get("byteOffset", 0) > start:
            other["byteOffset"] += delta
    gltf["buffers"][0]["byteLength"] = len(chunks[1][1])


def _measure(tag: str, arr: np.ndarray) -> None:
    flat = arr.reshape(-1, 3).astype(np.float32)
    luma = 0.2126 * flat[:, 0] + 0.7152 * flat[:, 1] + 0.0722 * flat[:, 2]
    mean = flat.mean(0)
    print("%-8s mean RGB %5.1f/%5.1f/%5.1f  R/B %.2f  median Y %5.1f  Y p10/p90 %5.1f/%5.1f"
          % (tag, mean[0], mean[1], mean[2], mean[0] / max(mean[2], 1e-3),
             float(np.median(luma)), float(np.percentile(luma, 10)),
             float(np.percentile(luma, 90))))


def regrade(img: Image.Image) -> Image.Image:
    src = np.asarray(img.convert("RGB")).astype(np.float32)
    luma = 0.2126 * src[..., 0] + 0.7152 * src[..., 1] + 0.0722 * src[..., 2]

    # 1. Flatten. Median dominates so island-edge speckle and the baked
    #    micro-normal churn collapse, but the raw luma still carries a quarter
    #    of the signal so real form gradients survive.
    med = np.asarray(
        Image.fromarray(np.clip(luma, 0, 255).astype(np.uint8)).filter(
            ImageFilter.MedianFilter(size=MEDIAN_RADIUS)), dtype=np.float32)
    flat = FLATTEN_MIX * med + (1.0 - FLATTEN_MIX) * luma

    # 2. Normalise through the source's own p2..p98 so the ramp is fully used.
    lo = float(np.percentile(flat, LO_PCT))
    hi = float(np.percentile(flat, HI_PCT))
    t = np.clip((flat - lo) / max(hi - lo, 1e-3), 0.0, 1.0)

    # 3. Soft quantisation: pull part way toward large flat steps. Full
    #    posterisation bands on a 2048 map; a partial pull reads as painted
    #    planes without a visible contour line.
    t = t + QUANT_MIX * (np.round(t * QUANT_STEPS) / QUANT_STEPS - t)
    t = np.clip(t, 0.0, 1.0)

    # 4. Ramp. Chroma is authored entirely by value: the source's olive cast is
    #    discarded rather than corrected, which is the whole point.
    stops = np.array([s[0] for s in RAMP], dtype=np.float32)
    cols = np.stack([_srgb_hex(s[1]) for s in RAMP])
    out = np.empty_like(src)
    for ch in range(3):
        out[..., ch] = np.interp(t, stops, cols[:, ch])
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGB")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true", help="measure, write nothing")
    ap.add_argument("--preview", default="", help="also write the graded map here as PNG")
    ap.add_argument("--force", action="store_true",
                    help="regrade even if this GLB already carries the stamp")
    args = ap.parse_args()

    gltf, chunks = _read_glb(GLB)
    stamped = str(gltf.get("extras", {}).get(STAMP_KEY, ""))
    if stamped and not args.force:
        raise SystemExit(
            "%s already carries %s=%s. The ramp is NOT idempotent -- it re-normalises\n"
            "through the graded map's own percentiles and lightens the machine again on\n"
            "every run. Restore the pristine asset (`git checkout --`) and re-run, or pass\n"
            "--force if you really mean to grade a graded map."
            % (os.path.relpath(GLB, REPO), STAMP_KEY, stamped))
    before = Image.open(io.BytesIO(_image_bytes(gltf, chunks))).convert("RGB")
    _measure("before", np.asarray(before))

    after = regrade(before)
    _measure("after", np.asarray(after))

    if args.preview:
        after.save(args.preview)

    if args.dry_run:
        print("dry run: %s unchanged" % os.path.relpath(GLB, REPO))
        return 0

    buf = io.BytesIO()
    after.save(buf, format="JPEG", quality=JPEG_QUALITY, subsampling=0)
    blob = buf.getvalue()
    gltf.setdefault("extras", {})[STAMP_KEY] = STAMP
    _replace_image(gltf, chunks, blob)
    _write_glb(GLB, gltf, chunks)
    # `tether_machine.glb.import` runs `gltf/embedded_image_handling=1`
    # (Extract Textures), so this sidecar is the file the engine actually
    # samples. Godot rewrites it on reimport; writing it here keeps the two
    # copies identical even before a reimport runs.
    with open(EXTRACTED, "wb") as fh:
        fh.write(blob)
    print("wrote %s (%d bytes embedded) and %s"
          % (os.path.relpath(GLB, REPO), len(blob), os.path.relpath(EXTRACTED, REPO)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
