"""Independent R4 audit: explicit UTF-8, binary pins, read-only Git, no engine."""
from pathlib import Path
import json,hashlib,subprocess,re,difflib
ROOT=Path('D:/tetherbound/redesign-hub'); OUT=Path(__file__).resolve().parent; PACK=OUT.parent
PARENT='8189ef734addce12d446c6c9a0f9d4016a0d657d'; NAV='tests/helpers/opening_geometry_navigator.gd'; GATHER='tests/helpers/gate_a_npc_gather_segment.gd'
SOURCE='282731a0b8450aa2dedc9d617d1e12ac38e8b3300e9b812ae9f1f87d64fb93ba'; PATCH='cd7edb02cf0912b215733d84eaf0e1f8e01592a3af61db8382e9715751456f0a'
H=lambda b:hashlib.sha256(b).hexdigest(); checks=[]
def check(name,ok,detail=None): checks.append({'name':name,'passed':bool(ok),'detail':detail})
def git(*args): return subprocess.check_output(['git',*args],cwd=ROOT)
freeze=json.loads((PACK/'freeze.json').read_bytes()); cause=json.loads((PACK/'cause-and-constraints.json').read_bytes())
check('parent and lane',git('rev-parse','HEAD').decode().strip()==PARENT==freeze['parent']==cause['parent'] and git('branch','--show-current').decode().strip()=='tb/hub')
check('tracked diff navigator only',git('diff','--name-only').decode().splitlines()==[NAV] and not git('diff','--cached','--name-only').strip())
def packet_hashes():
 return {p.relative_to(PACK).as_posix():H(p.read_bytes()) for p in PACK.rglob('*') if p.is_file() and p.relative_to(PACK).parts[0]!='independent' and p.relative_to(PACK).as_posix()!='freeze.json'}
frozen=packet_hashes(); check('exact32 frozen files and every hash',len(frozen)==32 and frozen==freeze['files_sha256'])
check('exact requested candidate source and patch',H((PACK/'proposal'/NAV).read_bytes())==SOURCE and H((PACK/'opening-production-obstacle.patch').read_bytes())==PATCH==freeze['patch_sha256'])
for name,pin in cause['after_source_sha256'].items():
 check('proposal current raw '+name,H((ROOT/name).read_bytes())==pin and (ROOT/name).read_bytes()==(PACK/'proposal'/name).read_bytes())
before=cause['before_source_sha256']; blobs=git('cat-file','--batch') if False else subprocess.check_output(['git','cat-file','--batch'],cwd=ROOT,input=''.join(PARENT+':'+n+'\n' for n in before).encode())
cursor=0
for name,pin in before.items():
 end=blobs.index(b'\n',cursor); size=int(blobs[cursor:end].split()[-1]); blob=blobs[end+1:end+1+size]; cursor=end+size+2
 raw=(PACK/'originals'/name).read_bytes(); check('original exact pin '+name,H(raw)==pin)
 check('original equals pinned Git '+name,raw.replace(b'\r\n',b'\n')==blob.replace(b'\r\n',b'\n'))
 if name!=NAV: check('protected current pin '+name,H((ROOT/name).read_bytes())==pin)
def make_patch():
 return ''.join(''.join(difflib.unified_diff((PACK/'originals'/n).read_bytes().decode('utf-8').splitlines(True),
                (PACK/'proposal'/n).read_bytes().decode('utf-8').splitlines(True),fromfile='a/'+n,tofile='b/'+n)) for n in [NAV,GATHER]).encode('utf-8')
regenerated=make_patch(); supplied=(PACK/'opening-production-obstacle.patch').read_bytes()
check('frozen patch truthfully reproduces original-to-proposal UTF8 bytes',regenerated==supplied,
      {'lossless_regenerated_sha256':H(regenerated),'supplied_sha256':H(supplied),'same_gather_bytes':(PACK/'originals'/GATHER).read_bytes()==(PACK/'proposal'/GATHER).read_bytes()})
check('patch has no nonexistent gather source change',b'--- a/'+GATHER.encode() not in supplied,
      'Supplied patch contains a mojibake-to-em-dash hunk despite identical original/proposal/current gather bytes.')
for label,key,paths in [('archives','archives_sha256',['ralph/reports/HUB/f17','ralph/reports/HUB/f18']),('tests','unchanged_tests_sha256',['tests'])]:
 pins=cause[key]; tracked=set(git('ls-files',*paths).decode().splitlines())
 if label=='tests': tracked-=set(cause['owned_paths'])
 check('exact '+label+' protected path set',set(pins)==tracked,{'count':len(pins)})
 bad=[n for n,pin in pins.items() if not (ROOT/n).is_file() or H((ROOT/n).read_bytes())!=pin]
 check('all '+label+' raw hashes unchanged',not bad,bad)
prior=PACK/'prior-failure'; pfreeze=json.loads((prior/'freeze.json').read_bytes())
for name,pin in pfreeze['files_sha256'].items(): check('prior immutable raw '+name,H((prior/name).read_bytes())==pin)
receipt=json.loads((prior/'receipt.json').read_bytes()); check('prior actual FAIL source',receipt['source']==PARENT and receipt['same_source'] and receipt['runs'][1]['native_exit']==1)
for run in receipt['runs']: check('prior receipt raw '+run['label'],H((prior/(run['label']+'.txt')).read_bytes())==run['raw_sha256'])
diag=json.loads((prior/'diagnostic.json').read_bytes()); check('prior floor and wall twelve-point FAIL retained',diag['exact_cached_contact_total']==12 and diag['cached_manifold_counts']==[2]*6 and len(diag['live_contacts'])==2 and diag['terminal']['refusal']=='actual production contact observation cap')
old=(PACK/'originals'/NAV).read_bytes().decode('utf-8').replace('\r\n','\n'); new=(PACK/'proposal'/NAV).read_bytes().decode('utf-8').replace('\r\n','\n')
def outer_functions(text):
 lines=text.splitlines(True); result={}; i=0
 while i<len(lines):
  m=re.match(r'^func (\w+)\(',lines[i])
  if not m: i+=1; continue
  start=i; i+=1
  while i<len(lines) and (lines[i].startswith(('\t',' ')) or not lines[i].strip() or lines[i].startswith('#')): i+=1
  result[m.group(1)]=''.join(lines[start:i]).rstrip()
 return result
of=outer_functions(old); nf=outer_functions(new); changed=sorted(n for n in of if of[n]!=nf.get(n)); added=sorted(set(nf)-set(of))
check('only five intended original functions changed',changed==['_native_tick','_native_tick_impl','_production_observe','_production_record','reset'],changed)
check('only three new production functions',added==['_production_collider_path','_production_heading','_production_wall_normals'],added)
for name in of:
 if name not in changed: check('original unchanged function '+name,of[name]==nf[name])
timing='\t\t\t"provisional_steering_us": _production_steering_us,\n'
check('actual observer guards byte exact except timing',nf['_production_observe'].replace(timing,'')==of['_production_observe'])
insertion='\tif _production_steering:\n\t\tvar steering_began: int = Time.get_ticks_usec()\n\t\tdirection = _production_heading(direction)\n\t\t_production_steering_us = Time.get_ticks_usec() - steering_began\n\t\tif refused():\n\t\t\treturn\n'
check('default movement and every guard exact after production-only insertion',nf['_native_tick_impl'].replace(insertion,'')==of['_native_tick_impl'])
check('reset only new unused nonproduction avoid state',nf['reset'].replace('\t_avoid_tangent = Vector3.ZERO\n\t_avoid_retry = 0\n','')==of['reset'])
check('all hard constants unchanged',re.findall(r'^const .*',old,re.M)==re.findall(r'^const .*',new,re.M))
heading=nf['_production_heading']; normals=nf['_production_wall_normals']
check('exactly one syntactic query only in empty pre-wall branch',heading.count('_motion(')==1 and 'if walls.is_empty():' in heading and '_motion(_body.global_transform, _production_prediction_motion)' in heading
      and '_production_prediction_motion = wanted * reach' in heading and 'var reach: float = speed * _production_delta' in heading)
check('prospective finite-positive bounded input',all(s in heading for s in ['not is_finite(speed)','speed <= 0.0','not is_finite(_production_delta)','_production_delta <= 0.0','not is_finite(reach)','reach > MAX_EDGE']))
check('full unchanged actor native motion query',of['_motion']==nf['_motion'] and '_registered_body_contract()' in nf['_motion'] and 'parameters.margin = _body.safe_margin' in nf['_motion'] and '_body_rid, parameters, hit' in nf['_motion'])
check('normal extraction <=7 all reported points undeduplicated', 'hit.get_collision_count() >= CONTACTS' in normals and 'for index in hit.get_collision_count():' in normals and 'walls.append(horizontal.normalized())' in normals and 'dedup' not in normals)
check('normal data stronger guards used for steering only',all(s in normals for s in ['not normal.is_finite()','not point.is_finite()','not is_finite(depth)','depth < -CONTACT_EPS','absf(normal.length_squared() - 1.0) > 0.001','hit.get_collision_local_shape(index) != _capsule_index']))
check('two math candidates against every reported wall', 'for choice in 2:' in heading and 'for wall: Vector3 in walls:' in heading and 'if heading.dot(wall) < -CONTACT_EPS:' in heading and '(along + opposing * 0.25).normalized()' in heading)
check('preferred hand and existing retry only', '_avoid_retry != _observed_choice' in heading and '_avoid_tangent = along' in heading and '_avoid_retry = _observed_choice' in heading)
check('new math gives no credit and resets no original budgets',all(s not in heading+normals for s in ['_observed_frames','_observed_distance','_stalled =','_retry_at =','_plans =','_checked_start =','global_position =','velocity =','_supported_step(']))
check('actual aggregate8 policy unchanged', 'contacts += collision.get_collision_count()' in nf['_production_observe'] and 'if contacts > CONTACTS:' in nf['_production_observe'] and nf['_production_observe'].replace(timing,'')==of['_production_observe'])
check('exact contact prefixes and queue retained','mini(CONTACTS - slides.size(), collision.get_collision_count())' in nf['_production_record'] and '_tick.records.size() >= 2' in nf['_production_record'])
check('indexed diagnostic collider getters only', '_observed_live.get_collider(index)' in nf['_production_record'] and 'collision.get_collider(index)' in nf['_production_record'] and 'get_path()' in nf['_production_collider_path'])
check('snapshot included before unchanged final success guard',nf['_production_observe'].index('var record: Dictionary = _production_record()')<nf['_production_observe'].index('if Time.get_ticks_usec() > _deadline:'))
check('safety ceiling candidly disclosed','_max_speed is production safety ceiling120m/s' in cause['approach']['prediction_limit'])
check('gather and original earned assertions byte exact',H((ROOT/GATHER).read_bytes())=='414f2b939bd356062f811af3aa528ecbbdcbc92200c39445a13f7c7ed526af6d' and (PACK/'originals'/GATHER).read_bytes()==(PACK/'proposal'/GATHER).read_bytes())
check('frozen packet immutable through independent audit',packet_hashes()==frozen)
failed=[c for c in checks if not c['passed']]
result={'verdict':'SOURCEFAIL' if failed else 'SOURCEPASS','scope':'frozen packet readiness only; F17#4 OPEN','parent':PARENT,'source_sha256':SOURCE,'patch_sha256':PATCH,
        'freeze_sha256':H((PACK/'freeze.json').read_bytes()),'independent_script_sha256':H(Path(__file__).read_bytes()),'checks':checks,'failed':failed,
        'engine_executed':False,'tracked_writes':False,'protected_archive_count':len(cause['archives_sha256']),'unchanged_test_count':len(cause['unchanged_tests_sha256']),
        'lossless_patch_sha256':H(regenerated)}
(OUT/'review.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'verdict':result['verdict'],'checks':len(checks),'failed':failed,'added_functions':added}))
