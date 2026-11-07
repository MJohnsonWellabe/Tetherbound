# F38#41 (LANE-MS, 7 Nov 2026): detailed quarry boulders, recombined in Blender
# from installed assets only (owner 7 Nov: new art from Blender, not Meshy).
#  - meshes: assets/environment/stylized_nature/Rock_Medium_{1,2,3}.gltf
#  - stone:  assets/environment/terrain/Rock030_Color.jpg + Rock030_NormalGL.jpg
# Each low-poly rock is subdivided, broken up with two noise displacements
# (broad fracture planes plus fine chisel grain), given box-projected UVs at a
# fixed texel density (so every scale reads the same grain), and wears the
# Rock030 stone the quarry faces and cliffs already use. Footprint and height
# stay within a few percent of the source so placements and colliders hold.
#   blender -b --python rock_medium_q41.py -- <repo root>
import bpy, sys, os, bmesh, mathutils, random

ROOT = sys.argv[sys.argv.index("--") + 1]
SRC = os.path.join(ROOT, "assets/environment/stylized_nature")
TEX = os.path.join(ROOT, "assets/environment/terrain")
OUT = os.path.join(ROOT, "assets/environment/stylized_nature_q41")
UV_M = 1.6        # metres of rock per Rock030 repeat (source units)
os.makedirs(OUT, exist_ok=True)

for n in (1, 2, 3):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(SRC, "Rock_Medium_%d.gltf" % n))
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    dims0 = obj.dimensions.copy()
    size = max(dims0)
    # The source splits vertices at UV/shading seams; weld them first so the
    # displacement moves one closed surface instead of tearing it open.
    bm = bmesh.new(); bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.002 * size)
    bm.to_mesh(obj.data); bm.free()
    random.seed(4100 + n)
    # Densify, then fracture: broad planes (low-frequency, strong) and grain.
    sub = obj.modifiers.new("sub", "SUBSURF"); sub.subdivision_type = "SIMPLE"; sub.levels = 3; sub.render_levels = 3
    t1 = bpy.data.textures.new("frac%d" % n, "VORONOI"); t1.noise_scale = 0.32 * size; t1.distance_metric = "DISTANCE"
    d1 = obj.modifiers.new("frac", "DISPLACE"); d1.texture = t1; d1.strength = 0.07 * size; d1.mid_level = 0.5
    t2 = bpy.data.textures.new("grain%d" % n, "CLOUDS"); t2.noise_scale = 0.06 * size; t2.noise_depth = 3
    d2 = obj.modifiers.new("grain", "DISPLACE"); d2.texture = t2; d2.strength = 0.018 * size; d2.mid_level = 0.5
    for m in list(obj.modifiers):
        bpy.ops.object.modifier_apply(modifier=m.name)
    dec = obj.modifiers.new("dec", "DECIMATE"); dec.ratio = 0.35
    bpy.ops.object.modifier_apply(modifier="dec")
    # Keep the original footprint and height.
    d = obj.dimensions
    obj.scale = (dims0.x / d.x, dims0.y / d.y, dims0.z / d.z)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bpy.ops.object.shade_flat()
    # Box-projected UVs at a fixed density.
    bm = bmesh.new(); bm.from_mesh(obj.data)
    uvl = bm.loops.layers.uv.verify()
    for f in bm.faces:
        nrm = f.normal; ax = max(range(3), key=lambda i: abs(nrm[i]))
        for l in f.loops:
            co = l.vert.co
            u, v = [(co.y, co.z), (co.x, co.z), (co.x, co.y)][ax]
            l[uvl].uv = (u / UV_M, v / UV_M)
    bm.to_mesh(obj.data); bm.free()
    # Rock030 stone material.
    mat = bpy.data.materials.new("Rock030_q41"); mat.use_nodes = True
    nt = mat.node_tree; bsdf = nt.nodes["Principled BSDF"]
    col = nt.nodes.new("ShaderNodeTexImage"); col.image = bpy.data.images.load(os.path.join(TEX, "Rock030_Color.jpg"))
    nrm = nt.nodes.new("ShaderNodeTexImage"); nrm.image = bpy.data.images.load(os.path.join(TEX, "Rock030_NormalGL.jpg")); nrm.image.colorspace_settings.name = "Non-Color"
    nm = nt.nodes.new("ShaderNodeNormalMap")
    nt.links.new(col.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(nrm.outputs["Color"], nm.inputs["Color"]); nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
    bsdf.inputs["Roughness"].default_value = 0.92
    obj.data.materials.clear(); obj.data.materials.append(mat)
    obj.name = "Rock_Medium_%d_q41" % n
    out = os.path.join(OUT, "Rock_Medium_%d_q41.glb" % n)
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=False)
    print("ROCK", n, "dims", tuple(round(x, 2) for x in dims0), "->", tuple(round(x, 2) for x in obj.dimensions), "faces", len(obj.data.polygons), out)
