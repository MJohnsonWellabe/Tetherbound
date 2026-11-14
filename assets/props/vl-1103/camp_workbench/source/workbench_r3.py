# r3 (LANE-SCENE, 13 Nov 2026, F39#13): dark stained wood (r2's wood rendered at the sand's own value on the GPU),
# non-metal tool colours (r2's metal tools rendered black), larger hung tools, a teal sailcloth awning.
# Tidewake camp workbench (P2-116). Procedural build + bake + GLB. blender -b -P workbench.py -- out.glb preview.png
import bpy, bmesh, math, random, sys
argv = sys.argv[sys.argv.index('--')+1:]; OUT, PREVIEW = argv
random.seed(1103); bpy.ops.wm.read_factory_settings(use_empty=True); scn = bpy.context.scene

def mat(name, stops, kind='noise', scale=6.0, rough=0.8, metal=0.0, stretch=(1,1,1)):
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial'); b = nt.nodes.new('ShaderNodeBsdfPrincipled'); nt.links.new(b.outputs[0], out.inputs[0])
    tc = nt.nodes.new('ShaderNodeTexCoord'); mp = nt.nodes.new('ShaderNodeMapping'); mp.inputs['Scale'].default_value = stretch
    nt.links.new(tc.outputs['Object'], mp.inputs['Vector'])
    if kind == 'wave':
        t = nt.nodes.new('ShaderNodeTexWave'); t.inputs['Scale'].default_value = scale; t.inputs['Distortion'].default_value = 4; t.inputs['Detail'].default_value = 3
    else:
        t = nt.nodes.new('ShaderNodeTexNoise'); t.inputs['Scale'].default_value = scale; t.inputs['Detail'].default_value = 6
    nt.links.new(mp.outputs[0], t.inputs['Vector'])
    r = nt.nodes.new('ShaderNodeValToRGB'); e = r.color_ramp
    e.elements[0].position, e.elements[0].color = stops[0][0], (*stops[0][1], 1)
    e.elements[1].position, e.elements[1].color = stops[-1][0], (*stops[-1][1], 1)
    for p, c in stops[1:-1]: el = e.elements.new(p); el.color = (*c, 1)
    nt.links.new(t.outputs['Fac'], r.inputs[0]); nt.links.new(r.outputs[0], b.inputs['Base Color'])
    b.inputs['Roughness'].default_value = rough; b.inputs['Metallic'].default_value = metal
    return m
WOOD = mat('wb_wood', [(0.25,(0.050,0.030,0.016)),(0.5,(0.100,0.062,0.032)),(0.75,(0.170,0.108,0.058))], 'noise', 3, 0.8, stretch=(1,1,14))
TOP  = mat('wb_top',  [(0.25,(0.095,0.058,0.030)),(0.5,(0.16,0.10,0.052)),(0.75,(0.24,0.155,0.085))], 'noise', 3, 0.75, stretch=(14,1,1))
STEEL= mat('wb_steel',[(0.2,(0.46,0.52,0.58)),(0.8,(0.72,0.78,0.84))], 'noise', 20, 0.4, 0.0)
IRON = mat('wb_iron', [(0.2,(0.045,0.055,0.075)),(0.8,(0.12,0.14,0.18))], 'noise', 12, 0.5, 0.0)
BRASS= mat('wb_brass',[(0.2,(0.55,0.36,0.07)),(0.8,(0.86,0.63,0.20))], 'noise', 10, 0.4, 0.0)
ROPE = mat('wb_rope', [(0.2,(0.48,0.40,0.24)),(0.8,(0.74,0.64,0.42))], 'wave', 30, 0.9)
SAIL = mat('wb_sail', [(0.3,(0.016,0.062,0.085)),(0.7,(0.030,0.105,0.130))], 'noise', 4, 0.9)

def box(name, size, loc, m, rot=(0,0,0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot); o = bpy.context.object
    o.name = name; o.scale = size; bpy.ops.object.transform_apply(scale=True)
    bev = o.modifiers.new('b', 'BEVEL'); bev.width = min(size)*0.12; bev.segments = 2
    o.data.materials.append(m); return o
def cyl(name, r, h, loc, m, rot=(0,0,0), v=12):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=h, vertices=v, location=loc, rotation=rot); o = bpy.context.object
    o.name = name; o.data.materials.append(m); return o

L, D, H = 2.6, 1.05, 0.95          # long work surface (judges: 'a larger work surface')
# heavy plank top in three boards with gaps, thick legs, cross braces, lower shelf
for i in range(3):
    box(f'top{i}', (L, D/3-0.02, 0.09), (0, -D/3 + i*D/3, H), TOP)
for sx in (-1, 1):
    for sy in (-1, 1):
        box(f'leg{sx}{sy}', (0.14, 0.14, H), (sx*(L/2-0.15), sy*(D/2-0.12), H/2-0.04), WOOD)
    box(f'brace{sx}', (0.08, D-0.2, 0.08), (sx*(L/2-0.15), 0, 0.28), WOOD)
box('shelf', (L-0.4, D-0.25, 0.05), (0, 0, 0.30), WOOD)
# tall tool board behind the bench: the silhouette that reads past the trainer
BH = 2.4
box('board', (L-0.1, 0.07, BH-H), (0, D/2+0.02, H + (BH-H)/2), WOOD)
for sx in (-1, 1): box(f'post{sx}', (0.12, 0.12, BH+0.25), (sx*(L/2-0.05), D/2+0.02, (BH+0.25)/2), WOOD)
box('cap', (L+0.25, 0.22, 0.08), (0, D/2-0.02, BH+0.27), WOOD)
yb = D/2 - 0.04   # hanging plane just in front of the board
# hung tools, large and spaced so each reads alone
def hammer(x, z):
    cyl('ham_h', 0.035, 0.75, (x, yb, z), TOP); box('ham_head', (0.32, 0.10, 0.12), (x, yb, z+0.4), IRON)
def saw(x, z):
    bpy.ops.mesh.primitive_cube_add(size=1, location=(x, yb, z)); o = bpy.context.object; o.name='saw_blade'
    o.scale = (0.86, 0.012, 0.23); bpy.ops.object.transform_apply(scale=True)
    bm = bmesh.new(); bm.from_mesh(o.data)
    for v in bm.verts:
        if v.co.x > 0 and v.co.z < 0: v.co.z += 0.13     # tapered blade
    bm.to_mesh(o.data); bm.free(); o.data.materials.append(STEEL)
    box('saw_handle', (0.2, 0.05, 0.27), (x-0.5, yb, z+0.02), TOP)
def tongs(x, z):
    for s in (-1, 1): box('tong', (0.045, 0.04, 0.8), (x+s*0.06, yb, z), IRON, rot=(0, s*0.09, 0))
def coil(x, z):
    bpy.ops.mesh.primitive_torus_add(major_radius=0.27, minor_radius=0.06, location=(x, yb-0.02, z), rotation=(math.pi/2, 0, 0))
    o = bpy.context.object; o.name='rope'; o.data.materials.append(ROPE)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.23, minor_radius=0.055, location=(x+0.03, yb-0.06, z-0.03), rotation=(math.pi/2, 0, 0.2))
    bpy.context.object.data.materials.append(ROPE)
hammer(-1.0, 1.5); saw(-0.2, 1.95); tongs(0.5, 1.62); coil(1.0, 1.7)
for x in (-1.0, -0.2, 0.5, 1.0):   # brass pegs
    cyl('peg', 0.025, 0.12, (x, yb, 2.2), BRASS, rot=(math.pi/2, 0, 0), v=8)
# vise on the left end, work on the top: a plank being cut, a mallet, a jar, a folded sail
box('vise_body', (0.22, 0.26, 0.2), (-L/2+0.2, -D/2+0.18, H+0.15), IRON)
cyl('vise_screw', 0.025, 0.4, (-L/2+0.2, -D/2-0.05, H+0.12), BRASS, rot=(math.pi/2, 0, 0))
box('workpiece', (1.1, 0.24, 0.06), (-0.35, -0.1, H+0.08), WOOD, rot=(0, 0, 0.12))
cyl('mallet_h', 0.03, 0.4, (0.35, -0.25, H+0.08), WOOD, rot=(0, math.pi/2, 0.5))
cyl('mallet_head', 0.08, 0.2, (0.55, -0.12, H+0.1), WOOD, rot=(math.pi/2, 0, 0.5))
cyl('jar', 0.09, 0.22, (0.85, 0.2, H+0.15), BRASS)
box('sail', (0.6, 0.45, 0.1), (0.95, -0.2, H+0.1), SAIL, rot=(0, 0, -0.2))
# lantern post at the right end (2.6 m) with a hanging lantern
box('lpost', (0.11, 0.11, 2.6), (L/2+0.25, D/2-0.05, 1.3), WOOD)
# r3 awning: teal sailcloth from the raised back posts down to two slim front poles
AW_BACK, AW_FRONT, AW_D = 3.0, 2.45, 1.75
for sx in (-1, 1):
    box(f'awpost{sx}', (0.10, 0.10, AW_BACK-BH), (sx*(L/2-0.05), D/2+0.02, BH+(AW_BACK-BH)/2), WOOD)
    box(f'awpole{sx}', (0.07, 0.07, AW_FRONT), (sx*(L/2+0.22), D/2+0.02-AW_D, AW_FRONT/2), WOOD)
box('awbar', (L+0.6, 0.07, 0.07), (0, D/2+0.02-AW_D, AW_FRONT), WOOD)
tilt = math.atan2(AW_BACK-AW_FRONT, AW_D)
box('awning', (L+0.7, math.hypot(AW_D, AW_BACK-AW_FRONT)+0.15, 0.035), (0, D/2+0.02-AW_D/2, (AW_BACK+AW_FRONT)/2+0.04), SAIL, rot=(tilt, 0, 0))
box('larm', (0.5, 0.08, 0.08), (L/2+0.05, D/2-0.05, 2.5), WOOD)
cyl('lantern', 0.11, 0.26, (L/2-0.12, D/2-0.05, 2.25), BRASS, v=8)
# apply modifiers, join by material, UV, bake
for o in scn.objects:
    bpy.context.view_layer.objects.active = o
    for md in list(o.modifiers): bpy.ops.object.modifier_apply(modifier=md.name)
groups = {}
for o in scn.objects: groups.setdefault(o.data.materials[0].name, []).append(o)
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
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.02); bpy.ops.object.mode_set(mode='OBJECT')
    m = o.data.materials[0]; nt = m.node_tree
    img = bpy.data.images.new(o.name + '_albedo', 512, 512); tex = nt.nodes.new('ShaderNodeTexImage'); tex.image = img; nt.nodes.active = tex
    bpy.ops.object.bake(type='DIFFUSE', pass_filter={'COLOR'}, margin=4)
    bsdf = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'); nt.links.new(tex.outputs[0], bsdf.inputs['Base Color'])
    img.filepath_raw = '/tmp/claude-0/-home-user-Tetherbound/8d507b71-beed-51e1-a9df-c37db50625e3/scratchpad/blender/r3_' + o.name + '.png'; img.file_format = 'PNG'; img.save(); img.pack()
# r3 fix: r2 turned each joined group about its OWN origin (its first part), which threw the hung tools,
# rope, vise and lantern off the bench (the floating black squares and the stray white ring in the GPU frames).
scn.cursor.location = (0, 0, 0)
for o in final:
    bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active = o
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
for o in final:   # tool board faces the camp camera, turned about the bench centre: tool board faces the camp camera (r1 showed its back: 'a notice board')
    o.rotation_euler[2] += math.pi
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', use_selection=True, export_apply=True)
bpy.ops.mesh.primitive_cylinder_add(radius=0.22, depth=1.8, location=(-0.6, -1.4, 0.9))
cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); scn.collection.objects.link(cam)
cam.location = (3.6, -8.0, 2.4); cam.rotation_euler = (math.radians(80), 0, math.radians(22)); scn.camera = cam
sun = bpy.data.objects.new('sun', bpy.data.lights.new('sun', 'SUN')); sun.data.energy = 2.5
sun.rotation_euler = (math.radians(40), math.radians(10), math.radians(-30)); scn.collection.objects.link(sun)
scn.world = bpy.data.worlds.new('w'); scn.world.color = (0.45, 0.55, 0.65)
scn.cycles.samples = 24; scn.render.resolution_x, scn.render.resolution_y = 960, 540
scn.view_settings.view_transform = 'Standard'; scn.render.filepath = PREVIEW; bpy.ops.render.render(write_still=True)
print('WB_OK', [(o.name, len(o.data.polygons)) for o in final])
