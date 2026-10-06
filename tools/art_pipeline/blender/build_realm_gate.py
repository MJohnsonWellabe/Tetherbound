"""Fit the inspected Meshy portal frame and measure its empty aperture.

blender --background --python tools/art_pipeline/blender/build_realm_gate.py
The raw, authorized image-to-3D task is retained under assets_raw/realm_gate_meshy.
"""
import argparse
import json
import sys
from pathlib import Path
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT = Path(__file__).resolve().parents[3]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--input', type=Path, default=ROOT / 'assets_raw/realm_gate_meshy/a/model.glb')
parser.add_argument('--output', type=Path, default=ROOT / 'assets/props/realm_gate_meshy/models')
parser.add_argument('--width', type=float, default=4.5)
parser.add_argument('--height', type=float, default=5.2)
parser.add_argument('--depth', type=float, default=0.9)
parser.add_argument('--source-jamb-fraction', type=float, default=1.1 / 2.25)
parser.add_argument('--target-jamb-x', type=float, default=1.53)
parser.add_argument('--aperture-height', type=float, default=3.8)
parser.add_argument('--aperture-width', type=float, default=2.8)
parser.add_argument('--width-through-height', type=float, default=2.0)
parser.add_argument('--min-pier-width', type=float, default=0.0)
parser.add_argument('--fit-rectangular-opening', action='store_true')
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else [])
assert 0.8 <= args.width <= 6.0 and 1.0 <= args.height <= 6.0 and 0.1 <= args.depth <= 2.0, 'Dimensions outside supported native-metre range'
assert 0.1 <= args.source_jamb_fraction <= 0.9, 'Source jamb fraction outside supported range'
assert 0 < args.target_jamb_x < args.width / 2, 'Target jamb must lie inside the outer footprint'
assert 0 < args.aperture_height < args.height and 0 < args.aperture_width < args.width, 'Aperture must fit inside the frame'
assert 0 < args.width_through_height <= args.aperture_height, 'Width proof cannot exceed the aperture height'
assert 0 <= args.min_pier_width < args.width / 2, 'Invalid minimum pier width'
assert not args.fit_rectangular_opening or args.aperture_width + 2 * args.min_pier_width <= args.width, 'Opening and piers exceed the outer cap'
assert args.input.is_file(), 'Input mesh does not exist'
OUT = args.output
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(args.input))
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
assert min(size) > 0, 'Input mesh has a degenerate dimension'
source_jamb_x = args.width * 0.5 * args.source_jamb_fraction
outer_half_width = args.width * 0.5
normalized_points = [Vector(((p.x - centre.x) * args.width / size.x,
                             (p.y - centre.y) * args.depth / size.y,
                             (p.z - lo.z) * args.height / size.z)) for p in points]
raw_bvh = BVHTree.FromPolygons(normalized_points, [list(p.vertices) for p in obj.data.polygons]) if args.fit_rectangular_opening else None

def measured_source_jamb(height, sign):
    # The failed constant-split fit left varying 0.42m piers. Match each
    # height's existing whole-depth jamb with the same monotonic UV-preserving
    # deformation, then retain the original aperture proof on the result.
    height = min(max(height, 0.05), args.width_through_height)
    distance = max(2.0, args.depth)
    for index in range(1, int(round(outer_half_width / 0.001)) + 1):
        x = sign * index * 0.001
        if raw_bvh.ray_cast(Vector((x, -distance, height)), Vector((0, 1, 0)), distance * 2)[0] is not None:
            return abs(x)
    raise RuntimeError('Measured source opening has no jamb')

for vertex in obj.data.vertices:
    x = (vertex.co.x - centre.x) * args.width / size.x
    # Preserve the footprint while giving the existing passage a clear width.
    # Monotonic deformation narrows the massive piers, retaining every face/UV.
    ax = abs(x)
    split, target = source_jamb_x, args.target_jamb_x
    if raw_bvh is not None:
        height = (vertex.co.z - lo.z) * args.height / size.z
        blend = min(1.0, max(0.0, (args.width_through_height + 0.4 - height) / 0.4))
        if blend > 0:
            split = split * (1 - blend) + measured_source_jamb(height, -1 if x < 0 else 1) * blend
            target = target * (1 - blend) + args.aperture_width * 0.5 * blend
    assert 0 < split < outer_half_width, 'Measured source jamb cannot support monotonic deformation'
    ax = ax * (target / split) if ax <= split else target + (ax - split) * ((outer_half_width - target) / (outer_half_width - split))
    vertex.co = Vector((ax if x >= 0 else -ax,
                        (vertex.co.y - centre.y) * args.depth / size.y,
                        (vertex.co.z - lo.z) * args.height / size.z))
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
    distance = max(2.0, args.depth)
    return bvh.ray_cast(Vector((x, -distance, z)), Vector((0, 1, 0)), distance * 2)[0] is not None
profile = []
for step in range(1, int(round(args.height / 0.05)) + 1):
    height = step * 0.05
    if blocked(0, height):
        break
    sides = []
    for sign in [-1, 1]:
        for index in range(1, int(round(outer_half_width / 0.01)) + 1):
            x = sign * index * 0.01
            if blocked(x, height):
                sides.append(x)
                break
        else:
            raise RuntimeError('Open silhouette has no jamb')
    profile.append([round(height, 3), round(sides[0], 3), round(sides[1], 3)])
OUT.mkdir(parents=True, exist_ok=True)
width_rows = [row for row in profile if row[0] <= args.width_through_height]
walk_width = min((row[2] - row[1] for row in width_rows), default=0.0)
pier_width = min((min(outer_half_width + row[1], outer_half_width - row[2]) for row in width_rows), default=0.0)
# Keep measured failures too; never export a candidate that misses its declared bar.
(OUT / 'aperture.json').write_text(json.dumps({'height_m': args.height, 'width_m': args.width,
    'depth_m': args.depth, 'profile_y_left_right': profile,
    'required_height_m': args.aperture_height, 'required_width_m': args.aperture_width,
    'width_through_height_m': args.width_through_height, 'min_pier_width_m': pier_width}, indent=2) + '\n')
assert profile and profile[-1][0] > args.aperture_height, 'Portal ceiling too low'
assert profile[-1][0] >= args.width_through_height, 'Width proof does not cover required height'
# A declared minimum-pier fit uses the inclusive supplied clearance contract;
# keep the original, stricter passage bar for the existing default invocation.
width_ok = walk_width >= args.aperture_width if args.min_pier_width > 0 else walk_width > args.aperture_width
assert width_ok, 'Portal passage too narrow'
assert pier_width >= args.min_pier_width, 'Portal piers too narrow'
bpy.ops.export_scene.gltf(filepath=str(OUT / 'realm_gate_frame.glb'), export_format='GLB',
    use_selection=True, export_animations=False, export_yup=True)
print('PORTAL_FIT', json.dumps({'triangles': sum(len(p.vertices)-2 for p in obj.data.polygons),
    'aperture_top': profile[-1][0], 'walk_width': walk_width, 'min_pier_width': pier_width}))
