"""
Remove `emissiveFactor` / `emissiveTexture` from the six production humanoid
`.glb` rigs, in place.

WHAT THIS FIXES, AND WHY IT WAS NEVER FOUND BY TUNING

Four independent blind critics across three separate visual sweeps reported
the same defect in nearly the same words: the player character "renders at
near-daylight brightness against pitch black", is "pasted onto black paper",
is "lit by a different rig than the world", "reads as composited in". Every
attempt to fix it was a LIGHTING change -- night ambient floors, exposure,
moon energy, colour grading -- because everyone reasonably assumed a lighting
symptom had a lighting cause. None of them worked, and none of them could
have.

Every one of the six rigs ships with:

    emissiveFactor = [1, 1, 1]
    emissiveTexture -> the same image as baseColorTexture

Measured on trainer_lod0.glb: the emissive and base-colour texture entries are
different `textures` indices that resolve to the SAME `images` source --
2048x2048, mean 0.2891, max 0.796, with 99.5% of texels above 0.05. That is a
full diffuse map, not a small glow mask.

Emission is added AFTER the lighting term. No ambient value, no exposure, no
time-of-day preset and no post adjustment can dim it. So the character emits
its own diffuse texture at full strength no matter how dark the world is --
which is exactly, and completely, the reported defect.

The signature says pipeline artefact rather than art decision: all six rigs
carry it, including rigs authored at different times from different sources.
Many exporters write emissiveFactor [1,1,1] whenever an emissive texture slot
is populated.

WHY THE SOURCE ASSET AND NOT A RUNTIME OVERRIDE

`scripts/player/trainer_model.gd` and `scripts/characters/npc_ranks.gd` both
instantiate the imported scene and neither constructs materials, so there is no
single existing choke point to patch. Six rigs reachable from several spawn
paths is precisely the shape where a runtime fix silently misses one -- the
failure class `ralph/conventions.md` already records twice ("a value written to
config, read back from config, and never reaching the shader"). Fixing the
asset fixes every path at once and is verifiable with tools/_char_probe.gd.

This also matches what this project already does for exactly this class of
problem: `desaturate_soil_texture.py`, `brighten_rock_texture.py` and
`contrast_rock_texture.py` all fix source pixels in place rather than fighting
them through a multiply, for the same reason.

IDEMPOTENT. Running twice is a no-op; the script reports what it changed and
exits non-zero only if it cannot parse a file.

    python3 tools/art_pipeline/strip_character_emissive.py [--dry-run]

Re-run `godot --headless --path . --import` afterwards: the import cache holds
the OLD material, and a capture run reads the imported form, not the .glb
(ralph/conventions.md, "Art pipeline traps").
"""

import json
import struct
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
CHARACTER_DIR = REPO / "assets" / "characters"

GLB_MAGIC = 0x46546C67  # 'glTF'
CHUNK_JSON = 0x4E4F534A  # 'JSON'
CHUNK_BIN = 0x004E4942  # 'BIN\0'


def read_glb(path):
    """Return (json_dict, bin_bytes). Raises ValueError on anything unexpected."""
    raw = path.read_bytes()
    if len(raw) < 12:
        raise ValueError("shorter than a GLB header")
    magic, version, total = struct.unpack_from("<III", raw, 0)
    if magic != GLB_MAGIC:
        raise ValueError("not a GLB (bad magic)")
    if version != 2:
        raise ValueError("GLB version %d, expected 2" % version)
    if total != len(raw):
        # Trust the file on disk over a stale header, but say so.
        print("    note: header length %d != file length %d" % (total, len(raw)))

    offset = 12
    js = None
    binary = b""
    while offset + 8 <= len(raw):
        length, kind = struct.unpack_from("<II", raw, offset)
        offset += 8
        payload = raw[offset:offset + length]
        if kind == CHUNK_JSON:
            js = json.loads(payload.decode("utf-8"))
        elif kind == CHUNK_BIN:
            binary = payload
        offset += length
    if js is None:
        raise ValueError("no JSON chunk")
    return js, binary


def write_glb(path, js, binary):
    """Re-emit a two-chunk GLB. Both chunks are padded to 4 bytes as the spec
    requires -- JSON with spaces, BIN with zeros. Getting this wrong produces a
    file Godot imports as an empty scene rather than erroring, so it is done
    explicitly rather than assumed."""
    js_bytes = json.dumps(js, separators=(",", ":")).encode("utf-8")
    js_pad = (4 - (len(js_bytes) % 4)) % 4
    js_bytes += b" " * js_pad

    bin_pad = (4 - (len(binary) % 4)) % 4
    bin_bytes = binary + b"\x00" * bin_pad

    total = 12 + 8 + len(js_bytes)
    if bin_bytes:
        total += 8 + len(bin_bytes)

    out = bytearray()
    out += struct.pack("<III", GLB_MAGIC, 2, total)
    out += struct.pack("<II", len(js_bytes), CHUNK_JSON)
    out += js_bytes
    if bin_bytes:
        out += struct.pack("<II", len(bin_bytes), CHUNK_BIN)
        out += bin_bytes
    path.write_bytes(bytes(out))


def strip(js):
    """Drop emissive keys from every material. Returns a list of descriptions of
    what was removed, empty if the file was already clean."""
    removed = []
    for index, material in enumerate(js.get("materials", [])):
        name = material.get("name", "material_%d" % index)
        factor = material.get("emissiveFactor")
        has_texture = "emissiveTexture" in material
        # A genuinely black emissiveFactor is already a no-op; leave it rather
        # than churn the file, so this stays idempotent and reviewable.
        lit = factor is not None and any(float(v) > 0.001 for v in factor)
        if not lit and not has_texture:
            continue
        bits = []
        if factor is not None:
            material.pop("emissiveFactor", None)
            bits.append("emissiveFactor=%s" % factor)
        if has_texture:
            material.pop("emissiveTexture", None)
            bits.append("emissiveTexture")
        # KHR_materials_emissive_strength multiplies emission; with emission
        # gone it is dead weight and would confuse the next reader.
        ext = material.get("extensions") or {}
        if "KHR_materials_emissive_strength" in ext:
            ext.pop("KHR_materials_emissive_strength")
            bits.append("KHR_materials_emissive_strength")
            if not ext:
                material.pop("extensions", None)
        removed.append("%s: %s" % (name, ", ".join(bits)))
    return removed


def main():
    dry_run = "--dry-run" in sys.argv
    rigs = sorted(CHARACTER_DIR.glob("*/*_lod0.glb"))
    if not rigs:
        print("no *_lod0.glb under %s" % CHARACTER_DIR)
        return 1

    touched = 0
    for path in rigs:
        rel = path.relative_to(REPO)
        try:
            js, binary = read_glb(path)
        except ValueError as exc:
            print("FAIL %s: %s" % (rel, exc))
            return 1
        removed = strip(js)
        if not removed:
            print("ok   %s (already clean)" % rel)
            continue
        touched += 1
        print("%s %s" % ("would" if dry_run else "strip", rel))
        for line in removed:
            print("       %s" % line)
        if not dry_run:
            write_glb(path, js, binary)

    print()
    print("%d of %d rig(s) %s" % (touched, len(rigs),
                                  "would change" if dry_run else "changed"))
    if touched and not dry_run:
        print("Now run: godot --headless --path . --import")
        print("Then verify: godot --headless --path . --script tools/_char_probe.gd")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
