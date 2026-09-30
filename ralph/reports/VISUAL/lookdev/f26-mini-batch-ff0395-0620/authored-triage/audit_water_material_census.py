from pathlib import Path
from collections import Counter
import json, hashlib, re, struct

prefix=Path('D:/tetherbound/f26-water-medium-ff0395c9ae')
source='ff0395c9ae9c7ba80d8d1f0ea003c1cab3bc06cd'
manifest=json.loads((prefix/'manifest.json').read_text(encoding='utf-8'))
native=json.loads(prefix.with_suffix('.native.json').read_text(encoding='utf-8'))
assert native['source_commit']==manifest['graphics_capture']['source_commit']==source
assert native['native_exit']==0 and not native['timed_out'] and not native['errors']
assert manifest['complete'] and manifest['failures']==[]
assert manifest['captured_frame_count']==manifest['planned_frame_count']==2
assert manifest['graphics_capture']['preset']=='Medium'
assert manifest['graphics_capture']['renderer']=='forward_plus'
assert manifest['bound_player_character']=='trainer'
def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
log=prefix.with_suffix('.log').read_text(encoding='utf-8',errors='replace').splitlines()
assert not [l for l in log if re.search(r'ERROR:|SCRIPT ERROR:|Parse Error:',l)]
output={'source_commit':source,'scope':'Independent read-only native binding census review; no engine or visual/criterion verdict.',
        'native_receipt':native,'log_sha256':digest(prefix.with_suffix('.log')),
        'manifest_sha256':digest(prefix/'manifest.json'),
        'warnings':[l for l in log if 'WARNING:' in l],'frames':[]}
for census in manifest['material_census']:
    bindings=census['bindings']; resources=census['resources']
    unbound=[b for b in bindings if 'active_material' in b and not b['active_material']]
    missing=[dict(id=k,**r) for k,r in resources.items() if r.get('source_exists') is False]
    empty_shader=[dict(id=k,**r) for k,r in resources.items() if r.get('code_empty')]
    null_samplers=[{'id':k,'path':r['path'],'class':r['class'],
                    'nulls':[n for n in r.get('null_object_properties',[]) if n.startswith('shader_parameter/')]}
                   for k,r in resources.items() if any(n.startswith('shader_parameter/') for n in r.get('null_object_properties',[]))]
    families={}
    for name,pattern in [('surface','WaterSurface'),('pumps','SluicePump'),('veilfall','Veilfall'),('currents','WaterCurrentFlow'),('terrain','Terrain')]:
        selected=[b for b in bindings if pattern.lower() in b['node'].lower()]
        families[name]={'bindings':len(selected),'kinds':dict(Counter(b['kind'] for b in selected)),
                        'first_nodes':[b['node'] for b in selected[:5]],
                        'active_materials':sorted(set(b.get('active_material','') for b in selected)-{''})}
    special=[]
    for b in bindings:
        if b['node']=='WaterSurface' or b['kind'].startswith('terrain_'):
            special.append({'binding':b,'resource':resources.get(b.get('active_material',b.get('resource','')),{})})
    frame=next(f for f in manifest['frames'] if f['frame_id']==census['frame_id'])
    png=prefix/(census['frame_id']+'.png'); data=png.read_bytes()
    assert data[:8]==b'\x89PNG\r\n\x1a\n' and data[12:16]==b'IHDR'
    size=list(struct.unpack('>II',data[16:24]));assert size==[1920,1080] and len(data)==frame['bytes']
    report={'frame_id':census['frame_id'],'binding_count':len(bindings),'declared_binding_count':census['binding_count'],
        'resource_count':len(resources),'kinds':dict(Counter(b['kind'] for b in bindings)),
        'classifications':dict(Counter(b.get('classification','not_surface') for b in bindings)),
        'resource_classes':dict(Counter(r['class'] for r in resources.values())),
        'unbound_active_surfaces':unbound,'source_paths_missing':missing,'empty_shader_code':empty_shader,
        'null_shader_samplers':null_samplers,'families':families,'special':special,
        'png':{'path':str(png),'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data),'dimensions':size}}
    assert report['binding_count']==report['declared_binding_count']
    # Every resource reference should resolve in this frame's fresh index.
    resource_ids=set(resources)
    dangling=[]
    for k,r in resources.items():
        dangling.extend((k,name,ref) for name,ref in r.get('children',{}).items() if ref and ref not in resource_ids)
    for b in bindings:
        for key in ['mesh_source_material','active_material','material_override','material_overlay','resource','texture','material']:
            if b.get(key) and b[key] not in resource_ids: dangling.append((b['node'],key,b[key]))
    report['dangling_resource_ids']=dangling; assert not dangling
    surface=next(b for b in bindings if b['node']=='WaterSurface')
    surface_material=resources[surface['active_material']]
    required_water_samplers={name:resources[surface_material['children']['shader_parameter/'+name]]['class']
        for name in ['terrain_height','wave_normal_a','wave_normal_b','foam_noise']}
    assert required_water_samplers==dict(terrain_height='ImageTexture',wave_normal_a='NoiseTexture2D',
                                       wave_normal_b='NoiseTexture2D',foam_noise='NoiseTexture2D')
    pump_bindings=[b for b in bindings if b['node'].startswith('WaterSluiceTwinPumps/SluicePump')]
    assert len(pump_bindings)==2
    pump_textures=[]
    for binding in pump_bindings:
        material=resources[binding['active_material']]
        texture=resources[material['children']['albedo_texture']]
        assert texture['source_exists'] and texture['path'].endswith('pump_station_Image_0.jpg')
        pump_textures.append(dict(node=binding['node'],texture=texture['path'],visible=binding['visible_in_tree']))
    groups={}
    for binding in bindings:
        if not binding['node'].startswith('WaterVeilfall/') or not binding.get('active_material'):continue
        material=resources[binding['active_material']]
        shader=resources.get(material.get('children',{}).get('shader'),{})
        if shader.get('path'):
            groups[shader['path']]=groups.get(shader['path'],0)+1
    for required_shader in ['waterfall_curtain','water_veilfall_fall','water_veilfall_spray',
                            'water_veilfall_silhouette','water_current_flow']:
        assert groups.get('res://shaders/'+required_shader+'.gdshader',0)>0
    report['required_water_surface_samplers']=required_water_samplers
    report['pump_bindings']=pump_textures
    report['veilfall_distinct_shader_counts']=groups
    report['active_unbound_triage']='Only hidden Player/Model/Body and Nose fallback capsules; character_model.gd::_hide_placeholders hides them once imported art is built. No visible active surface has a null material in the census.'
    report['null_sampler_triage']='The three ShaderMaterial resources are WaterGroundCover grass/strand-bush/strand-flower tiers. _height_maps/_control_maps/_color_maps use direct RenderingServer RID assignments in grass_field.gd:1819-1865; Resource.get_shader_parameter null is not a proven GPU missing binding. This census does not record those direct RID readbacks.'
    output['frames'].append(report)
output['bounded_verdict']='No concrete missing active material or required WaterSurface/pump/Veilfall material resource found in the recorded mounted subset. No gameplay fix justified by this evidence. Whole F26#0 remains unproved on this Water supplement alone.'
output['limits']=[
    'Exact Medium Forward+ only. Two staged daytime views, not whole visual matrix, earned route, weather/Surge/aftermath or High proof.',
    'Tree-wide visible_in_tree means scene visibility, not in-camera pixel visibility; many Veilfall-name nodes are ordinary imported vegetation.',
    'No missing external source path or empty shader in this recorded graph is not proof against an earlier silent substitution before binding.',
    'Terrain3DMaterial dictionary shader parameters are not traversed: coastal/coast_dune textures and Terrain3D private arrays have source assignment plus declared names, not actual texture/RID readback certification.',
    'GroundCover maps are direct GPU RID bindings not represented by ShaderMaterial getter, therefore their null getter entries are unresolved runtime-bind observations rather than demonstrated failures.',
    'Stormwood distinct families remain outside this Water supplement; use one existing production census if that gap must be closed, not another full timing or visual matrix.',
    'No full-bar judgment or criterion MET.']
out=Path('.tmp/f26-water-independent-material-review.json')
out.write_text(json.dumps(output,indent=2)+'\n',encoding='utf-8')
for f in output['frames']:
    print(json.dumps(dict(frame_id=f['frame_id'], bindings=f['binding_count'], resources=f['resource_count'],
        unbound=[{'node':b['node'],'visible':b['visible_in_tree']} for b in f['unbound_active_surfaces']],
        missing=len(f['source_paths_missing']), empty_shader=len(f['empty_shader_code']),
        null_samplers=f['null_shader_samplers'],
        family_counts={k:v['bindings'] for k,v in f['families'].items()}),indent=2))
print('OUTPUT',out)
