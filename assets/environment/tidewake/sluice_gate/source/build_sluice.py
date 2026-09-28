"""Reference-backed Veilfall sluice presentation. Blender 4.2+, CPU only.
Run: blender --background --python <this file> [-- --preview]
Coordinates are authored in Godot metres (X across, Y up, Z passage).
No gameplay, colliders or gate state are exported.
"""
import bpy, math, json, sys, hashlib
from pathlib import Path
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).resolve().parent))
from repair_material_export import repair

OUT=Path(__file__).resolve().parents[1]
ROOT=next(p for p in OUT.parents if (p/'project.godot').exists())
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
parts=[]
def v(p): return Vector((p[0], -p[2], p[1]))
def material(name, colour, rough=.7, metal=0, texture=None):
    m=bpy.data.materials.new(name); m.diffuse_color=(*colour,1); m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value=(*colour,1)
    p.inputs['Roughness'].default_value=rough; p.inputs['Metallic'].default_value=metal
    if texture:
        t=m.node_tree.nodes.new('ShaderNodeTexImage'); t.image=bpy.data.images.load(str(ROOT/texture),check_existing=True)
        m.node_tree.links.new(t.outputs['Color'],p.inputs['Base Color'])
    return m
WOOD=material('Installed_Quaternius_WoodTrim',(.32,.23,.14),.82,texture='assets/buildings/quaternius_medieval/T_WoodTrim_BaseColor.png')
BRONZE=material('Weathered_bronze',(.24,.155,.078),.64,.55)
EDGE=material('Worn_bronze_edges',(.29,.245,.16),.62,.6)
IRON=material('Dark_wet_iron',(.065,.095,.099),.5,.68)
PATINA=material('Recessed_bronze_patina',(.07,.19,.17),.83,.25)
for m in (WOOD,BRONZE,EDGE,IRON,PATINA):
    nodes=m.node_tree.nodes; links=m.node_tree.links
    p=nodes.get('Principled BSDF'); vc=nodes.new('ShaderNodeVertexColor');vc.layer_name='Wear'
    mix=nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1
    mix.inputs[2].default_value=p.inputs['Base Color'].default_value
    if p.inputs['Base Color'].links:links.new(p.inputs['Base Color'].links[0].from_socket,mix.inputs[2])
    links.new(vc.outputs['Color'],mix.inputs[1]);links.new(mix.outputs['Color'],p.inputs['Base Color'])

def finish(o,name,mat,bev=0):
    o.name=name; o.data.materials.append(mat)
    bpy.context.view_layer.objects.active=o
    if bev:
        m=o.modifiers.new('Hand_worn_edges','BEVEL'); m.width=bev; m.segments=2
        bpy.ops.object.modifier_apply(modifier=m.name)
    if mat==WOOD:
        # Planar projection confined to the uninterrupted dark wood strip of the
        # installed atlas. Long grain follows the longest beam dimension.
        uv=o.data.uv_layers.active or o.data.uv_layers.new()
        bounds=[max(c.co[i] for c in o.data.vertices)-min(c.co[i] for c in o.data.vertices) for i in range(3)]
        long=max(range(3), key=lambda i:bounds[i]); lo=[min(c.co[i] for c in o.data.vertices) for i in range(3)]
        for poly in o.data.polygons:
            remaining=[i for i in range(3) if i!=long]
            side=min(remaining,key=lambda i:abs(poly.normal[i]))
            for li in poly.loop_indices:
                co=o.data.vertices[o.data.loops[li].vertex_index].co
                uv.data[li].uv=((co[long]-lo[long])/max(bounds[long],.001), .40+.23*(co[side]-lo[side])/max(bounds[side],.001))
    # Broad vertex wear keeps colour/rough construction finish in exported GLBs.
    # Weathering is stable in object space, with paler worn bevels and dark recesses.
    ca=o.data.color_attributes.new(name='Wear',type='FLOAT_COLOR',domain='CORNER')
    seed=sum(ord(c) for c in name)+int(o.location.x*13)
    for poly in o.data.polygons:
        bevel_face=max(abs(n) for n in poly.normal)<.95
        for li in poly.loop_indices:
            p=o.data.vertices[o.data.loops[li].vertex_index].co
            variation=.86+.09*math.sin(p.x*7.13+p.z*9.71+seed)
            if mat==WOOD:
                base=(.54,.61,.66) if not bevel_face else (.74,.78,.79)
            elif mat==IRON: base=(.68,.75,.76) if not bevel_face else (1.05,1.03,.97)
            else: base=(.60,.68,.68) if not bevel_face else (1,.97,.90)
            ca.data[li].color=(*(min(1,c*variation) for c in base),1)
    parts.append(o); return o
def box(name,p,size,mat=WOOD,bev=.05):
    bpy.ops.mesh.primitive_cube_add(size=1,location=v(p)); o=bpy.context.object
    o.dimensions=(size[0],size[2],size[1]); bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(o,name,mat,bev)
def rod(name,a,b,r,mat=IRON,vertices=10):
    a,b=v(a),v(b); d=b-a
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=d.length,location=(a+b)/2)
    o=bpy.context.object; o.rotation_euler=d.to_track_quat('Z','Y').to_euler()
    return finish(o,name,mat,.025 if r>.1 else 0)
def torus(name,p,r,tube,mat=BRONZE):
    # Default Blender torus lies XY; turn upright into Godot XY plane.
    bpy.ops.mesh.primitive_torus_add(major_segments=40,minor_segments=8,location=v(p),major_radius=r,minor_radius=tube,rotation=(math.pi/2,0,0))
    return finish(bpy.context.object,name,mat)
def rivet(p):
    sign=1 if p[2]>0 else -1
    rod('Seated_iron_washer',(p[0],p[1],p[2]-.035),(p[0],p[1],p[2]+.035),.145,IRON,12)
    z=p[2]+sign*.055
    rod('Worn_hex_bolt',(p[0],p[1],z-.035),(p[0],p[1],z+.035),.087,EDGE,6)
def beam(name,a,b,w,d,mat=WOOD):
    a,b=v(a),v(b); direction=b-a
    bpy.ops.mesh.primitive_cube_add(size=1,location=(a+b)/2); o=bpy.context.object
    o.dimensions=(w,d,direction.length); bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.rotation_euler=direction.to_track_quat('Z','Y').to_euler(); return finish(o,name,mat,min(.04,w*.3,d*.3))
def join_export(name):
    bpy.ops.object.select_all(action='DESELECT')
    for o in parts:o.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]; bpy.ops.object.join(); o=bpy.context.object
    bpy.context.scene.cursor.location=(0,0,0); bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    o.name=name; o.data.calc_loop_triangles()
    verts=[o.matrix_world@x.co for x in o.data.vertices]
    xyz=[(p.x,p.z,-p.y) for p in verts]
    deg=sum(t.area<1e-10 for t in o.data.loop_triangles)
    report={'triangles':len(o.data.loop_triangles),'vertices':len(verts),'degenerate_triangles':deg,
      'bounds_min':[min(p[i] for p in xyz) for i in range(3)],'bounds_max':[max(p[i] for p in xyz) for i in range(3)],
      'material_surfaces':len(o.data.materials),'colliders':0}
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)
    repair(OUT/(name+'.glb'))
    o.hide_set(True); o.hide_render=True; parts.clear()
    return report,o

audit={}; models={}
for width in (18,30):
    half=width/2
    # Fixed posts are outside the full authored collision opening. Their lower
    # portions overlap the existing masonry, not the walkable width.
    for side in (-1,1):
        x=side*(half+.48)
        box('Guide_post',(x,4.25,0),(.78,8.5,1.1))
        box('Bronze_shoe',(x,.42,0),(.96,.84,1.25),BRONZE)
        box('Guide_iron_front',(side*(half+.10),4.0,-.51),(.16,8,.2),IRON,.025)
        for y in (1.1,4.7,7.7):
            box('Post_bronze_collar',(x,y,0),(.84,.26,1.19),BRONZE)
            for z in (-.64,.64):rivet((x,y,z))
        # Counterweight and chain remain beyond the opening at every height.
        cx=side*(half+1.1)
        box('Counterweight',(cx,5.8,0),(.62,1.6,.6),IRON,.10)
        box('Counterweight_band',(cx,5.8,0),(.69,.18,.67),EDGE,.025)
        rod('Counterweight_chain',(cx,6.6,0),(cx,9.6,0),.085,IRON)
        torus('Outside_chain_pulley',(cx,9.55,0),.38,.075,EDGE)
        beam('Header_brace',(x,7.6,0),(x-side*1.5,8.55,0),.29,.35)
    # Receiving drum and shroud occupy Y7.35..11.2, entirely below the Y12
    # ceiling. The slatted roll remains visible in both states: the leaf winds
    # into a mechanical housing instead of seeming to vanish into masonry.
    rod('Slatted_receiving_core',(-half,9.45,0),(half,9.45,0),1.30,IRON,40)
    for i in range(22):
        a=math.tau*i/22
        y=9.45+1.39*math.cos(a); z=1.39*math.sin(a)
        plank=box('Wound_gate_slat',(0,y,z),(width,.23,.22),WOOD,.035)
        plank.rotation_euler.x=a
    for x in (-half+.35,0,half-.35):
        # Hooped bearings around receiving drum; torus starts with Z axis and
        # is rotated to wind around the horizontal X axle.
        bpy.ops.mesh.primitive_torus_add(major_segments=40,minor_segments=8,location=v((x,9.45,0)),major_radius=1.5,minor_radius=.14,rotation=(0,math.pi/2,0))
        finish(bpy.context.object,'Drum_bearing_hoop',BRONZE)
    box('Shroud_top',(0,11.14,0),(width+.30,.22,3.28),IRON,.08)
    for z in (-1.64,1.64):
        box('Receiving_slot_lintel',(0,7.56,z),(width,.38,.25),BRONZE,.07)
        box('Shroud_drip_edge',(0,10.82,z),(width,.16,.30),EDGE,.045)
    # Visible support brackets are ABOVE the 7 m aperture; low feet remain
    # outside it. Projected apron shoes expose the receiving architecture.
    for side in (-1,1):
        x=side*(half-.5)
        for z in (-1.65,1.65):
            box('Receiving_side_cheek',(x,9.24,z),(.9,3.78,.28),IRON,.10)
            box('Cheek_bronze_endplate',(x,7.72,z),(.94,.58,.40),BRONZE,.075)
            for y in (7.72,10.72):rivet((x,y,z*1.14))
            beam('Visible_overhead_bracket',(side*(half+.1),7.25,z),(side*(half-1.45),8.42,z),.36,.38,BRONZE)
    rod('Winding_axle',(-half-1.1,9.45,0),(half+1.1,9.45,0),.19,IRON,16)
    for x in (-width*.28,width*.28):
        box('Receiving_slot_guide',(x,7.50,0),(.55,.85,1.2),IRON,.06)
    torus('Main_spoked_hoist_wheel',(0,9.45,-1.98),1.22,.14,EDGE)
    rod('Wheel_hub',(0,9.45,-2.2),(0,9.45,.32),.29,BRONZE,16)
    for i in range(8):
        a=i*math.tau/8
        rod('Wheel_spoke',(0,9.45,-1.98),(math.sin(a)*1.18,9.45+math.cos(a)*1.18,-1.98),.095,BRONZE)
    for x in (-2,2):box('Axle_bearing',(x,9.49,0),(.38,.8,.62),IRON)
    audit[f'frame_{width}'],models[f'frame_{width}']=join_export(f'sluice_frame_{width}')

    # Leaf fills the original 7 m height. Low timber planks stop water; the open
    # upper bars retain the old grille's sightline into the next room.
    boardw=.76; count=math.ceil(width/boardw); boardw=width/count
    for i in range(count):
        x=-half+(i+.5)*boardw
        for row,y in enumerate((.70,1.72)):
            depth=.39+.025*math.sin(i*1.73+row)
            box('Waterlogged_oak_plank_'+str(i)+'_'+str(row),(x,y,0),(boardw-.085,.94,depth),WOOD,.065)
        # Dark backing in the deep joints prevents bright holes through lower
        # gate while retaining real board separation and alternating end joints.
    box('Tongue_groove_backing',(0,1.18,0),(width-.18,2.13,.14),IRON,.04)
    for y in (.2,2.35,6.8):
        box('Leaf_crossrail',(0,y,0),(width,.40,.47),WOOD)
        for z in (-.30,.30):box('Crossrail_bronze_strap',(0,y,z),(width,.25,.14),BRONZE,.04)
    n=math.ceil(width/.9)
    for i in range(n+1):
        x=-half+.14+(width-.28)*i/n
        rod('Upright_grille_bar',(x,2.4,0),(x,6.8,0),.10,IRON)
        box('Bar_bronze_socket',(x,2.63,0),(.25,.40,.25),BRONZE,.035)
        for y in (3.84,5.20):
            box('Articulated_grille_hinge',(x,y,0),(.24,.20,.25),BRONZE,.035)
    for y in (3.84,5.20):box('Linked_grille_crossrail',(0,y,0),(width,.10,.14),IRON,.025)
    for x in (-half+.25,half-.25):
        box('Leaf_end_stile',(x,3.5,0),(.50,7,.64),IRON,.07)
        for y in (.6,2.35,6.40):
            for z in (-.38,.38):
                box('End_stile_saddle',(x,y,z),(.50,.7,.12),BRONZE,.035)
                rivet((x,y,z*1.18))
    for x in (-width*.28,width*.28):
        for z in (-.33,.33):box('Lifting_plate',(x,6.60,z),(.60,.60,.12),BRONZE)
    for x in [(-half+.5)+i*1.7 for i in range(math.ceil((width-1)/1.7))]:
        for y in (.2,2.35,6.8):
            for z in (-.40,.40):rivet((x,y,z))
    # Bronze X reinforcement is functional-sized and visible from either side.
    for segment in range(round(width/6)):
        cx=-half+(segment+.5)*width/round(width/6)
        for z in (-.36,.36):
            beam('Lower_gate_diagonal',(cx-2.35,.50,z),(cx+2.35,2.02,z),.30,.18,BRONZE)
            for xx,yy in ((cx-2.35,.5),(cx+2.35,2.02)):
                box('Diagonal_end_seat',(xx,yy,z),(.5,.48,.2),IRON,.055)
                rivet((xx,yy,z*1.43))
    audit[f'leaf_{width}'],models[f'leaf_{width}']=join_export(f'sluice_leaf_{width}')
    root=f'res://assets/environment/tidewake/sluice_gate/'
    (OUT/f'sluice_gate_{width}.tscn').write_text(f'''[gd_scene load_steps=3 format=3]

[ext_resource type="PackedScene" path="{root}sluice_frame_{width}.glb" id="1"]
[ext_resource type="PackedScene" path="{root}sluice_leaf_{width}.glb" id="2"]

[node name="SluiceGate{width}" type="Node3D"]
metadata/authored_opening_width_m = {float(width)}
metadata/authored_gate_height_m = 7.0
metadata/open_pose = "Hide GateLeaf: articulated leaf winds into fixed receiving drum"

[node name="FixedFrame" parent="." instance=ExtResource("1")]

[node name="GateLeaf" parent="." instance=ExtResource("2")]
''',encoding='utf-8')

(OUT/'source'/'mesh-audit.json').write_text(json.dumps(audit,indent=2)+'\n')
if '--preview' in sys.argv:
    for name in ('frame_18','leaf_18'):
        models[name].hide_set(False);models[name].hide_render=False
    bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.06)); floor=bpy.context.object
    floor.data.materials.append(material('Preview_ground',(.07,.09,.10)))
    bpy.ops.object.camera_add(location=(19,27,15)); cam=bpy.context.object
    cam.rotation_euler=(Vector((0,0,4.5))-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.type='ORTHO';cam.data.ortho_scale=27;bpy.context.scene.camera=cam
    bpy.ops.object.light_add(type='AREA',location=(4,8,18)); l=bpy.context.object
    l.data.energy=3500;l.data.shape='DISK';l.data.size=14
    l.rotation_euler=(Vector((0,0,4))-l.location).to_track_quat('-Z','Y').to_euler()
    scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=20
    scene.world.color=(.2,.25,.3);scene.render.resolution_x=1400;scene.render.resolution_y=900;scene.render.resolution_percentage=100
    scene.render.filepath=str(OUT/'source'/'cpu-preview.png');bpy.ops.render.render(write_still=True)
