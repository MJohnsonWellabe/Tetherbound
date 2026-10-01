from pathlib import Path
import hashlib, json, subprocess, math
root=Path('D:/tetherbound/redesign-hub'); out=Path(__file__).resolve().parent
H=lambda b:hashlib.sha256(b).hexdigest()
receipt=json.loads(Path('D:/tetherbound/m1-production-callback-r2/receipt.json').read_bytes())
assert receipt['same_source'] and receipt['head_after']==receipt['source']=='00c521aabdaba5a183ec20e3829797ce3f6750ff'
assert receipt['runs'][1]['native_exit']==1
for name,pin in receipt['source_after'].items(): assert H((root/name).read_bytes())==pin,name
rawpins={}
for name in ['receipt.json','native.txt','parser.txt']:
 b=(Path('D:/tetherbound/m1-production-callback-r2')/name).read_bytes(); p=out/'evidence'/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(b);rawpins[name]=H(b)
for row in receipt['runs']:assert rawpins[row['label']+'.txt']==row['raw_sha256']
lines=(out/'evidence/native.txt').read_text().splitlines()
observations=[json.loads(l.removeprefix('OPENING_PRODUCTION_OBSERVATION ')) for l in lines if l.startswith('OPENING_PRODUCTION_OBSERVATION ')]
failure=observations[-1];assert failure['refusal']=='actual production contact observation cap'
counts={};manifolds={}
for c in failure['slide_contacts']:
 counts[c['slide']]=counts.get(c['slide'],0)+1
 manifolds.setdefault((c['collider_rid'],c['collider_shape']),[]).append(c)
config=json.loads((root/'data/config/village_boundary.json').read_bytes())
terrain=json.loads((root/'data/config/terrain_playground.json').read_bytes())
roads=[point for route in terrain['paths']['routes'] for point in route['points']]
roads += [json.loads((root/'data/config/village.json').read_bytes())['road_plan'][k] for k in ['road_start','road_end']]
summary={'parent':receipt['source'],'raw_failure_sha256':rawpins,'failure':failure,'slide_manifold_counts':counts,
 'contact_identity_shapes':len(manifolds),'exact_duplicate_contacts':len(failure['slide_contacts'])-len({json.dumps({k:v for k,v in c.items() if k!='slide'},sort_keys=True) for c in failure['slide_contacts']}),
 'live_recovery_travel_length':math.sqrt(sum(x*x for x in failure['live_recovery_travel'])),
 'unchanged_policy':'Do not deduplicate differing positions/normals or admit >8 aggregate points. Change physical stick approach; preserve all manifold guards and budgets.',
 'boundary_outline':config['outline']['points'],'authored_roads':roads,'gates':config['gates']['entries'],
 'status':'READ_ONLY_DIAGNOSTIC; prior real FAIL preserved; no source/HEAD mutation, no engine'}
(out/'diagnostic.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
(out/'raw-failure-freeze.json').write_text(json.dumps({'parent':receipt['source'],'raw_failure_sha256':rawpins,'diagnostic_sha256':H((out/'diagnostic.json').read_bytes())},indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:summary[k] for k in ['raw_failure_sha256','slide_manifold_counts','contact_identity_shapes','exact_duplicate_contacts','live_recovery_travel_length','authored_roads','gates']}))
