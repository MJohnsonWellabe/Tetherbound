"""duskhush r9 (2 Nov 2026): raw Meshy image-to-3D -> rigged, clipped candidate GLB.

Re-run from the repository root (BLENDER defaults to `blender`, 4.2 LTS):

    BLENDER=/path/to/blender python3 assets/creatures/tetherbound/duskhush/candidate_r9/source/prepare_duskhush_r9.py

Same steps, in the same order, as the owner1101 Duskhush remake
(candidate_owner1101/source/provenance.json "commands"):

1. assets/creatures/tetherbound/pipwing/candidate_owner1101/source/prepare_pipwing_owner1101.py
   unchanged (tools/art_pipeline/blender/rig_bird.py with the shell-aware
   torso measurement; 19 bones; clips idle, walk, run, attack, hit, faint,
   charged, fly_grip, rest, swim, ride). One addition in front: rig_bird does
   not scale, so the owner1101 Duskhush shipped at Meshy's raw 1.87 m and the
   game fitted it up to 2.3 m at runtime. Here the welded, grounded mesh is
   scaled to the installed height (data/creatures/species.json
   duskhush.placeholder.height = 2.3 m, the height the owner1101 flag names)
   before rig_bird measures it, so the GLB's own height, rig and clip
   amplitudes are at 2.3 m. Uniform scale only; every measurement is relative.
2. Embedded textures re-encoded JPEG q88 (normal map included), as the
   owner1101 GLBs ship them.
3. tools/art_pipeline/arc_emission.py build() with the owner1101 species rule
   (data/creatures/arc_emission.json duskhush_owner1101: hue 255-300, lift
   0.05, blur 12, soften 1.5, gain 2), pointed at this model. Its sat_min 0.45
   lights 0.002% of this albedo (the r9 eyes are a paler lavender), so
   sat_min is re-chosen by that rule's own recorded method ("the first step
   that keeps the mask between 0.004% and 3%"): 0.45 -> 0.40, 0.007%, part of
   the eye rings and the violet primary-feather edges. The rule is passed here
   so data/ stays untouched until the creature lane wires the candidate.

tools/art_pipeline/texture_import_policy.py --apply is the creature lane's step
after it removes .gdignore and Godot writes the .import sidecars.
"""
import io, os, runpy, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[6]
SPECIES = "duskhush"
HEIGHT = 2.3
DIR = ROOT / "assets/creatures/tetherbound" / SPECIES / "candidate_r9"
RAW = DIR / "source" / (SPECIES + "_r9_meshy.glb")
OUT = DIR / "models" / ("creature_%s_r9.glb" % SPECIES)
REPORT = DIR / "source" / "prepare-report.json"
BIRD = ROOT / "assets/creatures/tetherbound/pipwing/candidate_owner1101/source/prepare_pipwing_owner1101.py"
BLENDER = os.environ.get("BLENDER", "blender")
ARC_RULE = {"model": str(OUT.relative_to(ROOT)), "hue": [255.0, 300.0], "sat_min": 0.40, "lift": 0.05,
            "blur_px": 12.0, "soften_px": 1.5, "gain": 2.0,
            "_why": "glowing violet eyes and feather edges; rule from arc_emission.json duskhush_owner1101, sat_min stepped 0.45 -> 0.40 to reach 0.004%"}


def rig_in_blender():
    """Blender side: scale to HEIGHT after rig_bird's weld/ground, then run the bird prep as is."""
    sys.path.insert(0, str(ROOT / "tools/art_pipeline/blender"))
    import bpy
    import rig_bird as r
    weld = r.join_normalise_weld

    def weld_and_scale():
        body = weld()
        low, high = r.point_bounds(r.world_points(body))
        k = HEIGHT / (high.z - low.z)
        body.scale = (k, k, k)
        bpy.context.view_layer.objects.active = body
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        print("  scaled %.4f m -> %.4f m (x%.4f)" % (high.z - low.z, HEIGHT, k))
        return body

    r.join_normalise_weld = weld_and_scale
    runpy.run_path(str(BIRD), run_name="__main__")


def blender(*args):
    subprocess.run([BLENDER, "--background", "--python-exit-code", "1", "--python", *args], check=True)


def reencode_jpeg(path, quality=88):
    sys.path.insert(0, str(ROOT / "tools/art_pipeline"))
    import shift_reserved_red as T
    from PIL import Image
    gltf, views = T._read_glb(path)
    for image in gltf["images"]:
        buf = io.BytesIO()
        Image.open(io.BytesIO(views[image["bufferView"]])).convert("RGB").save(buf, "JPEG", quality=quality)
        views[image["bufferView"]] = buf.getvalue()
        image["mimeType"] = "image/jpeg"
    T._write_glb(path, gltf, views)


def main():
    OUT.parent.mkdir(parents=True, exist_ok=True)
    blender(str(Path(__file__).resolve()), "--", str(RAW), "--out", str(OUT), "--report", str(REPORT))
    reencode_jpeg(str(OUT))
    sys.path.insert(0, str(ROOT / "tools/art_pipeline"))
    import arc_emission
    arc_emission.build(SPECIES + "_r9", ARC_RULE)


if __name__ == "__main__":
    try:
        import bpy  # noqa: F401  (inside Blender: the rig stage)
        rig_in_blender()
    except ImportError:
        main()
