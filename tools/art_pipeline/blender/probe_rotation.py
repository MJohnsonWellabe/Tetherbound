"""Quick headless probe: import a glb, apply a candidate rotation, render one
still from the front so the right fix can be picked by eye against Blender's
own coordinate space (the same space turntable.py and Godot's glTF importer
both use) rather than guessed in a different tool's axis convention.

    blender --background --python probe_rotation.py -- <model.glb> \
        --out <out.png> --rx <deg> --ry <deg> --rz <deg>

Rotation is applied in Blender's own post-import space (glTF Y-up already
converted to Blender Z-up by the importer), order X then Y then Z, about the
object's own origin, before the object is re-centred and dropped to the
ground plane.
"""
import pathlib
import sys

import bpy
from mathutils import Vector


def argv_after_double_dash():
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def option(args, name, default=None):
    return args[args.index(name) + 1] if name in args else default


def main():
    args = argv_after_double_dash()
    model = pathlib.Path(args[0]).resolve()
    out = pathlib.Path(option(args, "--out", "probe.png")).resolve()
    rx = float(option(args, "--rx", "0"))
    ry = float(option(args, "--ry", "0"))
    rz = float(option(args, "--rz", "0"))

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(model))
    objs = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active

    import math
    obj.rotation_euler = (math.radians(rx), math.radians(ry), math.radians(rz))
    bpy.context.view_layer.update()
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)

    # recentre on X/Y, drop to Z=0 (Blender Z-up)
    bbox = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    minv = Vector((min(v.x for v in bbox), min(v.y for v in bbox), min(v.z for v in bbox)))
    maxv = Vector((max(v.x for v in bbox), max(v.y for v in bbox), max(v.z for v in bbox)))
    centre = (minv + maxv) / 2
    obj.location.x -= centre.x
    obj.location.y -= centre.y
    obj.location.z -= minv.z

    dims = maxv - minv
    longest = max(dims.x, dims.y, dims.z, 1e-6)
    scale = 1.6 / longest
    obj.scale = (scale, scale, scale)
    obj.location *= scale
    bpy.context.view_layer.update()

    cam_data = bpy.data.cameras.new("cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = 2.4
    cam = bpy.data.objects.new("cam", cam_data)
    bpy.context.scene.collection.objects.link(cam)
    cam.location = (0, -4, 1.0)
    cam.rotation_euler = (math.radians(80), 0, 0)
    bpy.context.scene.camera = cam

    light_data = bpy.data.lights.new("sun", type="SUN")
    light_data.energy = 3.0
    light = bpy.data.objects.new("sun", light_data)
    bpy.context.scene.collection.objects.link(light)
    light.rotation_euler = (math.radians(55), 0, math.radians(35))

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT" if hasattr(bpy.types, "SceneEEVEE") else "BLENDER_EEVEE"
    scene.render.resolution_x = 480
    scene.render.resolution_y = 480
    scene.render.film_transparent = False
    scene.world = bpy.data.worlds.new("world")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs[0].default_value = (0.55, 0.55, 0.58, 1)

    scene.render.filepath = str(out)
    bpy.ops.render.render(write_still=True)
    print(f"wrote {out}  dims={dims.x:.2f},{dims.y:.2f},{dims.z:.2f}")


main()
