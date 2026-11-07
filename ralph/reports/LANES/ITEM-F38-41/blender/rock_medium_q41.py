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
VARIANT = os.environ.get("Q41_VARIANT", "r1")   # r2: split planes + warm stone
if VARIANT != "r1":
    OUT = os.path.join(ROOT, "assets/environment/stylized_nature_q41_%s" % VARIANT)
UV_M = 1.6 if VARIANT == "r1" else 2.6   # metres of rock per Rock030 repeat (source units)
WARM = (1.0, 1.0, 1.0, 1.0) if VARIANT == "r1" else (1.06, 0.98, 0.86, 1.0)
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
    if VARIANT != "r1":
        # Quarried blocks: chop 7 random planes through the outer ~22% of the
        # rock, keeping the inner side, for flat split faces and hard edges.
        bm = bmesh.new(); bm.from_mesh(obj.data)
        centre = sum((v.co for v in bm.verts), mathutils.Vector()) / max(len(bm.verts), 1)
        for k in range(7):
            nrm = mathutils.Vector((random.uniform(-1, 1), random.uniform(-1, 1), random.uniform(-0.35, 1.0))).normalized()
            far = max((v.co - centre).dot(nrm) for v in bm.verts)
            co = centre + nrm * far * random.uniform(0.72, 0.84)
            geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
            res = bmesh.ops.bisect_plane(bm, geom=geom, plane_co=co, plane_no=nrm, clear_outer=True)
            edges = [e for e in res["geom_cut"] if isinstance(e, bmesh.types.BMEdge)]
            if edges:
                bmesh.ops.holes_fill(bm, edges=edges, sides=0)
        bm.to_mesh(obj.data); bm.free()
    sub = obj.modifiers.new("sub", "SUBSURF"); sub.subdivision_type = "SIMPLE"; sub.levels = 3; sub.render_levels = 3
    t1 = bpy.data.textures.new("frac%d" % n, "VORONOI"); t1.noise_scale = 0.32 * size; t1.distance_metric = "DISTANCE"
    d1 = obj.modifiers.new("frac", "DISPLACE"); d1.texture = t1; d1.strength = (0.07 if VARIANT == "r1" else 0.02) * size; d1.mid_level = 0.5
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
    if VARIANT != "r1":
        # glTF export drops a multiply node, so the warm grade is baked into a
        # copy of the Rock030 texels (written into the GLB, source untouched).
        warm = col.image.copy(); warm.name = "Rock030_warm_%s" % VARIANT
        px = list(warm.pixels[:])
        for i in range(0, len(px), 4):
            px[i] = min(1.0, px[i] * WARM[0]); px[i + 1] = min(1.0, px[i + 1] * WARM[1]); px[i + 2] = min(1.0, px[i + 2] * WARM[2])
        warm.pixels[:] = px
        warm.filepath_raw = os.path.join(OUT, warm.name + ".png"); warm.file_format = "PNG"; warm.save(); warm.pack()
        col.image = warm
    obj.data.materials.clear(); obj.data.materials.append(mat)
    obj.name = "Rock_Medium_%d_q41%s" % (n, "" if VARIANT == "r1" else "_" + VARIANT)
    out = os.path.join(OUT, "Rock_Medium_%d_q41%s.glb" % (n, "" if VARIANT == "r1" else "_" + VARIANT))
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=False)
    print("ROCK", n, "dims", tuple(round(x, 2) for x in dims0), "->", tuple(round(x, 2) for x in obj.dimensions), "faces", len(obj.data.polygons), out)
