"""Prepare the inspected Meshy cliff; bake its colour onto a closed shell.

Usage: blender --background --python this.py -- input.glb output.glb report.json
The reference/remote task belongs in the asset's provenance, not this script.
"""
import json
import sys
from pathlib import Path

import bpy
import bmesh
from mathutils import Vector

source, output, report_path = map(Path, sys.argv[sys.argv.index('--') + 1:])
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(source.resolve()))
objects = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
if len(objects) != 1:
    raise SystemExit('Expected one contiguous cliff mesh; inspect unexpected parts.')
obj = objects[0]
bpy.context.view_layer.objects.active = obj
obj.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
mesh = bmesh.new()
mesh.from_mesh(obj.data)
before = len(mesh.verts)
extent = max(obj.dimensions)
bmesh.ops.remove_doubles(mesh, verts=list(mesh.verts), dist=extent * 1e-6)
bmesh.ops.dissolve_degenerate(mesh, dist=extent * 1e-6, edges=list(mesh.edges))
repair = 'weld_only'
original_nonmanifold = sum(not e.is_manifold for e in mesh.edges)
if original_nonmanifold:
    # Loop interpolation across the source UV seams smears its texture.
    # Reconstruct a closed shell, unwrap it, and bake colour from the source.
    mesh.to_mesh(obj.data)
    mesh.free()
    reference = obj.copy()
    reference.data = obj.data.copy()
    bpy.context.collection.objects.link(reference)
    reference.name = 'SourceTextureTransferOnly'
    reference.select_set(False)
    reference.hide_render = False
    obj.data.remesh_voxel_size = extent / 320.0
    bpy.ops.object.voxel_remesh()
    modifier = obj.modifiers.new('CliffReduction', 'DECIMATE')
    modifier.ratio = min(1.0, 12000 / sum(len(p.vertices) - 2 for p in obj.data.polygons))
    modifier.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    for layer in list(obj.data.uv_layers):
        obj.data.uv_layers.remove(layer)
    uv = obj.data.uv_layers.new(name='CliffBakedUV')
    uv.active_render = True
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=1.15192, island_margin=0.015)
    bpy.ops.object.mode_set(mode='OBJECT')
    baked = bpy.data.materials.new('CloudreachLimestoneBaked')
    baked.use_nodes = True
    principled = baked.node_tree.nodes.get('Principled BSDF')
    principled.inputs['Roughness'].default_value = 0.94
    texture = bpy.data.images.new('CloudreachLimestoneColour', width=2048, height=2048)
    image_node = baked.node_tree.nodes.new('ShaderNodeTexImage')
    image_node.image = texture
    baked.node_tree.nodes.active = image_node
    obj.data.materials.clear()
    obj.data.materials.append(baked)
    # Diffuse colour only: no baked lighting or source normal-map artefacts.
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 1
    scene.render.bake.use_selected_to_active = True
    scene.render.bake.use_pass_direct = False
    scene.render.bake.use_pass_indirect = False
    scene.render.bake.use_pass_color = True
    scene.render.bake.cage_extrusion = extent * 0.02
    scene.render.bake.max_ray_distance = extent * 0.04
    scene.render.bake.margin = 12
    reference.select_set(True)
    bpy.ops.object.bake(type='DIFFUSE')
    baked.node_tree.links.new(image_node.outputs['Color'], principled.inputs['Base Color'])
    texture.pack()
    bpy.data.objects.remove(reference, do_unlink=True)
    mesh = bmesh.new()
    mesh.from_mesh(obj.data)
    repair = 'voxel_320_decimate_12000_colour_bake_2048'
bmesh.ops.recalc_face_normals(mesh, faces=list(mesh.faces))
if mesh.calc_volume(signed=True) < 0:
    bmesh.ops.reverse_faces(mesh, faces=list(mesh.faces))
unseen = set(mesh.verts)
components = []
while unseen:
    stack = [unseen.pop()]
    count = 0
    while stack:
        vertex = stack.pop()
        count += 1
        for edge in vertex.link_edges:
            other = edge.other_vert(vertex)
            if other in unseen:
                unseen.remove(other)
                stack.append(other)
    components.append(count)
report = dict(source=str(source), vertices_before=before, vertices_prepared=len(mesh.verts),
              repair=repair, original_welded_nonmanifold=original_nonmanifold,
              triangles=sum(len(f.verts) - 2 for f in mesh.faces), components=components,
              non_manifold_edges=sum(not e.is_manifold for e in mesh.edges),
              boundary_edges=sum(e.is_boundary for e in mesh.edges),
              degenerate_faces=sum(f.calc_area() < 1e-12 for f in mesh.faces),
              edge_face_counts={str(n): sum(len(e.link_faces) == n for e in mesh.edges) for n in range(5)},
              signed_volume=mesh.calc_volume(signed=True),
              uv_layers=len(mesh.loops.layers.uv), material_count=len(obj.data.materials))
report_path.parent.mkdir(parents=True, exist_ok=True)
report_path.write_text(json.dumps(report, indent=2), encoding='utf-8')
if report['non_manifold_edges'] or len(components) != 1 or report['signed_volume'] <= 0:
    raise SystemExit('Cliff topology rejected; inspect report before integration.')
# Preserve the baked UVs and colour; record the actual repair.
mesh.to_mesh(obj.data)
mesh.free()
low = Vector(tuple(min(v.co[i] for v in obj.data.vertices) for i in range(3)))
high = Vector(tuple(max(v.co[i] for v in obj.data.vertices) for i in range(3)))
height = high.z - low.z
origin = Vector(((low.x + high.x) * .5, (low.y + high.y) * .5, low.z))
for vertex in obj.data.vertices:
    vertex.co = (vertex.co - origin) / height
obj.name = 'CloudreachLimestoneButtress'
output.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.export_scene.gltf(filepath=str(output.resolve()), export_format='GLB',
                          use_selection=True, export_animations=False)
print(json.dumps(report), flush=True)
