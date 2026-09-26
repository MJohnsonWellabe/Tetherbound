"""Fit the inspected Meshy portal frame and measure its empty aperture.

blender --background --python tools/art_pipeline/blender/build_realm_gate.py
The raw, authorized image-to-3D task is retained under assets_raw/realm_gate_meshy.
"""
import json
from pathlib import Path
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / 'assets/props/realm_gate_meshy/models'
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(ROOT / 'assets_raw/realm_gate_meshy/a/model.glb'))
meshes = [obj for obj in bpy.data.objects if obj.type == 'MESH']
assert meshes, 'Meshy task has no mesh'
bpy.ops.object.select_all(action='DESELECT')
for obj in meshes:
    obj.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
bpy.ops.object.join()
obj = bpy.context.object
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
obj.name = 'RealmGateStoneFrame'
points = [v.co.copy() for v in obj.data.vertices]
lo = Vector(tuple(min(p[i] for p in points) for i in range(3)))
hi = Vector(tuple(max(p[i] for p in points) for i in range(3)))
size = hi - lo
centre = (lo + hi) * 0.5
for vertex in obj.data.vertices:
    x = (vertex.co.x - centre.x) * 4.5 / size.x
    # Preserve the footprint while giving the existing passage a clear width.
    # Monotonic deformation narrows the massive piers, retaining every face/UV.
    ax = abs(x)
    ax = ax * (1.53 / 1.1) if ax <= 1.1 else 1.53 + (ax - 1.1) * (0.72 / 1.15)
    vertex.co = Vector((ax if x >= 0 else -ax,
                        (vertex.co.y - centre.y) * 0.9 / size.y,
                        (vertex.co.z - lo.z) * 5.2 / size.z))
obj.data.update()
for material in obj.data.materials:
    for node in list(material.node_tree.nodes):
        if node.type == 'NORMAL_MAP':
            node.inputs['Strength'].default_value = 0.4
        if node.type == 'BSDF_PRINCIPLED':
            roughness = node.inputs['Roughness']
            # glTF cannot carry an arbitrary Blender math node. Export a
            # constant matte roughness while retaining albedo/normal/metallic.
            for link in list(roughness.links):
                material.node_tree.links.remove(link)
            roughness.default_value = 0.86

# Sample the actual whole-depth silhouette, not an assumed ellipse. This keeps
# the separate animated portal surface inside the generated stone aperture.
points = [v.co.copy() for v in obj.data.vertices]
bvh = BVHTree.FromPolygons(points, [list(p.vertices) for p in obj.data.polygons])
def blocked(x, z):
    return bvh.ray_cast(Vector((x, -2.0, z)), Vector((0, 1, 0)), 4.0)[0] is not None
profile = []
for step in range(1, 105):
    height = step * 0.05
    if blocked(0, height):
        break
    sides = []
    for sign in [-1, 1]:
        for index in range(1, 226):
            x = sign * index * 0.01
            if blocked(x, height):
                sides.append(x)
                break
        else:
            raise RuntimeError('Open silhouette has no jamb')
    profile.append([round(height, 3), round(sides[0], 3), round(sides[1], 3)])
assert profile[-1][0] > 3.8, 'Portal ceiling too low'
assert min(row[2] - row[1] for row in profile if row[0] <= 2.0) > 2.8, 'Portal passage too narrow'
OUT.mkdir(parents=True, exist_ok=True)
(OUT / 'aperture.json').write_text(json.dumps({'height_m': 5.2, 'width_m': 4.5,
    'depth_m': 0.9, 'profile_y_left_right': profile}, indent=2) + '\n')
bpy.ops.export_scene.gltf(filepath=str(OUT / 'realm_gate_frame.glb'), export_format='GLB',
    use_selection=True, export_animations=False, export_yup=True)
print('PORTAL_FIT', json.dumps({'triangles': sum(len(p.vertices)-2 for p in obj.data.polygons),
    'aperture_top': profile[-1][0], 'walk_width': min(r[2]-r[1] for r in profile if r[0] <= 2.0)}))
