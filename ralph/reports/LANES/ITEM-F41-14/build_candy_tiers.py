# F41#14 Stormwood candy tiers (LANE-SW, 7 Nov 2026). Blender 4.2 script.
# blender -b -P build_candy_tiers.py -- <out dir> [preview.png]
# Three candy bodies with their own silhouettes, each 1.0 unit tall at
# authoring scale (the game scales them per tier so rarer reads bigger):
#   good  - a green wrapped oval sweet with two twisted fan ends (the classic sweet)
#   great - a blue-and-white striped twist: a longer body wound with a helix stripe
#   rare  - a faceted gold gem-candy seated on a five-point star wrapper
# No emission: the tier reads by shape, size and colour, not bloom.
import bpy, bmesh, math, sys, os
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index("--") + 1:]
OUT = argv[0]
PREVIEW = argv[1] if len(argv) > 1 else ""
R2 = len(argv) > 2 and argv[2] == "r2"   # round 2: deeper body colours, less-white wrappers
SUF = "_r2" if R2 else ""
C = {"good": "#2e8b3a" if R2 else "#4caf50", "good_wrap": "#9ccf8a" if R2 else "#d9f2c8", "great": "#1d4cc8" if R2 else "#2f63d6", "great_stripe": "#d2e0ff" if R2 else "#f2f5ff", "great_wrap": "#6f97f0" if R2 else "#bcd0ff"}

def lin(h):
    c = [int(h[i:i + 2], 16) / 255.0 for i in (1, 3, 5)]
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)

def mat(name, hexrgb, rough=0.35, metal=0.0):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*lin(hexrgb), 1)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    return m

def obj(name, bm, material, smooth=True):
    me = bpy.data.meshes.new(name); bm.to_mesh(me); me.materials.append(material)
    for p in me.polygons:
        p.use_smooth = smooth
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    return o

def fan_end(bm, x0, direction, r):
    # a twisted wrapper end: a cone flaring out with pleats
    seg = 12
    ring0 = []; ring1 = []
    for i in range(seg):
        a = i * math.tau / seg
        ring0.append(bm.verts.new(Vector((x0, math.cos(a) * r * 0.35, math.sin(a) * r * 0.35 + 0.5))))
        rr = r * (1.0 if i % 2 == 0 else 0.78)
        ring1.append(bm.verts.new(Vector((x0 + direction * r * 1.2, math.cos(a + 0.4) * rr, math.sin(a + 0.4) * rr + 0.5))))
    for i in range(seg):
        j = (i + 1) % seg
        bm.faces.new((ring0[i], ring0[j], ring1[j], ring1[i]) if direction > 0 else (ring0[j], ring0[i], ring1[i], ring1[j]))

def export(path, objs):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_yup=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
os.makedirs(OUT, exist_ok=True)
allobjs = []

# GOOD: wrapped oval sweet
bm = bmesh.new()
bmesh.ops.create_uvsphere(bm, u_segments=20, v_segments=12, radius=0.3)
for v in bm.verts:
    v.co.x *= 1.35; v.co.z = v.co.z * 0.95 + 0.5
body = obj("good_body", bm, mat("candy_good", C["good"]))
bm = bmesh.new(); fan_end(bm, 0.38, 1, 0.32); fan_end(bm, -0.38, -1, 0.32)
ends = obj("good_wrap", bm, mat("candy_good_wrap", C["good_wrap"], rough=0.5), smooth=False)
for o in (body, ends):
    o.location.x = -2.0
export(os.path.join(OUT, "candy_good%s.glb" % SUF), [body, ends]); allobjs += [body, ends]

# GREAT: striped twist (longer body, helix stripe), with wrapper ends
bm = bmesh.new()
bmesh.ops.create_uvsphere(bm, u_segments=24, v_segments=12, radius=0.3)
for v in bm.verts:
    v.co.x *= 1.9; v.co.z = v.co.z * 1.05 + 0.5
gbody = obj("great_body", bm, mat("candy_great", C["great"]))
bm = bmesh.new()
turns, steps = 4.0, 160
prev = None
for k in range(steps + 1):
    t = k / steps
    x = -0.52 + 1.04 * t
    half = math.sqrt(max(0.0, 1 - (x / 0.57) ** 2))
    a = t * turns * math.tau
    c = Vector((x, math.cos(a) * 0.315 * half, math.sin(a) * 0.33 * half + 0.5))
    ring = []
    for s in range(6):
        b = s * math.tau / 6
        ring.append(bm.verts.new(c + Vector((math.cos(b) * 0.045, 0, math.sin(b) * 0.045))))
    if prev:
        for s in range(6):
            q = (s + 1) % 6
            bm.faces.new((prev[s], prev[q], ring[q], ring[s]))
    prev = ring
stripe = obj("great_stripe", bm, mat("candy_great_stripe", C["great_stripe"], rough=0.4))
bm = bmesh.new(); fan_end(bm, 0.55, 1, 0.34); fan_end(bm, -0.55, -1, 0.34)
gwrap = obj("great_wrap", bm, mat("candy_great_wrap", C["great_wrap"], rough=0.5), smooth=False)
export(os.path.join(OUT, "candy_great%s.glb" % SUF), [gbody, stripe, gwrap]); allobjs += [gbody, stripe, gwrap]

# RARE: faceted gold gem-candy on a star wrapper
bm = bmesh.new()
# gem: 8-sided bipyramid with a crown table
seg = 8
top = bm.verts.new(Vector((0, 0, 1.0))); bot = bm.verts.new(Vector((0, 0, 0.18)))
girdle = [bm.verts.new(Vector((math.cos(i * math.tau / seg) * 0.36, math.sin(i * math.tau / seg) * 0.36, 0.55))) for i in range(seg)]
table = [bm.verts.new(Vector((math.cos((i + 0.5) * math.tau / seg) * 0.18, math.sin((i + 0.5) * math.tau / seg) * 0.18, 0.88))) for i in range(seg)]
for i in range(seg):
    j = (i + 1) % seg
    bm.faces.new((bot, girdle[j], girdle[i]))
    bm.faces.new((girdle[i], girdle[j], table[i]))
    bm.faces.new((table[i], girdle[j], table[j]))
    bm.faces.new((table[i], table[j], top))
gem = obj("rare_gem", bm, mat("candy_rare", "#f2b31c", rough=0.2, metal=0.3), smooth=False)
bm = bmesh.new()
pts = []
for i in range(10):
    a = i * math.tau / 10 + math.pi / 2
    r = 0.62 if i % 2 == 0 else 0.3
    pts.append(Vector((math.cos(a) * r, math.sin(a) * r, 0.2)))
centre_top = bm.verts.new(Vector((0, 0, 0.26)))
outer = [bm.verts.new(p) for p in pts]
under = [bm.verts.new(p - Vector((0, 0, 0.08))) for p in pts]
centre_bot = bm.verts.new(Vector((0, 0, 0.12)))
for i in range(10):
    j = (i + 1) % 10
    bm.faces.new((centre_top, outer[i], outer[j]))
    bm.faces.new((centre_bot, under[j], under[i]))
    bm.faces.new((outer[i], under[i], under[j], outer[j]))
star = obj("rare_star", bm, mat("candy_rare_wrap", "#7a3fbf", rough=0.45), smooth=False)
for o in (gem, star):
    o.location.x = 2.0
export(os.path.join(OUT, "candy_rare%s.glb" % SUF), [gem, star]); allobjs += [gem, star]
print("CANDY_OK", OUT)

if PREVIEW:
    sc = bpy.context.scene
    bpy.ops.mesh.primitive_plane_add(size=20)
    cd = bpy.data.cameras.new("c"); cd.lens = 40
    c = bpy.data.objects.new("c", cd); sc.collection.objects.link(c)
    c.location = (0, -6.5, 2.6); c.rotation_euler = (Vector((0, 0, 0.5)) - c.location).to_track_quat("-Z", "Y").to_euler()
    sc.camera = c
    s = bpy.data.lights.new("s", "SUN"); s.energy = 3
    so = bpy.data.objects.new("s", s); sc.collection.objects.link(so); so.rotation_euler = (0.7, 0.2, 0.6)
    w = bpy.data.worlds.new("w"); w.use_nodes = True; sc.world = w
    sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 24
    sc.render.resolution_x, sc.render.resolution_y = 960, 400
    sc.render.filepath = PREVIEW
    bpy.ops.render.render(write_still=True)
