"""mangrove_monitor r9 (2 Nov 2026): raw Meshy image-to-3D -> rigged, clipped candidate GLB.

Re-run from the repository root (BLENDER defaults to `blender`, 4.2 LTS):

    BLENDER=/path/to/blender python3 assets/creatures/tetherbound/mangrove_monitor/candidate_r9/source/prepare_mangrove_monitor_r9.py

Same steps, in the same order, as the owner1101 mangrove_monitor remake
(candidate_owner1101/source/provenance.json "commands"):

1. tools/art_pipeline/blender/prepare_remake_quadruped.py (dog3 15-bone rig and
   anatomical skin; strip_ground_patch auto) at the installed height
   (data/creatures/species.json placeholder.height = 3.4 m, the owner1101 height),
   run unchanged except for ONE measurement, replaced the way
   pipwing/candidate_owner1101/source/prepare_pipwing_owner1101.py replaces
   rig_bird.torso_half_width: rig_quadruped.find_legs splits its leg band into
   quadrants at the mesh's bounding-box midlines. This r9 mesh's long tail (and
   raised neck) put the box's y-midline behind BOTH leg pairs, so the "front"
   quadrants held all four feet and the "rear" columns landed on the tail
   (rear_l 2.45 m behind the real foot). find_legs_by_feet (below) takes the
   lowest 10% of the height (feet only: the tail's lowest point is above it),
   splits front/rear by 2-means on y and left/right at each pair's own x
   midpoint, and keeps rig_quadruped's separation refusal. Bones, regions,
   skin and clips are untouched.
2. assets/creatures/tetherbound/terrapup/candidate_dog3/source/author_native_clips.py
   unchanged (idle, walk, run, attack, charged, hit, faint, rest, swim,
   fly_grip, ride).
3. Embedded textures re-encoded JPEG q88 (normal map included), as the
   owner1101 GLBs ship them.
4. tools/art_pipeline/arc_emission.py build() with the owner1101 species rule
   (data/creatures/arc_emission.json mangrove_monitor_owner1101: same concept glow hue),
   pointed at this model. The rule is passed here so data/ stays untouched
   until the creature lane wires the candidate.

tools/art_pipeline/texture_import_policy.py --apply is the creature lane's step
after it removes .gdignore and Godot writes the .import sidecars.
"""
import io, json, os, runpy, subprocess, sys, tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[6]
SPECIES = "mangrove_monitor"
HEIGHT = 3.4
DIR = ROOT / "assets/creatures/tetherbound" / SPECIES / "candidate_r9"
RAW = DIR / "source" / (SPECIES + "_r9_meshy.glb")
OUT = DIR / "models" / ("creature_%s_r9.glb" % SPECIES)
REPORT = DIR / "source" / "prepare-report.json"
BLENDER = os.environ.get("BLENDER", "blender")
ARC_RULE = {"model": str(OUT.relative_to(ROOT)), "hue": [160.0, 200.0], "sat_min": 0.45, "lift": 0.05,
            "blur_px": 12.0, "soften_px": 1.5, "gain": 2.0,
            "_why": "glowing aqua eyes and thin aqua veins between the bark plates; rule copied from arc_emission.json mangrove_monitor_owner1101"}


FEET_BAND = 0.10


def find_legs_by_feet(body):
    """Blender side: the four foot columns from the ground-contact band."""
    import rig_quadruped as quad
    from mathutils import Vector
    low, high = quad.bounds(body)
    top = low.z + (high.z - low.z) * FEET_BAND
    band = [body.matrix_world @ v.co for v in body.data.vertices if (body.matrix_world @ v.co).z <= top]
    a, b = min(p.y for p in band), max(p.y for p in band)
    for _ in range(50):                   # 2-means on y: front pair vs rear pair
        split = (a + b) / 2
        front = [p.y for p in band if p.y < split]
        rear = [p.y for p in band if p.y >= split]
        a, b = sum(front) / len(front), sum(rear) / len(rear)
    split = (a + b) / 2
    legs = {}
    for prefix, pts in (("front", [p for p in band if p.y < split]), ("rear", [p for p in band if p.y >= split])):
        mid_x = (min(p.x for p in pts) + max(p.x for p in pts)) / 2
        for side, sel in (("l", [p for p in pts if p.x < mid_x]), ("r", [p for p in pts if p.x >= mid_x])):
            if not sel:
                raise SystemExit("no feet in the %s_%s column" % (prefix, side))
            legs[prefix + "_" + side] = sum(sel, Vector()) / len(sel)
    band_x = max(p.x for p in band) - min(p.x for p in band)
    band_y = max(p.y for p in band) - min(p.y for p in band)
    x_gap = abs(legs["front_l"].x - legs["front_r"].x) / max(band_x, 1e-6)
    y_gap = abs(legs["front_l"].y - legs["rear_l"].y) / max(band_y, 1e-6)
    if x_gap < quad.MIN_LEG_SEPARATION or y_gap < quad.MIN_LEG_SEPARATION:
        raise SystemExit("leg clusters are not separated (x %.2f, y %.2f)" % (x_gap, y_gap))
    print("FEET", {k: [round(c, 3) for c in v] for k, v in legs.items()})
    return legs


def rig_in_blender():
    """Blender side: patch find_legs, then run prepare_remake_quadruped.py as is."""
    sys.path.insert(0, str(ROOT / "tools/art_pipeline/blender"))
    import rig_quadruped as quad
    quad.find_legs = find_legs_by_feet
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
                str(RAW), rigged, str(REPORT), json.dumps({"species": SPECIES, "height": HEIGHT}))
        blender(str(ROOT / "assets/creatures/tetherbound/terrapup/candidate_dog3/source/author_native_clips.py"),
                "--", rigged, str(OUT))
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
