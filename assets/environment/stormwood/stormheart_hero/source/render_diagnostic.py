import bpy,math
from pathlib import Path
from mathutils import Vector
ROOT=next(p for p in Path(__file__).resolve().parents if (p/'project.godot').exists())/'assets_raw/stormheart_hero'
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'prepared_stormheart.blend'))
scene=bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=24
scene.cycles.use_denoising=True
scene.render.resolution_x=768;scene.render.resolution_y=896;scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX'
world=bpy.data.worlds.new('DiagnosticOvercast');scene.world=world;world.use_nodes=True
world.node_tree.nodes['Background'].inputs[0].default_value=(.36,.42,.48,1)
world.node_tree.nodes['Background'].inputs[1].default_value=.5
for name,location,energy,size in [('Key',(180,-280,390),2500000,260),('Rim',(-200,150,340),1600000,220)]:
    light=bpy.data.lights.new(name,'AREA');light.energy=energy;light.shape='DISK';light.size=size
    ob=bpy.data.objects.new(name,light);scene.collection.objects.link(ob);ob.location=location
    ob.rotation_euler=(Vector((0,0,140))-ob.location).to_track_quat('-Z','Y').to_euler()
cam_data=bpy.data.cameras.new('DiagnosticCamera');cam=bpy.data.objects.new('DiagnosticCamera',cam_data);scene.collection.objects.link(cam);scene.camera=cam
cam_data.type='ORTHO';cam_data.ortho_scale=370;cam_data.clip_end=2000
for name,location,target,ortho in [('reverse',(0,-650,175),(0,0,150),410),('front_south',(0,650,175),(0,0,150),410),('inside',(0,43,125),(0,-25,158),115)]:
    cam.location=location;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam_data.ortho_scale=ortho
    scene.render.filepath=str(ROOT/('diagnostic_'+name+'.png'))
    bpy.ops.render.render(write_still=True)
