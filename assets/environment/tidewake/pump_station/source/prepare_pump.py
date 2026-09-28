"""Blender 4.2: preserve Meshy pump UV/material, normalize scale and ground it."""
import bpy,json,math,hashlib
from pathlib import Path
from mathutils import Vector
HERE=Path(__file__).resolve().parent
ROOT=next(p for p in HERE.parents if (p/'project.godot').exists())
OUT=HERE.parent
src=HERE/'model.glb'
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(src))
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
for o in meshes:
    o.select_set(True)
bpy.context.view_layer.objects.active=meshes[0]
bpy.ops.object.join()
o=bpy.context.object
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
p=[v.co.copy() for v in o.data.vertices]
lo=Vector([min(v[k] for v in p) for k in range(3)])
hi=Vector([max(v[k] for v in p) for k in range(3)])
centre=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
scale=3.2/(hi.z-lo.z)
for v in o.data.vertices:v.co=(v.co-centre)*scale
o.name='VeilfallTwinPistonPump'
for mat in o.data.materials:
    if mat.use_nodes:
        bs=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
        if bs:
            bs.inputs['Roughness'].default_value=.68
            bs.inputs['Metallic'].default_value=.28
o.data.calc_loop_triangles()
pts=[v.co for v in o.data.vertices]
audit={'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'triangles':len(o.data.loop_triangles),'vertices':len(pts),'materials':len(o.data.materials),'height_m':3.2,'blender_bounds':[[min(v[k] for v in pts) for k in range(3)],[max(v[k] for v in pts) for k in range(3)]],'source_uv_preserved':True,'colliders':0}
(HERE/'geometry_validation.json').write_text(json.dumps(audit,indent=2))
bpy.ops.export_scene.gltf(filepath=str(OUT/'pump_station.glb'),export_format='GLB',use_selection=True,export_animations=False,export_yup=True)
print(json.dumps(audit))
