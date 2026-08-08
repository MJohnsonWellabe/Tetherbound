"""Remove unskinned stray meshes from a finished GLB, preserving its clips.

    blender --background --python tools/art_pipeline/blender/strip_strays.py \
            -- <model.glb> [--out <model.glb>]

Defaults to editing in place, because this is a repair rather than a stage.

## What it removes, and why it exists

Every model this project has shipped — five of them, three creatures and two
humans — carries a stray 42-vertex **Icosphere**, two units across, centred on
the origin, with no vertex groups. It comes out of the generator and rides
through the whole pipeline.

A blind reviewer found it from the renders alone, reporting "detached geometry
floating free in the sky, unattached to anything" and using it to argue the
asset should be rebuilt. It does not need a rebuild. It needs this.

Two reasons it is not cosmetic:

1. **It poisons bounds-based fitting.** `pal_body._fit()` measures the model's
   bounding box and scales it to the species' configured height. A sphere from
   z = -1 to +1 wrapped around a creature standing from 0 to 2.11 makes the
   measured height 3.11 instead of 2.11, so the creature is fitted to about
   two thirds of the size the data asked for. Every creature is affected, and
   by a different amount, since it depends on each one's own proportions.
2. **It is real geometry with a real material slot**, so whether it draws
   depends on nothing more reliable than luck.

The existing drop in `skin_transfer.py` and `animate_humanoid.py` runs before
the export and *reports* removing it, and the sphere is in the exported file
anyway. Rather than trust another in-pipeline drop, this script does the
removal as its own pass and then **verifies it by re-importing the file it
just wrote**. A repair that cannot confirm itself is how the sphere survived
five exports.

## Clips

Animations are the reason this is not a one-liner. Imported actions have to be
re-stashed as NLA tracks or the glTF exporter writes only the active one, and
the whole roster's clip set would silently collapse to a single animation. The
script counts clips before and after and refuses to overwrite the file if the
count drops.
"""

import pathlib
import sys

import bpy


def argv_after_double_dash() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def option(args: list[str], name: str, default=None):
    return args[args.index(name) + 1] if name in args else default


def load(path: pathlib.Path) -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path))


def strays() -> list[bpy.types.Object]:
    """Meshes with no vertex groups, on a model whose real mesh is skinned.

    Deliberately conservative: if NOTHING in the file is skinned, this is not a
    rigged character and every mesh is left alone rather than assuming the
    biggest one is the subject.
    """
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    if not any(o.vertex_groups for o in meshes):
        return []
    return [o for o in meshes if not o.vertex_groups]


def restash_actions(rig: bpy.types.Object) -> int:
    """Put every action back on its own NLA track so the exporter writes them all."""
    if rig is None:
        return 0
    rig.animation_data_create()
    existing = {strip.action.name
                for track in rig.animation_data.nla_tracks
                for strip in track.strips if strip.action}
    stashed = len(existing)
    for action in bpy.data.actions:
        if action.name in existing:
            continue
        track = rig.animation_data.nla_tracks.new()
        track.name = action.name
        track.strips.new(action.name, 1, action)
        action.use_fake_user = True
        stashed += 1
    rig.animation_data.action = None
    return stashed


def main() -> None:
    args = argv_after_double_dash()
    if not args:
        raise SystemExit("usage: ... strip_strays.py -- <model.glb> [--out <out.glb>]")
    model = pathlib.Path(args[0]).resolve()
    out = pathlib.Path(option(args, "--out", model)).resolve()

    load(model)
    clips_before = len(bpy.data.actions)
    doomed = strays()
    if not doomed:
        print(f"{model.name}: nothing to strip")
        return
    for stray in doomed:
        print(f"  removing stray: {stray.name} ({len(stray.data.vertices)} verts, "
              f"no vertex groups)")
        bpy.data.objects.remove(stray, do_unlink=True)

    rigs = [o for o in bpy.data.objects if o.type == "ARMATURE"]
    stashed = restash_actions(rigs[0] if rigs else None)
    print(f"  {stashed} clip(s) stashed as NLA tracks")

    temporary = out.with_suffix(".stripped.glb")
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=str(temporary), export_format="GLB",
        export_animations=True, export_animation_mode="NLA_TRACKS",
        export_skins=True, export_yup=True)

    # Verify against the file actually written, not against the scene in memory.
    # The in-pipeline version of this removal reported success five times and
    # shipped the sphere five times.
    load(temporary)
    remaining = strays()
    clips_after = len(bpy.data.actions)
    if remaining:
        temporary.unlink(missing_ok=True)
        raise SystemExit(f"FAILED: {len(remaining)} stray(s) still in the written file")
    if clips_after < clips_before:
        temporary.unlink(missing_ok=True)
        raise SystemExit(f"FAILED: clips dropped {clips_before} -> {clips_after}; "
                         f"refusing to overwrite {out.name}")

    temporary.replace(out)
    print(f"  verified: 0 strays, {clips_after} clips (was {clips_before})")
    print(f"-> {out}")


if __name__ == "__main__":
    main()
