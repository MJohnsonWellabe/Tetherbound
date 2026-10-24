"""Pipwing close-1024 Meshy remake: weld and decimate before rig_bird.py.

Bone-heat weighting found no solution on the raw 36k-vertex Meshy mesh (every
vertex unweighted). Weld coincident vertices and decimate, keeping UVs and
textures, as the quadruped pilots do.
Blender --background --python this.py -- raw.glb out.glb
"""
import bpy, sys
from pathlib import Path
root = Path(__file__).resolve().parents[6]
sys.path.insert(0, str(root / 'tools/art_pipeline/blender'))
import cleanup_mesh as cleanup
a = sys.argv[sys.argv.index('--') + 1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=a[0])
meshes = [o for o in bpy.data.objects if o.type == 'MESH']
for o in bpy.data.objects:
    o.select_set(o in meshes)
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
    bpy.ops.object.join()
body = bpy.context.view_layer.objects.active
bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.remove_doubles(threshold=0.0005); bpy.ops.object.mode_set(mode='OBJECT')
cleanup.decimate_to(body, 24000)
for o in list(bpy.data.objects):
    if o != body:
        bpy.data.objects.remove(o, do_unlink=True)
body.select_set(True)
bpy.ops.export_scene.gltf(filepath=a[1], export_format='GLB', use_selection=True)
