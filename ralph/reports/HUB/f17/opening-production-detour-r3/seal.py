from pathlib import Path
import hashlib,json,subprocess,difflib,math
root=Path('D:/tetherbound/redesign-hub');out=Path(__file__).resolve().parent
H=lambda b:hashlib.sha256(b).hexdigest();parent='00c521aabdaba5a183ec20e3829797ce3f6750ff'
owned=['tests/helpers/opening_geometry_navigator.gd','tests/helpers/gate_a_npc_gather_segment.gd']
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=root).decode().strip()==parent
assert set(subprocess.check_output(['git','diff','--name-only'],cwd=root).decode().splitlines())==set(owned)
receipt=json.loads((out/'evidence/receipt.json').read_bytes()); before=receipt['source_after'].copy()
before['data/config/village_boundary.json']=H((root/'data/config/village_boundary.json').read_bytes())
before['data/config/building_prefabs.json']=H((root/'data/config/building_prefabs.json').read_bytes())
for name,pin in before.items():
 raw=(root/name).read_bytes()
 if name in owned:
  oldbase=root/'ralph/reports/HUB/f17/opening-production-callback-r2'
  raw=(oldbase/('proposal' if 'navigator' in name else 'originals')/name).read_bytes()
 assert H(raw)==pin,(name,H(raw),pin)
 gitraw=subprocess.check_output(['git','show',parent+':'+name],cwd=root)
 assert raw.replace(b'\r\n',b'\n')==gitraw.replace(b'\r\n',b'\n'),name
 p=out/'originals'/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(raw)
after={};patch=b''
for name in owned:
 raw=(root/name).read_bytes();p=out/'proposal'/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(raw);after[name]=H(raw)
 patch+=''.join(difflib.unified_diff((out/'originals'/name).read_bytes().decode().splitlines(True),raw.decode().splitlines(True),fromfile='a/'+name,tofile='b/'+name)).encode()
(out/'opening-production-detour.patch').write_bytes(patch)
names=subprocess.check_output(['git','ls-files','ralph/reports/HUB/f17','ralph/reports/HUB/f18'],cwd=root).decode().splitlines()
archives={n:H((root/n).read_bytes()) for n in names}
native=(out/'evidence/native.txt').read_text();lines=native.splitlines()
costs=[json.loads(l.removeprefix('OPENING_PRODUCTION_LOG_COST '))['observation_print_us'] for l in lines if l.startswith('OPENING_PRODUCTION_LOG_COST ')]
obs=[json.loads(l.removeprefix('OPENING_PRODUCTION_OBSERVATION ')) for l in lines if l.startswith('OPENING_PRODUCTION_OBSERVATION ')];f=obs[-1]
terrain=json.loads((root/'data/config/terrain_playground.json').read_bytes());road=next(r['points'] for r in terrain['paths']['routes'] if r['label']=='Practice Meadow')
from_xz=(36,-16);idx=min(range(len(road)),key=lambda i:math.dist(from_xz,road[i]));points=[from_xz]+road[idx:]+[[47,-34.5]]
cause={'parent':parent,'permissions':{'approval_policy':'never','sandbox_mode':'danger-full-access'},'owned_paths':owned,'before_source_sha256':before,'after_source_sha256':after,'archives_sha256':archives,
 'prior':{'parser':0,'native':1,'native_seconds':327.422,'campaign_seconds':312.427,'Mira_and_wood':'Passed earlier blocker, real shop/tools and +4 Wood; entire village/gather and M1 prefix FAILED, F17#4 OPEN','receipt_sha256':H((out/'evidence/receipt.json').read_bytes()),'native_sha256':H((out/'evidence/native.txt').read_bytes())},
 'cause':{'failure':f['refusal'],'callback_own_us':f['callback_own_us'],'queries':f['queries'],'live_phase':f['live_state_phase'],'recorded_slide_counts_prefix':[2,3,3],'recorded_points':8,'actual_total':'greater than8 inferred from unchanged aggregate guard; exact total/third result count unavailable in old capped record','no_exact_duplicates':'Eight recorded points differ; cannot identify omitted points or deduplicate manifold by collider identity','live_skin':'Recovery length0.0006009215 and depths0.0001135/0.0000680 below unchanged skin0.001; controller grounded, recoverycount0; cap still refuses','print_us_min':min(costs),'print_us_max':max(costs),'tail_print_ms_range':[116,278],'print_limit':'Measured deferred IO substantial, not proof it was sole old deadline cause; still charged to overall physics tick'},
 'new_approach':{'stone_only':'Same node selected; physical stick follows existing Practice Meadow painted road from nearest authored node before turning toward stone. Wood unchanged. Original1800 budget spans every waypoint; no extra leg budget, fixture, grant or pose write. Original door departure still precedes guidance. Every actual step keeps full guards and aggregate8 contact cap. No dedup/query cache workaround.','authored_route':road,'illustrative_metadata_route':points,'illustrative_metadata_length_m':sum(math.dist(a,b) for a,b in zip(points,points[1:])),'limit':'Metadata route is advisory, not a terrain/collision theorem or actual success. Runtime path required. Stops on stall/physical cap.'},
 'diagnostics':'At most8 scalar cached-slide point counts added to sampled snapshot, point record remains capped8 prefix, no additional native query. All recorded/cached manifold guards unchanged.',
 'caps':{'callback_us':10000,'gather_frames':1800,'team_frames':3600,'stall_frames':90,'retry_frames':26,'aggregate_contacts':8,'frame_queries':96,'lifetime_queries':250000,'requests':24000},
 'root_proof':['--through-tournament','--world-seed=4','--no-checkpoints','--opening-contact-diagnostics'],'state':'FROZEN_SOURCE_CANDIDATE; independent source gate and ROOT actual fresh prefix required, no engine here, F17#4 OPEN'}
(out/'cause-and-constraints.json').write_text(json.dumps(cause,indent=2)+'\n',encoding='utf-8')
manifest={p.relative_to(out).as_posix():H(p.read_bytes()) for p in out.rglob('*') if p.is_file() and p.name!='freeze.json' and 'independent' not in p.relative_to(out).parts}
(out/'freeze.json').write_text(json.dumps({'parent':parent,'state':'FROZEN_SOURCE_CANDIDATE','patch_sha256':H(patch),'files_sha256':manifest},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'after':after,'patch':H(patch),'protected_archives':len(archives),'guided_illustration_metres':cause['new_approach']['illustrative_metadata_length_m'],'measured_print_us':[min(costs),max(costs)]}))
