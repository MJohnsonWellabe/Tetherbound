"""Independent R3 source audit; no engine, only reads Git, writes this directory."""
from pathlib import Path
import subprocess, hashlib, json, difflib, re, collections
ROOT=Path('D:/tetherbound/redesign-hub'); OUT=Path(__file__).resolve().parent; PACK=OUT.parent
PARENT='00c521aabdaba5a183ec20e3829797ce3f6750ff'
NAV='tests/helpers/opening_geometry_navigator.gd'; GATHER='tests/helpers/gate_a_npc_gather_segment.gd'
PINS={NAV:'9bb958c945f85cbd297066b5027f20cee4a158b7a0077e05e90aef21c7eb4661',GATHER:'414f2b939bd356062f811af3aa528ecbbdcbc92200c39445a13f7c7ed526af6d'}
PATCH='afb2eaa88392fc015127410e697f34a15e1a9da96d2a9c970413919d87144cb2'
H=lambda b:hashlib.sha256(b).hexdigest()
checks=[]
def check(name,ok,details=None): checks.append({'check':name,'passed':bool(ok),'details':details})
def git(*args): return subprocess.check_output(['git',*args],cwd=ROOT)
freeze=json.loads((PACK/'freeze.json').read_bytes()); cause=json.loads((PACK/'cause-and-constraints.json').read_bytes())
check('pinned HEAD',git('rev-parse','HEAD').decode().strip()==PARENT)
check('pinned lane',git('branch','--show-current').decode().strip()=='tb/hub')
check('exact tracked diff scope',set(git('diff','--name-only').decode().splitlines())==set(PINS))
check('no staged changes',not git('diff','--cached','--name-only').strip())
actual={p.relative_to(PACK).as_posix():H(p.read_bytes()) for p in PACK.rglob('*') if p.is_file() and p.name!='freeze.json' and 'independent' not in p.relative_to(PACK).parts}
check('exact frozen files and hashes',actual==freeze['files_sha256'],len(actual))
check('frozen parent',freeze['parent']==PARENT==cause['parent'])
check('frozen patch exact',H((PACK/'opening-production-detour.patch').read_bytes())==PATCH==freeze['patch_sha256'])
patch=''
for name,pin in PINS.items():
 old=(PACK/'originals'/name).read_bytes(); new=(PACK/'proposal'/name).read_bytes()
 check('exact new source '+name,H(new)==pin==cause['after_source_sha256'][name])
 check('current source frozen '+name,(ROOT/name).read_bytes()==new)
 patch+=''.join(difflib.unified_diff(old.decode().splitlines(True),new.decode().splitlines(True),fromfile='a/'+name,tofile='b/'+name))
check('independently regenerated whole patch',patch.encode()==(PACK/'opening-production-detour.patch').read_bytes())
before=cause['before_source_sha256']
# One read-only cat-file batch obtains pinned original blobs without engine or Git writes.
raw=subprocess.check_output(['git','cat-file','--batch'],input=''.join(PARENT+':'+n+'\n' for n in before).encode(),cwd=ROOT)
offset=0
for name,pin in before.items():
 end=raw.index(b'\n',offset); header=raw[offset:end].split(); size=int(header[-1]); blob=raw[end+1:end+1+size]; offset=end+size+2
 original=(PACK/'originals'/name).read_bytes()
 check('original hash '+name,H(original)==pin)
 check('pinned Git original '+name,original.replace(b'\r\n',b'\n')==blob.replace(b'\r\n',b'\n'))
 if name not in PINS: check('unchanged protected live '+name,H((ROOT/name).read_bytes())==pin)
archives=cause['archives_sha256']; bad=[n for n,pin in archives.items() if not (ROOT/n).is_file() or H((ROOT/n).read_bytes())!=pin]
check('all prior archive hashes',not bad,{'count':len(archives),'mismatches':bad})
check('exact protected tracked archive set',set(archives)==set(git('ls-files','ralph/reports/HUB/f17','ralph/reports/HUB/f18').decode().splitlines()))
rawfreeze=json.loads((PACK/'raw-failure-freeze.json').read_bytes())
for name,pin in rawfreeze['raw_failure_sha256'].items(): check('immutable raw failure '+name,H((PACK/'evidence'/name).read_bytes())==pin)
receipt=json.loads((PACK/'evidence/receipt.json').read_bytes())
check('prior real failure source retained',receipt['source']==PARENT and receipt['same_source'] and receipt['runs'][1]['native_exit']==1
      and receipt['source_after'][NAV]=='be502a6bb89402651965f4d7d5ab750b8de8ee7fe30934baa2959a68629fa74f')
for run in receipt['runs']: check('receipt output '+run['label'],H((PACK/'evidence'/(run['label']+'.txt')).read_bytes())==run['raw_sha256'])
check('prior run disposition',receipt['runs'][0]['native_exit']==0 and round(receipt['runs'][0]['elapsed_seconds'],3)==18.063
      and round(receipt['runs'][1]['elapsed_seconds'],3)==327.422)
native=(PACK/'evidence/native.txt').read_text(); lines=native.splitlines()
observations=[json.loads(l.split(' ',1)[1]) for l in lines if l.startswith('OPENING_PRODUCTION_OBSERVATION ')]
costs=[json.loads(l.split(' ',1)[1]) for l in lines if l.startswith('OPENING_PRODUCTION_LOG_COST ')]
campaign=[json.loads(l.removeprefix('FRESH CAMPAIGN RESULT ')) for l in lines if l.startswith('FRESH CAMPAIGN RESULT ')][-1]
terminal=observations[-1]; points=terminal['slide_contacts']; counts=collections.Counter(p['slide'] for p in points)
check('failed campaign not acceptance',not campaign['requested_prefix_passed'] and not campaign['campaign_complete'] and campaign['checkpoints']==[] and campaign['elapsed_seconds']==312.427)
check('terminal cap evidence',terminal['refusal']=='actual production contact observation cap' and len(points)==8 and sorted(counts.values())==[2,3,3])
identities={json.dumps({k:v for k,v in c.items() if k!='slide'},sort_keys=True) for c in points}
check('eight prefix points not exact duplicates',len(identities)==8)
check('deferred print observed range',min(c['observation_print_us'] for c in costs)==95858 and max(c['observation_print_us'] for c in costs)==321398)
def functions(text):
 starts=list(re.finditer(r'^func (\w+)\(',text,re.M)); result={}
 for i,m in enumerate(starts):
  block=text[m.start():starts[i+1].start() if i+1<len(starts) else len(text)].rstrip()
  cut=re.search(r'\n(?:class |var |# Opt-in)',block)
  result[m.group(1)]=block[:cut.start()].rstrip() if cut else block
 return result
old=(PACK/'originals'/NAV).read_text(); new=(PACK/'proposal'/NAV).read_text(); of=functions(old); nf=functions(new)
changed=sorted(n for n in of if of[n]!=nf.get(n))
check('navigator only intended functions changed',changed==['_choose_route','_init','_production_record','reset','walk_to'],changed)
for name in of:
 if name not in changed: check('unchanged navigator function '+name,of[name]==nf[name])
oldg=(PACK/'originals'/GATHER).read_text(); newg=(PACK/'proposal'/GATHER).read_text(); og=functions(oldg); ng=functions(newg)
gchanged=sorted(n for n in og if og[n]!=ng.get(n))
check('gather only heading and forwarding changed',gchanged==['_gather_authored_node','_walk_toward'],gchanged)
for name in og:
 if name not in gchanged: check('unchanged earned helper function '+name,og[name]==ng[name])
heading='\t# Stone lies beyond the concave fence corner. Follow the existing painted\n\t# Practice Meadow road before turning toward it, inside the same 1800 frames.\n'
normalized=ng['_gather_authored_node'].replace(heading,'').replace('1800, 1.55, "Practice Meadow" if item_id == "stone" else ""','1800, 1.55')
check('all original gather assertions exactly retained',normalized==og['_gather_authored_node'])
check('single shared walk budget',nf['walk_to'].count('while walked < budget')==1 and nf['walk_to'].count('walked += 1')==1
      and 'await step(point)' in nf['walk_to'] and 'budget > 3600' in nf['walk_to'])
check('guidance gated by mandatory departure', 'if not _guided_road.is_empty() and _departure.is_empty():' in nf['_choose_route']
      and of['_native_tick_impl']==nf['_native_tick_impl'])
check('guidance bounded original point storage', 'road.points.size() > MAX_ROAD_INPUTS' in nf['_init']
      and of['_append_road']==nf['_append_road'] and '_authored_roads.has(label)' in nf['_init'] and 'label.length() > 256' in nf['_init'])
check('nearest authored to end then target', 'range(nearest, _guided_road.size())' in nf['_choose_route']
      and '_route.append(_guided_road[index])' in nf['_choose_route'] and '_route.append(point)' in nf['_choose_route'])
check('scope and candidate limits intact', '_plans > MAX_PLANS or from.distance_to(point) > MAX_EDGE or _observed_choice >= MAX_CHOICES' in nf['_choose_route']
      and 'previous.distance_to(_guided_road[index]) > MAX_EDGE' in nf['_choose_route'] and 'previous.distance_to(point) > MAX_EDGE' in nf['_choose_route'])
check('aggregate all contact guards byte unchanged',of['_production_observe']==nf['_production_observe']
      and 'contacts += collision.get_collision_count()' in nf['_production_observe'] and 'if contacts > CONTACTS:' in nf['_production_observe'])
check('added counters bounded eight cached scalars', 'var slide_point_counts: Array[int] = []' in nf['_production_record']
      and 'for slide in mini(CONTACTS, _body.get_slide_collision_count()):' in nf['_production_record']
      and 'slide_point_counts.append(cached.get_collision_count() if cached != null else -1)' in nf['_production_record'])
check('point prefix still bounded eight', 'mini(CONTACTS - slides.size(), collision.get_collision_count())' in nf['_production_record']
      and 'if slides.size() == CONTACTS:' in nf['_production_record'] and '"slide_contacts_are_capped_prefix": true' in nf['_production_record'])
terrain=json.loads((PACK/'originals/data/config/terrain_playground.json').read_bytes()); roads=terrain['paths']['routes']
check('Practice Meadow label existing and unique',len([r for r in roads if r['label']=='Practice Meadow'])==1)
check('new road metadata equals immutable authored road',cause['new_approach']['authored_route']==[r['points'] for r in roads if r['label']=='Practice Meadow'][0])
check('all constants unchanged',re.findall(r'^const .*',old,re.M)==re.findall(r'^const .*',new,re.M))
analyzer=(OUT/'gdscript_analyzer.cpp').read_text()
check('official analyzer allows containing child argument range', 'valid = valid && current_min_argc <= parent_min_argc && parent_max_argc <= current_max_argc;' in analyzer)
check('walk override includes parent allowed arguments and equal first types',
      'func walk_to(point: Vector3, budget: int, close_enough: float = 0.8) -> bool:' in (PACK/'originals/tests/helpers/stick_navigator.gd').read_text()
      and 'func walk_to(point: Vector3, budget: int, close_enough: float = 0.8, authored_road: String = "") -> bool:' in new)
check('immutable packet after audit',{p.relative_to(PACK).as_posix():H(p.read_bytes()) for p in PACK.rglob('*') if p.is_file() and p.name!='freeze.json' and 'independent' not in p.relative_to(PACK).parts}==actual)
failed=[c for c in checks if not c['passed']]
result={'verdict':'SOURCEFAIL' if failed else 'SOURCEPASS','scope':'source readiness only; F17#4 OPEN','parent':PARENT,'source_sha256':PINS,'patch_sha256':PATCH,
        'engine_executed':False,'tracked_writes':False,'script_sha256':H(Path(__file__).read_bytes()),'freeze_sha256':H((PACK/'freeze.json').read_bytes()),
        'protected_archives':len(archives),'raw_failure_sha256':rawfreeze['raw_failure_sha256'],'checks':checks,'failed':failed}
result['parser_primary']={'url':'https://raw.githubusercontent.com/godotengine/godot/4.7-stable/modules/gdscript/gdscript_analyzer.cpp','sha256':H((OUT/'gdscript_analyzer.cpp').read_bytes()),'lines':'1770-1790','engine_parser_executed':False}
(OUT/'review.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'verdict':result['verdict'],'checks':len(checks),'failed':failed,'archives':len(archives)}))
