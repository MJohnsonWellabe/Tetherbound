# F41#1 Stormheart heartwood (LANE-BELOW6, 11 Nov 2026). Blender 4.2 script.
# blender -b -P build_heartwood.py -- <out.glb> [preview.png]
# The trunk's living core, standing ON THE HOLLOW'S AXIS where the player's
# camera looks: a faceted lightning core held in an open cage of braided
# heartwood roots that flare across the floor, climb together, and open above
# into an inner crown of limbs. Built around the origin in tree-local metres
# (Blender Z up); Godot places it at the hollow centre. Everything stays inside
# r 16 m above the floor, clear of the ascent ramp (r 22-30 m) and the
# OuterWorks deck (r 18-44 m). Materials are named (heartwood_bark,
# heartwood_vein, heartwood_core); Godot assigns the installed bark texture and
# the emissive colours at load (stormheart_tree.gd::_heartwood).
import bpy, bmesh, math, random, sys
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else "/tmp/stormheart_heartwood.glb"
PREVIEW = argv[1] if len(argv) > 1 else ""
rng = random.Random(11111)

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


M_BARK = mat("heartwood_bark", (0.36, 0.27, 0.19))
M_VEIN = mat("heartwood_vein", (0.6, 0.75, 1.0), emit=(0.62, 0.78, 1.0))
M_CORE = mat("heartwood_core", (0.55, 0.7, 1.0), emit=(0.66, 0.8, 1.0), strength=6.0)

roots = bmesh.new(); ruv = roots.loops.layers.uv.new("UVMap")
veins = bmesh.new(); vuv = veins.loops.layers.uv.new("UVMap")
core = bmesh.new(); cuv = core.loops.layers.uv.new("UVMap")


def pol(a, r, z):
    return Vector((math.cos(a) * r, math.sin(a) * r, z))


def tube(bm, uvl, pts, radii, sides=10, jag=0.1, cap=False):
    rings, length, prev = [], 0.0, None
    for k, (p, rad) in enumerate(zip(pts, radii)):
        if prev is not None:
            length += (p - prev).length
        prev = p
        tdir = (pts[min(k + 1, len(pts) - 1)] - pts[max(k - 1, 0)]).normalized()
        ref = Vector((0, 0, 1)) if abs(tdir.z) < 0.9 else Vector((1, 0, 0))
        side = tdir.cross(ref).normalized()
        up = side.cross(tdir).normalized()
        ring = [bm.verts.new(p + (side * math.cos(s * math.tau / sides) + up * math.sin(s * math.tau / sides))
                             * rad * (1 + rng.uniform(-jag, jag))) for s in range(sides)]
        rings.append((ring, length))
    for k in range(len(rings) - 1):
        (a, la), (b, lb) = rings[k], rings[k + 1]
        for s in range(sides):
            t = (s + 1) % sides
            f = bm.faces.new((a[s], a[t], b[t], b[s]))
            for loop, uv in zip(f.loops, ((s / sides, la), ((s + 1) / sides, la), ((s + 1) / sides, lb), (s / sides, lb))):
                loop[uvl].uv = (uv[0] * 1.6, uv[1] / 3.5)
    if cap:
        tip = bm.verts.new(pts[-1] + (pts[-1] - pts[-2]).normalized() * radii[-1] * 1.5)
        ring = rings[-1][0]
        for s in range(sides):
            bm.faces.new((ring[s], ring[(s + 1) % sides], tip))


# ---- the lightning core: a stack of faceted crystal segments on the axis ----
def core_segment(z0, z1, r0, r1, sides=6, twist=0.0):
    a = [core.verts.new(pol(i * math.tau / sides + twist, r0 * (1 + rng.uniform(-0.08, 0.08)), z0)) for i in range(sides)]
    b = [core.verts.new(pol(i * math.tau / sides + twist + 0.25, r1 * (1 + rng.uniform(-0.08, 0.08)), z1)) for i in range(sides)]
    for i in range(sides):
        j = (i + 1) % sides
        core.faces.new((a[i], a[j], b[j]))
        core.faces.new((a[i], b[j], b[i]))
    return b


z, twist = -0.5, 0.0
CORE_TOP = 96.0
while z < CORE_TOP:
    step = rng.uniform(3.5, 6.5)
    t = z / CORE_TOP
    r_lo = 1.75 * (1.0 - 0.55 * max(t, 0.0)) * rng.uniform(0.85, 1.1)
    r_hi = 1.75 * (1.0 - 0.55 * max(min((z + step) / CORE_TOP, 1.0), 0.0)) * rng.uniform(0.7, 1.0)
    core_segment(z, z + step, r_lo, r_hi, twist=twist)
    twist += 0.4
    z += step * 0.92
# shards leaning out of the base, between the roots
for i in range(7):
    a = i * math.tau / 7 + 0.22
    base = pol(a, 1.5, 0.0)
    d = (Vector((0, 0, 1)) + pol(a, 0.38, 0.0)).normalized()
    length, rad = rng.uniform(5.0, 9.5), rng.uniform(0.55, 0.9)
    side = d.cross(Vector((0.3, 0.7, 0.1))).normalized(); up = side.cross(d).normalized()
    ring0 = [core.verts.new(base + (side * math.cos(s * math.tau / 5) + up * math.sin(s * math.tau / 5)) * rad) for s in range(5)]
    ring1 = [core.verts.new(base + d * length * 0.75 + (side * math.cos(s * math.tau / 5) + up * math.sin(s * math.tau / 5)) * rad * 0.9) for s in range(5)]
    tip = core.verts.new(base + d * length)
    for s in range(5):
        t2 = (s + 1) % 5
        core.faces.new((ring0[s], ring0[t2], ring1[t2], ring1[s]))
        core.faces.new((ring1[s], ring1[t2], tip))

# jagged lightning filaments crawling up the crystal (vein material, bright)
for j in range(6):
    a0 = j * math.tau / 6 + 0.5
    pts = []
    zf = 0.3
    while zf < 46.0:
        t = zf / CORE_TOP
        rr = 1.75 * (1.0 - 0.55 * t) * 1.06 + 0.06
        pts.append(pol(a0 + rng.uniform(-0.35, 0.35) + zf * 0.05 * (1 if j % 2 else -1), rr, zf))
        zf += rng.uniform(0.9, 2.2)
    tube(veins, vuv, pts, [0.07] * len(pts), sides=4, jag=0.25)

# ---- braided heartwood roots: floor flare, climbing cage, inner crown ----
N = 6
CAGE_R = 3.7          # cage radius around the core (the core is 1.75 m)
for i in range(N):
    a0 = i * math.tau / N + rng.uniform(-0.12, 0.12)
    turn = 0.85 + rng.uniform(-0.15, 0.15)           # radians of spiral over the cage
    flare = rng.uniform(9.5, 13.0)
    peel = 30.0 + (i * 5) % 17 + rng.uniform(-2.0, 2.0)   # height where this root leaves the cage
    reach = rng.uniform(8.0, 11.0)                  # limb reach (inside the 18 m deck opening)
    top = peel + rng.uniform(24.0, 40.0)
    pts, radii = [], []
    n = 80
    for k in range(n + 1):
        t = k / n
        z = -0.9 + (top + 0.9) * t ** 1.7      # dense samples near the floor
        # floor flare: wide at the floor, pulled in to the cage by 7 m
        f = math.exp(-(z + 0.9) / 2.6)
        r = CAGE_R + (flare - CAGE_R) * f
        # cage: slight waist and wander
        r += 0.35 * math.sin(z * 0.21 + i)
        ang = a0 + turn * min(max(z, 0.0), peel) / peel + 0.10 * math.sin(z * 0.33 + i * 1.7)
        zz = z
        if z > peel:
            u = (z - peel) / (top - peel)
            r += reach * math.sin(u * math.pi * 0.5) ** 0.8          # sweep outward, then rise
            ang += 0.35 * u
            zz = peel + (z - peel) * (0.55 + 0.45 * u)
        pts.append(pol(ang, r, zz))
        rad = 1.0 * (1.0 - 0.45 * min(max(z, 0) / peel, 1.0))
        if z > peel:
            rad *= 1.0 - 0.72 * (z - peel) / (top - peel)
        radii.append(max(rad, 0.22))
    tube(roots, ruv, pts, radii, cap=True)
    if i % 2 == 0:
        vp = []
        for p, rad in list(zip(pts, radii))[14:66]:
            out = Vector((p.x, p.y, 0)).normalized()
            vp.append(p + out * (rad + 0.05))
        tube(veins, vuv, vp, [0.085] * len(vp), sides=5, jag=0.3)
    # a side branch off each limb
    if top - peel > 26:
        k0 = int(n * ((peel + (top - peel) * 0.45 + 0.9) / (top + 0.9)) ** (1 / 1.7))
        start = pts[k0]
        out = Vector((start.x, start.y, 0)).normalized()
        tang = Vector((-out.y, out.x, 0)) * (1 if i % 2 else -1)
        bp, br = [], []
        for k in range(15):
            u = k / 14
            bp.append(start + tang * (7.0 * u) + out * (2.0 * u) + Vector((0, 0, 9.0 * u ** 1.4)))
            br.append(radii[k0] * 0.7 * (1.0 - 0.7 * u))
        # keep the branch inside the deck opening
        bp = [p if math.hypot(p.x, p.y) < 16.0 else Vector((p.x, p.y, 0)).normalized() * 16.0 + Vector((0, 0, p.z)) for p in bp]
        tube(roots, ruv, bp, br, sides=8, cap=True)

# thinner counter-wound roots that tie the cage together (the braid)
for j in range(5):
    a0 = j * math.tau / 5 + 0.4
    pts, radii = [], []
    for k in range(60):
        t = k / 59
        z = -0.5 + t * 34.0
        r = CAGE_R + 0.55 + 2.2 * math.exp(-z / 2.0) + 0.3 * math.sin(z * 0.4 + j)
        pts.append(pol(a0 - 1.9 * t, r, z))
        radii.append(0.36 * (1.0 - 0.6 * t) + 0.1)
    tube(roots, ruv, pts, radii, sides=8, cap=True)

objs = []
for bm, name, material in ((roots, "HeartwoodRoots", M_BARK), (veins, "HeartwoodVeins", M_VEIN), (core, "HeartwoodCore", M_CORE)):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    m = bpy.data.meshes.new(name)
    bm.to_mesh(m)
    m.materials.append(material)
    o = bpy.data.objects.new(name, m)
    scene.collection.objects.link(o)
    if name != "HeartwoodCore":
        for poly in m.polygons:
            poly.use_smooth = True
    objs.append(o)

bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", export_yup=True, export_materials="EXPORT")
vs = [o.matrix_world @ v.co for o in objs for v in o.data.vertices]
above = [v for v in vs if v.z > 4.5]
print("HEARTWOOD_OK", OUT, "z", round(min(v.z for v in vs), 2), round(max(v.z for v in vs), 2),
      "max_r_all", round(max(math.hypot(v.x, v.y) for v in vs), 2),
      "max_r_above_4.5m", round(max(math.hypot(v.x, v.y) for v in above), 2),
      "tris", sum(len(o.data.polygons) for o in objs))

if PREVIEW:
    bpy.ops.mesh.primitive_cylinder_add(radius=0.25, depth=1.8, location=(6.5, -7.0, 0.9))
    bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, 0))
    cam_data = bpy.data.cameras.new("cam"); cam_data.lens = 18
    cam = bpy.data.objects.new("cam", cam_data); scene.collection.objects.link(cam)
    cam.location = (0.0, -26.0, 2.2)
    cam.rotation_euler = (Vector((0, 0, 11.0)) - cam.location).to_track_quat("-Z", "Y").to_euler()
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
