"""Mudsnout: small ivory tusks at the snout (owner, 24 Oct: "maybe needs a tusk").

Runs on the prepared rig (prepare_nat1024_candidate.py output), before
author_native_clips.py. Each tusk is a tapered, slightly curved cone rooted
at the lower side of the snout, sweeping outward and up the way the identity
reference (reference/side.png, nat1024-concept.png) shows. It is skinned
fully to the head bone and gets its own ivory material, so the fur texture is
untouched.

Blender --background --python this.py -- rigged.glb out_rigged.glb
"""
import bpy, bmesh, math, sys
from mathutils import Vector, Matrix
a = sys.argv[sys.argv.index('--') + 1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=a[0])
rig = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
body = next(o for o in bpy.data.objects if o.type == 'MESH' and o.vertex_groups)
P = [body.matrix_world @ v.co for v in body.data.vertices]
H = max(p.z for p in P) - min(p.z for p in P)
tip_y = min(p.y for p in P)
snout = [p for p in P if p.y < tip_y + 0.06 * H]
low_z = min(p.z for p in snout)
half_w = max(abs(p.x) for p in snout)

ivory = bpy.data.materials.new('mudsnout_tusk')
ivory.use_nodes = True
bsdf = ivory.node_tree.nodes['Principled BSDF']
bsdf.inputs['Base Color'].default_value = (0.86, 0.80, 0.66, 1.0)
bsdf.inputs['Roughness'].default_value = 0.45

LENGTH, ROOT_R, SEG = 0.13 * H, 0.021 * H, 6
for side in (-1, 1):
    bm = bmesh.new()
    # A curved horn: rings along an arc that sweeps outward, forward and up.
    rings = []
    for i in range(SEG + 1):
        t = i / SEG
        centre = Vector((side * (0.35 * t + 0.05 * t * t), -0.30 * t, 0.85 * t + 0.25 * t * t)) * LENGTH
        r = ROOT_R * (1.0 - 0.92 * t)
        ring = [bm.verts.new(centre + Vector((math.cos(k / 8 * math.tau) * r, 0, math.sin(k / 8 * math.tau) * r)))
                for k in range(8)]
        rings.append(ring)
    for r0, r1 in zip(rings, rings[1:]):
        for k in range(8):
            bm.faces.new((r0[k], r0[(k + 1) % 8], r1[(k + 1) % 8], r1[k]))
    bm.faces.new(list(reversed(rings[0])))
    mesh = bpy.data.meshes.new('tusk')
    bm.to_mesh(mesh); bm.free()
    obj = bpy.data.objects.new('tusk', mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = Vector((side * half_w * 0.62, tip_y + 0.05 * H, low_z + 0.02 * H))
    obj.data.materials.append(ivory)
    group = obj.vertex_groups.new(name='head')
    group.add(list(range(len(mesh.vertices))), 1.0, 'REPLACE')
    bpy.context.view_layer.update()
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True); body.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.join()
print('TUSKS', round(LENGTH, 3), 'm at snout tip', round(tip_y, 3))
for o in bpy.data.objects:
    o.select_set(o in (rig, body))
bpy.ops.export_scene.gltf(filepath=a[1], export_format='GLB', use_selection=True, export_yup=True,
                          export_skins=True, export_animations=False)
