"""Immutable R20 source/evidence arithmetic. No Godot, parser or native run."""
from pathlib import Path
from fractions import Fraction as F
import hashlib,json,struct
P=Path(__file__).resolve().parent
checks=[]
def check(name,condition):
 if not condition:raise AssertionError(name)
 checks.append(name)
def load(name):return json.loads((P/name).read_bytes())
def text(name):return (P/name).read_text(encoding='utf-8')
def f32(value):return struct.unpack('<f',struct.pack('<f',value))[0]
def exact(value):
 check('finite logged binary32 reconstruct '+str(value),abs(f32(value)-value)<1e-12)
 return F(f32(value))
def out(value):return {'fraction':str(value),'meters':float(value)}
raw=(P/'root-failed/native.log').read_bytes()
check('original native log binding',hashlib.sha256(raw).hexdigest()=='feccf36f0470fc1a095d6b3aaeb8e9b346ffe13742f049929b1bec27248c1a2a')
check('original receipt binding',hashlib.sha256((P/'root-failed/receipt.json').read_bytes()).hexdigest()=='dfed9541b69b2682442ce229bac5593237715e620622a80aacafbeb42af5f908')
check('R19 native failure binding',hashlib.sha256((P/'tree-failed/smoke.log').read_bytes()).hexdigest()=='0e267141c080a2bca82fbec627606fe35e4db822ad7bb1b4c49be7e96b9626a7')
receipt=load('root-failed/receipt.json')
check('actual ROOT head',receipt['head']=='7e487af97357d1357b6594c2e314c15b8f19d63d')
check('closure before equals after',receipt['closure_sha256']==receipt['after_digest']=='f899914a564e47430169de6012988a9528be4a448d1411b67abd7615791ef189')
rows=[json.loads(line.split('OPENING_PRODUCTION_OBSERVATION ',1)[1]) for line in raw.decode('utf-8').splitlines() if line.startswith('OPENING_PRODUCTION_OBSERVATION ')]
row=load('failed-sample.json')
check('single exact original PRE record',len([r for r in rows if 'failed_original_pre_sample' in r])==1 and row in rows)
s=row['failed_original_pre_sample'];g=s['original_motion_contact_geometry'][0]
check('diagnostic complete does not assert admission',s['complete'] and not s['acceptance'] and not s['backend_identity_proven'])
check('first PRE zero input',s['phase']=='original_pre' and row['delivered_input']==[0,0])
check('registered full shape margin and mask',s['query_margin']==0 and s['query_mask']==row['mask']==1 and s['query_motion']==[0,0,0])
check('original query charge',s['queries_before']==1 and s['queries_after']==3 and row['queries']==3)
check('original callback bound',row['timing']['pre_us']<row['timing']['callback_cap_us']==10000)
check('one reported motion BOX',len(s['original_motion_contact_geometry'])==len(row['live_contacts'])==1 and g['shape_type']==3 and g['shape_index']==0)
check('contact/rest identity agree',g['rid']==row['live_contacts'][0]['collider_rid']==s['rest_info']['rid'] and s['rest_info']['shape']==0)
check('original raw pair caveat',s['raw_pairs_are_not_a_penetration_certificate'] and not s['pair_limit_reached'] and s['pair_limit']==8)
identity={'basis_x':[1,0,0],'basis_y':[0,1,0],'basis_z':[0,0,1]}
for key in ['body_pose','shape_local_pose','shape_world_pose']:
 check('box unit identity '+key,all(g[key][k]==v for k,v in identity.items()))
check('capsule query unit identity',all(s['query_pose'][k]==v for k,v in identity.items()))
center=list(map(exact,s['query_pose']['origin']));half=list(map(exact,g['shape_data']));box=list(map(exact,g['shape_world_pose']['origin']))
h=exact(s['capsule']['height']);radius=exact(s['capsule']['radius']);skin=exact(row['safe_margin'])
check('valid complete capsule',h>=2*radius>0)
check('box half extents positive',all(v>0 for v in half))
bottom=center[1]-h/2;top=box[1]+half[1];depth=top-bottom
x_clear=half[0]-abs(center[0]-box[0]);z_clear=half[2]-abs(center[2]-box[2])
check('capsule axis projects inside top rectangle',x_clear>0 and z_clear>0)
check('capsule bottom above box bottom',bottom>box[1]-half[1])
check('segment lower center above top plane',center[1]-(h/2-radius)>top)
check('pair ideal initial penetration below skin',0<depth<skin)
# This is an envelope around stored geometry arithmetic, not an all-world
# numerical theorem. With exact identity bases, support bounds involve only
# sums/differences and halving; no rotating-axis cancellation or sqrt occurs.
# All Y terms/intermediates are below 4m. One full binary32 ULP at 4m is
# 2^-21m; allowing 64 ULP per surface exceeds the finite identity-expression
# operation count and includes the logged local/world composition discrepancy.
round_budget=64*F(1,2**21)
lower=depth-2*round_budget;upper=depth+2*round_budget
composed_box_y=exact(g['body_pose']['origin'][1])+exact(g['shape_local_pose']['origin'][1])
support_top=exact(s['rest_info']['point'][1])
check('box composition discrepancy within envelope',abs(composed_box_y-box[1])<round_budget)
check('reported support rounding within envelope',abs(support_top-top)<round_budget)
check('body/capsule bottom parity',abs(exact(s['body_pose']['origin'][1])-bottom)<round_budget)
check('rounding envelope below skin',0<lower<upper<skin)
# Pair-only virtual witness, quantized exactly as a Vector3 origin. Never
# writes a player or runs a query. A 0.4mm rise clears the conservative pair
# envelope and stays strictly inside the original 1mm skin.
shifted=F(f32(float(center[1])+0.0004));rise=shifted-center[1]
gap=(shifted-h/2-round_budget)-(top+round_budget)
check('quantized virtual rise inside original skin',0<rise<skin)
check('virtual full capsule pair envelope clear',gap>0)
check('floor collider never excluded from proof',g['rid']!=s['excluded_self_only'])
check('raw recovery remains above original guard',exact(row['live_recovery_travel'][1])>skin+F(1,100000))
check('post recovery depth differs from initial',abs(F(row['live_contacts'][0]['depth'])-depth)>F(1,100000))
provenance=load('native-source/provenance.json')
for name,meta in provenance.items():
 data=(P/'native-source'/name).read_bytes()
 check('pinned source '+name,len(data)==meta['bytes'] and hashlib.sha256(data).hexdigest()==meta['sha256'] and '/5b4e0cb0f/' in meta['url'])
def src(name):return text('native-source/'+name)
godot=src('modules/godot_physics_3d/register_types.cpp');jolt=src('modules/jolt_physics/register_types.cpp')
check('Godot compiled default priority0', 'set_default_server("GodotPhysics3D")' in godot and 'int p_priority = 0' in src('servers/physics_3d/physics_server_3d.h'))
check('Jolt registration does not set default','register_server("Jolt Physics"' in jolt and 'set_default_server(' not in jolt)
check('manager initial priority-1','default_server_priority = -1' in src('servers/physics_3d/physics_server_3d.h'))
check('manager priority strict ordering','if (default_server_priority < p_priority)' in src('servers/physics_3d/physics_server_3d.cpp'))
check('DEFAULT startup fallback','new_default_server()' in src('main/main.cpp') and s['configured_backend']=='DEFAULT')
check('no project engine override','physics_engine=' not in text('originals/project.godot'))
for cls,file in [('GodotPhysicsDirectSpaceState3D','modules/godot_physics_3d/godot_space_3d.h'),('JoltPhysicsDirectSpaceState3D','modules/jolt_physics/spaces/jolt_physics_direct_space_state_3d.h')]:
 check('live class discriminant '+cls,'GDCLASS('+cls+', PhysicsDirectSpaceState3D)' in src(file))
space=src('modules/godot_physics_3d/godot_space_3d.cpp')
method=space.split('int GodotPhysicsDirectSpaceState3D::intersect_shape',1)[1].split('bool GodotPhysicsDirectSpaceState3D::cast_motion',1)[0]
check('exact hidden candidate cap2048','INTERSECTION_QUERY_MAX = 2048' in src('modules/godot_physics_3d/godot_space_3d.h'))
check('cull before result filter',method.index('cull_aabb(')<method.index('_can_collide_with(')<method.index('solve_static('))
check('result count does not return cull count','return cc;' in method and 'return amount;' not in method)
check('server BOX half extent source','return half_extents;' in src('modules/godot_physics_3d/godot_shape_3d.cpp') and 'shape_set_data(get_shape(), size / 2)' in src('scene/resources/3d/box_shape_3d.cpp'))
check('capsule complete height source','-height * 0.5' in src('modules/godot_physics_3d/godot_shape_3d.cpp'))
nav=text('originals/tests/helpers/opening_geometry_navigator.gd')
check('strict raw guard retained','zero-motion recovery exceeds unchanged skin' in nav and '_capture_failed_pre_sample()' in nav)
check('server exception getter is not script-bound','virtual void body_get_collision_exceptions(' in src('servers/physics_3d/physics_server_3d.h') and 'D_METHOD("body_get_collision_exceptions"' not in src('servers/physics_3d/physics_server_3d.cpp'))
results={'scope':'AUTHOR SOURCE AND PAIR-ONLY ARITHMETIC; native failure authoritative','checks_passed':len(checks),'checks':checks,'root_engine_sha256':receipt['engine_sha256'],'body_and_query_bottom':out(bottom),'box_top_ideal':out(top),'box_top_native_rounded':out(support_top),'box_composition_difference':out(box[1]-composed_box_y),'initial_pair_penetration':out(depth),'rounding_per_surface_budget':out(round_budget),'conservative_pair_depth_interval':[out(lower),out(upper)],'xz_axis_inside_margins':[out(x_clear),out(z_clear)],'pair_only_virtual_rise':out(rise),'pair_only_virtual_gap_lower':out(gap),'compiled_default_backend':'GodotPhysics3D; source-derived from pinned official build registration','live_backend_discriminant_observed':False,'initial_candidate_completeness_proven':False,'all_colliders_certified':False,'native_clearance_witness_run':False,'admission':False,'R9_general_replacement':'HOLD','F17_4':'OPEN'}
(P/'source-results.json').write_bytes((json.dumps(results,indent=2)+'\n').encode('utf-8'))
print(json.dumps({k:results[k] for k in ['checks_passed','initial_pair_penetration','conservative_pair_depth_interval','pair_only_virtual_rise','pair_only_virtual_gap_lower','admission']},indent=2))
