"""Prepare the Stormursa v2 candidate using the existing quadruped pipeline.
v2 copy of ../prepare_native_candidate.py: weld, align the leg line to the rig
forward axis (-Y), stand on z=0 and lightly decimate the textured surface while
retaining UVs. v2 adds one uniform scale to v1's file height (1.3017 units) so
the v1 refit's absolute region distances fit the new body unchanged; the game
fits the standing height (4.10 m) at runtime.
Run in Blender with -- <raw.glb> --out <working-directory>.
"""
import json, math, pathlib, sys
import bpy
from mathutils import Vector
root=pathlib.Path(__file__).resolve().parents[6]
sys.path.insert(0,str(root/'tools/art_pipeline/blender'))
import rig_quadruped as rig
import cleanup_mesh as cleanup
V1_FILE_HEIGHT=1.3017096873743412
args=rig.argv_after_double_dash(); raw=pathlib.Path(args[0]); out=pathlib.Path(rig.option(args,'--out'));out.mkdir(parents=True,exist_ok=True)
rig.load(raw);body=rig.join_and_normalise()
low,high=rig.bounds(body);s=V1_FILE_HEIGHT/(high.z-low.z);body.scale=(s,s,s);bpy.ops.object.transform_apply(scale=True)
legs=rig.find_legs(body)
front=(legs['front_l']+legs['front_r'])/2; rear=(legs['rear_l']+legs['rear_r'])/2
angle=math.atan2((rear-front).x,(rear-front).y)
body.rotation_euler.z=angle;bpy.ops.object.transform_apply(rotation=True)
low,high=rig.bounds(body);body.location=Vector((-(low.x+high.x)/2,-(low.y+high.y)/2,-low.z));bpy.ops.object.transform_apply(location=True)
legs=rig.find_legs(body);front=(legs['front_l']+legs['front_r'])/2; rear=(legs['rear_l']+legs['rear_r'])/2
cleanup.decimate_to(body,28000)
report={'scale':s,'align_deg':math.degrees(angle),'residual_leg_line_deg':math.degrees(math.atan2((rear-front).x,(rear-front).y)),'legs':{k:list(v) for k,v in legs.items()},'triangles':sum(len(p.vertices)-2 for p in body.data.polygons)}
(out/'prepare-report.json').write_text(json.dumps(report,indent=2))
bpy.ops.object.select_all(action='DESELECT');body.select_set(True);bpy.context.view_layer.objects.active=body
bpy.ops.export_scene.gltf(filepath=str(out/'textured-aligned.glb'),export_format='GLB',use_selection=True)
