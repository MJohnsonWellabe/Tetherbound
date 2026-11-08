# F40#4 P2-023 (LANE-CR, 7 Nov 2026): sculpted strata cliff module (variant r3), from the
# F40#1 strata terrace script (variants r1/r2 kept for provenance).
# Run: blender -b -P strata_terrace.py -- <out.glb> <texture_dir> [seed] [length_m]
# New mesh built procedurally (no Meshy). Textures from strata_textures.py
# (strata_side_Color.png: horizontal pale strata bands; strata_top_Color.png: moss lip).
import bpy, bmesh, sys, math, random
from mathutils import Vector, noise

argv = sys.argv[sys.argv.index("--") + 1:]
out, tex = argv[0], argv[1]
seed = int(argv[2]) if len(argv) > 2 else 7
length = float(argv[3]) if len(argv) > 3 else 11.0
variant = argv[4] if len(argv) > 4 else "r1"
random.seed(seed)

bpy.ops.wm.read_factory_settings(use_empty=True)

def outline(cx, cy, rx, ry, n, rough, s):
    pts = []
    for i in range(n):
        a = 2 * math.pi * i / n
        # superellipse (squarish) so tiers read as shelves, not discs
        c, si = math.cos(a), math.sin(a)
        e = 0.35
        x = math.copysign(abs(c) ** e, c) * rx
        y = math.copysign(abs(si) ** e, si) * ry
        k = 1.0 + rough * noise.noise(Vector((x * 0.35 + s, y * 0.35, s * 0.7)))
        k += rough * 0.5 * noise.noise(Vector((x * 1.1, y * 1.1 + s, 3.0)))
        pts.append((cx + x * k, cy + y * k))
    return pts

def mat(name, factor, rough=0.9, image="strata_side_Color.png"):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    img = nt.nodes.new("ShaderNodeTexImage")
    img.image = bpy.data.images.load(tex + "/" + image)
    mix = nt.nodes.new("ShaderNodeMixRGB")
    mix.blend_type = "MULTIPLY"
    mix.inputs[0].default_value = 1.0
    mix.inputs[2].default_value = factor
    nt.links.new(img.outputs["Color"], mix.inputs[1])
    nt.links.new(mix.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = rough
    return m

# tier materials: warm cream, cool pale grey, buff; moss lip on tops
mats = [mat("strata_cream", (1.0, 1.0, 1.0, 1)), mat("strata_grey", (0.93, 0.94, 0.95, 1)),
        mat("strata_buff", (0.98, 0.95, 0.88, 1)), mat("strata_moss", (1.0, 1.0, 1.0, 1), 1.0, "strata_top_Color.png" if variant == "r1" else "strata_top_r2_Color.png")]

bm = bmesh.new()
tiers = [  # (half length, half depth, height, y offset back, roughness)
    (length * 0.5, 2.6, 0.75, 0.0, 0.10),
    (length * 0.42, 2.0, 0.65, 0.55, 0.12),
    (length * 0.30, 1.4, 0.55, 1.05, 0.14),
]
if variant == "r3":
    # F40#4 r3: cliff module to replace the straight-walled cliff_shelf mesas. Many thin
    # strata, each with a small random inset or overhang, an uneven stepped top, and a
    # slumped end so neither the walls nor the top edge read as one extrusion.
    tiers = []
    hx, hy, back = length * 0.5, length * 0.22, 0.0
    for k in range(9):
        h = random.uniform(0.6, 1.3)
        tiers.append((hx, hy, h, back, 0.16 + 0.02 * k))
        d = random.uniform(-0.25, 0.55)  # negative = overhang
        hx = max(length * 0.18, hx - d * 1.6 - (length * 0.05 if k >= 6 else 0.0))
        hy = max(1.2, hy - d)
        back += random.uniform(-0.3, 0.3)
if variant == "r2":
    # r2 (judges r1: "stone staircases / flat slabs pasted on the grass"): a raised
    # landform instead of steps -- four uneven, rougher tiers that climb to one side,
    # deeper footprint, taller faces, offsets that do not stack symmetrically.
    tiers = [
        (length * 0.5, 4.2, 1.4, 0.0, 0.22),
        (length * 0.40, 3.4, 1.2, 0.9, 0.26),
        (length * 0.27, 2.6, 1.5, 2.1, 0.28),
        (length * 0.15, 1.6, 1.1, 2.6, 0.30),
    ]
z = -0.6  # bottom tier starts below ground so it seats into the lawn
for t, (hx, hy, h, back, rough) in enumerate(tiers):
    shift = random.uniform(-0.6, 0.6) if variant == "r1" else random.uniform(-0.8, 0.8) if variant == "r3" else length * (0.04 * t + random.uniform(-0.05, 0.05))
    pts = outline(shift, back, hx, hy, 40, rough, seed * 3.1 + t)
    bot = [bm.verts.new((x, y, z)) for x, y in pts]
    # top edge slightly inset and wobbled: chipped, eroded lip
    top = []
    for i, (x, y) in enumerate(pts):
        d = Vector((x - shift, y - back, 0)).normalized()
        chip = 0.08 + 0.18 * max(0.0, noise.noise(Vector((x * 0.9, y * 0.9, t + seed))))
        dz = 0.10 * noise.noise(Vector((x * 0.5, y * 0.5, 5.0 + t)))
        top.append(bm.verts.new((x - d.x * chip, y - d.y * chip, z + h + (0.6 if t == 0 else 0.0) + dz)))
    n = len(pts)
    uv = bm.loops.layers.uv.verify()
    arc = [0.0]
    for i in range(n):
        arc.append(arc[-1] + (Vector(pts[(i + 1) % n]) - Vector(pts[i])).length)
    for i in range(n):
        f = bm.faces.new((bot[i], bot[(i + 1) % n], top[(i + 1) % n], top[i]))
        f.material_index = t % 3
        for loop, a in zip(f.loops, (arc[i], arc[i + 1], arc[i + 1], arc[i])):
            loop[uv].uv = (a / 6.0, loop.vert.co.z / 3.0 + t * 0.37)
    ft = bm.faces.new(top)
    ft.material_index = 3
    for loop in ft.loops:
        loop[uv].uv = (loop.vert.co.x / 6.0, loop.vert.co.y / 6.0)
    z = z + h + (0.6 if t == 0 else 0.0) - 0.05

bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
me = bpy.data.meshes.new("strata_terrace")
bm.to_mesh(me)
ob = bpy.data.objects.new("strata_terrace", me)
bpy.context.scene.collection.objects.link(ob)
for m in mats:
    me.materials.append(m)
bpy.context.view_layer.objects.active = ob
ob.select_set(True)
# horizontal strata bands: subdivide sides, then a light noise displace
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.quads_convert_to_tris()
bpy.ops.mesh.tris_convert_to_quads()
bpy.ops.mesh.subdivide(number_cuts=2)
bpy.ops.object.mode_set(mode="OBJECT")
tx = bpy.data.textures.new("strata_noise", "CLOUDS")
tx.noise_scale = 0.8
d = ob.modifiers.new("disp", "DISPLACE")
d.texture = tx
d.strength = 0.4
d.mid_level = 0.5
b = ob.modifiers.new("bevel", "BEVEL")
b.width = 0.05
b.segments = 1
bpy.ops.object.modifier_apply(modifier="disp")
bpy.ops.object.modifier_apply(modifier="bevel")
bpy.ops.object.shade_smooth_by_angle(angle=math.radians(40))
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=True, export_apply=True)
print("STRATA_TERRACE", out, "verts", len(me.vertices), "dims", tuple(round(v, 2) for v in ob.dimensions))
