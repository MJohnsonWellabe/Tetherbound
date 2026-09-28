"""Blender 4.2 CPU authoring. --background --python source/build_banner.py
Original folded banner extending installed Quaternius Fantasy Props family.
Blender +Y faces front; exported Godot front is -Z. Root is cloth centre.
"""
from pathlib import Path
import bpy, math, json, hashlib
from mathutils import Vector
H=Path(__file__).resolve().parent; OUT=H.parent
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def material(name,color,rough=.8,metal=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
 return m
cloth=material('VeilfallBlueLinen',(.11,.22,.35),.96)
p=cloth.node_tree.nodes.get('Principled BSDF');t=cloth.node_tree.nodes.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(OUT/'heart_banner_albedo.png'));cloth.node_tree.links.new(t.outputs['Color'],p.inputs['Base Color'])
gold=material('AgedOchreThread',(.48,.32,.12),.9)
brass=material('WeatheredBrass',(.34,.24,.12),.52,.5)
iron=material('DarkIronMount',(.055,.073,.076),.72,.55)
wood=material('OiledTimberCrossbar',(.13,.079,.038),.88)
def point(u,v,offset=0):
 x=(u-.5)*2.8
 # Scalloped drape under hanging loops; full pointed hem, asymmetric folds.
 bottom=-1.92-.68*(1-abs(2*u-1))
 top=2.6-.07*math.sin(u*math.pi*5)**2
 z=top+(bottom-top)*v
 depth=.11*math.sin(u*math.pi*6+.9*v)+.055*math.sin(u*math.pi*3-2.5*v)+.075*v*v*math.sin(u*7+v*4)
 return (x, .24+depth+offset,z)
def mesh(name,verts,faces,mat,uv=None):
 me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update();ob=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(ob);ob.data.materials.append(mat)
 if uv:
  lay=me.uv_layers.new(name='UVMap')
  for poly in me.polygons:
   for li in poly.loop_indices:lay.data[li].uv=uv[me.loops[li].vertex_index]
 for f in me.polygons:f.use_smooth=True
 return ob
nx,ny=24,44;verts=[];uv=[];faces=[]
for j in range(ny+1):
 for i in range(nx+1):
  u=i/nx;v=j/ny;verts.append(point(u,v));uv.append((u,1-v))
for j in range(ny):
 for i in range(nx):
  a=j*(nx+1)+i;faces.append((a,a+1,a+nx+2,a+nx+1))
ob=mesh('FoldedCrestCloth',verts,faces,cloth,uv)
mod=ob.modifiers.new('WovenThickness','SOLIDIFY');mod.thickness=.014;mod.offset=0
bpy.context.view_layer.objects.active=ob;ob.select_set(True);bpy.ops.object.modifier_apply(modifier=mod.name);ob.select_set(False)
def ribbon(name,coords,width):
 vv=[];ff=[]
 for u,v,axis in coords:
  for sign in [-1,1]:
   du=sign*width/2/2.8 if axis=='u' else 0;dv=sign*width/2/4.8 if axis=='v' else 0
   vv.append(point(min(1,max(0,u+du)),min(1,max(0,v+dv)),.011))
 for i in range(len(coords)-1):ff.append((2*i,2*i+1,2*i+3,2*i+2))
 return mesh(name,vv,ff,gold)
ribbon('LeftSelvage',[(.028,j/ny,'u') for j in range(ny+1)],.075)
ribbon('RightSelvage',[(.972,j/ny,'u') for j in range(ny+1)],.075)
ribbon('PointedHem',[(i/nx,.974,'v') for i in range(nx+1)],.07)
ribbon('TopHem',[(i/nx,.033,'v') for i in range(nx+1)],.055)
def rod(name,a,b,r,mat,segments=12):
 a,b=Vector(a),Vector(b);vec=b-a
 bpy.ops.mesh.primitive_cylinder_add(vertices=segments,radius=r,depth=vec.length,location=(a+b)/2)
 o=bpy.context.object;o.name=name;o.rotation_euler=vec.to_track_quat('Z','Y').to_euler();o.data.materials.append(mat)
 bevel=o.modifiers.new('SoftForgedEdges','BEVEL');bevel.width=min(r*.15,.012);bevel.segments=2
 bpy.ops.object.modifier_apply(modifier=bevel.name)
 for f in o.data.polygons:f.use_smooth=True
 return o
rod('TimberCrossbar',(-1.69,.24,2.76),(1.69,.24,2.76),.072,wood)
for side in [-1,1]:
 x=side*1.53
 rod('WallPeg', (x,-.23,2.73),(x,.25,2.73),.047,iron)
 rod('WallPlate',(x,-.23,2.48),(x,-.23,2.98),.088,iron)
 rod('PoleFerrule',(side*1.52,.24,2.76),(side*1.73,.24,2.76),.085,brass)
 bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=.12,location=(side*1.76,.24,2.76));bpy.context.object.name='BrassFinial';bpy.context.object.scale=(1.4,.75,.75);bpy.context.object.data.materials.append(brass)
for i in range(6):
 u=.05+.9*i/5;x=(u-.5)*2.8
 # Small leather/cloth hangers wrap bar, clearly separating support and cloth.
 rod('HangingLoop', (x,.28,2.58),(x,.29,2.83),.039,gold,10)
# Short weighted fringe follows pointed lower seam, not long decorative ropes.
for i in range(33):
 u=.022+.956*i/32;a=Vector(point(u,1,.004));b=a+Vector((.005*math.sin(i),.012,-.09-.018*math.sin(i*2)))
 rod('HemFringe',a,b,.013,gold,5)
# Join each material class, keep just five compact mesh draw surfaces.
for mat in [cloth,gold,brass,iron,wood]:
 obs=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.data.materials and o.data.materials[0]==mat]
 bpy.ops.object.select_all(action='DESELECT')
 for o in obs:o.select_set(True)
 bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();bpy.context.object.name=mat.name
objs=[o for o in bpy.context.scene.objects if o.type=='MESH'];pts=[o.matrix_world@v.co for o in objs for v in o.data.vertices]
bounds=[[min(p[k] for p in pts) for k in range(3)],[max(p[k] for p in pts) for k in range(3)]]
tri=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in objs)
bpy.ops.export_scene.gltf(filepath=str(OUT/'heart_banner.glb'),export_format='GLB',export_yup=True,export_animations=False,export_cameras=False,export_lights=False)
(H/'geometry_validation.json').write_text(json.dumps({'triangles':tri,'mesh_count':len(objs),'degenerate_polygons':sum(p.area < 1e-10 for o in objs for p in o.data.polygons),'godot_bounds_min':[bounds[0][0],bounds[0][2],-bounds[1][1]],'godot_bounds_max':[bounds[1][0],bounds[1][2],-bounds[0][1]],'front':'-Z','root':'Cloth centre; pole at local Y 2.76; rearmost wall plate reaches local Z +0.318.','collision':False,'animation':'Static authored folds; no pretend wind motion.','glb_sha256':hashlib.sha256((OUT/'heart_banner.glb').read_bytes()).hexdigest()},indent=2))
# CPU studio preview is diagnostic only, never acceptance evidence.
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=24
scene.render.resolution_x=720;scene.render.resolution_y=960;scene.render.resolution_percentage=100
scene.world.color=(.22,.22,.22)
for pos,power,size in [((2,6,7),1000,5),((-4,2,3),700,4)]:
 bpy.ops.object.light_add(type='AREA',location=pos);o=bpy.context.object;o.data.energy=power;o.data.shape='DISK';o.data.size=size;o.rotation_euler=(-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(4,11,2.7));cam=bpy.context.object;cam.rotation_euler=(Vector((0,.1,.15))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=7.2;scene.camera=cam
scene.view_settings.view_transform='AgX';scene.render.filepath=str(H/'preview.png');bpy.ops.render.render(write_still=True)
