"""List every object in a GLB with the facts that matter for stray-hunting.

    blender --background --python tools/art_pipeline/blender/probe_objects.py -- <model.glb>

Written to answer one question the reports could not: WHAT is the stray
42-vertex mesh that survives strip_strays.py's removal-and-verify.
"""

import pathlib
import sys

import bpy


def main() -> None:
    args = sys.argv[sys.argv.index("--") + 1:]
    path = pathlib.Path(args[0]).resolve()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path))
    print(f"\n=== {path.name}")
    for obj in bpy.data.objects:
        line = f"  {obj.type:9s} {obj.name!r:32s} parent={obj.parent.name if obj.parent else None!r}"
        if obj.type == "MESH":
            line += (f" verts={len(obj.data.vertices)} groups={len(obj.vertex_groups)}"
                     f" mesh_data={obj.data.name!r} materials={[m.name for m in obj.data.materials]}"
                     f" dims={tuple(round(d, 3) for d in obj.dimensions)}"
                     f" loc={tuple(round(c, 3) for c in obj.location)}")
            line += f" modifiers={[m.type for m in obj.modifiers]}"
        print(line)
    print(f"  meshes in bpy.data.meshes: {[m.name for m in bpy.data.meshes]}")
    print(f"  actions: {len(bpy.data.actions)}")


main()
