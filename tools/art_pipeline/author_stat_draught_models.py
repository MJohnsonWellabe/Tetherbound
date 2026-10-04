"""Normalize Meshy's bottle and fit six authored stat badges (Blender 4.2).

--background --python <script> -- --output assets/props/stat_draughts
First import adds --source assets_raw/stat_draught_bottle/model.glb.
Rebuilds reuse committed bottle_base.glb. No API calls. One shared 0.80m
Meshy bottle, six small badge GLBs and composition scenes. Symbols follow
gen_item_icons.icon_stat_draught; light enamel marks permanent elixirs.
"""
import argparse
import math
from pathlib import Path
import sys
import bpy
import bmesh
from mathutils import Vector

SPECS = {
 'elixir_might': ('attack', True, '#905021'),
 'elixir_guard': ('defence', True, '#295493'),
 'elixir_vigour': ('health', True, '#286645'),
 'swift_tonic': ('speed', False, '#98711d'),
 'attack_tonic': ('attack', False, '#905021'),
 'stoneguard_brew': ('defence', False, '#465764'),
}
BADGE_PLANES = {}
REVERSE_SCALE = 1.0
INLAY_EMISSION = 0.28

def linear(v):
    return v/12.92 if v <= .04045 else ((v+.055)/1.055)**2.4

def material(name, colour, rough=.55):
    m=bpy.data.materials.new(name);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value=tuple(linear(int(colour[i:i+2],16)/255) for i in (1,3,5))+(1,)
    p.inputs['Roughness'].default_value=rough
    return m

def mesh(name, verts, faces, mat):
    data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.update()
    obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj

def symbol(stat):
    if stat=='attack':
        return [(-.021,-.105),(.021,-.105),(.021,-.052),(.071,-.052),(.071,-.027),(.024,-.027),(.033,.064),(0,.108),(-.033,.064),(-.024,-.027),(-.071,-.027),(-.071,-.052),(-.021,-.052)]
    if stat=='speed':
        return [(.018,.115),(-.073,-.012),(-.015,-.012),(-.043,-.12),(.079,.036),(.018,.036),(.06,.115)]
    if stat=='health':
        return [(math.sin(t)**3*.105,(13*math.cos(t)-5*math.cos(2*t)-2*math.cos(3*t)-math.cos(4*t))*.007) for t in [2*math.pi*i/32 for i in range(32)]]
    return [(-.092,.078),(0,.112),(.092,.078),(.082,-.032),(0,-.115),(-.082,-.032)]

def export(objects, path):
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects:obj.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_yup=True,export_normals=True,export_cameras=False,export_lights=False)

def prepare(source,out,write_base=True):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(source))
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
    points=[o.matrix_world@v.co for o in objects for v in o.data.vertices]
    lo=Vector(tuple(min(p[i] for p in points) for i in range(3)))
    hi=Vector(tuple(max(p[i] for p in points) for i in range(3)))
    center=Vector(((hi.x+lo.x)/2,(hi.y+lo.y)/2,lo.z));scale=.8/(hi.z-lo.z)
    for obj in objects:
        for v in obj.data.vertices:v.co=(obj.matrix_world@v.co-center)*scale
        obj.matrix_world.identity()
        # Weld seam duplicates while retaining per-loop UVs.
        bm=bmesh.new();bm.from_mesh(obj.data)
        bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
        bm.to_mesh(obj.data);bm.free();obj.data.update()
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects:obj.select_set(True)
    bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join()
    bottle=bpy.context.object;bottle.name='Shared Meshy bottle'
    bpy.context.view_layer.update()
    if write_base:export([bottle],out/'bottle_base.glb')
    # Fit a shallow planar insert within each mount. Projecting every glyph
    # vertex separately bent concave polygons through their backing surface.
    # One shared plane per face keeps all inlay layers parallel and separated.
    for front in (True,False):
        direction=1 if front else -1
        radius=.066 if front else .071*REVERSE_SCALE
        samples=[]
        for k in range(5):
            for j in range(48):
                a=j*2*math.pi/48;r=radius*k/4
                hit,at,_,_=bottle.ray_cast(Vector((math.cos(a)*r,-2*direction,.33+math.sin(a)*r*1.1)),Vector((0,direction,0)))
                if not hit:raise RuntimeError('Badge mount misses bottle')
                samples.append(at.y)
        BADGE_PLANES[front]=min(samples) if front else max(samples)
    return bottle

def fitted_point(bottle,x,z,front,depth):
    direction=1 if front else -1
    return (x,BADGE_PLANES[front]-direction*depth,z)

def disc(bottle,mat,front,radius,depth,name,inner=0):
    # Thin enamel insert, seated inside the existing mount's silhouette.
    n=48;verts=[];scale=1 if front else REVERSE_SCALE
    if inner==0:verts.append(fitted_point(bottle,0,.33,front,depth))
    for r in ((inner,radius) if inner else (radius,)):
        for j in range(n):
            a=2*math.pi*j/n
            verts.append(fitted_point(bottle,math.cos(a)*r*scale,.33+math.sin(a)*r*scale*1.10,front,depth))
    faces=[]
    for j in range(n):
        if inner:
            a=j;b=(j+1)%n
            # Angular-then-radial ordering faces +Y; the front faces -Y.
            face=(a,b,b+n,a+n);faces.append(tuple(reversed(face)) if front else face)
        else:
            face=(0,j+1,(j+1)%n+1);faces.append(face if front else tuple(reversed(face)))
    obj=mesh(name,verts,faces,mat)
    for polygon in obj.data.polygons:polygon.use_smooth=True
    return obj

def relief(bottle,points,mat,front,name,depth=.009):
    factor=.54 if front else .54*REVERSE_SCALE
    points=[(x*factor,.33+z*factor) for x,z in points]
    area=sum(a[0]*b[1]-b[0]*a[1] for a,b in zip(points,points[1:]+points[:1]))
    if area<0:points.reverse()
    n=len(points)
    verts=[fitted_point(bottle,x,z,front,d) for d in (depth,depth-.0015) for x,z in points]
    faces=[tuple(range(n)),tuple(reversed(range(n,2*n)))]
    faces += [(j+n,(j+1)%n+n,(j+1)%n,j) for j in range(n)]
    if not front:faces=[tuple(reversed(f)) for f in faces]
    return mesh(name,verts,faces,mat)

def badge(bottle,item,stat,permanent,colour,out):
    enamel=material('Enamel '+item,colour,.62)
    ivory=material('Ivory inlay','#ead8aa',.48)
    # A low, local luminous inlay keeps the mark readable in night shadows.
    # The bottle/enamel/brass remain ordinarily lit, with no added light/halo.
    principled=ivory.node_tree.nodes.get('Principled BSDF')
    principled.inputs['Emission Color'].default_value=principled.inputs['Base Color'].default_value
    principled.inputs['Emission Strength'].default_value=INLAY_EMISSION
    gold=material('Brass badge rim','#b49a60',.46)
    parts=[]
    field=ivory if permanent else enamel
    glyph=enamel if permanent else ivory
    for front in (True,False):
        parts.append(disc(bottle,field,front,.066,.006,'Fitted enamel'))
        if not front:parts.append(disc(bottle,gold,front,.071,.0065,'Reverse rim',.065))
        points=symbol(stat)
        if stat=='attack' and permanent:
            # Broad crossed blades distinguish Might from the single Attack
            # sword; the light field carries the permanent-item class.
            for angle in (-.55,.55):
                c,s=math.cos(angle),math.sin(angle)
                blade=[((x*.80*c-z*s)*.95,(x*.80*s+z*c)*.95) for x,z in points]
                parts.append(relief(bottle,blade,glyph,front,'Might crossed blade'))
            points=[]
        if points:parts.append(relief(bottle,points,glyph,front,'Stat '+stat))
        if stat=='defence' and not permanent:
            inset=[(x*.52,z*.52) for x,z in symbol(stat)]
            parts.append(relief(bottle,inset,enamel,front,'Armour inset',.011))
    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts:obj.select_set(True)
    bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join()
    joined=bpy.context.object;joined.name=item+' badge'
    export([joined],out/f'{item}_badge.glb');bpy.data.objects.remove(joined,do_unlink=True)
    (out/f'{item}.tscn').write_text(f'''[gd_scene load_steps=3 format=3]

[ext_resource type="PackedScene" path="res://assets/props/stat_draughts/bottle_base.glb" id="1"]
[ext_resource type="PackedScene" path="res://assets/props/stat_draughts/{item}_badge.glb" id="2"]

[node name="{item}" type="Node3D"]

[node name="Bottle" parent="." instance=ExtResource("1")]

[node name="Badge" parent="." instance=ExtResource("2")]
''')

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--output',type=Path,required=True);parser.add_argument('--source',type=Path)
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:]);args.output.mkdir(parents=True,exist_ok=True)
    bottle=prepare(args.source or args.output/'bottle_base.glb',args.output,write_base=args.source is not None)
    for item,(stat,permanent,colour) in SPECS.items():badge(bottle,item,stat,permanent,colour,args.output)
