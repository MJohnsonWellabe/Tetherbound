# Preview render with a 1.80 m trainer ruler (scale check). blender -b -P preview.py -- <in.glb> <out.png>
import bpy, sys, math
argv = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=argv[0])
bpy.ops.mesh.primitive_cylinder_add(radius=0.25, depth=1.8, location=(-1.0, -4.0, 0.9))
bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0))
g = bpy.data.materials.new("lawn"); g.diffuse_color = (0.35, 0.5, 0.2, 1); bpy.context.object.data.materials.append(g)
cam = bpy.data.cameras.new("c"); co = bpy.data.objects.new("c", cam); bpy.context.scene.collection.objects.link(co)
co.location = (4.0, -16.0, 4.0); co.rotation_euler = (math.radians(80), 0, math.radians(14))
bpy.context.scene.camera = co
sun = bpy.data.lights.new("s", "SUN"); sun.energy = 4; so = bpy.data.objects.new("s", sun); so.rotation_euler = (0.8, 0.3, 0.6)
bpy.context.scene.collection.objects.link(so)
w = bpy.data.worlds.new("w"); w.color = (0.55, 0.7, 0.9); bpy.context.scene.world = w
s = bpy.context.scene; s.render.engine = "CYCLES"; s.cycles.samples = 16; s.cycles.device = "CPU"; s.render.resolution_x = 960; s.render.resolution_y = 540
s.render.filepath = argv[1]; bpy.ops.render.render(write_still=True)
