"""Prepare reference-backed Meshy Stormheart while retaining its bark texture.

Blender 4.2 background script. Coordinates below are Blender Z-up; exported
glTF is Godot Y-up. This edits art only; no gameplay collision is exported.
"""
import bpy, bmesh, math, json, hashlib
from pathlib import Path
from mathutils import Vector

ROOT=next(p for p in Path(__file__).resolve().parents if (p/'project.godot').exists())/'assets_raw/stormheart_hero'
OUT=ROOT.parents[1]/'assets/environment/stormwood/stormheart_hero'
OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
SOURCE=Path(__file__).resolve().parent/'model.glb'
bpy.ops.import_scene.gltf(filepath=str(SOURCE if SOURCE.exists() else ROOT/'model.glb'))
obj=next(o for o in bpy.context.scene.objects if o.type=='MESH')
bpy.context.view_layer.objects.active=obj
obj.select_set(True)
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
coords=[v.co.copy() for v in obj.data.vertices]
lo=Vector(tuple(min(v[k] for v in coords) for k in range(3)))
hi=Vector(tuple(max(v[k] for v in coords) for k in range(3)))
centre=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
scale=300/(hi.z-lo.z)
for v in obj.data.vertices:
    p=(v.co-centre)*scale
    # Open the two existing lobes by 18m each, leaving the crown texture and
    # branch topology intact. No radial projection onto a cylinder is used.
    p.x += 18*math.tanh(p.x/9)
    p.y += 24*math.tanh(p.y/10)
    # The generated roots spread to134m at uniform height300. A smooth root-only
    # taper brings their low tips to the established~91m outer footprint.
    t=max(0,min(1,p.z/65));t=t*t*(3-2*t)
    root_scale=.55+.45*t
    p.x*=root_scale;p.y*=root_scale
    # CPU front/back inspection established source front=-Y. Rotate the
    # complete tree180degrees so its actual cleft faces game south(-Z).
    p.x=-p.x;p.y=-p.y
    v.co=p
obj.name='StormheartLivingBarkAndCrown'
bm=bmesh.new();bm.from_mesh(obj.data)
bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.0005)
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
bm.to_mesh(obj.data);bm.free()
obj.data.update()
source=obj.data.copy()
source.calc_loop_triangles()
source_vertices=[v.co.copy() for v in source.vertices]
source_tris=[tuple(t.vertices) for t in source.loop_triangles]
source_loops=[tuple(t.loops) for t in source.loop_triangles]
source_uvs=[l.uv.copy() for l in source.uv_layers.active.data]
original_material=obj.data.materials[0]
original_material.name='StormheartOriginalTexturedBarkAndLeaves'

# Meshy bark/foliage is not a dependable watertight volume. A closed Boolean
# trial discarded exterior regions and was rejected. Clip the actual surface
# triangles instead, preserving every untouched triangle and its exact UVs.
def hollow_distance(p):
    if p.z > 221:return 1.
    radius=49 if p.z<=184 else max(0,49*(1-(p.z-184)/37))
    a=math.atan2(p.y,p.x)
    radius+=min(1,radius/10)*(1.25*math.sin(a*5+p.z*.024)+.8*math.sin(a*11-p.z*.015))
    return math.hypot(p.x,p.y)-radius

def south_distance(p):
    return max(-p.y,((p.x/10)**2+((p.z-6)/17)**2-1)*10)

def east_distance(p):
    return max(-p.x,((p.y/10)**2+((p.z-6)/16)**2-1)*10)

def clip_polygon(poly,field):
    result=[]
    for i,current in enumerate(poly):
        previous=poly[i-1]
        dp=field(previous[0]);dc=field(current[0])
        if (dp>=0)!=(dc>=0):
            low,high=0.,1.
            for unused in range(22):
                t=(low+high)/2
                value=field(previous[0].lerp(current[0],t))
                if (value>=0)==(dp>=0):low=t
                else:high=t
            t=(low+high)/2
            result.append((previous[0].lerp(current[0],t),previous[1].lerp(current[1],t)))
        if dc>=0:result.append(current)
    return result

out_vertices=[];out_uvs=[];out_faces=[];clipped_triangles=0
for triangle,loops in zip(source_tris,source_loops):
    polygon=[(source_vertices[v],source_uvs[l]) for v,l in zip(triangle,loops)]
    changed=False
    for field in [hollow_distance,south_distance,east_distance]:
        if any(field(p[0])<0 for p in polygon):changed=True
        polygon=clip_polygon(polygon,field)
        if not polygon:break
    if changed:clipped_triangles+=1
    if len(polygon)<3:continue
    base=len(out_vertices)
    out_vertices.extend(p[0] for p in polygon);out_uvs.extend(p[1] for p in polygon)
    for i in range(1,len(polygon)-1):out_faces.append((base,base+i,base+i+1))
mesh=bpy.data.meshes.new('StormheartClearanceSurface')
mesh.from_pydata(out_vertices,[],out_faces);mesh.materials.append(original_material)
layer=mesh.uv_layers.new(name='UVMap')
for loop in mesh.loops:layer.data[loop.index].uv=out_uvs[loop.vertex_index]
obj.data=mesh
bm=bmesh.new();bm.from_mesh(mesh)
bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.0001)
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
bm.to_mesh(mesh);bm.free()
for poly in obj.data.polygons:poly.use_smooth=True
for mat in obj.data.materials:
    mat.use_backface_culling=False
obj.data.update();obj.data.calc_loop_triangles()
points=[v.co for v in obj.data.vertices]
report={'source_glb_sha256':hashlib.sha256((ROOT/'model.glb').read_bytes()).hexdigest(),
    'source_task_id':'01a0e4a2-5b8b-77c4-bf72-2b340d0a8f00',
    'vertices':len(points),'triangles':len(obj.data.loop_triangles),'source_triangles_touched_by_clearance':clipped_triangles,
    'bounds_godot_min':[min(p.x for p in points),min(p.z for p in points),min(-p.y for p in points)],
    'bounds_godot_max':[max(p.x for p in points),max(p.z for p in points),max(-p.y for p in points)],
    'low_root_radius_max':max(math.hypot(p.x,p.y) for p in points if p.z<20),
    'sections':[],'treatment':'18m lateral and24m depth coherent cleft opening; root-only horizontal taper0.55to1 acrossY0to65; surface clipping for irregular cavity and organic south/east arches; original UVs/textures preserved; no cylindrical projection or Boolean classification',
    'visual_acceptance':'Candidate only. Newly exposed clipping boundaries are open; native appearance and integration require visual inspection.'}
for y in [6,20,50,90,130,150,174,184]:
    band=[p for p in points if abs(p.z-y)<1]
    report['sections'].append({'height':y,'min_radius':min(math.hypot(p.x,p.y) for p in band),'vertices_in_section':len(band)})
violations=[p for p in points if 6<=p.z<=174 and math.hypot(p.x,p.y)<44]
report['vertices_inside_required_hollow']=len(violations)
assert not violations, f'{len(violations)} vertices inside required hollow'
# Triangle barycentric sampling catches any chord crossing the protected core.
bad_triangles=0
for tri in obj.data.loop_triangles:
    a,b,c=[obj.data.vertices[i].co for i in tri.vertices]
    if max(a.z,b.z,c.z)<6 or min(a.z,b.z,c.z)>174:continue
    bad=False
    for i in range(7):
        for j in range(7-i):
            p=a*(i/6)+b*(j/6)+c*(1-(i+j)/6)
            if 6<=p.z<=174 and math.hypot(p.x,p.y)<44:bad=True
    if bad:bad_triangles+=1
report['sampled_triangles_inside_required_hollow']=bad_triangles
assert bad_triangles==0

def planar_min_radius(poly):
    cross_signs=[];distances=[]
    for i,item in enumerate(poly):
        a=item[0];b=poly[(i+1)%len(poly)][0]
        dx=b.x-a.x;dy=b.y-a.y
        cross_signs.append(dx*(-a.y)-dy*(-a.x))
        t=max(0,min(1,-(a.x*dx+a.y*dy)/max(dx*dx+dy*dy,1e-20)))
        distances.append(math.hypot(a.x+t*dx,a.y+t*dy))
    if all(x>1e-8 for x in cross_signs) or all(x< -1e-8 for x in cross_signs):return 0.
    return min(distances)

minimum_clearance=1e20
portal_hits={'south':0,'east':0}
minimum_triangle_area=1e20
for tri in obj.data.loop_triangles:
    points_tri=[obj.data.vertices[i].co for i in tri.vertices]
    area=(points_tri[1]-points_tri[0]).cross(points_tri[2]-points_tri[0]).length*.5
    minimum_triangle_area=min(minimum_triangle_area,area)
    poly=[(p,Vector((0.,0.))) for p in points_tri]
    hollow_band=clip_polygon(clip_polygon(poly,lambda p:p.z-6),lambda p:174-p.z)
    if len(hollow_band)>=3:minimum_clearance=min(minimum_clearance,planar_min_radius(hollow_band))
    for axis in ['south','east']:
        test=poly[:]
        fields=[lambda p:p.z-6,lambda p:16-p.z]
        if axis=='south':fields += [lambda p:p.y-44,lambda p:160-p.y,lambda p:p.x+5,lambda p:5-p.x]
        else:fields += [lambda p:p.x-44,lambda p:160-p.x,lambda p:p.y+5,lambda p:5-p.y]
        for field in fields:
            test=clip_polygon(test,field)
            if not test:break
        if len(test)>=3:portal_hits[axis]+=1
report['exact_projected_triangle_clearance_radius_m']=minimum_clearance
report['south_east_portal_triangle_hits_10m_width_10m_headroom_from_Y6']=portal_hits
report['minimum_triangle_area_m2']=minimum_triangle_area
report['normals_finite_and_unit']=all(math.isfinite(v.normal.length) and abs(v.normal.length-1)<.001 for v in obj.data.vertices)
assert minimum_clearance>=44
assert all(v==0 for v in portal_hits.values())
for o in bpy.context.scene.objects:o.select_set(o==obj)
bpy.context.view_layer.objects.active=obj
bpy.ops.export_scene.gltf(filepath=str(OUT/'stormheart_hero.glb'),export_format='GLB',use_selection=True,export_yup=True,export_apply=True)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'prepared_stormheart.blend'))
(ROOT/'geometry_audit.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
