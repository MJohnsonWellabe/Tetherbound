"""staticub r10 (2 Nov 2026): raw Meshy image-to-3D -> rigged, clipped candidate GLB.

Re-run from the repository root (BLENDER defaults to `blender`, 4.2 LTS):

    BLENDER=/path/to/blender python3 assets/creatures/tetherbound/staticub/candidate_r10/source/prepare_staticub_r10.py

Same steps, in the same order, as the owner1101 staticub remake
(candidate_owner1101/source/provenance.json "commands"):

1. tools/art_pipeline/blender/prepare_remake_quadruped.py (dog3 15-bone rig and
   anatomical skin) run unchanged, with the owner1101 parameters
   (candidate_owner1101/source/provenance.json "commands": patch false, no baked
   ground disc), at the installed height (data/creatures/species.json
   placeholder.height = 3.25 m). The bear cub has no long tail, so the stock
   rig_quadruped.find_legs quadrant split lands on the four paws (checked
   against the feet-only band: front y -0.4, rear y 1.35 m) and is kept.
2. assets/creatures/tetherbound/terrapup/candidate_dog3/source/author_native_clips.py
   unchanged (idle, walk, run, attack, charged, hit, faint, rest, swim,
   fly_grip, ride).
3. Embedded textures re-encoded JPEG q88 (normal map included), as the
   owner1101 GLBs ship them.
4. tools/art_pipeline/arc_emission.py build() with the owner1101 species rule
   (data/creatures/arc_emission.json staticub_owner1101: hue 175-205, lift
   0.04, blur 8, soften 1, gain 2), pointed at this model. Its sat_min 0.45
   lights 0.0001% of this albedo, so sat_min is re-chosen by that rule's own
   recorded method ("the first step that keeps the mask between 0.004% and
   3%"), in 0.05 steps as the r9 Duskhush prep did: 0.45 -> 0.25, 0.005%.
   The r10 concept's lightning veins are violet (albedo hue 255-285), outside
   this electric-blue band, so they do not glow under this rule; widening the
   hue band is a rule change for the creature lane, not this prep. The rule is
   passed here so data/ stays untouched until the creature lane wires the
   candidate.

tools/art_pipeline/texture_import_policy.py --apply is the creature lane's step
after it removes .gdignore and Godot writes the .import sidecars.
"""
import io, json, os, runpy, subprocess, sys, tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[6]
SPECIES = "staticub"
HEIGHT = 3.25
DIR = ROOT / "assets/creatures/tetherbound" / SPECIES / "candidate_r10"
RAW = DIR / "source" / (SPECIES + "_r10_meshy.glb")
OUT = DIR / "models" / ("creature_%s_r10.glb" % SPECIES)
REPORT = DIR / "source" / "prepare-report.json"
BLENDER = os.environ.get("BLENDER", "blender")
ARC_RULE = {"model": str(OUT.relative_to(ROOT)), "hue": [175.0, 205.0], "sat_min": 0.25, "lift": 0.04,
            "blur_px": 8.0, "soften_px": 1.0, "gain": 2.0,
            "_why": "electric-blue eyes and lightning lines; rule from arc_emission.json staticub_owner1101, sat_min stepped 0.45 -> 0.25 to reach 0.004%"}


def rig_in_blender():
    """Blender side: run prepare_remake_quadruped.py as is."""
    runpy.run_path(str(ROOT / "tools/art_pipeline/blender/prepare_remake_quadruped.py"), run_name="__main__")


def blender(*args):
    subprocess.run([BLENDER, "--background", "--python-exit-code", "1", "--python", *args], check=True)


def reencode_jpeg(path, quality=88):
    sys.path.insert(0, str(ROOT / "tools/art_pipeline"))
    import shift_reserved_red as T
    from PIL import Image
    gltf, views = T._read_glb(path)
    for image in gltf["images"]:
        raw = views[image["bufferView"]]
        buf = io.BytesIO()
        Image.open(io.BytesIO(raw)).convert("RGB").save(buf, "JPEG", quality=quality)
        views[image["bufferView"]] = buf.getvalue()
        image["mimeType"] = "image/jpeg"
    T._write_glb(path, gltf, views)


def main():
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        rigged = os.path.join(tmp, "rigged.glb")
        blender(str(Path(__file__).resolve()), "--",
                str(RAW), rigged, str(REPORT), json.dumps({"species": SPECIES, "height": HEIGHT, "patch": False}))
        blender(str(ROOT / "assets/creatures/tetherbound/terrapup/candidate_dog3/source/author_native_clips.py"),
                "--", rigged, str(OUT))
    reencode_jpeg(str(OUT))
    sys.path.insert(0, str(ROOT / "tools/art_pipeline"))
    import arc_emission
    arc_emission.build(SPECIES + "_r10", ARC_RULE)


if __name__ == "__main__":
    try:
        import bpy  # noqa: F401  (inside Blender: the rig stage)
        rig_in_blender()
    except ImportError:
        main()
