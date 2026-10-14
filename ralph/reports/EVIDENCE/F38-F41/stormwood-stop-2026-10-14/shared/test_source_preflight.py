from pathlib import Path
import copy,json,os,subprocess,time
import source_preflight as m
P=Path(__file__).resolve().parent;R=P.parent/('cpu-source-fixture-'+__import__('uuid').uuid4().hex);R.mkdir(exist_ok=False)
env=dict(os.environ,GIT_NO_LAZY_FETCH='1',GIT_OPTIONAL_LOCKS='0')
def g(*args,data=None):
 r=subprocess.run([m.G,'-C',str(R),'-c','gc.auto=0','-c','maintenance.auto=false',*args],input=data,capture_output=True,env=env,timeout=10)
 assert r.returncode==0,r.stderr;return r.stdout
g('init');g('config','user.name','CPU');g('config','user.email','cpu@example.invalid');g('config','core.autocrlf','false')
for name,data in {'binding.bin':b'\0binary','lf.txt':b'line\n','raw-crlf.txt':b'raw\r\n','outside.txt':b'outside\n','sparse.txt':b'sparse\n','deleted.txt':b'gone\n','text-with-nul.gd':b'a\0\n','invalid.gd':b'\xff\n'}.items():(R/name).write_bytes(data)
g('add','.');g('commit','-m','base');base=g('rev-parse','HEAD').decode().strip()
(R/'deleted.txt').unlink();g('add','-A');g('commit','-m','target');target=g('rev-parse','HEAD').decode().strip();g('checkout','--detach',target)
g('update-index','--skip-worktree','sparse.txt');(R/'sparse.txt').unlink();(R/'lf.txt').write_bytes(b'line\r\n')
job=dict(source_commit=target,source_parent=base,staging_base=base,changed_source_paths=['deleted.txt'],source_bindings=[dict(path='binding.bin',blob=g('rev-parse',target+':binding.bin').decode().strip(),hash_mode='binary',sha256=m.sha(b'\0binary'))])
contract=dict(source=target,full_index_paths=7,materialize=['binding.bin','lf.txt','raw-crlf.txt','outside.txt','text-with-nul.gd','invalid.gd'],canonical_paths=['lf.txt','text-with-nul.gd','invalid.gd'],deleted_paths=['deleted.txt'])
results=[]
def run(name,action=None,restore=None,expected=None,audit_class=m.Audit,seconds=5):
 if action:action()
 try:
  try:result=audit_class(R,job,contract,seconds).run()
  except Exception as e:
   if expected is None or expected not in str(e):raise
   results.append(dict(case=name,status='PASS_REJECTED',reason=str(e)));return
  assert expected is None,(name,'expected rejection',result)
  results.append(dict(case=name,status='PASS',result=result))
 finally:
  if restore:restore()
run('raw CRLF + whitelist canonical + binary + permitted sparse absence')
run('dirty outside bindings',lambda:(R/'outside.txt').write_bytes(b'bad\n'),lambda:(R/'outside.txt').write_bytes(b'outside\n'),'Dirty tracked')
run('dirty canonical text',lambda:(R/'lf.txt').write_bytes(b'changed\r\n'),lambda:(R/'lf.txt').write_bytes(b'line\r\n'),'Dirty tracked')
run('canonical path not authorized',lambda:contract.update(canonical_paths=[]),lambda:contract.update(canonical_paths=['lf.txt','text-with-nul.gd','invalid.gd']),'Dirty tracked')
run('NUL text normalization forbidden',lambda:(R/'text-with-nul.gd').write_bytes(b'a\0\r\n'),lambda:(R/'text-with-nul.gd').write_bytes(b'a\0\n'),'Dirty tracked')
run('nonUTF8 normalization forbidden',lambda:(R/'invalid.gd').write_bytes(b'\xff\r\n'),lambda:(R/'invalid.gd').write_bytes(b'\xff\n'),'utf-8')
run('missing required',lambda:(R/'outside.txt').unlink(),lambda:(R/'outside.txt').write_bytes(b'outside\n'),'Missing materialized')
run('deleted path reappears',lambda:(R/'deleted.txt').write_bytes(b'gone\n'),lambda:(R/'deleted.txt').unlink(),'Deleted path reappeared')
g('update-index','--skip-worktree','outside.txt')
run('dirty skip-worktree file',lambda:(R/'outside.txt').write_bytes(b'bad\n'),lambda:(R/'outside.txt').write_bytes(b'outside\n'),'Dirty tracked')
g('update-index','--no-skip-worktree','outside.txt')
original_index=(R/'.git/index').read_bytes()
other=g('hash-object','-w','--stdin',data=b'tamper\n').decode().strip()
run('full-index tamper outside bindings',lambda:g('update-index','--cacheinfo','100644',other,'outside.txt'),lambda:(R/'.git/index').write_bytes(original_index),'Full index differs')
run('binding digest mismatch',lambda:job['source_bindings'][0].update(sha256='0'*64),lambda:job['source_bindings'][0].update(sha256=m.sha(b'\0binary')),'Binding content mismatch')
run('aggregate deadline',expected='deadline',seconds=-1)
class MidIndex(m.Audit):
 def path(self,rel):
  p=super().path(rel)
  if rel=='binding.bin':(R/'.git/index').write_bytes(original_index+b'changed')
  return p
run('mid-audit index mutation',restore=lambda:(R/'.git/index').write_bytes(original_index),expected='HEAD/index changed',audit_class=MidIndex)
head=(R/'.git/HEAD').read_bytes()
class MidHead(m.Audit):
 def path(self,rel):
  p=super().path(rel)
  if rel=='binding.bin':(R/'.git/HEAD').write_bytes((base+'\n').encode())
  return p
run('mid-audit HEAD mutation',restore=lambda:(R/'.git/HEAD').write_bytes(head),expected='HEAD/index changed',audit_class=MidHead)
# Exercise the production subprocess timeout using a harmless sleeping executable invocation.
original_run=m.subprocess.run
def slow(*args,**kwargs):
 return original_run([os.sys.executable,'-c','import time;time.sleep(3)'],capture_output=True,timeout=kwargs['timeout'])
m.subprocess.run=slow
start=time.monotonic()
try:
 try:m.Audit(R,job,contract,.08).git('rev-parse','HEAD');raise AssertionError('Slow Git accepted')
 except subprocess.TimeoutExpired:assert time.monotonic()-start<2
finally:m.subprocess.run=original_run
results.append(dict(case='slow Git child terminated at remaining deadline',status='PASS_REJECTED'))
(P/'cpu-source-results.json').write_text(json.dumps(dict(status='PASS',stage_access=False,cases=results),indent=2)+'\n',encoding='utf-8')
print('PASS',len(results),'source preflight cases; no native stage access')
