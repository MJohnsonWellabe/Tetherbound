from pathlib import Path
import hashlib,json,ast,os
R=Path(__file__).resolve().parent
def read(p):return json.loads(p.read_bytes())
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,v):p.write_text(json.dumps(v,indent=2)+'\n',encoding='utf-8',newline='\n')
packet=read(R/'packet.json');source=packet['source'];old=packet['transition_from']
review=read(R/'independent-executable-review.json');ioreview=read(R/'independent-transition-io-review.json')
assert not review['remaining_findings']
assert 'PASS' in ioreview['status']
assert sha(R/'swap_stage.py') in json.dumps(ioreview)
for folder in ('shared','visibility','palette','memory'):
 d=R/folder;job=read(d/'native-job.json');admission=read(d/'native-admission.json')
 assert job['status']=='PREPARED' and not job['launch_allowed'] and len(job['steps'])==1
 assert admission['status']=='NOT_ADMITTED' and not admission['launch_allowed']
 assert admission['job_sha256']==sha(d/'native-job.json')
 assert job['supervisor_sha256']==sha(d/'run_validation.ps1')==review['runner_pins'][folder]['sha256']
 assert job['source_commit']==source and job['native_transition_from']==old
 assert sha(d/'source_preflight.py')=='d4cb5bce3664f35f05c576f6fd691411cf71c5c6d78e7fa1aaec3a8d5517d7d2'
 write(d/'root-review.template.json',{'status':'NOT_REVIEWED','source_commit':source,'transition_from':old,'job_sha256':'FILL_AFTER_ROOT_ADMISSION','source_and_transition_reviewed':False,'imports_ready':False,'execution_contract_reviewed':False,'external_memory_sampling_reviewed':False,'terrain_dll_sha256':'5cf87b3a5dea907b788f187e7ede6347f3aaba25396610269120a3cf2a903306'})
for f in ('cpu-source-closure.json','cpu-pack-membership.json','cpu-successor-oracles.json','cpu-launch-gates.json','cpu-deadline-verification.json','cpu-transition-guard-verification.json','cpu-git-deadline.json','shared/cpu-source-results.json','shared/cpu-bounded-source-results.json'):
 assert read(R/f)['status'].startswith('PASS'),f
assert read(R/'cpu-transition-guard-verification.json')['swap_sha256']==sha(R/'swap_stage.py')
assert read(R/'cpu-git-deadline.json')['swap_sha256']==sha(R/'swap_stage.py')
assert sha(R.parent/'load-memory-discriminator/review-request.json')=='864a238b950dec2b589a54a2a1d0d47437141fb6c602843f7e94cf1a3ea17719'
# Prove the process wrapper is the only changed transition function, apart
# from the intentionally rebound source-audit pins/count and transition pins.
P=Path('D:/tetherbound/.artifacts/codex-look-meadows/medium-off-b9d7edeb7f-from-5650c507e6-r4')
def functions(path):
 text=path.read_text(encoding='utf-8-sig');tree=ast.parse(text)
 return {n.name:ast.get_source_segment(text,n) for n in tree.body if isinstance(n,(ast.FunctionDef,ast.ClassDef))}
a,b=functions(P/'swap_stage.py'),functions(R/'swap_stage.py')
for key in ('capacity_budget','MutationGate','locked_file','verify_backups','final_owner_cas','safe_path','write_new'):
 assert a[key]==b[key],key
packet['status']='PREPARED_NOT_ADMITTED';write(R/'packet.json',packet)
provenance=read(R/'preparation-provenance.json')
provenance['altered_scope']+=['contract-derived source counts','ordered completion marker and mount interval','terminal resource rejection','caller-owned Git I/O deadline including Windows stdin']
write(R/'preparation-provenance.json',provenance)
files=[p for p in R.iterdir() if p.is_file() and p.name not in ('manifest.json','cpu-gate-job.json','cpu-gate-admission.json','cpu-synthetic-memory.jsonl')]
for folder in ('shared','visibility','palette','memory','offline-native.git'):
 files.extend(p for p in (R/folder).rglob('*') if p.is_file())
entries=[{'path':p.relative_to(R).as_posix(),'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(set(files))]
manifest={'schema':'codex.stormwood-successor-manifest.v1','status':'PREPARED_NOT_ADMITTED','source':source,'transition_from':old,'automatic_sequence':False,'native_executed':False,'files':entries,'excluded':'CPU fixture directories and synthetic gate/sample payloads are retained but not runtime inputs; all bytes still count toward the packet cap.'}
write(R/'manifest.json',manifest)
total=sum(p.stat().st_size for p in R.rglob('*') if p.is_file())
assert total<16*1024**2,total
for entry in entries:assert sha(R/entry['path'])==entry['sha256']
print(json.dumps({'status':'PREPARED_NOT_ADMITTED','manifest_sha256':sha(R/'manifest.json'),'files':len(entries),'packet_bytes_including_fixtures':total,'packet_cap_bytes':16*1024**2,'native_executed':False}))
