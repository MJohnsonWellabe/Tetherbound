# Preview render (3 views) of a GLB beside a 1.80 m trainer-height bar for the scale check.
#   blender -b --python render_preview.py -- <glb> <out.png> <height_m>
import bpy, sys, math, os
args = sys.argv[sys.argv.index("--") + 1:]
glb, out, height = args[0], args[1], float(args[2])
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb)
objs = [o for o in bpy.data.objects if o.type == "MESH"]
import mathutils
mn = mathutils.Vector((1e9,)*3); mx = mathutils.Vector((-1e9,)*3)
for o in objs:
    for c in o.bound_box:
        p = o.matrix_world @ mathutils.Vector(c); mn = mathutils.Vector(map(min, mn, p)); mx = mathutils.Vector(map(max, mx, p))
s = height / (mx.z - mn.z)
for o in objs:
    o.scale = o.scale * s
bpy.context.view_layer.update()
for o in objs:
    o.location.z -= mn.z * s
# 1.80 m trainer bar
bpy.ops.mesh.primitive_cylinder_add(radius=0.12, depth=1.8, location=(1.4, 0, 0.9))
bar = bpy.context.object
mat = bpy.data.materials.new("bar"); mat.diffuse_color = (0.2, 0.6, 0.65, 1); bar.data.materials.append(mat)
bpy.ops.object.light_add(type="SUN", rotation=(math.radians(50), 0, math.radians(30))); bpy.context.object.data.energy = 3.5
w = bpy.data.worlds.new("w"); bpy.context.scene.world = w; w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.45, 0.55, 0.62, 1); w.node_tree.nodes["Background"].inputs[1].default_value = 0.8
sc = bpy.context.scene
sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 24
sc.render.resolution_x, sc.render.resolution_y = 900, 600
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
frames = []
for i, ang in enumerate([20, 110, 200]):
    r = 5.5
    cam.location = (r * math.sin(math.radians(ang)), -r * math.cos(math.radians(ang)), 1.4)
    d = mathutils.Vector((0.4, 0, 0.6)) - cam.location
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    p = out.replace(".png", "_%d.png" % i); sc.render.filepath = p
    bpy.ops.render.render(write_still=True); frames.append(p)
print("frames", frames)
