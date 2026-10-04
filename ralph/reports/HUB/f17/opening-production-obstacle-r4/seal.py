from pathlib import Path
import hashlib,json,subprocess,difflib,shutil
root=Path('D:/tetherbound/redesign-hub')
out=root/'.tmp/opening-production-obstacle-r4-corrected'
parent='8189ef734addce12d446c6c9a0f9d4016a0d657d'
assert not out.exists()
H=lambda b:hashlib.sha256(b).hexdigest()
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=root).decode().strip()==parent
owned=['tests/helpers/opening_geometry_navigator.gd','tests/helpers/gate_a_npc_gather_segment.gd']
assert set(subprocess.check_output(['git','diff','--name-only'],cwd=root).decode().splitlines())=={owned[0]}
receipt=json.loads((root/'.tmp/opening-production-detour-r3-failure/receipt.json').read_bytes())
before=receipt['source_after'].copy()
for name in ['data/config/village_boundary.json','data/config/building_prefabs.json']:
    before[name]=H((root/name).read_bytes())
out.mkdir()
for name,pin in before.items():
    raw=(root/'ralph/reports/HUB/f17/opening-production-detour-r3/proposal'/name).read_bytes() if name in owned else (root/name).read_bytes()
    assert H(raw)==pin,name
    gitraw=subprocess.check_output(['git','show',parent+':'+name],cwd=root)
    assert raw.replace(b'\r\n',b'\n')==gitraw.replace(b'\r\n',b'\n'),name
    p=out/'originals'/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(raw)
patch=b'';after={}
for name in owned:
    raw=(root/name).read_bytes();p=out/'proposal'/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(raw);after[name]=H(raw)
    patch+=''.join(difflib.unified_diff((out/'originals'/name).read_bytes().decode('utf-8').splitlines(True),raw.decode().splitlines(True),fromfile='a/'+name,tofile='b/'+name)).encode()
(out/'opening-production-obstacle.patch').write_bytes(patch)
prior=root/'.tmp/opening-production-detour-r3-failure'
shutil.copytree(prior,out/'prior-failure')
shutil.copyfile(root/'.tmp/check-obstacle-r4-source.py',out/'author-source-check.py')
shutil.copyfile(__file__,out/'seal.py')
names=subprocess.check_output(['git','ls-files','ralph/reports/HUB/f17','ralph/reports/HUB/f18'],cwd=root).decode().splitlines()
archives={n:H((root/n).read_bytes()) for n in names}
tests=subprocess.check_output(['git','ls-files','tests'],cwd=root).decode().splitlines()
testpins={n:H((root/n).read_bytes()) for n in tests if n not in owned}
cause={'parent':parent,'owned_paths':owned,'before_source_sha256':before,'after_source_sha256':after,'archives_sha256':archives,'unchanged_tests_sha256':testpins,
 'prior':{'state':'ACTUAL FAIL; F17#4 OPEN','parser_exit':0,'parser_seconds':17.656,'native_exit':1,'native_seconds':293.203,'campaign_seconds':277.246,'exact_cached_counts':[2,2,2,2,2,2],'exact_cached_total':12,'logged_points':8,'floor_and_wall':'Distinct collider RID with near-horizontal normal; precise second node unknown. Error defaults each manifold index0, so six Terrain labels incomplete.','raw_files_sha256':json.loads((prior/'freeze.json').read_bytes())['files_sha256']},
 'approach':{'query':'Current actual pre zero-motion result supplies up to7 unsaturated native contacts. If no non-floor horizontal wall normal, exactly one _motion from actual bound actor current global_transform, motion=desired*_max_speed*delta, full unchanged capsule/mask/skin/exclusions. All costs share original cap.','prediction_limit':'_max_speed is production safety ceiling120m/s, so approximately2m at60Hz: conservative bounded upper step, not exact ordinary walking trajectory. No pose/speed or collider writes. Prediction supplies headings only, never clearance or traversal credit; shallow current overlap and all cached actual slide points remain mandatory.','heading':'At most2 tangential-plus-quarter-outward provisional headings, each non-inward to every reported horizontal wall normal. Prior orientation retained when viable; existing26-frame retry counter reverses preference. No new retry/stall/progress/budget resets. Conflicting normals with no outward heading refuse. Physical next step and whole route remain unproved.','route':'Existing mandatory door checks and target remain unchanged. Retained stone Practice Meadow metadata hint unchanged. Every movement uses normal parsed stick and original one walk loop.','diagnostics':'Per-contact native collider paths added within existing8 live/contact cached prefixes; snapshot and metadata cost included in existing final deadline. No extra snapshot/query beyond the optional one prospective call.'},
 'caps':{'callback_us':10000,'aggregate_contacts':8,'frame_queries':96,'lifetime_queries':250000,'requests':24000,'stall_frames':90,'retry_frames':26,'gather_frames':1800,'team_frames':3600,'choices':8},
 'api_docs':['https://docs.godotengine.org/en/4.7/classes/class_physicstestmotionresult3d.html','https://docs.godotengine.org/en/4.7/classes/class_kinematiccollision3d.html'],
 'required_root_run':['--through-tournament','--world-seed=4','--no-checkpoints','--opening-contact-diagnostics'],
 'state':'FROZEN SOURCE CANDIDATE; independent source gate then ROOT actual prefix required; no engine here; F17#4 OPEN'}
(out/'cause-and-constraints.json').write_text(json.dumps(cause,indent=2)+'\n',encoding='utf-8')
manifest={p.relative_to(out).as_posix():H(p.read_bytes()) for p in out.rglob('*') if p.is_file() and p.name!='freeze.json'}
# Include the nested prior-failure freeze itself as raw evidence.
manifest['prior-failure/freeze.json']=H((out/'prior-failure/freeze.json').read_bytes())
(out/'freeze.json').write_text(json.dumps({'parent':parent,'state':'FROZEN_SOURCE_CANDIDATE','patch_sha256':H(patch),'files_sha256':manifest},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'source':after,'patch':H(patch),'protected_archives':len(archives),'unchanged_tests':len(testpins),'frozen_files':len(manifest)}))
