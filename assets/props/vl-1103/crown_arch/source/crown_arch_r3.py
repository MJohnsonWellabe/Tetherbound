# Stormwood Crown Arch r3 (F41#17 close-out): r2 + weathered stone, more copper and set-in glass, a landing that beds into the ground. blender -b -P crown_arch.py -- out.glb preview.png
import bpy, bmesh, math, random, sys
from mathutils import Vector, Matrix
argv = sys.argv[sys.argv.index('--')+1:]; OUT, PREVIEW = argv
random.seed(43); bpy.ops.wm.read_factory_settings(use_empty=True); scn = bpy.context.scene
def ramp_mat(name, stops, kind, scale, stretch=(1,1,1), rough=0.85, metal=0.0):
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial'); b = nt.nodes.new('ShaderNodeBsdfPrincipled'); nt.links.new(b.outputs[0], out.inputs[0])
    tc = nt.nodes.new('ShaderNodeTexCoord'); mp = nt.nodes.new('ShaderNodeMapping'); mp.inputs['Scale'].default_value = stretch
    nt.links.new(tc.outputs['Object'], mp.inputs['Vector'])
    t = nt.nodes.new('ShaderNodeTexWave' if kind == 'wave' else 'ShaderNodeTexNoise'); t.inputs['Scale'].default_value = scale
    if kind == 'wave': t.bands_direction = 'Z'; t.inputs['Distortion'].default_value = 2.5; t.inputs['Detail'].default_value = 4
    else: t.inputs['Detail'].default_value = 7
    nt.links.new(mp.outputs[0], t.inputs['Vector'])
    r = nt.nodes.new('ShaderNodeValToRGB'); e = r.color_ramp
    e.elements[0].position, e.elements[0].color = stops[0][0], (*stops[0][1], 1)
    e.elements[1].position, e.elements[1].color = stops[-1][0], (*stops[-1][1], 1)
    for p, c in stops[1:-1]: el = e.elements.new(p); el.color = (*c, 1)
    nt.links.new(t.outputs['Fac'], r.inputs[0]); nt.links.new(r.outputs[0], b.inputs['Base Color'])
    b.inputs['Roughness'].default_value = rough; b.inputs['Metallic'].default_value = metal; return m
def weathered(name, stops):
    # r3: the r2 slate ramp, darkened by vertical rain streaks and patched with
    # olive-ochre lichen, so the stone stops reading as one uniform lilac.
    m = ramp_mat(name, stops, 'noise', 2.5, stretch=(1,1,5)); nt = m.node_tree
    b = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'); base = b.inputs['Base Color'].links[0].from_socket
    tc = nt.nodes.new('ShaderNodeTexCoord')
    ms = nt.nodes.new('ShaderNodeMapping'); ms.inputs['Scale'].default_value = (7, 7, 0.35); nt.links.new(tc.outputs['Object'], ms.inputs['Vector'])
    ns = nt.nodes.new('ShaderNodeTexNoise'); ns.inputs['Scale'].default_value = 3.0; ns.inputs['Detail'].default_value = 5; nt.links.new(ms.outputs[0], ns.inputs['Vector'])
    rs = nt.nodes.new('ShaderNodeValToRGB'); rs.color_ramp.elements[0].position = 0.45; rs.color_ramp.elements[0].color = (1,1,1,1)
    rs.color_ramp.elements[1].position = 0.7; rs.color_ramp.elements[1].color = (0.45,0.45,0.45,1); nt.links.new(ns.outputs['Fac'], rs.inputs[0])
    mul = nt.nodes.new('ShaderNodeMixRGB'); mul.blend_type = 'MULTIPLY'; mul.inputs['Fac'].default_value = 1.0
    nt.links.new(base, mul.inputs[1]); nt.links.new(rs.outputs[0], mul.inputs[2])
    nl = nt.nodes.new('ShaderNodeTexNoise'); nl.inputs['Scale'].default_value = 4.5; nl.inputs['Detail'].default_value = 8; nt.links.new(tc.outputs['Object'], nl.inputs['Vector'])
    rl = nt.nodes.new('ShaderNodeValToRGB'); rl.color_ramp.elements[0].position = 0.6; rl.color_ramp.elements[0].color = (0,0,0,1)
    rl.color_ramp.elements[1].position = 0.68; rl.color_ramp.elements[1].color = (1,1,1,1); nt.links.new(nl.outputs['Fac'], rl.inputs[0])
    lic = nt.nodes.new('ShaderNodeMixRGB'); lic.blend_type = 'MIX'
    lic.inputs[2].default_value = (0.16, 0.15, 0.06, 1)
    nt.links.new(rl.outputs[0], lic.inputs['Fac']); nt.links.new(mul.outputs[0], lic.inputs[1]); nt.links.new(lic.outputs[0], b.inputs['Base Color'])
    return m
STONE = weathered('arch_stone', [(0.0,(0.03,0.036,0.04)),(0.35,(0.065,0.072,0.075)),(0.6,(0.11,0.115,0.115)),(0.85,(0.055,0.06,0.062)),(1.0,(0.15,0.15,0.145))])
MOSS  = ramp_mat('arch_moss',  [(0.3,(0.015,0.04,0.025)),(0.55,(0.035,0.09,0.05)),(0.8,(0.07,0.15,0.08))], 'noise', 6)
COPPER= ramp_mat('arch_copper',[(0.3,(0.05,0.17,0.14)),(0.6,(0.11,0.28,0.22)),(0.8,(0.36,0.22,0.08))], 'noise', 9, rough=0.45, metal=0.6)
GLASS = bpy.data.materials.new('arch_glass'); GLASS.use_nodes = True
gb = GLASS.node_tree.nodes['Principled BSDF']; gb.inputs['Base Color'].default_value = (0.62, 0.86, 0.98, 1)
gb.inputs['Roughness'].default_value = 0.15; gb.inputs['Emission Color'].default_value = (0.55, 0.85, 1.0, 1); gb.inputs['Emission Strength'].default_value = 2.0

def rock(loc, size, rot, m, jitter=0.18, sub=2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub, radius=1, location=loc, rotation=rot); o = bpy.context.object
    o.scale = size; bpy.ops.object.transform_apply(location=False, scale=True, rotation=False)
    bm = bmesh.new(); bm.from_mesh(o.data)
    for v in bm.verts: v.co *= 1 + random.uniform(-jitter, jitter)
    bm.to_mesh(o.data); bm.free(); o.data.materials.append(m); return o
def slab(loc, size, rot, m):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot); o = bpy.context.object
    o.scale = size; bpy.ops.object.transform_apply(location=False, scale=True, rotation=False)
    bv = o.modifiers.new('b', 'BEVEL'); bv.width = 0.05; bv.segments = 2
    o.data.materials.append(m); return o

LEG = 2.15; TOP = 3.7; APEX = 5.35
# four legs: stacked stratified slabs, wider at the foot, slight inward lean
for sx in (-1, 1):
    for sy in (-1, 1):
        z = 0.0; i = 0
        while z < TOP:
            h = random.uniform(0.32, 0.5); t = z / TOP
            w = 0.95 - 0.30 * t
            lean = 0.10 * t
            slab((sx*(LEG - lean) + random.uniform(-0.04, 0.04), sy*(LEG - lean) + random.uniform(-0.04, 0.04), z + h/2),
                 (w + random.uniform(-0.06, 0.08), w + random.uniform(-0.06, 0.08), h*0.96), (0, 0, random.uniform(-0.25, 0.25)), STONE)
            z += h; i += 1
        # copper band two thirds up, root flare of mossy stones at the foot
        bpy.ops.mesh.primitive_cylinder_add(radius=0.56, depth=0.16, vertices=16, location=(sx*(LEG-0.07), sy*(LEG-0.07), 2.5))
        bpy.context.object.data.materials.append(COPPER)
        # r3: a second, lower copper band and two glass shards set into the stone
        bpy.ops.mesh.primitive_cylinder_add(radius=0.66, depth=0.12, vertices=16, location=(sx*(LEG-0.02), sy*(LEG-0.02), 1.05))
        bpy.context.object.data.materials.append(COPPER)
        for gz, ga in ((1.7, 0.6), (3.05, 2.4)):
            a = ga + (0.8 if sx > 0 else 0) + (1.6 if sy > 0 else 0)
            bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.09, depth=0.42, location=(sx*LEG + 0.42*math.cos(a), sy*LEG + 0.42*math.sin(a), gz),
                                            rotation=(math.radians(90), 0, a + math.radians(90)))
            bpy.context.object.data.materials.append(GLASS)
        for k in range(5):
            a = random.uniform(0, 2*math.pi)
            rock((sx*LEG + 0.75*math.cos(a), sy*LEG + 0.75*math.sin(a), 0.05), (0.5, 0.42, 0.25), (0, 0, a), MOSS, 0.08)
        rock((sx*LEG, sy*LEG, 0.35), (0.85, 0.85, 0.45), (0, 0, 0), MOSS, 0.15)
# four pointed arches as voussoir chains, one over each side
def arch(p0, p1):
    p0 = Vector(p0); p1 = Vector(p1); mid = (p0 + p1) / 2; span = (p1 - p0).length
    dirv = (p1 - p0).normalized(); n = 13
    for k in range(n):
        u0, u1 = k / n, (k + 1) / n
        def pt(u):   # pointed (two-centred) arch
            x = (u - 0.5) * span
            h = (APEX - TOP) * (1 - (abs(x) / (span/2)) ** 1.6)
            return mid + dirv * x + Vector((0, 0, TOP + h))
        a, b = pt(u0), pt(u1); c = (a + b) / 2; seg = b - a
        o = slab(c, (seg.length * 1.05, 0.62, 0.55), (0, 0, 0), STONE)
        o.rotation_mode = 'QUATERNION'; o.rotation_quaternion = seg.to_track_quat('X', 'Z')
        if k in (3, n - 4):   # r3: copper straps across the voussoirs
            st = slab(c, (0.12, 0.7, 0.62), (0, 0, 0), COPPER)
            st.rotation_mode = 'QUATERNION'; st.rotation_quaternion = seg.to_track_quat('X', 'Z')
        if k == n // 2:   # keystone, copper-capped
            slab(c + Vector((0, 0, 0.36)), (0.5, 0.75, 0.22), (0, 0, math.atan2(dirv.y, dirv.x)), COPPER)
for sx in (-1, 1): arch((sx*LEG, -LEG, 0), (sx*LEG, LEG, 0))
for sy in (-1, 1): arch((-LEG, sy*LEG, 0), (LEG, sy*LEG, 0))
# crown: a stone ring on the crossing, copper rim, five glass points (the tallest 7.0 m)
bpy.ops.mesh.primitive_cylinder_add(radius=1.25, depth=0.55, vertices=20, location=(0, 0, APEX + 0.2)); bpy.context.object.data.materials.append(STONE)
bpy.ops.mesh.primitive_torus_add(major_radius=1.25, minor_radius=0.1, location=(0, 0, APEX + 0.48)); bpy.context.object.data.materials.append(COPPER)
for k in range(5):
    a = k * 2*math.pi/5 + 0.3; r = 0.0 if k == 0 else 0.75
    h = 1.55 if k == 0 else random.uniform(0.85, 1.15)
    x, y = (0, 0) if k == 0 else (r*math.cos(a), r*math.sin(a))
    bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.26 if k == 0 else 0.18, depth=h, location=(x, y, APEX + 0.45 + h/2),
                                    rotation=(0 if k == 0 else 0.25*math.sin(a), 0 if k == 0 else -0.25*math.cos(a), 0))
    bpy.context.object.data.materials.append(GLASS)

# r3: the 9 x 9 m footing mesh is hidden (its collider stays 0.2 m proud), so
# the landing itself carries the feet: broken flagstones about 0.28 m high over
# a rounded square (superellipse) that covers the collider, stepping down at a
# ragged edge under a band of half-sunk rubble and moss, so no straight edge or
# corner shows.
FLAG = weathered('arch_flag', [(0.2,(0.035,0.04,0.042)),(0.5,(0.07,0.075,0.075)),(0.8,(0.045,0.07,0.05))])
def sq(x, y): return (abs(x)**4 + abs(y)**4) ** 0.25
for gx in range(-7, 8):
    for gy in range(-7, 8):
        x, y = gx*0.78 + random.uniform(-0.22, 0.22), gy*0.78 + random.uniform(-0.22, 0.22)
        d = sq(x, y); ang = math.atan2(y, x)
        edge = 5.0 + 0.35*math.sin(ang*5 + 0.7) + 0.25*math.sin(ang*11) + random.uniform(-0.25, 0.25)
        if d > edge: continue
        if d > 3.4 and random.random() < 0.18: continue
        fall = max(0.0, d - 3.8)
        top = 0.28 - fall*0.16 + random.uniform(-0.03, 0.02)
        tilt = 0.03 + 0.06*min(fall, 1.5)
        slab((x, y, top - 0.13), (random.uniform(0.5, 0.95), random.uniform(0.45, 0.85), 0.26),
             (random.uniform(-tilt, tilt), random.uniform(-tilt, tilt), random.uniform(-0.7, 0.7)), FLAG)
for k in range(14):
    a = random.uniform(0, 2*math.pi); rr = random.uniform(2.2, 3.6)
    rock((rr*math.cos(a), rr*math.sin(a), 0.27), (random.uniform(0.25,0.45), random.uniform(0.2,0.4), random.uniform(0.05,0.09)), (0,0,a), MOSS, 0.08)
for k in range(72):
    a = k*2*math.pi/72 + random.uniform(-0.03, 0.03)
    c, s_ = math.cos(a), math.sin(a)
    rr = 4.55 / ((abs(c)**4 + abs(s_)**4) ** 0.25) + random.uniform(-0.25, 0.45)
    m = MOSS if k % 2 else STONE
    rock((rr*c, rr*s_, random.uniform(0.0, 0.08)), (random.uniform(0.35,0.7), random.uniform(0.3,0.55), random.uniform(0.18,0.3)), (0,0,a), m, 0.12)
# apply, join by material, UV + bake the textured ones
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
    if o.name == 'arch_glass': continue
    bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active = o
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.01); bpy.ops.object.mode_set(mode='OBJECT')
    m = o.data.materials[0]; nt = m.node_tree
    img = bpy.data.images.new(o.name + '_albedo', 1024, 1024); tex = nt.nodes.new('ShaderNodeTexImage'); tex.image = img; nt.nodes.active = tex
    bpy.ops.object.bake(type='DIFFUSE', pass_filter={'COLOR'}, margin=4)
    bsdf = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'); nt.links.new(tex.outputs[0], bsdf.inputs['Base Color'])
    img.filepath_raw = '/tmp/claude-0/work/blender/' + o.name + '.png'; img.file_format = 'PNG'; img.save(); img.pack()
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', use_selection=True, export_apply=True)
bpy.ops.mesh.primitive_cylinder_add(radius=0.22, depth=1.8, location=(0.9, -3.2, 0.9))
cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); scn.collection.objects.link(cam)
cam.location = (9.0, -21.0, 4.5); cam.rotation_euler = (math.radians(88), 0, math.radians(25)); scn.camera = cam
sun = bpy.data.objects.new('sun', bpy.data.lights.new('sun', 'SUN')); sun.data.energy = 2.5
sun.rotation_euler = (math.radians(45), math.radians(15), math.radians(-35)); scn.collection.objects.link(sun)
scn.world = bpy.data.worlds.new('w'); scn.world.color = (0.48, 0.42, 0.62)
scn.cycles.samples = 24; scn.render.resolution_x, scn.render.resolution_y = 960, 540
scn.view_settings.view_transform = 'Standard'; scn.render.filepath = PREVIEW; bpy.ops.render.render(write_still=True)
print('ARCH_R3_OK', [(o.name, len(o.data.polygons)) for o in final])
