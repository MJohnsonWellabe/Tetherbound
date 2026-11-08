# F38#30 / F38#24 (LANE-MESHY, 8 Nov 2026): Warrens hill v1 on the procedural Bank's own height field.
# Input: the live Bank visual mesh exported in warrens space (headless GLTFDocument export, .artifacts).
# Vertex POSITIONS are kept exactly (merge-by-distance 1 mm only), so the existing Bank trimesh collider
# still matches the visible hill. Only UVs, normals and a baked albedo are new.
# Textures (installed only): assets/environment/terrain/stylised/{meadow_grass,wet_earth,rock_scree,dirt_path}_Color.png
# Run: blender -b --python warrens_bank_hill.py -- <bank_export.glb> <out_dir> [bake_px]
import bpy, bmesh, sys, os, math, mathutils
argv = sys.argv[sys.argv.index("--") + 1:]
src, out_dir = argv[0], argv[1]
px = int(argv[2]) if len(argv) > 2 else 4096
ROOT = "/home/user/Tetherbound/assets/environment/terrain/stylised/"
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
obj = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
obj.name = "WarrensBankHill"
mw = obj.matrix_world.copy()
obj.parent = None
obj.matrix_world = mw
for o in list(bpy.context.scene.objects):
    if o is not obj:
        bpy.data.objects.remove(o, do_unlink=True)
print("HILL world matrix identity:", mw == mathutils.Matrix.Identity(4), mw)
bpy.ops.object.select_all(action='DESELECT')
bpy.context.view_layer.objects.active = obj
obj.select_set(True)
me = obj.data
before = [tuple(v.co) for v in me.vertices[:5]]
# Clear imported custom normals, weld exact duplicates, make faces point outward (up).
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.remove_doubles(threshold=0.001)
bpy.ops.mesh.normals_make_consistent(inside=False)
bpy.ops.object.mode_set(mode='OBJECT')
try:
    bpy.ops.mesh.customdata_custom_splitnormals_clear()
except Exception as e:
    print("no custom normals", e)
for p in me.polygons:
    p.use_smooth = True
# Most faces of a height field face up: flip the whole mesh if the area-weighted normal points down.
nz = sum(p.normal.z * p.area for p in me.polygons)
if nz < 0:
    bm = bmesh.new(); bm.from_mesh(me)
    bmesh.ops.reverse_faces(bm, faces=bm.faces); bm.to_mesh(me); bm.free()
print("HILL verts", len(me.vertices), "faces", len(me.polygons), "dims", tuple(round(d, 2) for d in obj.dimensions))
# Unique UVs for the bake.
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.002)
bpy.ops.object.mode_set(mode='OBJECT')

def img(name):
    return bpy.data.images.load(ROOT + name)

# --- bake material: box-projected installed textures, slope + strata + AO ---
mat = bpy.data.materials.new("bake"); mat.use_nodes = True
nt = mat.node_tree; N = nt.nodes; L = nt.links
for n in list(N): N.remove(n)
outn = N.new("ShaderNodeOutputMaterial"); emit = N.new("ShaderNodeEmission")
L.new(emit.outputs[0], outn.inputs[0])
tc = N.new("ShaderNodeTexCoord")
def boxtex(file, metres):
    m = N.new("ShaderNodeMapping"); m.inputs["Scale"].default_value = (1.0 / metres,) * 3
    L.new(tc.outputs["Object"], m.inputs[0])
    t = N.new("ShaderNodeTexImage"); t.image = img(file); t.projection = 'BOX'; t.projection_blend = 0.35
    L.new(m.outputs[0], t.inputs[0])
    return t.outputs[0]
grass = boxtex("meadow_grass_Color.png", 3.0)
earth = boxtex("wet_earth_Color.png", 2.5)
rock = boxtex("rock_scree_Color.png", 3.5)
dirt = boxtex("dirt_path_Color.png", 2.5)
geo = N.new("ShaderNodeNewGeometry"); sep = N.new("ShaderNodeSeparateXYZ"); L.new(geo.outputs["Normal"], sep.inputs[0])
# slope: 1 = flat (grass), 0 = steep (earth)
slope = N.new("ShaderNodeMapRange"); slope.inputs["From Min"].default_value = 0.55; slope.inputs["From Max"].default_value = 0.80
L.new(sep.outputs[2], slope.inputs["Value"])
# strata bands along world height with wobble
pos = N.new("ShaderNodeSeparateXYZ"); L.new(tc.outputs["Object"], pos.inputs[0])
noise = N.new("ShaderNodeTexNoise"); noise.inputs["Scale"].default_value = 0.08
L.new(tc.outputs["Object"], noise.inputs["Vector"])
wob = N.new("ShaderNodeMath"); wob.operation = 'MULTIPLY_ADD'; wob.inputs[1].default_value = 3.0
L.new(noise.outputs["Fac"], wob.inputs[0]); L.new(pos.outputs[2], wob.inputs[2])
band = N.new("ShaderNodeMath"); band.operation = 'PINGPONG'; band.inputs[1].default_value = 2.0
L.new(wob.outputs[0], band.inputs[0])
bandr = N.new("ShaderNodeMapRange"); bandr.inputs["From Min"].default_value = 0.6; bandr.inputs["From Max"].default_value = 1.6
L.new(band.outputs[0], bandr.inputs["Value"])
strata = N.new("ShaderNodeMixRGB"); strata.blend_type = 'MIX'
L.new(bandr.outputs[0], strata.inputs[0]); L.new(earth, strata.inputs[1]); L.new(rock, strata.inputs[2])
# darker seam lines between bands
seam = N.new("ShaderNodeMapRange"); seam.inputs["From Min"].default_value = 0.0; seam.inputs["From Max"].default_value = 0.25
seam.inputs["To Min"].default_value = 0.62; seam.inputs["To Max"].default_value = 1.0
L.new(band.outputs[0], seam.inputs["Value"])
earthc = N.new("ShaderNodeMixRGB"); earthc.blend_type = 'MULTIPLY'; earthc.inputs[0].default_value = 1.0
L.new(strata.outputs[0], earthc.inputs[1]); L.new(seam.outputs[0], earthc.inputs[2])
# grass with a dirt lip where slope transitions (worn edge)
lip = N.new("ShaderNodeMapRange"); lip.inputs["From Min"].default_value = 0.70; lip.inputs["From Max"].default_value = 0.80
L.new(sep.outputs[2], lip.inputs["Value"])
grassd = N.new("ShaderNodeMixRGB"); L.new(lip.outputs[0], grassd.inputs[0]); L.new(dirt, grassd.inputs[1]); L.new(grass, grassd.inputs[2])
mix = N.new("ShaderNodeMixRGB"); L.new(slope.outputs[0], mix.inputs[0]); L.new(earthc.outputs[0], mix.inputs[1]); L.new(grassd.outputs[0], mix.inputs[2])
ao = N.new("ShaderNodeAmbientOcclusion"); ao.inputs["Distance"].default_value = 4.0
aor = N.new("ShaderNodeMapRange"); aor.inputs["To Min"].default_value = 0.45
L.new(ao.outputs["AO"], aor.inputs["Value"])
fin = N.new("ShaderNodeMixRGB"); fin.blend_type = 'MULTIPLY'; fin.inputs[0].default_value = 1.0
L.new(mix.outputs[0], fin.inputs[1]); L.new(aor.outputs[0], fin.inputs[2])
L.new(fin.outputs[0], emit.inputs[0])
bake_img = bpy.data.images.new("warrens_bank_hill_albedo", px, px)
tn = N.new("ShaderNodeTexImage"); tn.image = bake_img; N.active = tn
me.materials.clear(); me.materials.append(mat)
scn = bpy.context.scene; scn.render.engine = 'CYCLES'; scn.cycles.device = 'CPU'; scn.cycles.samples = 8
scn.render.bake.margin = 8
bpy.ops.object.bake(type='EMIT')
os.makedirs(out_dir, exist_ok=True)
tex_path = os.path.join(out_dir, "warrens_bank_hill_albedo.jpg")
bake_img.filepath_raw = tex_path; bake_img.file_format = 'JPEG'; scn.render.image_settings.quality = 88; bake_img.save()
# --- export material: baked albedo only ---
final = bpy.data.materials.new("WarrensBankHill"); final.use_nodes = True
b = final.node_tree.nodes["Principled BSDF"]; b.inputs["Roughness"].default_value = 0.95
t2 = final.node_tree.nodes.new("ShaderNodeTexImage"); t2.image = bpy.data.images.load(tex_path)
final.node_tree.links.new(t2.outputs[0], b.inputs["Base Color"])
me.materials.clear(); me.materials.append(final)
after = [tuple(v.co) for v in me.vertices[:5]]
print("HILL first verts before/after weld:", before[:2], after[:2])
glb = os.path.join(out_dir, "warrens_bank_hill.glb")
bpy.ops.export_scene.gltf(filepath=glb, export_format='GLB', export_image_format='JPEG', export_yup=True)
print("HILL wrote", glb, tex_path)
