# Preview + 1.80 m scale check for warrens_bank_hill.glb (LANE-MESHY, 8 Nov 2026).
# blender -b --python render_preview.py -- <glb> <out.png>
import bpy, sys, math, mathutils
argv = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=argv[0])
scn = bpy.context.scene
# 1.80 m trainer bar at the mouth (warrens local origin; approach side is Blender +Y)
bpy.ops.mesh.primitive_cylinder_add(radius=0.3, depth=1.8, location=(0, 4.0, 0.9))
bar = bpy.context.active_object; m = bpy.data.materials.new("bar"); m.diffuse_color = (0.9, 0.1, 0.9, 1); bar.data.materials.append(m)
m.use_nodes = True; m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.9, 0.1, 0.9, 1)
w = bpy.data.worlds.new("w"); scn.world = w; w.use_nodes = True; w.node_tree.nodes["Background"].inputs[0].default_value = (0.55, 0.68, 0.85, 1); w.node_tree.nodes["Background"].inputs[1].default_value = 1.2
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN")); scn.collection.objects.link(sun); sun.rotation_euler = (math.radians(50), 0, math.radians(30)); sun.data.energy = 3.5
cams = []
for name, loc, tgt in [("route", (24, 60, 8), (0, -20, 6)), ("mouth", (6, 22, 3), (0, 0, 3)), ("se", (110, 60, 40), (0, -45, 5))]:
    c = bpy.data.objects.new(name, bpy.data.cameras.new(name)); scn.collection.objects.link(c); c.data.clip_end = 3000; c.data.lens = 28
    c.location = loc; c.rotation_euler = (mathutils.Vector(tgt) - mathutils.Vector(loc)).to_track_quat('-Z', 'Y').to_euler(); cams.append(c)
scn.render.engine = 'CYCLES'; scn.cycles.samples = 24; scn.cycles.device = 'CPU'
scn.render.resolution_x = 800; scn.render.resolution_y = 450
base = argv[1].rsplit(".", 1)[0]
for c in cams:
    scn.camera = c; scn.render.filepath = f"{base}_{c.name}.png"; bpy.ops.render.render(write_still=True)
