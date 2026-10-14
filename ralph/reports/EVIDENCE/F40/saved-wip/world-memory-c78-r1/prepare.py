from pathlib import Path
import copy, hashlib, json, os, re, subprocess

repo=Path('D:/tetherbound/codex-look-cloudreach')
out=Path(__file__).resolve().parent
pin='c78baa87f86a6b0740cdc0ad13b8c038ac0d3a4a'
base='5e784b4f5edd8aa4c90323fbb9cdb70f5f8c0d76'
old=out.parent/'current-fd2acbeff8'
env=dict(os.environ,GIT_NO_LAZY_FETCH='1',GIT_OPTIONAL_LOCKS='0')
def git(*args,data=None):
    return subprocess.check_output(['git.exe','--no-optional-locks','-c','gc.auto=0','-c','maintenance.auto=false',*args],cwd=repo,env=env,input=data)
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def write(name,value): (out/name).write_text(json.dumps(value,indent=2)+'\n',encoding='utf-8')
assert not (out/'frozen.json').exists(),'Frozen packet must not be rebuilt'
assert git('rev-parse','HEAD').decode().strip()==pin and not git('status','--porcelain').strip()
prior=read(old/'slot-medium-off.json')
bindings_prior=read(out.parent/'base-storage-candidate/manifest.json')['source_bindings']
changed=git('diff','--name-only',base,pin).decode().splitlines()
paths=sorted({b['path'] for b in bindings_prior}|{p for p in changed if not p.startswith('ralph/')}|{'scripts/world/cloudreach_pickup_readability.gd','data/config/cloudreach_pickup_readability.json'})
payload=git('cat-file','--batch',data=''.join(pin+':'+p+'\n' for p in paths).encode())
cursor=0; bindings=[]; blobs={}
for p in paths:
    end=payload.index(b'\n',cursor); oid,kind,size=payload[cursor:end].decode().split(); cursor=end+1
    assert kind=='blob'
    blob=payload[cursor:cursor+int(size)];cursor+=int(size)+1;blobs[p]=blob
    bindings.append({'path':p,'blob':oid,'bytes':len(blob),'sha256':hashlib.sha256(blob).hexdigest()})
assert cursor==len(payload)
for name in ['cloudreach_biome_look.json','cloudreach_cliffhold_detail.json','cloudreach_pickup_readability.json']:
    assert json.loads(blobs['data/config/'+name])['enabled'] is False
# Non-thin source delta; exact prerequisite is a repository commit, not a guessed stage revision.
pack=git('pack-objects','--stdout','--revs','--window=0','--threads=1',data=(pin+'\n^'+base+'\n').encode())
assert len(pack)<16*1024*1024
(out/'source.pack').write_bytes(pack)
git('index-pack',str(out/'source.pack'))
verified=git('verify-pack','-v',str(out/'source.idx')).decode()
object_ids={line.split()[0] for line in verified.splitlines() if re.match(r'^[0-9a-f]{40} ',line)}
required=set(git('rev-list','--objects','--no-object-names',pin,'^'+base).decode().splitlines())
assert object_ids==required
tree=git('rev-parse',pin+'^{tree}').decode().strip()
tree_data=git('ls-tree','-r','-t','-z',pin)
(out/'checkout-tree.z').write_bytes(tree_data)
manifest={'status':'PREPARED_NOT_ADMITTED','source_commit':pin,'source_parent':git('rev-parse',pin+'^').decode().strip(),'source_tree':tree,'base_commit_required':base,'changed_source_paths':changed,'source_bindings':bindings,'binding_scope':'Critical source/config/capture witnesses; exact commit/tree plus clean checkout remains mandatory for all other runtime source/assets. These selected hashes are not a claim to hash every world dependency.','source_pack':{'path':str(out/'source.pack'),'sha256':sha(out/'source.pack'),'bytes':len(pack),'objects':len(object_ids),'closure':'Non-thin complete reachable-object difference relative to required base commit; base reachable object closure must exist at root. No lazy fetch authorized.'},'checkout_tree':{'path':str(out/'checkout-tree.z'),'sha256':sha(out/'checkout-tree.z'),'format':'git ls-tree -r -t -z; exact canonical snapshot metadata'},'native_stage_accessed':False}
write('manifest.json',manifest)
(out/'Medium-graphics_override.cfg').write_bytes((old/'Medium-graphics_override.cfg').read_bytes())
job=copy.deepcopy(prior)
job_id='cr-c78-world-memory-r1'; run='D:/tetherbound/.artifacts/s/run-'+job_id
job.update(schema='codex.cloudreach-world-memory.v1',job_id=job_id,status='NOT_ADMITTED',launch_allowed=False,source_commit=pin,source_tree=tree,source_parent=manifest['source_parent'],source_pack=str(out/'source.pack'),source_pack_sha256=sha(out/'source.pack'),source_manifest=str(out/'manifest.json'),source_manifest_sha256=sha(out/'manifest.json'),scope='One changed-source full-world memory discriminator, with existing Medium OFF four-view Cliffhold capture if it completes within unchanged guards. No automatic retry or acceptance claim.',output_directory=run+'/frames',supervisor_output_directory=run,maximum_engine_launches=1,automatic_retries=0,owner_thread='01a13307-fea3-7ae0-a0cf-ecd8f0e0d502')
job['args']=[a.replace('--source-commit='+prior['source_commit'],'--source-commit='+pin).replace('run-crfd-medium-off-r1','run-'+job_id) for a in prior['args']]
job['isolated_profile']['graphics_override_source']=str(out/'Medium-graphics_override.cfg')
job['isolated_profile']['profile_directory']=run+'/h0'
job['history']={'failed_world_receipt':{'path':'D:/tetherbound/.artifacts/s/run-crfd-medium-off-r1/receipt.json','sha256':sha(Path('D:/tetherbound/.artifacts/s/run-crfd-medium-off-r1/receipt.json'))},'r1_r2_bulk':'Preserved failures; no reinterpretation','verified_r3_raw':{'path':'D:/tetherbound/.artifacts/portable-native-batch/cloudreach-lifetime-bulk-r3-owned-handle/raw-evidence.json','sha256':'21c0c4658bac55a1d14846833de5e01c3d131cb6c54d0389230c0cbf58ab1bb1'},'meaning':'R3 supports retained-cache mechanism, not world saving. Root directed next diagnostic without waiting on old 645 equivalence gate.'}
assert sha(Path(job['history']['verified_r3_raw']['path']))==job['history']['verified_r3_raw']['sha256']
job['receipt_checks']=[s.replace('All 50 canonical source bindings',f'All {len(bindings)} canonical source bindings') for s in prior['receipt_checks']]
job['memory_discriminator']={'trace_prefix':'CLOUDREACH_COVER_MEMORY ','analyzer_path':str(out/'analyze_trace.py'),'analyzer_sha256':sha(out/'analyze_trace.py'),'maximum_trace_lines_per_dress':87,'periodic_maximum_lines':64,'periodic_minimum_ms':10000,'mandatory_complete_trace_last_phase':'cover_returned','measurement_scope':'Synchronous engine allocator snapshots and logical live packed payload; no renderer readbacks or added awaits. Pair with existing supervisor metrics without equating engine uptime and supervisor clocks.','on_failure':'Keep raw output and receipt FAILED; analyze valid partial trace to identify active phase. No partial-image or trace PASS; no automatic retry.'}
job['execution_contract']={'root_review_required':True,'old_645_equivalence_gate_required':False,'supervisor_sha256':None,'supervisor_policy':'Root binds independently reviewed executable supervisor before admission; no legacy launcher supplied or authorized by this packet.','identity':'Prelaunch exact executable read lease/hash held through explicit owned-child exit; same-owned-handle image proof plus CIM PID/parent/start/full argv. No image-query retry on timeout.','lifecycle':'Independent 480-second owned-handle child deadline. Bounded stop/exit waits; Dispose is never exit evidence. Unconfirmed exit retains executable and owner leases in exceptional safety hold for root attention.','stage':'Root alone prepares exact clean commit/tree and verifies required base closure. Snapshot actual current owner/stage metadata; do not restore a stale stage pin. No stage preparation authorized by CPU packet check.','admission':'One fresh output/home, exact job/manifest/source/profile/supervisor hashes and root grant. Existing resource minima and caps remain mandatory; source improvement is not a headroom forecast.'}
write('native-job.json',job)
write('native-admission.json',{'status':'NOT_ADMITTED','launch_allowed':False,'job_id':job_id,'job_sha256':sha(out/'native-job.json'),'reviewed_by_thread':None,'supervisor_path':None,'supervisor_sha256':None})
same=['wall_cap_seconds','guards','preset','expected_frames','expected_other_files','startup_method','extra_receipt_requirements','engine','candidate_flags','admission_floors']
assert all(job[k]==prior[k] for k in same)
assert [a.replace('--source-commit='+pin,'--source-commit='+prior['source_commit']).replace('run-'+job_id,'run-crfd-medium-off-r1') for a in job['args']]==prior['args']
for p in ('data/config/cloudreach_look.json','data/config/cloudreach_world.json','tools/visual_judge/camera_sets/cloudreach-look.json'):
    assert git('show',prior['source_commit']+':'+p)==blobs[p],p
write('cpu-source-checks.json',{'status':'EXACT_SOURCE_AND_LIMIT_COMPARISON_PASS_NATIVE_UNRUN','source_commit':pin,'binding_count':len(bindings),'pack_objects':len(object_ids),'pack_closure_verified':True,'unchanged_fields':same,'unchanged_density_world_camera_files':True,'argv_changes_only':['source commit','fresh output'],'engine_launches':0,'native_stage_accessed':False,'actual_owner_accessed':False,'launch_allowed':False})
print(json.dumps({'status':'PREPARED_NOT_ADMITTED','job_sha256':sha(out/'native-job.json'),'bindings':len(bindings),'pack_bytes':len(pack),'pack_objects':len(object_ids)}))
