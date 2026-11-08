# F38#20 keep curtain walls (LANE-SW, 7 Nov 2026, round 2). Blender 4.2 script.
# blender -b -P build_keep_walls.py -- <repo root> <out.glb>
# A crenellated stone curtain wall with round towers ringing the keep hill
# (build_keep_hill.py's heightfield) below the keep, open at the front so the
# hall and keep face stay in view: "a keep on a hill with walls". Same local
# frame as the hill (x right, z from the gate mouth, y from the hill base 14 m
# under the hall floor). Written with 1 m marker posts at the hill's bounding-box corners so the
# loader's bbox recentring matches the hill (width_m 856, offset [-2, -14, 240]).
import bpy, bmesh, math, sys, os, importlib.util
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
ROOT, OUT = argv[0], argv[1]
spec = importlib.util.spec_from_file_location("hill", os.path.join(os.path.dirname(os.path.abspath(__file__)), "hill_height.py"))
hill = importlib.util.module_from_spec(spec); spec.loader.exec_module(hill)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
m = bpy.data.materials.new("wall_stone"); m.use_nodes = True
nt = m.node_tree; b = nt.nodes["Principled BSDF"]
t = nt.nodes.new("ShaderNodeTexImage"); t.image = bpy.data.images.load(os.path.join(ROOT, "assets/environment/terrain/Rock030_Color.jpg"))
nt.links.new(t.outputs["Color"], b.inputs["Base Color"]); b.inputs["Roughness"].default_value = 0.9

def bl(x, z, y):
    return Vector((x, -z, y))

bm = bmesh.new()
uv = bm.loops.layers.uv.new("UVMap")

def box(cx, cz, y0, w, d, h, yaw):
    c, s = math.cos(yaw), math.sin(yaw)
    pts = []
    for dy in (0.0, h):
        for (ox, oz) in ((-w / 2, -d / 2), (w / 2, -d / 2), (w / 2, d / 2), (-w / 2, d / 2)):
            pts.append(bm.verts.new(bl(cx + ox * c - oz * s, cz + ox * s + oz * c, y0 + dy)))
    faces = [(0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
    for fi in faces:
        f = bm.faces.new([pts[i] for i in fi])
        for loop in f.loops:
            co = loop.vert.co
            loop[uv].uv = ((co.x - co.y) / 8.0, co.z / 8.0)

def tower(cx, cz, y0, r, h):
    seg = 16
    ring0 = [bm.verts.new(bl(cx + math.cos(i * math.tau / seg) * r, cz + math.sin(i * math.tau / seg) * r, y0)) for i in range(seg)]
    ring1 = [bm.verts.new(bl(cx + math.cos(i * math.tau / seg) * r, cz + math.sin(i * math.tau / seg) * r, y0 + h)) for i in range(seg)]
    for i in range(seg):
        j = (i + 1) % seg
        f = bm.faces.new((ring0[i], ring0[j], ring1[j], ring1[i]))
        for loop, (u, v) in zip(f.loops, ((i, 0), (i + 1, 0), (i + 1, 1), (i, 1))):
            loop[uv].uv = (u * r * math.tau / seg / 8.0, v * h / 8.0)
    bm.faces.new(list(reversed(ring1)))
    for i in range(0, seg, 2):   # merlons
        a = (i + 0.5) * math.tau / seg
        box(cx + math.cos(a) * r * 0.92, cz + math.sin(a) * r * 0.92, y0 + h, 3.2, 2.2, 3.0, a)

CX, CZ, RX, RZ = 0.0, 205.0, 255.0, 175.0
WALL_H, WALL_T, SEG = 20.0, 6.0, 9.0
n = int(math.tau * math.sqrt((RX ** 2 + RZ ** 2) / 2) / SEG)
pts = []
for i in range(n + 1):
    a = -math.pi / 2 + i * math.tau / n
    pts.append((CX + math.cos(a) * RX, CZ + math.sin(a) * RZ))
def open_front(x, z):
    return abs(x) < 125.0 and z < 150.0   # the hall and the keep's face stay in view
tower_every = 10
for i in range(n):
    (x0, z0), (x1, z1) = pts[i], pts[i + 1]
    mx, mz = (x0 + x1) / 2, (z0 + z1) / 2
    if open_front(mx, mz):
        continue
    ground = min(hill.height(x0, z0), hill.height(x1, z1), hill.height(mx, mz)) - 3.0
    yaw = math.atan2(z1 - z0, x1 - x0)
    L = math.hypot(x1 - x0, z1 - z0) + 0.6
    box(mx, mz, ground, L, WALL_T, WALL_H + 3.0, yaw)
    # crenellation: two merlons per segment on the wall top
    for k in (-0.25, 0.25):
        box(mx + math.cos(yaw) * L * k, mz + math.sin(yaw) * L * k, ground + WALL_H + 3.0, 2.6, WALL_T, 2.6, yaw)
    if i % tower_every == 0 or open_front(*pts[i + 1]) != open_front(*pts[i]):
        tower(x0, z0, hill.height(x0, z0) - 3.0, 9.0, WALL_H + 14.0)
# extent markers at two opposite corners of the hill's bounding box (x -430..426,
# z -40..520, y from 0), 8 m under the meadow, so the loader recentres both alike
for x, z in ((-430.0 + 0.25, -40.0 + 0.25), (426.0 - 0.25, 520.0 - 0.25)):
    box(x, z, 0.0, 0.5, 0.5, 1.0, 0.0)

me = bpy.data.meshes.new("keep_walls"); bm.to_mesh(me); me.materials.append(m)
o = bpy.data.objects.new("KeepWalls", me); scene.collection.objects.link(o)
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", export_yup=True, export_image_format="JPEG")
xs = [v.co.x for v in me.vertices]; zs = [v.co.z for v in me.vertices]; ls = [-v.co.y for v in me.vertices]
print("WALLS_OK", OUT, "x", round(min(xs), 1), round(max(xs), 1), "z(local)", round(min(ls), 1), round(max(ls), 1), "y", round(min(zs), 1), round(max(zs), 1))
