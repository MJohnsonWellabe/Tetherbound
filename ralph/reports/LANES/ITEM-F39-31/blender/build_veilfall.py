"""Blender 4.2 build of a tiered, tree-dressed Veilfall (F39#31/#2, LANE-TW, 7 Nov 2026).
blender -b -P build_veilfall.py -- <texture_dir> <out.glb>
Authored in metres, Blender Z up, front (falls) facing -Y (glTF +Z). No installed or Meshy mesh
is used: tiers, crags, tree clumps, falls and mist are procedural from this script."""
import bpy, bmesh, math, random, sys
from mathutils import Vector, noise
from mathutils.bvhtree import BVHTree
argv = sys.argv[sys.argv.index("--") + 1:]
TEX, OUT = argv[0], argv[1]
random.seed(1107)
bpy.ops.wm.read_factory_settings(use_empty=True)

def material(name, tex, rough=0.85):
    m = bpy.data.materials.new(name); m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    img = m.node_tree.nodes.new("ShaderNodeTexImage")
    img.image = bpy.data.images.load(f"{TEX}/{tex}.png")
    m.node_tree.links.new(img.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = rough
    return m
MATS = {k: material("veilfall_" + k, "veilfall_" + k) for k in ("rock", "moss", "foliage", "water", "foam")}
ORDER = ["rock", "moss", "foliage", "water", "foam"]
bm = bmesh.new(); uv = bm.loops.layers.uv.new("UVMap")

def face(verts, mat, uvs):
    f = bm.faces.new(verts); f.material_index = ORDER.index(mat)
    for loop, t in zip(f.loops, uvs):
        loop[uv].uv = t
    return f

def radius_fn(r, cx, cy, seed, rib=0.11, lump=0.30):
    def fn(a, z):
        p = Vector((math.cos(a) * 1.8, math.sin(a) * 1.8, z / 220.0 + seed))
        l = noise.noise(p) * lump
        # columnar ribs: high-frequency in angle, slow in height
        q = Vector((math.cos(a) * 22.0, math.sin(a) * 22.0, z / 400.0 + seed * 2))
        k = noise.noise(q) * rib
        bays = 0.07 * math.sin(3.0 * a + seed) + 0.05 * math.sin(7.0 * a + seed * 1.3)
        return r * (1.0 + l + k + bays)
    return fn

def tier(cx, cy, r0, r1, z0, z1, seed, seg=128, rings=14, cap="moss"):
    """Cliff wall from z0 (radius r0) to z1 (radius r1), then a domed turf cap."""
    f0 = radius_fn(1.0, cx, cy, seed)
    grid = []
    for i in range(rings + 1):
        t = i / rings; z = z0 + (z1 - z0) * t
        # slight overhang/bulge in the middle third, strata steps
        r = r0 + (r1 - r0) * t ** 0.8
        r *= 1.0 + 0.03 * math.sin(t * math.pi * 3.0 + seed)
        row = []
        for j in range(seg):
            a = 2 * math.pi * j / seg
            rr = r * f0(a, z)
            zz = z + (z1 - z0) * 0.45 * t ** 1.5 * noise.noise(Vector((math.cos(a) * 2.5, math.sin(a) * 2.5, seed + 5.0)))
            row.append(bm.verts.new((cx + math.cos(a) * rr, cy + math.sin(a) * rr, zz)))
        grid.append(row)
    circ = 2 * math.pi * (r0 + r1) * 0.5
    for i in range(rings):
        for j in range(seg):
            j2 = (j + 1) % seg
            u0 = j / seg * circ / 90.0; u1 = (j + 1) / seg * circ / 90.0
            v0 = grid[i][j].co.z / 90.0; v1 = grid[i + 1][j].co.z / 90.0
            face([grid[i][j], grid[i][j2], grid[i + 1][j2], grid[i + 1][j]], "rock",
                 [(u0, v0), (u1, v0), (u1, v1), (u0, v1)])
    # cap: two inner rings rising into a gentle dome, so ledges read green from below
    top = grid[-1]; prev = top
    for k, (frac, lift) in enumerate(((0.82, 6.0), (0.45, 14.0))):
        ring = []
        for j, v in enumerate(top):
            d = Vector((v.co.x - cx, v.co.y - cy, 0.0)) * frac
            jitter = noise.noise(Vector((v.co.x / 40.0, v.co.y / 40.0, seed))) * 4.0
            ring.append(bm.verts.new((cx + d.x, cy + d.y, v.co.z + lift + jitter)))
        for j in range(seg):
            j2 = (j + 1) % seg
            vs = [prev[j], prev[j2], ring[j2], ring[j]]
            face(vs, cap, [(w.co.x / 60.0, w.co.y / 60.0) for w in vs])
        prev = ring
    c = bm.verts.new((cx, cy, sum(v.co.z for v in prev) / len(prev) + 6.0))
    for j in range(seg):
        vs = [prev[j], prev[(j + 1) % seg], c]
        face(vs, cap, [(w.co.x / 60.0, w.co.y / 60.0) for w in vs])
    return f0

def blob(centre, sx, sy, sz, mat, subdiv=2):
    res = bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=1.0)
    vs = res["verts"]
    for v in vs:
        n = noise.noise(v.co * 1.7 + Vector(centre) * 0.01) * 0.18
        v.co = Vector((centre[0] + v.co.x * sx * (1 + n), centre[1] + v.co.y * sy * (1 + n), centre[2] + v.co.z * sz * (1 + n)))
    fs = {f for v in vs for f in v.link_faces}
    for f in fs:
        f.material_index = ORDER.index(mat); f.smooth = True
        for loop in f.loops:
            loop[uv].uv = (loop.vert.co.x / 30.0, loop.vert.co.z / 30.0)

# ---- tiers: (centre_y shift back as we climb so the front shows ledges)
TIERS = [  # cx, cy, r_bottom, r_top, z0, z1
    (0.0, 0.0, 400.0, 360.0, -10.0, 150.0),
    (-10.0, 40.0, 300.0, 268.0, 140.0, 300.0),
    (15.0, 80.0, 215.0, 185.0, 290.0, 440.0),
    (0.0, 110.0, 135.0, 105.0, 430.0, 585.0),
]
rfns = []
for k, t in enumerate(TIERS):
    rfns.append(tier(*t, seed=11.0 + k * 3.7))

# ---- flank crags / pinnacles with green caps (board: rocky spires around the massif)
CRAGS = [(-330, -90, 70, 50, 0, 210), (345, -40, 62, 44, 0, 240), (-250, 200, 80, 55, 120, 380),
         (260, 170, 75, 50, 130, 400), (-150, -250, 55, 38, 0, 165), (190, -230, 48, 34, 0, 140),
         (-60, 260, 70, 45, 280, 520), (110, 240, 60, 40, 300, 540)]
for k, (x, y, r0, r1, z0, z1) in enumerate(CRAGS):
    tier(x, y, r0, r1, z0, z1, seed=40.0 + k * 2.3, seg=40, rings=10)

# ---- jagged pinnacles: thin crags rising off the ledges and summit (round 2: break the ziggurat)
bm.normal_update()
_bvh0 = BVHTree.FromBMesh(bm)
for k, (cx, cy, r0, r1, z0, z1) in enumerate(TIERS):
    for _ in range(9 + 3 * k):
        a = random.uniform(0, 2 * math.pi); rr = r1 * random.uniform(0.55, 0.9)
        x, y = cx + math.cos(a) * rr, cy + math.sin(a) * rr
        hit = _bvh0.ray_cast(Vector((x, y, 2000.0)), Vector((0, 0, -1)))
        if hit[0] is None:
            continue
        base = hit[0].z - 10.0; h = random.uniform(40, 105) * (1.25 if k == len(TIERS) - 1 else 1.0)
        rad = random.uniform(16, 34)
        tier(x, y, rad, rad * random.uniform(0.5, 0.7), base, base + h, seed=70.0 + k * 9 + _ * 0.7, seg=24, rings=8)
# ---- tree clumps on every ledge annulus and crag cap, seated by raycast on the built rock
bm.verts.ensure_lookup_table(); bm.faces.ensure_lookup_table()
bm.normal_update()
BVH = BVHTree.FromBMesh(bm)
def seat(x, y):
    hit = BVH.ray_cast(Vector((x, y, 2000.0)), Vector((0, 0, -1)))
    if hit[0] is None or abs(hit[1].z) < 0.3:  # only on upward-facing turf
        return None
    return hit[0].z

def ledge_points(cx, cy, rf, r_out, r_in, z, n, front_bias=0.6):
    pts = []
    for _ in range(n):
        a = random.uniform(0, 2 * math.pi)
        if random.random() < front_bias:  # favour the visible (south, -Y) faces
            a = -math.pi / 2 + random.gauss(0, 0.9)
        rr = random.uniform(r_in, r_out * 0.97)
        pts.append((cx + math.cos(a) * rr * rf(a, z) , cy + math.sin(a) * rr * rf(a, z), z))
    return pts
FRONT = -math.pi / 2
FALL_BANDS = [(FRONT, 0.26), (FRONT - 0.55, 0.18), (FRONT + 0.62, 0.17), (FRONT + 0.48, 0.18), (FRONT - 0.50, 0.17)]
def in_fall(a):
    return any(abs((a - c + math.pi) % (2 * math.pi) - math.pi) < hw for c, hw in FALL_BANDS)
trees = 0
for k, (cx, cy, r0, r1, z0, z1) in enumerate(TIERS):
    inner = TIERS[k + 1][3] * 0.9 if k + 1 < len(TIERS) else 0.0
    inner_r = TIERS[k + 1][2] if k + 1 < len(TIERS) else 20.0
    for (x, y, z) in ledge_points(cx, cy, rfns[k], r1, max(inner_r * 0.95, r1 * 0.35), z1 + 4.0, 260 - k * 40):
        z = seat(x, y)
        if z is None:
            continue
        h = random.uniform(16, 30)
        blob((x, y, z + h * 0.45), h * 0.42, h * 0.42, h * 0.62, "foliage", 1)
        trees += 1
    # trees hanging on the cliff face ledges (strata steps), front only
    for _ in range(110 - k * 20):
        a = -math.pi / 2 + random.gauss(0, 0.75); z = random.uniform(z0 + 20, z1 - 15)
        if in_fall(a):
            continue
        t = (z - z0) / (z1 - z0); r = (r0 + (r1 - r0) * t ** 0.8) * rfns[k](a, z) + 5.0
        h = random.uniform(10, 18)
        blob((cx + math.cos(a) * r, cy + math.sin(a) * r, z), h * 0.5, h * 0.5, h * 0.42, "foliage", 1)
        trees += 1
# rim groves: a dense band of canopy along each tier lip so ledges read green from sea level
for k, (cx, cy, r0, r1, z0, z1) in enumerate(TIERS):
    for _ in range(150 - k * 25):
        a = FRONT + random.uniform(-1.9, 1.9)
        if in_fall(a):
            continue
        rr = r1 * rfns[k](a, z1) * random.uniform(0.88, 0.99)
        x, y = cx + math.cos(a) * rr, cy + math.sin(a) * rr
        z = seat(x, y)
        if z is None:
            continue
        h = random.uniform(14, 26)
        blob((x, y, z + h * 0.4), h * 0.45, h * 0.45, h * 0.6, "foliage", 1)
        trees += 1
for (x, y, r0, r1, z0, z1) in CRAGS:
    for _ in range(9):
        a = random.uniform(0, 2 * math.pi); rr = random.uniform(0.1, 0.8) * r1; h = random.uniform(12, 22)
        zs = seat(x + math.cos(a) * rr, y + math.sin(a) * rr)
        if zs is None:
            continue
        blob((x + math.cos(a) * rr, y + math.sin(a) * rr, zs + h * 0.45), h * 0.42, h * 0.42, h * 0.6, "foliage", 1)
        trees += 1

# ---- falls: ribbons hugging each tier's front, plus plunge mist
def fall(k, a, w_top, w_bot, z_top=None, z_bot=None, steps=16):
    cx, cy, r0, r1, z0, z1 = TIERS[k]
    zt = z_top if z_top is not None else z1 + 6.0
    zb = z_bot if z_bot is not None else z0 - 4.0
    rows = []
    for i in range(steps + 1):
        t = i / steps; z = zt + (zb - zt) * t
        tt = min(1.0, max(0.0, (z - z0) / (z1 - z0)))
        w = w_top + (w_bot - w_top) * t
        w *= 1.0 + 0.22 * noise.noise(Vector((a * 7.0, z / 35.0, k * 3.1)))  # ragged, breaking edges
        row = []
        for s in (-1.0, -0.5, 0.0, 0.5, 1.0):
            aa = a + s * (w * 0.5) / max(r1, 1.0)
            r = (r0 + (r1 - r0) * tt ** 0.8) * max(rfns[k](a + d, z) for d in (-0.08, -0.04, 0.0, 0.04, 0.08)) + 9.0 + 6.0 * t + 3.0 * (1 - abs(s))
            row.append(bm.verts.new((cx + math.cos(aa) * r, cy + math.sin(aa) * r, z)))
        rows.append(row)
    for i in range(steps):
        for s in range(4):
            vs = [rows[i][s], rows[i][s + 1], rows[i + 1][s + 1], rows[i + 1][s]]
            u0, u1 = s / 4 * w_top / 60.0, (s + 1) / 4 * w_top / 60.0
            v0, v1 = i / steps * (zt - zb) / 60.0, (i + 1) / steps * (zt - zb) / 60.0
            f = face(vs, "water", [(u0, v0), (u1, v0), (u1, v1), (u0, v1)])
            f.normal_update()
            if f.normal.dot(Vector((math.cos(a), math.sin(a), 0))) < 0:
                f.normal_flip()
    # plunge mist: soft white puffs at the fall foot
    foot = rows[-1][2].co
    for _ in range(9):
        r = random.uniform(0.12, 0.22) * w_bot
        off = Vector((random.uniform(-0.7, 0.7) * w_bot, random.uniform(-0.1, 0.4) * w_bot, random.uniform(0, 18)))
        o = foot + off + Vector((math.cos(a), math.sin(a), 0)) * r * 0.4
        blob((o.x, o.y, o.z), r, r * 0.7, r * 0.28, "foam", 2)

# main stepped cascade down the centre of every tier
for k, w in enumerate((150, 120, 95, 70)):
    fall(k, FRONT + 0.03 * k, w * 0.75, w)
# side veils
fall(0, FRONT - 0.55, 70, 100); fall(0, FRONT + 0.62, 60, 90)
fall(1, FRONT + 0.48, 50, 75); fall(2, FRONT - 0.50, 42, 62)
# sea foam skirt along the front shore
for _ in range(14):
    a = FRONT + random.gauss(0, 0.7); r = 400 * rfns[0](a, 0.0) + random.uniform(0, 15)
    s = random.uniform(12, 26)
    blob((math.cos(a) * r, math.sin(a) * r, 0.5), s, s * 0.6, s * 0.12, "foam", 1)

me = bpy.data.meshes.new("VeilfallTiered"); bm.normal_update(); bm.to_mesh(me); bm.free()
for k in ORDER:
    me.materials.append(MATS[k])
ob = bpy.data.objects.new("VeilfallTiered", me); bpy.context.collection.objects.link(ob)
print("VEILFALL verts", len(me.vertices), "faces", len(me.polygons), "tree clumps", trees,
      "bbox", [round(v, 1) for v in ob.dimensions])
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", export_apply=True, export_yup=True)
