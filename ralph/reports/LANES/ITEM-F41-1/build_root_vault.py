# F41#1 Stormheart root vault (LANE-SW, 7 Nov 2026). Blender 4.2 script.
# blender -b -P build_root_vault.py -- <out.glb> [preview.png]
# Builds the underside of the OuterWorks deck (annulus r 18.3-44.6 m, top 5.92 m
# above the hollow floor, tree-local metres) as a living-root vault: a bark web
# whose grain runs along the roots, ~56 primary + 56 secondary gnarled roots that
# flare down into the outer wall, and thin vein strips on some roots (the trunk's
# own lightning, natural glow). No collider. Materials are named; Godot assigns
# the installed bark texture (Bark_TwistedTree) to "vault_bark" and an emissive
# blue-white to "vault_vein" at load (stormheart_tree.gd::_root_vault).
import bpy, bmesh, math, random, sys
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else "/tmp/stormheart_root_vault.glb"
PREVIEW = argv[1] if len(argv) > 1 else ""

R_IN, R_OUT, TOP = 18.3, 44.6, 5.92
FLAT_IN = 20.2          # keep r < this flat: lanterns hang from the lip at r 18.7
LOW_LIMIT = 4.7         # nothing hangs lower than this except wall flares
WALL_FLARE_BOTTOM = 0.0
# Godot-angle gaps (atan2(z, x)) of the trunk entrance splits: no wall flares there.
GAPS = [(-1.84 - 0.12, -1.30 + 0.12), (1.43 - 0.12, 1.71 + 0.12)]
rng = random.Random(1107)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

def mat(name, rgb, emit=None):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*rgb, 1)
    b.inputs["Roughness"].default_value = 0.85
    if emit:
        b.inputs["Emission Color"].default_value = (*emit, 1)
        b.inputs["Emission Strength"].default_value = 3.0
    return m

M_BARK = mat("vault_bark", (0.36, 0.27, 0.19))
M_VEIN = mat("vault_vein", (0.6, 0.75, 1.0), emit=(0.62, 0.78, 1.0))

def bl(godot_angle, r, z):
    # Godot (x, y, z) = (cos a r, z, sin a r); glTF export maps Blender (x, y, z) -> Godot (x, z, -y).
    return Vector((math.cos(godot_angle) * r, -math.sin(godot_angle) * r, z))

def in_gap(a):
    a = math.atan2(math.sin(a), math.cos(a))
    return any(lo <= a <= hi for lo, hi in GAPS)

def sag(a, r):
    if r < FLAT_IN:
        return 0.0
    t = (r - FLAT_IN) / (R_OUT - FLAT_IN)
    return 0.55 * math.sin(math.pi * t) * (0.6 + 0.4 * math.sin(a * 23.0 + r * 0.4))

# --- bark web (the ceiling skin), grain along r ---
web = bmesh.new()
uvl = web.loops.layers.uv.new("UVMap")
NA, NR = 360, 28
grid = []
for i in range(NA + 1):
    a = -math.pi + i * math.tau / NA
    row = []
    for j in range(NR + 1):
        r = R_IN + (R_OUT - R_IN) * j / NR
        row.append(web.verts.new(bl(a, r, TOP - 0.02 - sag(a, r))))
    grid.append(row)
for i in range(NA):
    for j in range(NR):
        f = web.faces.new((grid[i][j], grid[i][j + 1], grid[i + 1][j + 1], grid[i + 1][j]))
        for loop, (ii, jj) in zip(f.loops, ((i, j), (i, j + 1), (i + 1, j + 1), (i + 1, j))):
            a_mid = 31.0 * math.tau / NA * ii
            loop[uvl].uv = (a_mid / 3.5, (R_IN + (R_OUT - R_IN) * jj / NR) / 3.5)
bmesh.ops.reverse_faces(web, faces=web.faces[:])   # face down, toward the camera
me = bpy.data.meshes.new("vault_web")
web.to_mesh(me)
me.materials.append(M_BARK)
web_obj = bpy.data.objects.new("RootVaultWeb", me)
scene.collection.objects.link(web_obj)

# --- roots ---
roots = bmesh.new()
ruv = roots.loops.layers.uv.new("UVMap")
veins = bmesh.new()
vuv = veins.loops.layers.uv.new("UVMap")

def tube(bm, uvlayer, pts, radii, sides=9, jag=0.12):
    rings = []
    length = 0.0
    prev = None
    for k, (p, rad) in enumerate(zip(pts, radii)):
        if prev is not None:
            length += (p - prev).length
        prev = p
        tdir = (pts[min(k + 1, len(pts) - 1)] - pts[max(k - 1, 0)]).normalized()
        side = tdir.cross(Vector((0, 0, 1)))
        if side.length < 1e-3:
            side = Vector((1, 0, 0))
        side.normalize()
        up = side.cross(tdir).normalized()
        ring = []
        for s in range(sides + 1):
            th = s * math.tau / sides
            rr = rad * (1.0 + rng.uniform(-jag, jag)) if s < sides else None
            if s == sides:
                ring.append(ring[0])
                continue
            # slightly flattened against the ceiling: roots are pressed half into the web
            v = bm.verts.new(p + side * math.cos(th) * rr + up * math.sin(th) * rr * 0.8)
            ring.append(v)
        rings.append((ring, length))
    for k in range(len(rings) - 1):
        (a_ring, la), (b_ring, lb) = rings[k], rings[k + 1]
        for s in range(sides):
            f = bm.faces.new((a_ring[s], a_ring[s + 1], b_ring[s + 1], b_ring[s]))
            for loop, (u, v) in zip(f.loops, ((s / sides, la), ((s + 1) / sides, la), ((s + 1) / sides, lb), (s / sides, lb))):
                loop[uvlayer].uv = (u * 1.4, v / 3.5)

def root_path(a0, r0, r1, depth, wander, flare):
    pts, radii = [], []
    n = 34
    phase = rng.uniform(0, math.tau)
    for k in range(n + 1):
        t = k / n
        r = r0 + (r1 - r0) * t
        a = a0 + wander * math.sin(phase + t * 5.0) / r * 6.0 + 0.04 * t
        z = TOP - 0.15 - sag(a, r) * 0.6 - depth * math.sin(math.pi * min(1.0, t * 1.15)) * (0.0 if r < FLAT_IN else 1.0)
        rad = 0.28 + (0.95 - 0.28) * t ** 1.4
        # Never through the deck floor above: the top of the (flattened) tube stays under it.
        z = min(max(z, LOW_LIMIT), TOP - 0.04 - rad * 0.8 * 1.13)
        pts.append(bl(a, r, z))
        radii.append(rad)
    if flare:
        a_end = a0 + wander * math.sin(phase + 5.0) / r1 * 6.0 + 0.04
        z0 = pts[-1].z
        for k in range(1, 10):
            t = k / 9
            rad = 0.95 + 0.9 * t
            # The flare ends vertical, so its last ring is level and rests on the floor.
            z = z0 + (WALL_FLARE_BOTTOM + 0.02 - z0) * t
            pts.append(bl(a_end, r1 + 0.35 * t, z))
            radii.append(rad)
    return pts, radii

N = 56
vein_count = 0
for i in range(N):
    a0 = -math.pi + (i + rng.uniform(-0.25, 0.25)) * math.tau / N
    flare = not in_gap(a0)
    pts, radii = root_path(a0, rng.uniform(19.0, 23.0), R_OUT - 0.2, rng.uniform(0.35, 0.9), rng.uniform(0.3, 0.9), flare)
    tube(roots, ruv, pts, radii)
    # secondary root between primaries, thinner, no wall flare
    a1 = a0 + math.tau / N * 0.5 + rng.uniform(-0.05, 0.05)
    p2, r2 = root_path(a1, rng.uniform(24.0, 30.0), R_OUT - 0.6, rng.uniform(0.2, 0.5), rng.uniform(0.25, 0.7), False)
    tube(roots, ruv, p2, [x * 0.6 for x in r2], sides=7)
    if i % 4 == 1:
        # vein: thin strip along the underside of this root, from mid-span to the wall
        vp = [p - Vector((0, 0, rad * 0.8 + 0.03)) for p, rad in zip(pts, radii)][12:34]
        tube(veins, vuv, vp, [0.07] * len(vp), sides=5, jag=0.3)
        vein_count += 1

for bm, name, material in ((roots, "RootVaultRoots", M_BARK), (veins, "RootVaultVeins", M_VEIN)):
    m = bpy.data.meshes.new(name)
    bm.to_mesh(m)
    m.materials.append(material)
    o = bpy.data.objects.new(name, m)
    scene.collection.objects.link(o)
    for poly in m.polygons:
        poly.use_smooth = True

bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", export_yup=True, export_materials="EXPORT", export_normals=True)
zs = [v.co.z for o in scene.objects if o.type == 'MESH' for v in o.data.vertices]
print("ROOT_VAULT_OK", OUT, "veins", vein_count, "z", round(min(zs), 3), round(max(zs), 3))

if PREVIEW:
    # Scale check: a 1.80 m trainer capsule standing under the vault at r 30, camera at 1.6 m.
    bpy.ops.mesh.primitive_cylinder_add(radius=0.25, depth=1.8, location=tuple(bl(0.4, 30.0, 0.9)))
    bpy.data.objects[-1].name = "Trainer_1_80m"
    bpy.ops.mesh.primitive_plane_add(size=120, location=(0, 0, 0))
    cam_data = bpy.data.cameras.new("cam")
    cam_data.lens = 18
    cam = bpy.data.objects.new("cam", cam_data)
    scene.collection.objects.link(cam)
    cam.location = bl(0.4, 22.0, 1.6)
    target = bl(0.4, 34.0, 4.5)
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    sun = bpy.data.lights.new("sun", "SUN"); sun.energy = 2.0
    so = bpy.data.objects.new("sun", sun); scene.collection.objects.link(so); so.rotation_euler = (0.9, 0.2, 0.3)
    pt = bpy.data.lights.new("lamp", "POINT"); pt.energy = 4000
    po = bpy.data.objects.new("lamp", pt); scene.collection.objects.link(po); po.location = bl(0.4, 28.0, 3.0)
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 16
    world = bpy.data.worlds.new("w"); world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.6
    scene.world = world
    scene.render.resolution_x, scene.render.resolution_y = 960, 540
    scene.render.filepath = PREVIEW
    bpy.ops.render.render(write_still=True)
    print("PREVIEW_OK", PREVIEW)
