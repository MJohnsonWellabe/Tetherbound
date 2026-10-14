from pathlib import Path
import hashlib,json,os,subprocess,tempfile
ROOT=Path(__file__).resolve().parent
REPO=Path('D:/tetherbound/codex-look-stormwood')
PRE=Path('D:/tetherbound/.artifacts/codex-look-meadows/medium-off-b9d7edeb7f-from-5650c507e6-r4')
OLD='b9d7edeb7f18d7ca2192f018016d4126f1910f91'
TARGET='868a7b5c8c4d89483a85f2ce0f6c7c7bb2c558ee'
GIT='C:/Users/mattj/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/git/mingw64/bin/git.exe'
ENV=dict(os.environ,GIT_NO_LAZY_FETCH='1',GIT_OPTIONAL_LOCKS='0',GIT_TERMINAL_PROMPT='0')
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p):return json.loads(p.read_bytes())
def write(p,v):p.write_text(json.dumps(v,indent=2)+'\n',encoding='utf-8',newline='\n')
def git(*args,data=None,store=None):
    loc=['--git-dir',str(store)] if store else ['-C',str(REPO)]
    # File-backed stdin/stdout avoids Windows communicate's unbounded pipe write.
    with tempfile.TemporaryFile(dir=ROOT) as inp, tempfile.TemporaryFile(dir=ROOT) as out, tempfile.TemporaryFile(dir=ROOT) as err:
        inp.write(data or b'');inp.seek(0)
        p=subprocess.Popen([GIT,'-c','gc.auto=0','-c','maintenance.auto=false',*loc,*args],stdin=inp,stdout=out,stderr=err,env=ENV)
        try:p.wait(timeout=45)
        except subprocess.TimeoutExpired:
            p.kill();p.wait(timeout=5);raise
        assert out.tell()+err.tell()<=64*1024**2,'Preparation query output cap'
        out.seek(0);err.seek(0)
        if p.returncode:raise RuntimeError(err.read(3000).decode(errors='replace'))
        return out.read()

def tree(ref):
    result={};objects=set()
    for row in git('ls-tree','-rtz',ref).split(b'\0'):
        if not row:continue
        meta,path=row.split(b'\t');mode,kind,oid=meta.decode().split();objects.add(oid)
        if kind=='blob':result[path.decode()]=(mode,oid)
    objects.add(git('rev-parse',ref+'^{tree}').decode().strip())
    return result,objects
before,base_objects=tree(OLD);after,required=tree(TARGET)
parent=git('rev-parse',TARGET+'^').decode().strip()
required.update([TARGET,parent,OLD,git('rev-parse',OLD+'^').decode().strip()])
review=Path('D:/tetherbound/.artifacts/codex-look-stormwood/868-independent-source-review/review.json')
assert sha(review.read_bytes())=='999f9247fed8c1ce3035bc96eb7902ed9637e2f38d056c6da5d1301ef809f060'
frozen=ROOT.parent/'load-memory-discriminator/review-request.json'
assert sha(frozen.read_bytes())=='864a238b950dec2b589a54a2a1d0d47437141fb6c602843f7e94cf1a3ea17719'
bindings=read(frozen)['source_bindings']
assert len(bindings)==794 and all(after[b['path']][1]==b['blob'] for b in bindings)
bound={b['path'] for b in bindings}
oldcontract=read(PRE/'off/source-contract.json')
assert oldcontract['source']==OLD and oldcontract['full_index_paths']==len(before)==49341
oldmat=set(oldcontract['materialize']);delta=sorted(p for p in before.keys()|after.keys() if before.get(p)!=after.get(p))
writes=sorted(bound|{p for p in delta if p in after and p in oldmat})
materialize=sorted((oldmat & after.keys())|set(writes))
contract={'source':TARGET,'full_index_paths':len(after),'materialize':materialize,
    'canonical_paths':sorted(set(oldcontract['canonical_paths']) & set(materialize)),
    'deleted_paths':sorted(set(oldcontract['deleted_paths'])|{p for p in delta if p not in after})}
inventory={'source':TARGET,'base':OLD,'native':OLD,'transition_delta':[
    {'path':p,'native':{'mode':before[p][0],'blob':before[p][1]} if p in before else None,
     'target':{'mode':after[p][0],'blob':after[p][1]} if p in after else None} for p in delta],
    'planned_writes':writes,'before_materialized':len(oldmat),'after_materialized':len(materialize)}
write(ROOT/'transition-inventory.json',inventory)
write(ROOT/'source-bindings.json',{'source':TARGET,'parent':parent,'base':OLD,'native_transition_from':OLD,'source_bindings':bindings})
for name in ('shared','visibility','palette','memory'):
    d=ROOT/name;d.mkdir(exist_ok=True)
    (d/'source_preflight.py').write_bytes((PRE/'off/source_preflight.py').read_bytes())
    write(d/'source-contract.json',contract)
    write(d/'source-contract-before.json',oldcontract)
    write(d/'source-job-before.json',{'source_commit':OLD,'source_parent':git('rev-parse',OLD+'^').decode().strip(),'staging_base':OLD,'changed_source_paths':[],'source_bindings':[]})
    for fn in ('test_source_preflight.py','test_bounded_source.ps1'):(d/fn).write_bytes((PRE/'off'/fn).read_bytes())
# Read-only object queries use the reviewed predecessor proof store, not the
# live native worktree/index/owner. New writes stay in this artifact directory.
base_store=PRE/'offline-native.git'
# Two bounded predecessor-store queries failed. Use the reviewed b9 tree
# closure as the base, and send every target-only tree/blob plus commit metadata.
# This is conditional closure on that exact verified base, not a fresh object
# availability scan of the native store. Root's full audit remains mandatory.
base_objects=(base_objects-{oid for mode,oid in before.values()})|{before[p][1] for p in oldmat}|{OLD,git('rev-parse',OLD+'^').decode().strip()}
required=(required-{oid for mode,oid in after.values()})|{after[p][1] for p in materialize}|{TARGET,parent,OLD}
missing=sorted(required-base_objects)
print('REVIEWED BASE OBJECTS',len(base_objects),'TARGET REQUIRED',len(required),'TRANSPORT',len(missing),flush=True)
pack=git('pack-objects','--stdout',data=('\n'.join(missing)+'\n').encode())
assert len(pack)<16*1024**2
(ROOT/'source.pack').write_bytes(pack)
store=ROOT/'offline-native.git'
git('init','--bare',str(store))
(store/'objects/info/alternates').write_text(str(base_store/'objects').replace('\\','/')+'\n',encoding='utf-8',newline='\n')
git('index-pack','--stdin',data=pack,store=store)
# Verify only transported objects here; unchanged objects are bound to the
# predecessor's reviewed source/tree closure, never assumed from working files.
checked=git('cat-file','--batch-check',data=('\n'.join(missing)+'\n').encode(),store=store).decode().splitlines()
assert len(checked)==len(missing) and not any(r.endswith(' missing') for r in checked)
checks=[]
for args in [('rev-parse',TARGET),('rev-parse',TARGET+'^'),('ls-tree','-rz',TARGET),('diff','--name-only',OLD,TARGET)]:
    actual=git(*args,store=store);assert actual==git(*args)
    checks.append({'args':args,'stdout_sha256':sha(actual)})
# One batched transfer verifies ALL bound raw payloads; no per-file Git loop.
raw=git('cat-file','--batch',data=('\n'.join(b['blob'] for b in bindings)+'\n').encode())
at=0
for b in bindings:
    end=raw.index(b'\n',at);header=raw[at:end].split();assert header[1]==b'blob'
    n=int(header[2]);data=raw[end+1:end+1+n];at=end+n+2
    assert n==b['bytes'] and sha(data)==b['sha256'],b['path']
assert at==len(raw)
write(ROOT/'cpu-source-closure.json',{'status':'PASS_EXACT_DELTA_CLOSURE_ON_REVIEWED_B9_BASE','source':TARGET,'transition_from':OLD,
    'root_review_sha256':sha(review.read_bytes()),'frozen_review_request_sha256':sha(frozen.read_bytes()),
    'required_objects':len(required),'transport_objects':len(missing),'pack_bytes':len(pack),'pack_sha256':sha(pack),
    'bound_raw_payloads':len(bindings),'queries':checks,'native_stage_worktree_or_index_accessed':False,
    'native_owner_or_lock_accessed':False,'native_writes':False,'engines_launched':0,
    'closure_limitation':'Native object availability was not freshly enumerated; exact reviewed b9 base closure and mandatory transition audit are prerequisites','base_proof_store':str(base_store),'reviewed_base_closure_sha256':sha((PRE/'cpu-source-verification.json').read_bytes()),'base_contract_sha256':sha((PRE/'off/source-contract.json').read_bytes()),
    'target_index_entries':len(after),'target_materialized':len(materialize),'delta_paths':len(delta),'planned_writes':len(writes)})
print(json.dumps(read(ROOT/'cpu-source-closure.json'),indent=2))
