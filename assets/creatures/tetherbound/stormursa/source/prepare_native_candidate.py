"""Prepare this Stormursa candidate using the existing quadruped pipeline.
Weld, align and lightly decimate the textured surface while retaining UVs.
Run in Blender with -- <raw.glb> --out <working-directory>.
"""
import json, math, pathlib, sys
import bpy
from mathutils import Vector
root=pathlib.Path(__file__).resolve().parents[5]
sys.path.insert(0,str(root/'tools/art_pipeline/blender'))
import rig_quadruped as rig
import cleanup_mesh as cleanup
args=rig.argv_after_double_dash(); raw=pathlib.Path(args[0]); out=pathlib.Path(rig.option(args,'--out'));out.mkdir(parents=True,exist_ok=True)
rig.load(raw);body=rig.join_and_normalise(); legs=rig.find_legs(body)
front=(legs['front_l']+legs['front_r'])/2; rear=(legs['rear_l']+legs['rear_r'])/2
angle=math.atan2((rear-front).x,(rear-front).y)
body.rotation_euler.z=angle;bpy.ops.object.transform_apply(rotation=True)
low,high=rig.bounds(body);body.location=Vector((-(low.x+high.x)/2,-(low.y+high.y)/2,-low.z));bpy.ops.object.transform_apply(location=True)
cleanup.decimate_to(body,28000)
bpy.ops.object.select_all(action='DESELECT');body.select_set(True);bpy.context.view_layer.objects.active=body
bpy.ops.export_scene.gltf(filepath=str(out/'textured-aligned.glb'),export_format='GLB',use_selection=True)
