"""Orthographic front/side/three-quarter previews of a prop GLB, on CPU.

    blender --background --python tools/art_pipeline/blender/preview_props.py \
            -- <model.glb> --out shots/dir [--size 512] [--samples 24]

WHY NOT turntable.py, which already does this. That script renders in EEVEE, and
EEVEE needs a GL context: in a headless cloud container with no libEGL it aborts
with "Couldn't open libEGL.so.1" after importing the model, and `xvfb-run` does
not help because the missing piece is the driver, not the display. Cycles on CPU
has no such dependency. It is slower, which does not matter for a 500px prop
check, and it is a fair likeness of the shape -- which is the only thing these
frames are for. They judge silhouette and proportion against an art board; they
are not evidence about how the prop looks in Godot, and must not be used as such.
"""
import argparse
import math
import pathlib
import sys

import bpy
from mathutils import Vector

VIEWS = {
    "front": (0.0, 0.0),
    "side": (math.pi / 2, 0.0),
    "three_quarter": (math.pi * 0.25, 0.28),
}


def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def bounds():
    lo = Vector((1e9,) * 3)
    hi = Vector((-1e9,) * 3)
    for o in bpy.data.objects:
        if o.type != "MESH":
            continue
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c)
            for k in range(3):
                lo[k] = min(lo[k], w[k])
                hi[k] = max(hi[k], w[k])
    return lo, hi


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    ap = argparse.ArgumentParser()
    ap.add_argument("model")
    ap.add_argument("--out", required=True)
    ap.add_argument("--size", type=int, default=512)
    ap.add_argument("--samples", type=int, default=24)
    a = ap.parse_args(argv)

    clear()
    bpy.ops.import_scene.gltf(filepath=a.model)
    lo, hi = bounds()
    centre = (lo + hi) * 0.5
    extent = max((hi - lo).x, (hi - lo).y, (hi - lo).z)

    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = a.samples
    scene.render.resolution_x = scene.render.resolution_y = a.size
    scene.render.film_transparent = False

    # A neutral studio: one key, one fill, a mid-grey world. Deliberately flat --
    # these frames are read for shape, so a dramatic key that carves the silhouette
    # would be flattering the very thing under test.
    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.28, 0.29, 0.31, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 1.1
    scene.world = world

    key = bpy.data.lights.new("Key", "SUN")
    key.energy = 3.2
    ko = bpy.data.objects.new("Key", key)
    ko.rotation_euler = (math.radians(52), 0, math.radians(38))
    bpy.context.collection.objects.link(ko)

    cam_data = bpy.data.cameras.new("Cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = extent * 1.18
    cam = bpy.data.objects.new("Cam", cam_data)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam

    out = pathlib.Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    dist = extent * 2.4
    for name, (yaw, pitch) in VIEWS.items():
        # +Y is the prop's FRONT. Every wall-mounted prop in build_hall_props.py is
        # authored with -Y against the stone and its working face toward +Y, so a
        # camera parked at -Y photographs the backplate. The first run of this
        # script did exactly that and made the Rift Siphon -- whose whole point is
        # a caged glowing chamber on its front -- render as a featureless slab.
        cam.location = centre + Vector((
            math.sin(yaw) * math.cos(pitch),
            math.cos(yaw) * math.cos(pitch),
            math.sin(pitch))) * dist
        direction = centre - cam.location
        cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = str(out / (name + ".png"))
        bpy.ops.render.render(write_still=True)
        print("[preview] %s" % scene.render.filepath)


if __name__ == "__main__":
    main()
