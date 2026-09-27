"""Reference-backed world bottles matching gen_item_icons.icon_stat_draught.

Run with Blender 4.2: blender --background --python <this file> -- --output <dir>
Existing item icons are the silhouette/stat reference; no downloaded/generated
third-party geometry. Opaque glazed ceramic avoids transparency sorting at
pickup distance. Geometry, trim, cork and relief emblems are authored here.
All assets stand at z=0, export Y-up, and are 0.80m high at scale 1.
"""
import argparse
import math
from pathlib import Path
import sys
import bpy

SPECS = {
    'elixir_might': ('attack', True, '#bc713d'),
    'elixir_guard': ('defence', True, '#477fc1'),
    'elixir_vigour': ('health', True, '#469c67'),
    'swift_tonic': ('speed', False, '#d5a433'),
    'attack_tonic': ('attack', False, '#bc713d'),
    'stoneguard_brew': ('defence', False, '#667f8d'),
}

def linear(v):
    return v/12.92 if v <= .04045 else ((v+.055)/1.055)**2.4

def mat(name, colour, rough=.4, metal=0):
    m=bpy.data.materials.new(name)
    m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF')
    c=tuple(linear(int(colour[i:i+2],16)/255) for i in (1,3,5))
    p.inputs['Base Color'].default_value=(*c,1)
    p.inputs['Roughness'].default_value=rough
    p.inputs['Metallic'].default_value=metal
    if metal:
        # Both production loaders retain textured metal; the harvest loader
        # deliberately strips untextured imported metallic scalars.
        image=bpy.data.images.new(name+' ORM',width=1,height=1)
        image.colorspace_settings.name='Non-Color'
        image.pixels=(1.0,rough,metal,1.0)
        image.pack()
        tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image
        split=m.node_tree.nodes.new('ShaderNodeSeparateColor')
        m.node_tree.links.new(tex.outputs['Color'],split.inputs['Color'])
        m.node_tree.links.new(split.outputs['Green'],p.inputs['Roughness'])
        m.node_tree.links.new(split.outputs['Blue'],p.inputs['Metallic'])
    return m

def mesh(name, verts, faces, material, bevel=0):
    data=bpy.data.meshes.new(name)
    data.from_pydata(verts,[],faces)
    data.update()
    obj=bpy.data.objects.new(name,data)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material)
    if bevel:
        mod=obj.modifiers.new('Crafted rounded edges','BEVEL')
        mod.width=bevel
        mod.segments=3
        mod.affect='EDGES'
        norm=obj.modifiers.new('Face normals','WEIGHTED_NORMAL')
        norm.keep_sharp=True
    return obj

def profile(name, rings, material, power=2.0, n=24, bevel=.005):
    # A continuous closed shell; each ring is height, half-width, half-depth.
    verts=[]
    for z,w,d in rings:
        for j in range(n):
            t=2*math.pi*j/n
            c,s=math.cos(t),math.sin(t)
            verts.append((w*math.copysign(abs(c)**(2/power),c),d*math.copysign(abs(s)**(2/power),s),z))
    faces=[tuple(reversed(range(n)))]
    for k in range(len(rings)-1):
        for j in range(n):
            a=k*n+j;b=k*n+(j+1)%n
            faces.append((a,b,b+n,a+n))
    faces.append(tuple(range((len(rings)-1)*n,len(rings)*n)))
    return mesh(name,verts,faces,material,bevel)

def relief(name, points, yfront, thickness, material, bevel=.003):
    # Polygon in X/Z; positive signed area is outward toward negative Y.
    area=sum(a[0]*b[1]-b[0]*a[1] for a,b in zip(points,points[1:]+points[:1]))
    if area<0: points=list(reversed(points))
    n=len(points)
    v=[(x,yfront,z) for x,z in points]+[(x,yfront+thickness,z) for x,z in points]
    faces=[tuple(range(n)),tuple(reversed(range(n,2*n)))]
    faces += [(j,(j+1)%n,(j+1)%n+n,j+n) for j in range(n)]
    return mesh(name,v,faces,material,bevel)

def symbol(stat):
    if stat=='attack':
        return [(-.021,-.105),(.021,-.105),(.021,-.052),(.071,-.052),(.071,-.027),(.024,-.027),(.033,.064),(0,.108),(-.033,.064),(-.024,-.027),(-.071,-.027),(-.071,-.052),(-.021,-.052)]
    if stat=='speed':
        return [(.018,.115),(-.073,-.012),(-.015,-.012),(-.043,-.12),(.079,.036),(.018,.036),(.06,.115)]
    if stat=='health':
        return [(math.sin(t)**3*.105,(13*math.cos(t)-5*math.cos(2*t)-2*math.cos(3*t)-math.cos(4*t))*.007) for t in [2*math.pi*i/48 for i in range(48)]]
    return [(-.092,.078),(0,.112),(.092,.078),(.082,-.032),(0,-.115),(-.082,-.032)]

def bottle(item,stat,permanent,colour,out):
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    glaze=mat('Glazed ceramic '+colour,colour,.29)
    edge=mat('Foot and neck ceramic',colour,.38)
    brass=mat('Warm aged brass','#cbb078',.34,.6)
    cork=mat('Natural cork','#91704b',.88)
    dark=mat('Dark leather label','#343631',.82)
    ink=mat('Ivory stat relief','#eee3bd',.42)
    if permanent:
        rings=[(0,.155,.12),(.025,.193,.146),(.055,.207,.152),(.55,.207,.152),(.59,.19,.144),(.665,.10,.092),(.737,.10,.092)]
        bodypower=3.6
        bottom=[(.02,.196,.148),(.034,.216,.160),(.065,.216,.160),(.08,.205,.153)]
        label_z=.31; label_y=-.159
    else:
        rings=[(0,.205,.15),(.024,.252,.171),(.065,.263,.178),(.105,.256,.174),(.565,.105,.090),(.615,.082,.078),(.735,.082,.078)]
        bodypower=2.8
        bottom=[(.019,.245,.168),(.034,.266,.181),(.065,.270,.184),(.085,.262,.180)]
        label_z=.285; label_y=-.149
    profile('Bottle body',rings,glaze,bodypower)
    profile('Protective foot ring',bottom,brass,bodypower)
    r=.109 if permanent else .091
    profile('Rolled neck lip',[(.708,r,.095),(.721,r+.012,.106),(.739,r+.012,.106),(.749,r,.095)],brass)
    profile('Stopper',[(.734,r-.01,.080),(.785,r-.006,.084),(.800,r-.017,.077)],cork,2.0,20,.003)
    if permanent:
        profile('Permanent seal collar',[(.664,.112,.101),(.675,.123,.112),(.692,.123,.112),(.704,.112,.101)],brass,2,24)
        # A closed metal clasp connects the collar to the stopper.
        relief('Seal clasp',[(-.029,.68),(.029,.68),(.029,.785),(-.029,.785)],-.11,.03,brass,.004)
    else:
        # A simple opaque rope winding distinguishes a reusable corked tonic.
        profile('Cord lower',[(.646,.087,.083),(.651,.092,.088),(.660,.092,.088),(.664,.087,.083)],cork,2,24,.002)
        profile('Cord upper',[(.667,.087,.083),(.672,.092,.088),(.681,.092,.088),(.685,.087,.083)],cork,2,24,.002)
    # The framed front plate follows the existing icon's large stat symbol.
    # Small flanges bed it into the curved body instead of floating a label.
    frame=[(-.134,label_z-.136),(-.118,label_z-.155),(.118,label_z-.155),(.134,label_z-.136),(.134,label_z+.133),(.118,label_z+.151),(-.118,label_z+.151),(-.134,label_z+.133)]
    relief('Brass label frame',frame,label_y,.047,brass,.008)
    panel=[(x*.9,label_z+(z-label_z)*.9) for x,z in frame]
    relief('Inlaid leather plate',panel,label_y-.004,.012,dark,.004)
    points=[(x,label_z+z) for x,z in symbol(stat)]
    relief('Stat '+stat,points,label_y-.012,.012,ink,.002)
    if stat=='defence':
        # Central inset makes this an armour plate, matching the UI glyph.
        relief('Armour plate inset',[(x*.54,label_z+(z-label_z)*.54) for x,z in points],label_y-.014,.003,dark,.002)
    # Matching reverse face keeps the stat readable from opposing approaches.
    front=[o for o in bpy.context.scene.objects if o.name.startswith(('Brass label','Inlaid leather','Stat ','Armour plate'))]
    if not permanent:
        # Seat the plate along the flask's taper instead of burying its base
        # or floating the upper edge in front of the narrow shoulder.
        for obj in front:
            for v in obj.data.vertices:
                v.co.y += .19*(v.co.z-label_z)
    for obj in front:
        back=obj.copy();back.data=obj.data.copy();back.name=obj.name+' reverse'
        bpy.context.collection.objects.link(back);back.rotation_euler.z=math.pi
    # Export evaluated geometry only; all materials are opaque PBR, no lights.
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=str(out/f'{item}.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True,export_texcoords=False,export_normals=True,export_materials='EXPORT',export_cameras=False,export_lights=False)
    print('DRAUGHT',item,'objects',len(bpy.context.scene.objects))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True)
    args=p.parse_args(sys.argv[sys.argv.index('--')+1:]);args.output.mkdir(parents=True,exist_ok=True)
    for item,(stat,permanent,colour) in SPECS.items(): bottle(item,stat,permanent,colour,args.output)
