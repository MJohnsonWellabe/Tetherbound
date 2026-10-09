from pathlib import Path
from PIL import Image,ImageDraw
import json,re,hashlib,struct,zlib
packet=Path('C:/CodexTemp/tetherbound-proof/native-e-6a5f4bf281-gate-perches-r1')
raw=Path('D:/CodexTemp/tetherbound-native/d-e2d54b40aa/.tmp/e-gate-perches-6a5f-day-r1')
terminal=json.loads((packet/'capture-terminal.json').read_text(encoding='utf-8-sig'))
assert terminal['source']=='6a5f4bf281138b8560825725fca6eefaf8f7de82' and terminal['exit_code']==0 and terminal['reason']=='process_exit'
manifest=(raw/'manifest.txt').read_text(encoding='utf-8-sig')
assert '# frame matrix: 4 frames written, 0 rows skipped' in manifest
lines=manifest.splitlines();graphics=[json.loads(s[len('# graphics_capture '):]) for s in lines if s.startswith('# graphics_capture ')]
assert len(graphics)==1 and graphics[0]['source_commit']==terminal['source']
assert graphics[0]['preset']=='High' and graphics[0]['renderer']=='forward_plus' and graphics[0]['resolution']==[1920,1080]
rows=[s for s in lines if s.startswith('MANIFEST ')]
assert len(rows)==4
names=[s[len('MANIFEST '):].split(' | ')[0] for s in rows]
assert [n[:2] for n in names]==['01','04','19','20'] and 'approach' in names[0] and 'detail-crag' in names[1] and 'landing' in names[2] and 'vista' in names[3]
files=sorted(p for p in raw.glob('*.png') if not p.name.startswith('_'))
assert {p.stem for p in files}==set(names) and len(files)==4
logs=(packet/'capture.stdout.log').read_text(encoding='utf-8-sig')+'\n'+(packet/'capture.stderr.log').read_text(encoding='utf-8-sig')
assert not re.search(r'^(SCRIPT ERROR:|ERROR:)',logs,re.M)
checks=[];contact=Image.new('RGB',(1920,1130),(22,22,22));draw=ImageDraw.Draw(contact)
for i,p in enumerate(files):
 data=p.read_bytes();assert data[:8]==b'\x89PNG\r\n\x1a\n';offset=8;dims=None;ended=False
 while offset<len(data):
  n=struct.unpack('>I',data[offset:offset+4])[0];kind=data[offset+4:offset+8];payload=data[offset+8:offset+8+n]
  crc=struct.unpack('>I',data[offset+8+n:offset+12+n])[0];assert zlib.crc32(kind+payload)&0xffffffff==crc
  if kind==b'IHDR':dims=list(struct.unpack('>II',payload[:8]))
  offset+=n+12
  if kind==b'IEND':ended=True;break
 assert ended and offset==len(data) and dims==[1920,1080]
 with Image.open(p) as im:
  im.load();im=im.convert('RGB');im.thumbnail((960,540));contact.paste(im,((i%2)*960,(i//2)*565));draw.text(((i%2)*960+4,(i//2)*565+543),p.stem,fill='white')
 checks.append({'original':str(p),'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data),'dimensions':dims,'png_crc_verified':True})
summary={'source':terminal['source'],'exit':0,'frames':4,'selected_rows':[1,4,19,20],'graphics':graphics[0],'manifest_sha256':hashlib.sha256((raw/'manifest.txt').read_bytes()).hexdigest(),'scope':'Four existing Gate/Perches day rows and read-only geometry/actor operands only; separate Gate/Perches original runtime and blind reviews required. Original staged chapter fixture, no whole criterion, blind PASS, earned route, motion or performance claim.'}
(packet/'native-image-integrity.json').write_text(json.dumps(checks,indent=2)+'\n')
# Persist unified summary only after actor/pocket checks below.
contact.save(packet/'native-four-frame-contact.jpg',quality=94)
import math
before=json.loads((packet/'source-before-capture.json').read_text(encoding='utf-8-sig'))
after=json.loads((packet/'source-after-capture.json').read_text(encoding='utf-8-sig'))
assert before['source']==after['source']==terminal['source']
assert before['tracked_clean'] and after['tracked_clean']
assert before['head_tree']==before['index_tree']==after['head_tree']==after['index_tree']
observations=[s for s in lines if s.startswith('# realm_gate_render_support ')]
assert len(observations)==1
geometry=json.loads(observations[0][len('# realm_gate_render_support '):])
assert geometry['status']=='sampled_mounted_render_triangles' and geometry['frame_id'] in names
assert geometry['expected_targets']==geometry['observed_targets']=={'facade':1,'tower':2,'paver':3}
def finite(value):
 if isinstance(value,dict): return all(finite(v) for v in value.values())
 if isinstance(value,list): return all(finite(v) for v in value)
 if isinstance(value,(float,int)) and not isinstance(value,bool): return math.isfinite(value)
 return True
assert finite(geometry)
assert len(geometry['targets'])==6 and all(t['bottom_query_count']>0 for t in geometry['targets'])
targets=[]
for target in geometry['targets']:
 qs=[q for q in geometry['queries'] if q['target_path']==target['path']]
 assert len(qs)==target['bottom_query_count']
 gaps=[]
 for q in qs:
  assert q['unsupported_xz']==(not bool(q['hits']))
  below=[h for h in q['hits'] if h['height']<=q['world_foot'][1]]
  assert q['no_support_below_foot']==(not bool(below))
  for h in q['hits']:
   assert 0<=h['mesh_index']<len(geometry['meshes']) and len(h['triangle_world'])==3
   assert abs(h['foot_minus_height']-(q['world_foot'][1]-h['height']))<0.0001
  if below:gaps.append(min(h['foot_minus_height'] for h in below))
 targets.append({'path':target['path'],'role':target['role'],'queries':len(qs),'unsupported_xz':sum(q['unsupported_xz'] for q in qs),'no_support_below_foot':sum(q['no_support_below_foot'] for q in qs),'nearest_below_gap_range':[min(gaps),max(gaps)] if gaps else None})
support={'source':terminal['source'],'frame_id':geometry['frame_id'],'observer_line_sha256':hashlib.sha256(observations[0].encode()).hexdigest(),'queries':len(geometry['queries']),'meshes':len(geometry['meshes']),'target_config_sha256':geometry['target_config_sha256'],'targets':targets,'scope':'Geometric column operands only; no walkability, contact, material, blind, earned, performance or whole acceptance claim.'}
(packet/'gate-support-integrity.json').write_text(json.dumps(support,indent=2)+'\n')
print(json.dumps({'source':support['source'],'queries':support['queries'],'meshes':support['meshes'],'targets':len(targets)}))
# Final summary printed after all selected-row checks.



actor_lines = [s for s in lines if s.startswith('# perch_actor_snapshot ')]
assert len(actor_lines) == 2
actors = [json.loads(s[len('# perch_actor_snapshot '):]) for s in actor_lines]
assert [a['frame_id'] for a in actors] == names[2:]
assert re.search(r'^Vulkan .* - Forward\+ - Using Device', logs, re.M)
for a in actors:
    assert a['status'] == 'sampled_mounted_actors' and a['physics_tick'] > 0 and a['drawn_frame'] > 0
    assert finite(a) and a['camera'] and a['actors']
    assert a['image_path'].endswith('/' + a['frame_id'] + '.png')
    pocket = a['edge_nature']
    assert pocket['status'] == 'mounted' and pocket['children'] == len(pocket['placements']) == 15
    assert len({p['path'] for p in pocket['placements']}) == 15
    assert all(p['model_status'] == 'present' and p['model_transform'] for p in pocket['placements'])
receipt = {'source': terminal['source'], 'selected_rows': [19,20], 'authored_placements':15,
           'original_readonly_actor_and_pocket_receipts':actors,
           'scope':'Actual mounted identities/transforms only; no inferred ownership, pixel identity, no-floating, spacing fix, whole visual or runtime verdict.'}
(packet/'perches-actor-pocket-integrity.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps({'source':terminal['source'],'actor_records':len(actors),'mounted_placements_each':[len(a['edge_nature']['placements']) for a in actors]}))

(packet/'native-verified-summary.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps(summary))

