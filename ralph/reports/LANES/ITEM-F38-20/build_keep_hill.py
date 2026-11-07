# F38#20 keep hill (LANE-SW, 7 Nov 2026). Blender 4.2 script.
# blender -b -P build_keep_hill.py -- <repo root> <out.glb> [preview.png]
# A broad grassy hill with rock outcrops under the Meadows stronghold keep, so
# the keep crowns a hill instead of perching on the horizon. Authored in the
# stronghold's local metres (Godot x right, z away from the gate mouth); the
# hero-gatehouse loader recentres it (bbox centre in x/z, base at y 0), so the
# config places it with width_m = the mesh's x size (scale 1) and an offset.
# The hall's footprint (|x| < 70 m, z < 125 m) is notched below the hall floor,
# and nothing rises in front of the mouth (z < -20 m). Textures: the installed
# assets/environment/terrain Grass004 and Rock030, embedded in the GLB.
import bpy, bmesh, math, random, sys, os
from mathutils import Vector, noise

argv = sys.argv[sys.argv.index("--") + 1:]
ROOT, OUT = argv[0], argv[1]
PREVIEW = argv[2] if len(argv) > 2 else ""

X_HALF, Z0, Z1 = 430.0, -40.0, 520.0   # local extent (z from the gate mouth)
CX, CZ = 0.0, 200.0                    # hill crown behind the keep (keep centre z 149)
RX, RZ = 420.0, 300.0
H = 78.0                               # crown height above the hill base
BASE_SINK = 14.0                       # base sits this far below the hall floor (config offset y)
NOTCH_X, NOTCH_Z = 70.0, 125.0         # hall footprint: kept below the floor
NOTCH_TOP = BASE_SINK - 3.0            # 3 m under the hall floor
STEP = 8.0
rng = random.Random(1107)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

def tex_mat(name, image_rel, tint):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    img = bpy.data.images.load(os.path.join(ROOT, image_rel))
    t = nt.nodes.new("ShaderNodeTexImage"); t.image = img
    mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"; mix.blend_type = "MULTIPLY"
    mix.inputs["Factor"].default_value = 1.0
    mix.inputs[7].default_value = (*tint, 1)
    nt.links.new(t.outputs["Color"], mix.inputs[6])
    nt.links.new(mix.outputs[2], b.inputs["Base Color"])
    b.inputs["Roughness"].default_value = 0.95
    return m

M_GRASS = tex_mat("hill_grass", "assets/environment/terrain/Grass004_Color.jpg", (0.82, 0.9, 0.62))
M_ROCK = tex_mat("hill_rock", "assets/environment/terrain/Rock030_Color.jpg", (0.72, 0.7, 0.66))

def smooth(t):
    t = max(0.0, min(1.0, t)); return t * t * (3 - 2 * t)

def height(x, z):
    d = math.sqrt(((x - CX) / RX) ** 2 + ((z - CZ) / RZ) ** 2)
    h = H * (0.5 + 0.5 * math.cos(math.pi * min(1.0, d))) if d < 1.0 else 0.0
    h += 9.0 * noise.noise(Vector((x / 140.0, z / 140.0, 0.3))) * smooth(1.0 - d)
    h += 3.0 * noise.noise(Vector((x / 37.0, z / 37.0, 1.7))) * smooth(1.0 - d)
    h *= smooth((z - Z0) / 60.0)                                   # nothing in front of the mouth
    # hall notch: capped under the floor across the footprint, blended out over 40 m
    nx = smooth((abs(x) - NOTCH_X) / 40.0)
    nz = smooth((z - NOTCH_Z) / 40.0)
    inside = 1.0 - max(nx, nz)
    cap = NOTCH_TOP
    if h > cap:
        h = h * (1.0 - inside) + cap * inside
    return max(0.0, h)

def bl(x, z, y):   # Godot (x, y, z) -> Blender (x, -z, y)
    return Vector((x, -z, y))

bm = bmesh.new()
uv = bm.loops.layers.uv.new("UVMap")
nx_ = int(2 * X_HALF / STEP); nz_ = int((Z1 - Z0) / STEP)
grid = [[bm.verts.new(bl(-X_HALF + i * STEP, Z0 + j * STEP, height(-X_HALF + i * STEP, Z0 + j * STEP))) for j in range(nz_ + 1)] for i in range(nx_ + 1)]
for i in range(nx_):
    for j in range(nz_):
        vs = (grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1])
        f = bm.faces.new(vs)
        for loop, v in zip(f.loops, vs):
            loop[uv].uv = (v.co.x / 18.0, v.co.y / 18.0)
        # steep faces take the rock material
        f.normal_update()
        f.material_index = 1 if f.normal.z < 0.80 else 0
bmesh.ops.reverse_faces(bm, faces=[f for f in bm.faces if f.normal.z < 0])

# rock outcrops on the upper slopes: squashed noisy boulders, half buried
for k in range(26):
    a = rng.uniform(0, math.tau); d = rng.uniform(0.25, 0.7)
    x = CX + math.cos(a) * RX * d; z = CZ + math.sin(a) * RZ * d
    if abs(x) < NOTCH_X + 30 and z < NOTCH_Z + 30:
        continue
    r = rng.uniform(9.0, 22.0)
    res = bmesh.ops.create_icosphere(bm, subdivisions=2, radius=r)
    for v in res["verts"]:
        n = v.co.normalized()
        v.co = v.co * (1.0 + 0.28 * noise.noise(n * 2.3 + Vector((k, 0, 0))))
        v.co.z *= 0.55
        v.co += bl(x, z, height(x, z) - r * 0.18)
    for f in {f for v in res["verts"] for f in v.link_faces}:
        f.material_index = 1
        for loop in f.loops:
            loop[uv].uv = (loop.vert.co.x / 9.0 + loop.vert.co.z / 9.0, loop.vert.co.y / 9.0)

me = bpy.data.meshes.new("keep_hill")
bm.to_mesh(me)
me.materials.append(M_GRASS); me.materials.append(M_ROCK)
for p in me.polygons:
    p.use_smooth = True
obj = bpy.data.objects.new("KeepHill", me)
scene.collection.objects.link(obj)

bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", export_yup=True, export_image_format="JPEG")
xs = [v.co.x for v in me.vertices]; zs = [v.co.z for v in me.vertices]; ys = [-v.co.y for v in me.vertices]
print("HILL_OK", OUT, "x_size", round(max(xs) - min(xs), 2), "z(local)", round(min(ys), 1), round(max(ys), 1),
      "x_centre", round((max(xs) + min(xs)) / 2, 2), "y", round(min(zs), 2), round(max(zs), 2))

if PREVIEW:
    # 1.80 m scale capsule on the crown, camera 650 m south at eye height near the base.
    bpy.ops.mesh.primitive_cylinder_add(radius=6, depth=150, location=tuple(bl(0, 149, height(0, 149) + 75)))  # keep proxy, ~150 m
    bpy.ops.mesh.primitive_cylinder_add(radius=0.25, depth=1.8, location=tuple(bl(160, 120, height(160, 120) + 0.9)))
    cam_data = bpy.data.cameras.new("cam"); cam_data.lens = 35
    cam = bpy.data.objects.new("cam", cam_data); scene.collection.objects.link(cam)
    cam.location = bl(0, -650, 10); cam.rotation_euler = (bl(0, 150, 50) - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    sun = bpy.data.lights.new("sun", "SUN"); sun.energy = 3
    so = bpy.data.objects.new("sun", sun); scene.collection.objects.link(so); so.rotation_euler = (0.9, 0.3, 0.5)
    world = bpy.data.worlds.new("w"); world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.5, 0.65, 0.9, 1)
    scene.world = world
    scene.render.engine = "CYCLES"; scene.cycles.device = "CPU"; scene.cycles.samples = 16
    scene.render.resolution_x, scene.render.resolution_y = 960, 540
    scene.render.filepath = PREVIEW
    bpy.ops.render.render(write_still=True)
    print("PREVIEW_OK", PREVIEW)
