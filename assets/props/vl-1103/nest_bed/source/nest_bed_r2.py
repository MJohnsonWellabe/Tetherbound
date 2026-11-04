# Tidewake creature nest bed (P2-115). Procedural build + texture bake + GLB export.
# Run: blender -b -P nest_bed.py -- <out.glb> <preview.png>
import bpy, bmesh, math, random, sys
from mathutils import Vector, Matrix
argv = sys.argv[sys.argv.index('--')+1:]
OUT, PREVIEW = argv[0], argv[1]
random.seed(1031)
bpy.ops.wm.read_factory_settings(use_empty=True)
scn = bpy.context.scene
R_OUT = 2.3          # outer radius (4.6 m across, matches the camp bed rim span)
RIM_H = 0.82         # rim crest height: reads edge-on, below a 1.8 m trainer's hip

def mat(name, build):
    m = bpy.data.materials.new(name); m.use_nodes = True
    nt = m.node_tree; nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial'); bsdf = nt.nodes.new('ShaderNodeBsdfPrincipled')
    nt.links.new(bsdf.outputs[0], out.inputs[0]); build(nt, bsdf); return m

def ramp(nt, src, stops):
    r = nt.nodes.new('ShaderNodeValToRGB'); e = r.color_ramp
    e.elements[0].position, e.elements[0].color = stops[0][0], (*stops[0][1], 1)
    e.elements[1].position, e.elements[1].color = stops[-1][0], (*stops[-1][1], 1)
    for p, c in stops[1:-1]:
        el = e.elements.new(p); el.color = (*c, 1)
    nt.links.new(src, r.inputs[0]); return r

def wood(nt, b):   # weathered driftwood: grey-tan with grain
    tc = nt.nodes.new('ShaderNodeTexCoord'); w = nt.nodes.new('ShaderNodeTexWave'); w.wave_type='BANDS'
    w.inputs['Scale'].default_value = 9.0; w.inputs['Distortion'].default_value = 3.0; w.inputs['Detail'].default_value = 4
    nt.links.new(tc.outputs['Object'], w.inputs['Vector'])
    r = ramp(nt, w.outputs['Fac'], [(0.0,(0.04,0.025,0.015)),(0.45,(0.09,0.06,0.035)),(1.0,(0.20,0.15,0.10))])
    nt.links.new(r.outputs[0], b.inputs['Base Color']); b.inputs['Roughness'].default_value = 0.85

def straw(nt, b):  # sea-grass straw: golden with green-grey streaks
    tc = nt.nodes.new('ShaderNodeTexCoord'); n = nt.nodes.new('ShaderNodeTexNoise')
    n.inputs['Scale'].default_value = 14.0; n.inputs['Detail'].default_value = 8
    mp = nt.nodes.new('ShaderNodeMapping'); mp.inputs['Scale'].default_value = (1, 1, 8)
    nt.links.new(tc.outputs['Object'], mp.inputs['Vector']); nt.links.new(mp.outputs[0], n.inputs['Vector'])
    r = ramp(nt, n.outputs['Fac'], [(0.25,(0.16,0.10,0.03)),(0.5,(0.36,0.24,0.07)),(0.75,(0.52,0.38,0.13))])
    nt.links.new(r.outputs[0], b.inputs['Base Color']); b.inputs['Roughness'].default_value = 0.9

def canvas(nt, b): # cream sailcloth cushion with soft weave mottling
    tc = nt.nodes.new('ShaderNodeTexCoord'); n = nt.nodes.new('ShaderNodeTexNoise'); n.inputs['Scale'].default_value = 5
    nt.links.new(tc.outputs['Object'], n.inputs['Vector'])
    r = ramp(nt, n.outputs['Fac'], [(0.3,(0.28,0.21,0.13)),(0.7,(0.42,0.34,0.22))])
    nt.links.new(r.outputs[0], b.inputs['Base Color']); b.inputs['Roughness'].default_value = 0.95

def blanket(nt, b): # sea-teal wool blanket with a pale woven stripe (no red)
    tc = nt.nodes.new('ShaderNodeTexCoord'); w = nt.nodes.new('ShaderNodeTexWave'); w.inputs['Scale'].default_value = 0.8
    w.inputs['Distortion'].default_value = 0.4
    nt.links.new(tc.outputs['Object'], w.inputs['Vector'])
    r = ramp(nt, w.outputs['Fac'], [(0.0,(0.015,0.07,0.09)),(0.90,(0.03,0.12,0.15)),(0.93,(0.45,0.38,0.24)),(1.0,(0.45,0.38,0.24))])
    nt.links.new(r.outputs[0], b.inputs['Base Color']); b.inputs['Roughness'].default_value = 0.92

M_WOOD, M_STRAW, M_CANVAS, M_BLANKET = mat('nest_wood', wood), mat('nest_straw', straw), mat('nest_canvas', canvas), mat('nest_blanket', blanket)

def link(o, m):
    o.data.materials.append(m); return o

def tube_along(points, radius, name, m, sides=8):
    cu = bpy.data.curves.new(name, 'CURVE'); cu.dimensions = '3D'; cu.bevel_depth = radius; cu.bevel_resolution = 3 if m is M_WOOD else 1; cu.resolution_u = 8 if m is M_WOOD else 4
    sp = cu.splines.new('NURBS'); sp.points.add(len(points)-1)
    for p, co in zip(sp.points, points): p.co = (*co, 1)
    sp.use_endpoint_u = True; sp.order_u = 4
    o = bpy.data.objects.new(name, cu); scn.collection.objects.link(o); link(o, m)
    return o

parts = []
# 1. woven rim: many twisted reed/branch strands spiralling around a torus core
core = bpy.ops.mesh.primitive_torus_add(major_radius=R_OUT-0.42, minor_radius=0.42, major_segments=64, minor_segments=12,
                                         location=(0, 0, RIM_H-0.42))
core = bpy.context.object; core.name = 'rim_core'; core.scale = (1, 1, 0.85); link(core, M_STRAW); parts.append(core)
for s in range(22):
    ph = s * 2 * math.pi / 22; pts = []
    turns = 5 + (s % 3)
    for i in range(0, 97):
        t = i / 96 * 2 * math.pi
        a = ph + turns * t
        rr = (R_OUT-0.42) + 0.40 * math.cos(a)
        z = (RIM_H-0.42) + 0.35 * math.sin(a) + random.uniform(-0.01, 0.01)
        pts.append((rr*math.cos(t), rr*math.sin(t), z))
    parts.append(tube_along(pts, 0.035 + 0.015*random.random(), f'reed{s}', M_STRAW))
# 2. driftwood branches lashed around the outside (break the ring regularity)
for k in range(9):
    t0 = k * 2*math.pi/9 + random.uniform(-0.2, 0.2); span = random.uniform(0.7, 1.1)
    pts = []
    for i in range(7):
        t = t0 + span * i / 6
        rr = R_OUT - 0.06 + random.uniform(-0.05, 0.05)
        z = 0.16 + 0.42*math.sin(math.pi*i/6) + random.uniform(-0.04, 0.04)
        pts.append((rr*math.cos(t), rr*math.sin(t), z))
    parts.append(tube_along(pts, random.uniform(0.10, 0.14), f'drift{k}', M_WOOD))
# 3. raised plump cushion inside the rim (domed, reads as a bed edge-on)
bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, radius=1.0, location=(0, 0, 0.18))
cu = bpy.context.object; cu.name = 'cushion'; cu.scale = (R_OUT-0.6, R_OUT-0.68, 0.50)
bm = bmesh.new(); bm.from_mesh(cu.data)
for v in bm.verts:   # flatten the bottom, pillow-tuck the edge, soft lumps
    if v.co.z < 0: v.co.z *= 0.15
    v.co.z += 0.06*math.sin(3*math.atan2(v.co.y, v.co.x)) * max(v.co.z, 0)
bm.to_mesh(cu.data); bm.free(); link(cu, M_CANVAS); parts.append(cu)
# 4. folded blanket draped over one side of the cushion and the rim
bpy.ops.mesh.primitive_grid_add(x_subdivisions=40, y_subdivisions=24, size=1, location=(0, 0, 0))
bl = bpy.context.object; bl.name = 'blanket'
bm = bmesh.new(); bm.from_mesh(bl.data)
for v in bm.verts:
    u, w = v.co.x + 0.5, v.co.y + 0.5            # 0..1
    ang = math.radians(-35) + (u - 0.5) * 1.5     # arc segment of the bed
    rad = 0.35 + w * (R_OUT - 0.05 - 0.35)        # from centre out over the rim
    x, y = rad*math.cos(ang), rad*math.sin(ang)
    if rad < R_OUT-0.75: z = 0.18 + 0.50*math.sqrt(max(0, 1-(rad/(R_OUT-0.6))**2)) + 0.03
    else:
        d = (rad - (R_OUT-0.42))/0.5; z = (RIM_H-0.42) + 0.42*math.sqrt(max(0, 1-min(1, d*d))) + 0.02
        if rad > R_OUT-0.15: z -= (rad-(R_OUT-0.15))*2.2
    z += 0.025*math.sin(u*22) + 0.02*math.sin(w*9 + u*3)  # folds
    v.co = Vector((x, y, z))
bm.to_mesh(bl.data); bm.free()
sol = bl.modifiers.new('thick', 'SOLIDIFY'); sol.thickness = 0.03
link(bl, M_BLANKET); parts.append(bl)
# 5. loose straw tufts spilling over the rim and on the cushion
for k in range(45):
    t = random.uniform(0, 2*math.pi); inside = random.random() < 0.45
    rr = random.uniform(0.6, R_OUT-0.9) if inside else random.uniform(R_OUT-0.65, R_OUT+0.15)
    base = Vector((rr*math.cos(t), rr*math.sin(t), (0.62 if inside else RIM_H-0.05) if rr < R_OUT else 0.02))
    d = Vector((random.uniform(-1,1), random.uniform(-1,1), random.uniform(-0.2, 0.5))).normalized()*random.uniform(0.25, 0.45)
    pts = [base, base + d*0.5 + Vector((0,0,0.03)), base + d]
    parts.append(tube_along([tuple(p) for p in pts], 0.02, f'straw{k}', M_STRAW))
# convert curves, join per material, UV, bake
bpy.ops.object.select_all(action='DESELECT')
for o in list(scn.objects):
    if o.type == 'CURVE':
        o.select_set(True)
bpy.context.view_layer.objects.active = next(o for o in scn.objects if o.type=='CURVE')
bpy.ops.object.convert(target='MESH')
for o in scn.objects:
    bpy.context.view_layer.objects.active = o
    for m in o.modifiers: bpy.ops.object.modifier_apply(modifier=m.name)
groups = {}
for o in scn.objects:
    groups.setdefault(o.data.materials[0].name, []).append(o)
final = []
for name, objs in groups.items():
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1: bpy.ops.object.join()
    o = bpy.context.object; o.name = name; final.append(o)
scn.render.engine = 'CYCLES'; scn.cycles.samples = 8; scn.cycles.device = 'CPU'
for o in final:
    bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active = o
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.01); bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.shade_smooth()
    m = o.data.materials[0]; nt = m.node_tree
    img = bpy.data.images.new(o.name + '_albedo', 1024, 1024); tex = nt.nodes.new('ShaderNodeTexImage'); tex.image = img
    nt.nodes.active = tex
    bpy.ops.object.bake(type='DIFFUSE', pass_filter={'COLOR'}, margin=4)
    bsdf = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
    nt.links.new(tex.outputs[0], bsdf.inputs['Base Color'])
    img.filepath_raw = '/tmp/claude-0/work/blender/r2_' + o.name + '_albedo.png'; img.file_format = 'PNG'; img.save(); img.pack()
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', use_selection=True, export_apply=True)
# preview with a 1.80 m trainer stand-in for the scale check
bpy.ops.mesh.primitive_cylinder_add(radius=0.22, depth=1.8, location=(R_OUT+0.8, 0, 0.9))
tr = bpy.context.object; tr.name = 'trainer_1p80'
cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); scn.collection.objects.link(cam)
cam.location = (6.5, -8.5, 2.2); cam.rotation_euler = (math.radians(80), 0, math.radians(36)); scn.camera = cam
sun = bpy.data.objects.new('sun', bpy.data.lights.new('sun', 'SUN')); sun.data.energy = 2.0
sun.rotation_euler = (math.radians(40), math.radians(10), math.radians(30)); scn.collection.objects.link(sun)
scn.world = bpy.data.worlds.new('w'); scn.world.color = (0.45, 0.55, 0.65)
scn.render.engine = 'CYCLES'; scn.cycles.samples = 24; scn.render.resolution_x, scn.render.resolution_y = 960, 540
scn.view_settings.view_transform = 'Standard'; scn.render.filepath = PREVIEW; bpy.ops.render.render(write_still=True)
print('NEST_OK', [ (o.name, len(o.data.polygons)) for o in final])
