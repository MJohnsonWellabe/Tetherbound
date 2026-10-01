"""Frozen source and sampling controls only. Never runs Godot or CI."""
from pathlib import Path
import hashlib, json, math, re
PACK=Path(__file__).resolve().parent
checks=[]
def check(name,passed,detail=None):checks.append({'name':name,'passed':bool(passed),'detail':detail})
def text(rel):return (PACK/rel).read_text(encoding='utf-8')
def sha(raw):return hashlib.sha256(raw).hexdigest()
manifest=json.loads(text('manifest.json'))
for rel,entry in manifest['files'].items():
    raw=(PACK/rel).read_bytes()
    check('frozen input '+rel,sha(raw)==entry['sha256'] and len(raw)==entry['bytes'])
def functions(s):
    markers=list(re.finditer(r'^(?:static )?func (\w+)\(',s,re.M))
    return {m[1]:s[m.start():markers[i+1].start() if i+1<len(markers) else len(s)].rstrip() for i,m in enumerate(markers)}
def baseline(s):
    block=s[s.index('const HISTORICAL_BASELINE := ')+len('const HISTORICAL_BASELINE := '):]
    block=block[:block.index('\n}\n')+2]
    block='\n'.join(l for l in block.splitlines() if not l.lstrip().startswith('#'))
    return json.loads(re.sub(r',\s*([}\]])',r'\1',block))
road='tests/test_road_creature_visibility.gd'
old,new=text('originals/'+road),text('proposal/'+road)
ob,nb=baseline(old),baseline(new)
expected=json.loads(json.dumps(ob));expected['meadows']['band1_lower_meadows'][0]=250
check('only first-road sample count changes',nb==expected and ob['meadows']['band1_lower_meadows']==[251,124,130.0])
check('all visibility test functions unchanged',functions(old)==functions(new))
for realm,routes in ob.items():
    for id,values in routes.items():
        check('failure budgets remain exact '+realm+'/'+id,nb[realm][id][1:]==values[1:])
model=text('inputs/visibility-model.gd')
for declaration in ['const SAMPLE_STEP_M := 10.0','const REQUIRED_VISIBLE := 2','const MIN_VISIBLE_HEIGHT_PX := 15.0','const REFERENCE_DISTANCE_M := 40.0','const REFERENCE_PROJECTED_HEIGHT_PX := 15.0']:
    check('visibility calibration preserved '+declaration,declaration in model)
old_terrain=json.loads(text('inputs/historical-terrain.json'))
new_terrain=json.loads(text('inputs/current-terrain.json'))
op=old_terrain['trail']['bands'][0]['points'];np=new_terrain['trail']['bands'][0]['points']
check('same entire road tail and point count',len(op)==len(np)==27 and op[1:]==np[1:])
check('only accepted first point moves',op[0]==[11.5,2] and np[0]==[13.79,14])
def sample(points):
    walked,next_distance=0.,0.
    out=[]
    for a,b in zip(points,points[1:]):
        length=math.dist(a,b)
        if length<=.001:continue
        forward=[(b[i]-a[i])/length for i in range(2)]
        while next_distance<walked+length:
            along=next_distance-walked
            if along>=0:out.append([a[i]+forward[i]*along for i in range(2)])
            next_distance+=10
        walked+=length
    if not out or math.dist(out[-1],points[-1])>.01:out.append(points[-1])
    return walked,out
old_len,old_samples=sample(op);new_len,new_samples=sample(np)
check('historical unchanged sampler yields251',len(old_samples)==251)
check('accepted unchanged sampler yields250',len(new_samples)==250)
check('exact approved first-leg shortening',abs(old_len-new_len-12.1691079701663)<1e-8)
check('old count remains a failing negative control',len(new_samples)!=ob['meadows']['band1_lower_meadows'][0])
check('new count matches while ceiling is unchanged',len(new_samples)==nb['meadows']['band1_lower_meadows'][0] and nb['meadows']['band1_lower_meadows'][1:]==[124,130.0])

contract='tests/test_gate_a_npc_gather_segment_contract.gd'
before,after=text('originals/'+contract),text('proposal/'+contract)
bf,af=functions(before),functions(after)
target='test_pre_press_winner_snapshot_is_not_returned_as_success'
check('contract entrypoints unchanged',bf.keys()==af.keys())
check('every other controller/activation test unchanged',all(bf[k]==af[k] for k in bf if k!=target))
old_line='\tvar finish := source.find("\\n\\n## Travel one leg", start)'
new_line='''\t# Isolate the actual function by its next declaration, independent of
\t# travel-comment wording or helpers subsequently added after the approach.
\tvar finish := source.find("\\nfunc ", start + 1)'''
guard='\tif start < 0 or finish <= start:\n\t\treturn\n'
restored=after.replace(new_line,old_line).replace(guard,'')
check('only declaration boundary and failed-bounds guard added',restored==before)
assertions=lambda s:re.findall(r'(?m)^\tassert_\w+\([^\n]*(?:\n\t{2,}[^\n]*)*',s)
check('all original activation/controller assertions retained exactly',assertions(before)==assertions(after))
helper=text('inputs/gather-helper.gd')
check('gather helper raw hash remains exact',sha((PACK/'inputs/gather-helper.gd').read_bytes())=='414f2b939bd356062f811af3aa528ecbbdcbc92200c39445a13f7c7ed526af6d')
start=helper.index('func _one_approach(')
finish=helper.find('\nfunc ',start+1)
check('retired comment really is absent after approach',helper.find('\n\n## Travel one leg',start)==-1)
check('declaration bounds actual next function',finish>start and helper[finish:].startswith('\nfunc _press_and_observe_activation('))
approach=helper[start:finish]
stale='await _tap_action(&"interact")\n\t\t\treturn true'
retry='_nav.reset()\n\t\t\tcontinue'
competitor='_competing_activation])\n\t\t\t\treturn false'
def valid(s):return stale not in s and retry in s and competitor in s
check('actual isolated approach passes all original checks',valid(approach))
check('stale snapshot success negative control rejected',not valid(approach+'\n'+stale))
check('removed no-activation retry negative control rejected',not valid(approach.replace(retry,'')))
check('competing activation retry negative control rejected',not valid(approach.replace(competitor,'_competing_activation])\n\t\t\t\tcontinue')))
check('signal observed by controller contract remains', '_arbiter.connect("activated", activation_handler)' in helper and 'await _press_and_observe_activation(target)' in approach)
check('target success requires post-press verdict','if activation == ActivationVerdict.TARGET:\n\t\t\t\treturn true' in approach)
check('no test skip added',not re.search(r'(?m)^\s*(?:skip|pending|quarantine)\(',after))
log=text('prior-failure/tests.log')
check('retained original sole road count failure','expected 251, got 250  (meadows/band1_lower_meadows sample count)' in log)
check('retained actual all-critical-route visibility pass','ok    test_road_creature_visibility.gd :: test_every_critical_route_has_two_forward_visible_creatures_at_every_sample' in log.replace('\n',''))
result={'classification':'SOURCEPASS' if all(c['passed'] for c in checks) else 'SOURCEFAIL',
 'acceptance':'F17#4 OPEN; no engine/parser/CI run for this proposal; ROOT raw failure retained',
 'passed':sum(c['passed'] for c in checks),'total':len(checks),
 'manifest_sha256':sha((PACK/'manifest.json').read_bytes()),
 'sampling':{'old_length_m':old_len,'current_length_m':new_len,'shortening_m':old_len-new_len,'old_count':len(old_samples),'current_count':len(new_samples),'step_m':10,'failure_ceilings':[124,130.0]},
 'checks':checks}
(PACK/'source-results.json').write_bytes((json.dumps(result,indent=2)+'\n').encode('utf-8'))
print(json.dumps({k:result[k] for k in ['classification','passed','total','manifest_sha256','sampling']},indent=2))
for c in checks:
    if not c['passed']:print('FAIL',c['name'],c['detail'])
raise SystemExit(0 if result['classification']=='SOURCEPASS' else 1)
