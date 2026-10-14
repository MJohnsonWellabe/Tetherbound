from pathlib import Path
import hashlib,json,subprocess,os,shutil,re,ast
P=Path(__file__).resolve().parent;F=P.with_name('executable-c836-from565-r2');A=P.with_name('executable-c836-from565');Q=P.with_name('executable-c836-r3-preparation')
OLD='b9d7edeb7f18d7ca2192f018016d4126f1910f91';NEW='c836df19793e420982bb4aa7b4a0428380126c82'
G='C:/Users/mattj/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/git/mingw64/bin/git.exe'
ENV=dict(os.environ,GIT_NO_LAZY_FETCH='1',GIT_OPTIONAL_LOCKS='0',GIT_TERMINAL_PROMPT='0')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n',encoding='utf-8',newline='\n')
def g(root,*args,data=None):
 r=subprocess.run([G,'-C',str(root),'-c','gc.auto=0','-c','maintenance.auto=false','-c','core.fsmonitor=false',*args],input=data,stdout=subprocess.PIPE,stderr=subprocess.PIPE,env=ENV,timeout=60)
 assert r.returncode==0,(args,r.stderr.decode(errors='replace'));return r.stdout
O=P/'offline.git'
if not O.exists():
 g(P,'init','--bare','--quiet',str(O));(O/'objects/info/alternates').write_text((A/'offline.git/objects').as_posix()+'\n',encoding='utf-8',newline='\n')
def tree(ref):
 entries={};trees={g(O,'rev-parse',ref+'^{tree}').decode().strip()}
 for row in g(O,'ls-tree','-rzt',ref).split(b'\0'):
  if not row:continue
  meta,name=row.split(b'\t',1);mode,kind,oid=meta.decode().split()
  if kind=='tree':trees.add(oid)
  else:entries[name.decode()]=(mode,oid)
 return entries,trees
before,ot=tree(OLD);after,nt=tree(NEW)
parent=g(O,'rev-parse',NEW+'^').decode().strip();changed=sorted(p for p in before.keys()|after.keys() if before.get(p)!=after.get(p))
required=ot|nt|{OLD,NEW,parent}
for path in changed:
 for t in (before,after):
  if path in t:required.add(t[path][1])
rows=g(O,'cat-file','--batch-check',data=('\n'.join(sorted(required))+'\n').encode()).decode().splitlines()
missing=[r for r in rows if r.endswith(' missing')]
save(P/'transport-inventory.json',dict(base=OLD,target=NEW,changed_paths=changed,required_objects=sorted(required),missing=missing))
assert not missing,missing
if not (P/'transition.pack').exists():
 payload=g(O,'pack-objects','--stdout',data=('\n'.join(sorted(required))+'\n').encode());assert len(payload)<32*1024**2
 (P/'transition.pack').write_bytes(payload)
pack=dict(path=(P/'transition.pack').as_posix(),bytes=(P/'transition.pack').stat().st_size,sha256=sha(P/'transition.pack'))
for name in ('operation_budget.py','operation_budget.ps1','owner_publication.ps1'):
 shutil.copyfile(Q/'generic'/name,P/'root-transition'/name)
shutil.copyfile(F/'root-transition/transition_checks.py',P/'root-transition/transition_checks.py')
save(P/'baseline-confirmation.json',dict(source=OLD,reported_index_sha256='8564bb8b52f74c58803830eb8562798a00af80804039c1be217eea885cf096f4',index_entries=49341,materialized_files=12887,canonical_files=4203,authority='Root confirmed successful transition at 05:47 America/Chicago, 2026-10-14. Systems has not read native stage.',stage_access=False))
print(json.dumps(dict(changed=len(changed),pack=pack,required=len(required))))
