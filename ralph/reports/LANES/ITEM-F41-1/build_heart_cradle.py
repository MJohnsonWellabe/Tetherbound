# F41#1 Stormheart heart cradle (LANE-SW, 7 Nov 2026, round 2). Blender 4.2 script.
# blender -b -P build_heart_cradle.py -- <out.glb> [preview.png]
# The trunk's visible core, built in the heart cleft (Godot angle 90 deg, the
# existing heart_cleft): a cluster of faceted crystal prisms (the lightning core,
# natural glow) cradled by braided heartwood roots that rise from the floor
# around it and climb the cleft into the seam. Tree-local metres; everything
# stays outside the 44 m hollow floor (r >= 44.6). Materials are named
# (cradle_bark, cradle_vein, core_crystal); Godot assigns the installed bark
# texture and the emissive colours at load (stormheart_tree.gd::_heart_cradle).
import bpy, bmesh, math, random, sys
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else "/tmp/stormheart_heart_cradle.glb"
PREVIEW = argv[1] if len(argv) > 1 else ""
ANGLE = math.pi / 2          # heart_cleft angle_deg 90
R_CORE = 49.0                # crystal base (the meshy crystal sat at 51)
R_MIN = 44.6                 # never inside the hollow floor's 44 m
rng = random.Random(11072)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

def mat(name, rgb, emit=None, strength=3.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*rgb, 1)
    b.inputs["Roughness"].default_value = 0.8
    if emit:
        b.inputs["Emission Color"].default_value = (*emit, 1)
        b.inputs["Emission Strength"].default_value = strength
    return m

M_BARK = mat("cradle_bark", (0.36, 0.27, 0.19))
M_VEIN = mat("cradle_vein", (0.6, 0.75, 1.0), emit=(0.62, 0.78, 1.0))
M_CRYS = mat("core_crystal", (0.55, 0.7, 1.0), emit=(0.66, 0.8, 1.0), strength=6.0)

def bl(a, r, z):
    return Vector((math.cos(a) * r, -math.sin(a) * r, z))

# local frame at the cleft: inward (toward the axis), tangent, up (Blender)
CENTRE = bl(ANGLE, R_CORE, 0.0)
INWARD = (-CENTRE).normalized()
TANGENT = Vector((0, 0, 1)).cross(INWARD).normalized()
UP = Vector((0, 0, 1))

def at(inward, tangent, z):
    return CENTRE + INWARD * inward + TANGENT * tangent + UP * z

def radius_of(p):
    return math.hypot(p.x, p.y)

def keep_out(p):
    r = radius_of(p)
    if r < R_MIN:
        p = p * (R_MIN / r)
        p.z = p.z
    return p

# ---- crystal cluster ----
crys = bmesh.new()
cuv = crys.loops.layers.uv.new("UVMap")

def prism(base, direction, length, radius, sides=6):
    d = direction.normalized()
    side = d.cross(Vector((0.3, 0.7, 0.1))).normalized()
    up = side.cross(d).normalized()
    rings = []
    for k, (t, s) in enumerate(((0.0, 0.85), (0.08, 1.0), (0.78, 1.0))):
        ring = []
        for i in range(sides):
            th = i * math.tau / sides + 0.3
            rr = radius * s * (1.0 + rng.uniform(-0.06, 0.06))
            ring.append(crys.verts.new(base + d * (length * t) + side * math.cos(th) * rr + up * math.sin(th) * rr))
        rings.append(ring)
    tip = crys.verts.new(base + d * length)
    for k in range(2):
        for i in range(sides):
            j = (i + 1) % sides
            f = crys.faces.new((rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i]))
            for loop, uv in zip(f.loops, ((i / sides, k), ((i + 1) / sides, k), ((i + 1) / sides, k + 1), (i / sides, k + 1))):
                loop[cuv].uv = uv
    for i in range(sides):
        j = (i + 1) % sides
        crys.faces.new((rings[2][i], rings[2][j], tip))
    crys.faces.new(list(reversed(rings[0])))

base_c = at(-0.5, 0.0, 1.2)
prism(base_c, UP * 1.0 + INWARD * 0.12, 15.0, 1.9)          # the heart
for i in range(10):
    ang = i * math.tau / 10 + rng.uniform(-0.2, 0.2)
    lean = rng.uniform(0.35, 0.8)
    d = UP + (INWARD * math.cos(ang) + TANGENT * math.sin(ang)) * lean
    if (INWARD * math.cos(ang)).dot(INWARD) > 0.6:
        d = UP + TANGENT * math.sin(ang) * lean + INWARD * 0.3   # don't spear toward the floor
    off = INWARD * math.cos(ang) * 1.2 + TANGENT * math.sin(ang) * 1.6
    prism(base_c + off, d, rng.uniform(5.0, 10.5), rng.uniform(0.7, 1.3))

# ---- braided roots ----
roots = bmesh.new()
ruv = roots.loops.layers.uv.new("UVMap")
veins = bmesh.new()
vuv = veins.loops.layers.uv.new("UVMap")

def tube(bm, uvl, pts, radii, sides=10, jag=0.1):
    rings, length, prev = [], 0.0, None
    for k, (p, rad) in enumerate(zip(pts, radii)):
        if prev is not None:
            length += (p - prev).length
        prev = p
        tdir = (pts[min(k + 1, len(pts) - 1)] - pts[max(k - 1, 0)]).normalized()
        ref = Vector((0, 0, 1)) if abs(tdir.z) < 0.9 else Vector((1, 0, 0))
        side = tdir.cross(ref).normalized()
        up = side.cross(tdir).normalized()
        ring = [bm.verts.new(p + (side * math.cos(s * math.tau / sides) + up * math.sin(s * math.tau / sides)) * rad * (1 + rng.uniform(-jag, jag))) for s in range(sides)]
        rings.append((ring, length))
    for k in range(len(rings) - 1):
        (a, la), (b, lb) = rings[k], rings[k + 1]
        for s in range(sides):
            t = (s + 1) % sides
            f = bm.faces.new((a[s], a[t], b[t], b[s]))
            for loop, uv in zip(f.loops, ((s / sides, la), ((s + 1) / sides, la), ((s + 1) / sides, lb), (s / sides, lb))):
                loop[uvl].uv = (uv[0] * 1.6, uv[1] / 3.5)

N_ROOTS = 9
for i in range(N_ROOTS):
    side_sign = -1 if i % 2 == 0 else 1
    spread = 3.0 + (i // 2) * 1.5
    phase = rng.uniform(0, math.tau)
    pts, radii = [], []
    n = 46
    for k in range(n + 1):
        t = k / n
        z = 0.2 + t * 46.0
        # start splayed on the floor around the crystal, hug it, then braid up the seam
        hug = math.exp(-((z - 9.0) / 9.0) ** 2)
        # around the crystal (hug) the roots part to the sides and behind it, leaving the core open to the hollow
        tangent = side_sign * (spread * (1.0 - hug) * (1.0 - t) ** 0.6 + (4.4 + 0.5 * (i // 2)) * hug + 0.7 * math.sin(phase + z * 0.25) * (1.0 - hug))
        inward = (1.6 - 4.0 * t) * (1.0 - hug) - 2.2 * hug - 0.5 * (i % 3)
        p = keep_out(at(inward, tangent, z))
        pts.append(p)
        radii.append(1.55 * (1.0 - t) ** 0.8 + 0.35)
    tube(roots, ruv, pts, radii)
    if i % 3 == 0:
        vp = [p + INWARD * (rad + 0.04) for p, rad in zip(pts, radii)][4:40]
        tube(veins, vuv, vp, [0.09] * len(vp), sides=5, jag=0.3)

objs = []
for bm, name, material in ((roots, "CradleRoots", M_BARK), (veins, "CradleVeins", M_VEIN), (crys, "CoreCrystal", M_CRYS)):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    m = bpy.data.meshes.new(name)
    bm.to_mesh(m)
    m.materials.append(material)
    o = bpy.data.objects.new(name, m)
    scene.collection.objects.link(o)
    if name != "CoreCrystal":
        for poly in m.polygons:
            poly.use_smooth = True
    objs.append(o)

bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", export_yup=True, export_materials="EXPORT")
vs = [o.matrix_world @ v.co for o in objs for v in o.data.vertices]
print("CRADLE_OK", OUT, "z", round(min(v.z for v in vs), 2), round(max(v.z for v in vs), 2), "min_r", round(min(math.hypot(v.x, v.y) for v in vs), 2))

if PREVIEW:
    bpy.ops.mesh.primitive_cylinder_add(radius=0.25, depth=1.8, location=tuple(at(5.5, 4.0, 0.9)))
    bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, 0))
    cam_data = bpy.data.cameras.new("cam"); cam_data.lens = 20
    cam = bpy.data.objects.new("cam", cam_data); scene.collection.objects.link(cam)
    cam.location = at(30.0, 0.0, 1.6)
    cam.rotation_euler = (at(0, 0, 12.0) - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    sun = bpy.data.lights.new("sun", "SUN"); sun.energy = 2.5
    so = bpy.data.objects.new("sun", sun); scene.collection.objects.link(so); so.rotation_euler = (0.8, 0.3, 0.6)
    world = bpy.data.worlds.new("w"); world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.5
    scene.world = world
    scene.render.engine = "CYCLES"; scene.cycles.device = "CPU"; scene.cycles.samples = 16
    scene.render.resolution_x, scene.render.resolution_y = 960, 540
    scene.render.filepath = PREVIEW
    bpy.ops.render.render(write_still=True)
    print("PREVIEW_OK", PREVIEW)
