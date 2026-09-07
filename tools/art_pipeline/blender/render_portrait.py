"""Render one HUD portrait from an installed creature model.

    blender --background --python tools/art_pipeline/blender/render_portrait.py \
            -- <model.glb> --out assets/ui/portraits/creatures/<species>.png [--size 1024]

Reuses turntable.py's own normalise/camera/lighting pipeline (same flat,
neutral studio setup already used for every reference-comparison render in
this project) for a single three-quarter view, framed tighter than the
turntable's comparison-sheet framing so the creature fills the portrait the
way `assets/ui/portraits/creatures/*.png` already do.
"""

import pathlib
import sys

import bpy

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import turntable  # noqa: E402

## Fills more of the frame than the turntable's own 0.78 -- a portrait has
## no ground plane or scale-comparison job to leave headroom for.
PORTRAIT_FRAME_FILL = 0.94
PORTRAIT_AZIMUTH = 35.0  # turntable.ANGLES["three_quarter"]


def main() -> None:
    args = turntable.argv_after_double_dash()
    if not args:
        raise SystemExit("usage: ... render_portrait.py -- <model> --out <file.png> [--size N]")

    model = pathlib.Path(args[0]).resolve()
    if not model.exists():
        raise SystemExit(f"no such model: {model}")
    out_path = pathlib.Path(turntable.option(args, "--out", "portrait.png")).resolve()
    size = int(turntable.option(args, "--size", 1024))

    turntable.load(model)
    centre, extent = turntable.normalise()
    key = turntable.build_lighting()
    turntable.build_ground(extent)
    turntable.configure_render(size)
    camera = turntable.build_camera()

    turntable.FRAME_FILL = PORTRAIT_FRAME_FILL
    radius = extent * 4.0
    turntable.aim(camera, centre, PORTRAIT_AZIMUTH, radius, extent)
    key.rotation_euler = (
        __import__("math").radians(turntable.KEY_ELEVATION_DEGREES), 0.0,
        __import__("math").radians(PORTRAIT_AZIMUTH + turntable.KEY_OFFSET_DEGREES))

    out_path.parent.mkdir(parents=True, exist_ok=True)
    bpy.context.scene.render.filepath = str(out_path)
    bpy.ops.render.render(write_still=True)

    print(f"\n{model.name}: portrait -> {out_path}")


if __name__ == "__main__":
    main()
