# F41#9 Stormwood harvest nodes (LANE-SW, 7 Nov 2026). Blender 4.2 script.
# blender -b -P build_harvest_nodes.py -- <out dir> [preview dir]
# Three nodes, each about 1 m tall at authoring scale (the game fits height_m):
#   stormwood_stormglass_node.glb  violet storm-glass prisms with copper ore bands
#                                  in a dark basalt matrix (the named material reads:
#                                  storm glass, plus Stormwood's copper highlight)
#   stormwood_stormglass_crown.glb taller, spikier crown grade: more and longer
#                                  prisms, a copper collar
#   stormwood_glowmoss_mound.glb   a solid lumpy moss cushion with small
#                                  bioluminescent teal caps (no mushroom blob, no disc)
# Natural glow only (the glass and the fungi caps), kept low so it does not clip.
import bpy, bmesh, math, random, sys, os
from mathutils import Vector, noise

argv = sys.argv[sys.argv.index("--") + 1:]
OUT = argv[0]
PREVIEW = argv[1] if len(argv) > 1 else ""

def lin(hexrgb):
    # glTF colours are linear; Godot shows them as sRGB, so author from sRGB targets.
    c = [int(hexrgb[i:i + 2], 16) / 255.0 for i in (1, 3, 5)]
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)

def material(name, rgb, metallic=0.0, rough=0.8, emit=None, strength=0.0):
    rgb = lin(rgb) if isinstance(rgb, str) else rgb
    emit = lin(emit) if isinstance(emit, str) else emit
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*rgb, 1)
    b.inputs["Metallic"].default_value = metallic
    b.inputs["Roughness"].default_value = rough
    if emit:
        b.inputs["Emission Color"].default_value = (*emit, 1)
        b.inputs["Emission Strength"].default_value = strength
    return m

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def prism(bm, base, d, length, radius, sides=6, rng=None, tip=0.22):
    d = d.normalized()
    side = d.cross(Vector((0.31, 0.71, 0.13))).normalized(); up = side.cross(d).normalized()
    rings = []
    for t, s in ((0.0, 0.9), (1.0 - tip, 1.0)):
        rings.append([bm.verts.new(base + d * length * t + (side * math.cos(i * math.tau / sides + 0.2) + up * math.sin(i * math.tau / sides + 0.2)) * radius * s * (1 + rng.uniform(-0.07, 0.07))) for i in range(sides)])
    apex = bm.verts.new(base + d * length)
    faces = []
    for i in range(sides):
        j = (i + 1) % sides
        faces.append(bm.faces.new((rings[0][i], rings[0][j], rings[1][j], rings[1][i])))
        faces.append(bm.faces.new((rings[1][i], rings[1][j], apex)))
    faces.append(bm.faces.new(list(reversed(rings[0]))))
    return faces

def lump(bm, centre, r, squash, seed, detail=2.2, amp=0.3):
    res = bmesh.ops.create_icosphere(bm, subdivisions=3, radius=r)
    for v in res["verts"]:
        n = v.co.normalized()
        v.co = v.co * (1.0 + amp * noise.noise(n * detail + Vector((seed, seed * 0.3, 0))))
        v.co.z = max(v.co.z * squash, -0.02)
        v.co += centre
    return {f for v in res["verts"] for f in v.link_faces}

def export(objs_spec, path):
    for name, bm, mats, idx_faces in objs_spec:
        me = bpy.data.meshes.new(name); bm.to_mesh(me)
        for m in mats:
            me.materials.append(m)
        if name not in ("Glass",):
            for poly in me.polygons:
                poly.use_smooth = True
        o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_yup=True)

def preview(path, dist=3.2, h=0.9):
    if not PREVIEW:
        return
    sc = bpy.context.scene
    bpy.ops.mesh.primitive_cylinder_add(radius=0.12, depth=1.8, location=(0.9, 0.6, 0.9))  # 1.80 m trainer ruler
    bpy.ops.mesh.primitive_plane_add(size=20)
    cd = bpy.data.cameras.new("c"); cd.lens = 35
    c = bpy.data.objects.new("c", cd); sc.collection.objects.link(c)
    c.location = (dist * 0.7, -dist, h + 0.9); c.rotation_euler = (Vector((0.3, 0, h * 0.6)) - c.location).to_track_quat("-Z", "Y").to_euler()
    sc.camera = c
    s = bpy.data.lights.new("s", "SUN"); s.energy = 2.5
    so = bpy.data.objects.new("s", s); sc.collection.objects.link(so); so.rotation_euler = (0.8, 0.2, 0.7)
    w = bpy.data.worlds.new("w"); w.use_nodes = True
    w.node_tree.nodes["Background"].inputs["Color"].default_value = (0.42, 0.36, 0.6, 1)
    sc.world = w
    sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 24
    sc.render.resolution_x, sc.render.resolution_y = 640, 480
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)

def glass_node(path, crown, seed, prev):
    reset()
    rng = random.Random(seed)
    M_GLASS = material("storm_glass", "#6a54c4", rough=0.12, emit="#7a68e0", strength=0.35)
    M_COPPER = material("storm_copper", "#b8743c", metallic=0.6, rough=0.4)
    M_BASALT = material("storm_basalt", "#2a2a30", rough=0.9)
    bm_g = bmesh.new(); bm_c = bmesh.new(); bm_b = bmesh.new()
    # basalt matrix
    lump(bm_b, Vector((0, 0, 0.0)), 0.55 if not crown else 0.7, 0.45, seed, amp=0.35)
    for k in range(3):
        a = rng.uniform(0, math.tau)
        lump(bm_b, Vector((math.cos(a) * 0.45, math.sin(a) * 0.45, 0)), rng.uniform(0.2, 0.3), 0.5, seed + k)
    # glass prisms
    n = 7 if not crown else 13
    for i in range(n):
        if i == 0:
            d, L, r, base = Vector((0.05, 0.03, 1)), (0.95 if not crown else 1.0), 0.13, Vector((0, 0, 0.12))
        else:
            a = i * math.tau / (n - 1) + rng.uniform(-0.25, 0.25)
            lean = rng.uniform(0.25, 0.6) if not crown else rng.uniform(0.12, 0.45)
            d = Vector((math.cos(a) * lean, math.sin(a) * lean, 1))
            L = rng.uniform(0.35, 0.7) * (1.0 if not crown else 1.25)
            r = rng.uniform(0.05, 0.1)
            base = Vector((math.cos(a) * 0.18, math.sin(a) * 0.18, 0.1))
        if crown and i == 0:
            L = 1.0
        prism(bm_g, base, d, L, r, rng=rng)
        # copper band around each prism foot
        res = bmesh.ops.create_cone(bm_c, segments=8, radius1=r * 1.7, radius2=r * 1.35, depth=0.1 if not crown else 0.14, cap_ends=True)
        rot = Vector((0, 0, 1)).rotation_difference(d.normalized()).to_matrix()
        for v in res["verts"]:
            v.co = rot @ v.co + base + d.normalized() * 0.08
    # copper ore nuggets in the basalt
    # copper ore seams: knobbly nuggets sitting on the basalt surface
    R0 = 0.55 if not crown else 0.7
    for k in range(9 if not crown else 14):
        a = k * math.tau / (9 if not crown else 14) + rng.uniform(-0.2, 0.2); rr = rng.uniform(0.2, 0.75) * R0
        z = 0.45 * R0 * math.sqrt(max(0.0, 1 - (rr / (R0 * 1.15)) ** 2))
        lump(bm_c, Vector((math.cos(a) * rr, math.sin(a) * rr, z)), rng.uniform(0.07, 0.12), 0.7, seed + 40 + k, amp=0.45)
    export([("Glass", bm_g, [M_GLASS], None), ("Copper", bm_c, [M_COPPER], None), ("Basalt", bm_b, [M_BASALT], None)], path)
    preview(prev)

def moss_node(path, seed, prev):
    reset()
    rng = random.Random(seed)
    M_MOSS = material("glow_moss", "#2f5a2c", rough=0.95)
    M_MOSS_DK = material("glow_moss_dark", "#1f3f22", rough=0.95)
    M_CAP = material("glow_cap", "#3fae8f", rough=0.5, emit="#4fd3a8", strength=0.5)
    M_STEM = material("glow_stem", "#9aa596", rough=0.7)
    bm_m = bmesh.new(); bm_d = bmesh.new(); bm_c = bmesh.new(); bm_s = bmesh.new()
    lump(bm_m, Vector((0, 0, 0)), 0.6, 0.55, seed, detail=3.0, amp=0.28)
    for k in range(5):
        a = k * math.tau / 5 + rng.uniform(-0.3, 0.3)
        lump(bm_d if k % 2 else bm_m, Vector((math.cos(a) * 0.5, math.sin(a) * 0.5, 0)), rng.uniform(0.22, 0.34), 0.55, seed + k, detail=3.5, amp=0.3)
    # small bioluminescent caps growing from the cushion
    for k in range(9):
        a = rng.uniform(0, math.tau); rr = rng.uniform(0.1, 0.6)
        z0 = 0.33 * max(0.0, 1 - (rr / 0.75) ** 2) + 0.02
        h = rng.uniform(0.06, 0.16); cr = rng.uniform(0.04, 0.08)
        base = Vector((math.cos(a) * rr, math.sin(a) * rr, z0))
        st = bmesh.ops.create_cone(bm_s, segments=6, radius1=cr * 0.3, radius2=cr * 0.25, depth=h, cap_ends=True)
        for v in st["verts"]:
            v.co += base + Vector((0, 0, h / 2))
        cap = bmesh.ops.create_uvsphere(bm_c, u_segments=10, v_segments=6, radius=cr)
        for v in cap["verts"]:
            v.co.z = max(v.co.z, 0) * 0.55
            v.co += base + Vector((0, 0, h))
    export([("Moss", bm_m, [M_MOSS], None), ("MossDark", bm_d, [M_MOSS_DK], None), ("Caps", bm_c, [M_CAP], None), ("Stems", bm_s, [M_STEM], None)], path)
    preview(prev, dist=2.6, h=0.5)

os.makedirs(OUT, exist_ok=True)
P = lambda n: os.path.join(PREVIEW, n) if PREVIEW else ""
glass_node(os.path.join(OUT, "stormwood_stormglass_node.glb"), False, 9101, P("stormglass.png"))
glass_node(os.path.join(OUT, "stormwood_stormglass_crown.glb"), True, 9102, P("crown.png"))
moss_node(os.path.join(OUT, "stormwood_glowmoss_mound.glb"), 9103, P("glowmoss.png"))
print("HARVEST_OK", OUT)
