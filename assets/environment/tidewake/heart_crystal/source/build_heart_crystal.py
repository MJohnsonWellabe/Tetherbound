"""Original Veilfall hero crystal. Run with Blender 4.2 --background --python.

Reference is direction only; all topology is authored here. Blender Z-up is
exported as glTF/Godot Y-up. No stock primitives, textures, or external assets.
"""
import bpy
import bmesh
import json
import math
import hashlib
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parent.parent
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
vertices, faces, face_tones = [], [], []
components = []


def crystal(name, base, tip, radius, sides, phase, shoulder, depth=0.78):
    start = len(vertices)
    bottom, top = Vector(base), Vector(tip)
    axis = (top-bottom).normalized()
    right = axis.cross(Vector((0, 1, 0))).normalized()
    across = axis.cross(right).normalized()
    vertices.append(tuple(bottom))
    # Deliberately unequal terminations and offset shoulder heights. These are
    # continuous mineral planes, not stacked primitive cones or regular prisms.
    sections = [(0.19, 0.50), (shoulder, 1.0), (0.73, 0.77), (0.86, 0.46)]
    for ring, (height, width) in enumerate(sections):
        centre = bottom.lerp(top, height)
        for side in range(sides):
            angle = phase + side * math.tau / sides
            irregular = 1.0 + 0.08 * math.sin(side * 2.14 + phase)
            offset = (right * math.cos(angle) + across * math.sin(angle)*depth)
            vertices.append(tuple(centre + offset * radius * width * irregular))
    top_index = len(vertices)
    vertices.append(tuple(top))
    for side in range(sides):
        nxt = (side+1) % sides
        faces.append((start, start+1+nxt, start+1+side))
        face_tones.append(0.48 + 0.18*math.sin(side*1.8+phase))
        for ring in range(3):
            a = start+1+ring*sides
            faces.append((a+side, a+nxt, a+sides+nxt, a+sides+side))
            face_tones.append(0.48+0.22*math.sin(side*2.1+phase)+0.04*ring)
        a = start+1+3*sides
        faces.append((a+side, a+nxt, top_index))
        face_tones.append(0.66+0.16*math.sin(side*2.1+phase))
    components.append({'name':name,'first_vertex':start,'vertex_count':len(vertices)-start})


# Main spire retains the board's tall diamond identity. Satellite axes diverge
# from a shared lower heart, giving front, side and reverse silhouettes.
crystal('Heart', (0, 0, 0), (0.18, 0.04, 10), 1.46, 8, 0.22, 0.46)
crystal('LeftCrown', (-0.30, 0.12, 1.4), (-2.25, 0.10, 8.30), 0.72, 6, 0.48, 0.49)
crystal('RightCrown', (0.42, 0.25, 1.8), (2.08, 0.24, 7.05), 0.89, 7, 0.05, 0.43)
crystal('RearSpire', (0.12, 0.40, 2.0), (0.78, 1.35, 8.88), 0.68, 6, 0.30, 0.47)
crystal('FrontBlade', (-0.22, -0.24, 0.85), (-0.60, -1.28, 6.25), 0.64, 6, 0.70, 0.46)
crystal('LeftSplinter', (-0.69, -0.05, 2.30), (-2.48, -0.51, 5.65), 0.38, 5, 0.23, 0.52)
crystal('RightSplinter', (0.55, -0.12, 1.45), (2.33, -0.66, 4.92), 0.43, 5, 0.43, 0.48)

# Exact five-metre width; keep the designed depth and ten-metre height.
lo_x, hi_x = min(v[0] for v in vertices), max(v[0] for v in vertices)
mid_x = (lo_x+hi_x)*0.5
vertices = [((v[0]-mid_x)*5/(hi_x-lo_x),v[1],v[2]) for v in vertices]
mesh = bpy.data.meshes.new('VeilfallHeart_CustomFacets')
mesh.from_pydata(vertices, [], faces)
mesh.update()
obj = bpy.data.objects.new('HeartCrystal', mesh)
bpy.context.collection.objects.link(obj)
bpy.context.view_layer.objects.active = obj
obj.select_set(True)
bm = bmesh.new()
bm.from_mesh(mesh)
bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
bm.to_mesh(mesh)
bm.free()

uv = mesh.uv_layers.new(name='FacetUV')
colour = mesh.color_attributes.new(name='Color', type='FLOAT_COLOR', domain='CORNER')
for polygon in mesh.polygons:
    polygon.use_smooth = False
    coords = [(0,0),(1,0),(0.5,1)] if len(polygon.loop_indices)==3 else [(0,0),(1,0),(1,1),(0,1)]
    for loop_index, coord in zip(polygon.loop_indices, coords):
        uv.data[loop_index].uv = coord
        tone = face_tones[polygon.index]
        colour.data[loop_index].color = (tone, tone, tone, 1)

mat = bpy.data.materials.new('Veilfall_BlueWhite_Mineral')
mat.diffuse_color = (0.055, 0.32, 0.65, 1)
mat.use_nodes = True
bsdf = mat.node_tree.nodes.get('Principled BSDF')
bsdf.inputs['Base Color'].default_value = (0.055, 0.32, 0.65, 1)
bsdf.inputs['Metallic'].default_value = 0.18
bsdf.inputs['Roughness'].default_value = 0.20
bsdf.inputs['Emission Color'].default_value = (0.035, 0.20, 0.48, 1)
bsdf.inputs['Emission Strength'].default_value = 0.28
mesh.materials.append(mat)

# Validate welded authoring topology before glTF's intentional normal/UV splits.
bm = bmesh.new()
bm.from_mesh(mesh)
nonmanifold = sum(not e.is_manifold for e in bm.edges)
degenerate = sum(f.calc_area() < 1e-8 for f in bm.faces)
assert nonmanifold == 0 and degenerate == 0
seen, closed = set(), []
for vertex in bm.verts:
    if vertex in seen:
        continue
    stack, group = [vertex], set()
    while stack:
        item = stack.pop()
        if item in group:
            continue
        group.add(item)
        stack.extend(e.other_vert(item) for e in item.link_edges)
    seen.update(group)
    group_faces = {f for v in group for f in v.link_faces}
    volume = 0.0
    for f in group_faces:
        vs = [v.co for v in f.verts]
        volume += sum(vs[0].dot(vs[i].cross(vs[i+1]))/6 for i in range(1,len(vs)-1))
    assert volume > 0
    closed.append({'vertices':len(group),'faces':len(group_faces),'signed_volume_m3':round(volume,6)})
bm.free()

out = ROOT/'heart_crystal.glb'
bpy.ops.export_scene.gltf(filepath=str(out), export_format='GLB', use_selection=True,
    export_yup=True, export_normals=True, export_texcoords=True,
    export_materials='EXPORT', export_vertex_color='ACTIVE')
bounds = [[min(v[i] for v in vertices) for i in range(3)], [max(v[i] for v in vertices) for i in range(3)]]
receipt = {'generator':'Blender 4.2.9 / original project-authored mesh',
    'vertices_welded':len(vertices),'polygon_faces':len(faces),
    'triangles':sum(len(f)-2 for f in faces),'closed_components':closed,
    'nonmanifold_edges':nonmanifold,'degenerate_faces':degenerate,
    'normals':'flat per facet; consistently outward; positive signed volume on each component',
    'blender_bounds_xyz':bounds,
    'godot_bounds_xyz':[[bounds[0][0],bounds[0][2],-bounds[1][1]], [bounds[1][0],bounds[1][2],-bounds[0][1]]],
    'sha256':hashlib.sha256(out.read_bytes()).hexdigest(),
    'components':components}
(ROOT/'source'/'geometry_validation.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps(receipt,indent=2))
