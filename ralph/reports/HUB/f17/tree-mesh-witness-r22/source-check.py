"""Author R22 source preservation and bounded indexing models; native UNRUN."""
from pathlib import Path
import gzip,hashlib,json,math,random,re,struct
P=Path(__file__).resolve().parent;W=P.parents[4]
checks=[]
def ck(name,value):
 if not value:raise AssertionError(name)
 checks.append(name)
def sha(b):return hashlib.sha256(b).hexdigest()
path='tools/_probe_scatter_tree_prompt_height.gd'
old=(P/'originals'/path).read_bytes();new=(P/'proposal'/path).read_bytes()
ck('working probe matches frozen proposal',(W/path).read_bytes()==new)
member=b'var _geometry_faces := PackedVector3Array()\n'
hook=b'\t# One full-precision geometry witness before the unchanged original walk.\n\tprint("TREE_GEOMETRY ", JSON.stringify(_fixture_geometry(world, trunk, placement, layer, order), "", true, true))\n'
start=new.index(b'\t_geometry_faces = faces.duplicate()')
end=new.index(b'func _axis(',start)
helpers=new[start:end]
reversed_source=new[:start]+b'\n'+new[end:]
reversed_source=reversed_source.replace(member,b'',1).replace(hook,b'',1)
ck('exact complete R19 probe recovered by removing only capture additions',reversed_source==old)
for name,digest in json.loads((P/'unchanged-paths.json').read_bytes()).items():ck('unchanged '+name,sha((W/name).read_bytes())==digest)
src=new.decode('utf-8');extra=helpers.decode('utf-8')
ck('single pre-walk print',src.count('print("TREE_GEOMETRY ')==1)
ck('full precision explicit', 'JSON.stringify(_fixture_geometry(world, trunk, placement, layer, order), "", true, true)' in src)
ck('capture after original settle before original walk',src.index('for frame in 30: await physics_frame')<src.index('print("TREE_GEOMETRY ')<src.index('for frame in 180:'))
ck('native sample output cannot gate success','if record[' not in src and 'if _fixture_geometry' not in src)
ck('same all original frame awaits',new.count(b'await physics_frame')==old.count(b'await physics_frame') and new.count(b'await process_frame')==old.count(b'await process_frame'))
ck('same stick/action operations',new.count(b'_axis(')==old.count(b'_axis(') and new.count(b'Input.parse_input_event')==old.count(b'Input.parse_input_event'))
ck('no added frame, queries, scene nodes or mutation',all(token not in extra for token in ['await ','body_test_motion(','.intersect_shape(','.collide_shape(','.cast_motion(','.get_rest_info(','.test_move(','.move_and_slide(','.set_faces(','.height_at(','.new()', '.add_child(']) and re.search(r'\.(position|global_position|transform|shape|disabled)\s*=(?!=)',extra) is None)
ck('snapshot is actual construction array','_geometry_faces = faces.duplicate()' in src)
ck('exact1176face count before vertex loop',extra.index('_geometry_faces.size() != 1176')<extra.index('for vertex: Vector3 in _geometry_faces'))
ck('finite vertices before dictionary/JSON',extra.index('not vertex.is_finite()')<extra.index('ids.has(vertex)'))
ck('225vertex cap before append',extra.index('vertices.size() == 225')<extra.index('vertices.append'))
ck('exact225 count before triangle output',extra.index('vertices.size() != 225')<extra.index('for index in 392'))
ck('392triangle index records','for index in 392:' in extra and 'indices[index * 3 + 2]' in extra)
ck('expected registered types',[src.count(t) for t in ['SHAPE_CONCAVE_POLYGON','SHAPE_CYLINDER','SHAPE_CAPSULE']]==[2,1,2])
ck('RID/type/one shape checked before native data',extra.index('body_get_shape_count(rid) != 1')<extra.index('shape_get_data(shape)') and extra.index('shape_get_type(shape) != expected_type')<extra.index('shape_get_data(shape)'))
ck('native triangle faces exact match','data.faces == _geometry_faces' in extra and 'if data.faces != _geometry_faces' in extra)
ck('primitive dimensions server and resource captured','"resource_height"' in extra and 'height != record.shape_data.resource_height' in extra and 'radius != record.shape_data.resource_radius' in extra)
ck('registered and node transforms captured','body_get_state(rid, PhysicsServer3D.BODY_STATE_TRANSFORM)' in extra and 'body_get_shape_transform(rid, 0)' in extra and '"shape_node_world_pose"' in extra)
ck('native node pose/space/shape parity checked','body_pose == body.global_transform' in extra and 'local_pose == collision.transform' in extra and 'body.get_world_3d().space' in extra and extra.count('body_get_shape_count(rid)')==2)
ck('effective mask/layer recorded','body_get_collision_layer(rid)' in extra and 'body_get_collision_mask(rid)' in extra)
ck('basis scale and full signed bases captured','"basis_scale"' in extra and '"basis_determinant"' in extra and all('"basis_'+axis+'"' in extra for axis in ['x','y','z']))
ck('disabled server limitation explicit','"server_disabled_state_observed": false' in extra and 'no public server getter' in extra and 'and not collision.disabled' in extra)
ck('no invented server disabled getter','body_is_shape_disabled' not in extra and 'body_get_shape_disabled' not in extra)
ck('no invented exception getter','body_get_collision_exceptions' not in extra)
ck('no new prompt offer or LOS call','_prompt.interaction_offer' not in extra and '"radius": _prompt.radius' in extra and '"global_transform": _geometry_transform(_prompt.global_transform)' in extra)
ck('same kept identity and actual settled state','"kept_record"' in extra and '"order": order' in extra and '"settled_start"' in extra and '"floor_max_angle": _player.floor_max_angle' in extra)
ck('native backend class recorded','direct_space_state.get_class()' in extra)
ck('capture alone never acceptance','"acceptance": false' in extra and '"native_queries_added": 0' in extra)
def f32(x):return struct.unpack('<f',struct.pack('<f',x))[0]
def encode(faces):
 if len(faces)!=1176:return None
 ids={};vertices=[];indices=[]
 for vertex in faces:
  if not all(math.isfinite(v) for v in vertex):return None
  if vertex not in ids:
   if len(vertices)==225:return None
   ids[vertex]=len(vertices);vertices.append(vertex)
  indices.append(ids[vertex])
 if len(vertices)!=225:return None
 return vertices,[indices[i*3:i*3+3] for i in range(392)]
rng=random.Random(22);maximum_json=0
for model in range(64):
 heights={(x,z):f32(rng.uniform(-25,25)) for x in range(-7,8) for z in range(-7,8)}
 faces=[]
 for x in range(-7,7):
  for z in range(-7,7):
   points=[(f32(98.15209197998047+dx),heights[dx,dz],f32(-35.932098388671875+dz)) for dx,dz in [(x,z),(x+1,z),(x,z+1),(x+1,z+1)]]
   faces.extend(points[i] for i in [0,1,2,1,3,2])
 vertices,triangles=encode(faces)
 decoded=json.loads(json.dumps({'vertices':vertices,'triangle_indices':triangles},separators=(',',':')))
 reconstructed=[tuple(decoded['vertices'][i]) for tri in decoded['triangle_indices'] for i in tri]
 ck('synthetic indexing model exact full diagonal/values '+str(model),len(vertices)==225 and len(triangles)==392 and reconstructed==faces and all(0<=i<225 for tri in triangles for i in tri))
 maximum_json=max(maximum_json,len(json.dumps(decoded,separators=(',',':'))))
ck('wrong face count refuses bounded metadata',encode(faces[:-1]) is None and encode(faces+[faces[0]]) is None)
bad=faces.copy();bad[0]=(math.nan,0,0)
ck('nonfinite vertex refuses bounded metadata',encode(bad) is None)
bad=faces.copy();bad[1]=(1000,0,1000)
ck('226th vertex refuses without oversized output',encode(bad) is None)
for name,meta in json.loads((P/'native-source/provenance.json').read_bytes()).items():ck('pinned source '+name,sha((P/'native-source'/name).read_bytes())==meta['sha256'] and '/5b4e0cb0f/' in meta['url'])
apis=(P/'native-source/servers/physics_3d/physics_server_3d.cpp').read_text(encoding='utf-8')
for name in ['body_get_shape_count','body_get_shape','body_get_shape_transform','body_get_state','body_get_space','body_get_collision_layer','body_get_collision_mask','shape_get_type','shape_get_data']:ck('GDScript API bound '+name,'D_METHOD("'+name+'"' in apis)
xml=(P/'native-source/doc/classes/JSON.xml').read_text(encoding='utf-8')
ck('full_precision API bound and documented','name="full_precision"' in xml and 'guarantee exact decoding' in xml)
native=(P/'native-source/modules/godot_physics_3d/godot_shape_3d.cpp').read_text(encoding='utf-8')
ck('native Concave dictionary faces producer','d["faces"] = get_faces();' in native and 'd["backface_collision"] = backface_collision;' in native)
prior=json.loads((P/'prior-failure/result.json').read_bytes())
ck('prior original native tree failure retained',prior['exit']==1 and sha((P/'prior-failure/smoke.log').read_bytes())==prior['raw_log_sha256'])
ci=gzip.decompress((P/'latest-mira-ci/job-110442934661-decoded.log.gz').read_bytes())
ck('latest Mira POST Terrain failure retained',b'0.0013064146' in ci and b'Mira' in ci and b'"live_state_phase":"post"' in ci and b'/root/MeadowsPlayground/Terrain' in ci)
result={'scope':'AUTHOR SOURCE/BOUNDED INDEXING ONLY; Godot parser/unit/native UNRUN; actual prior FAIL authoritative','checks_passed':len(checks),'checks':checks,'synthetic_index_models':64,'synthetic_height_values':'random indexing data, never represented as native terrain samples','maximum_synthetic_mesh_json_bytes':maximum_json,'maximum_vertices':225,'maximum_triangles':392,'maximum_face_vertices':1176,'native_queries_added':0,'logical_paths':[path],'proposal_sha256':sha(new),'old_probe_sha256':sha(old),'geometry_witness_native':'PENDING ROOT original probe after independent review','latest_ci_decoded_raw_sha256':sha(ci),'acceptance':False,'F17_4':'OPEN'}
(P/'source-results.json').write_bytes((json.dumps(result,indent=2)+'\n').encode('utf-8'))
print(json.dumps({k:result[k] for k in ['checks_passed','synthetic_index_models','maximum_synthetic_mesh_json_bytes','proposal_sha256','old_probe_sha256','latest_ci_decoded_raw_sha256','acceptance']},indent=2))
