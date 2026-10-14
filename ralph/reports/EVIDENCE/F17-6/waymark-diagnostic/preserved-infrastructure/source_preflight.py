"""Read-only source audit. Supervisor supplies the hard outer wall deadline."""
from pathlib import Path
import hashlib,json,os,subprocess,sys,time
G='C:/Users/mattj/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/git/mingw64/bin/git.exe'
sha=lambda b:hashlib.sha256(b).hexdigest()
blob=lambda b:hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()
def require(value,why):
 if not value:raise RuntimeError(why)
class Audit:
 def __init__(self,stage,job,contract,seconds=115):
  self.stage=Path(stage);self.job=job;self.c=contract;self.end=time.monotonic()+seconds
 def remaining(self):
  left=self.end-time.monotonic();require(left>0,'Source preflight deadline exceeded');return left
 def git(self,*args):
  e=dict(os.environ,GIT_NO_LAZY_FETCH='1',GIT_OPTIONAL_LOCKS='0',GIT_TERMINAL_PROMPT='0')
  r=subprocess.run([G,'-C',str(self.stage),'-c','gc.auto=0','-c','maintenance.auto=false','-c','core.fsmonitor=false',*args],capture_output=True,env=e,timeout=min(30,self.remaining()))
  self.remaining();require(len(r.stdout)+len(r.stderr)<=16*1024*1024,'Git output cap exceeded')
  require(r.returncode==0,'Bounded Git failed: '+args[0]+': '+r.stderr[:2000].decode(errors='replace'));return r.stdout
 def path(self,rel):
  require(not Path(rel).is_absolute() and '..' not in Path(rel).parts,'Unsafe source path')
  p=self.stage/rel
  # Cache checked parents: 49k paths must not each walk to the drive root.
  q=p
  while q not in self.checked:
   if q.exists():require(not q.is_symlink() and not(getattr(q.lstat(),'st_file_attributes',0)&0x400),'Reparse source path')
   self.checked.add(q)
   if q==self.stage:break
   q=q.parent
  return p
 def run(self):
  self.checked=set();source=self.c['source'];require(self.job['source_commit']==source,'Contract/source mismatch')
  head=self.git('rev-parse','HEAD').decode().strip();require(head==source,'HEAD mismatch')
  require(self.git('rev-parse','--abbrev-ref','HEAD').strip()==b'HEAD','Detached HEAD required')
  require(self.git('rev-parse',source+'^').decode().strip()==self.job['source_parent'],'Parent mismatch')
  changed=self.git('diff','--name-only',self.job['staging_base'],source).decode().splitlines()
  require(changed==self.job['changed_source_paths'],'Changed path metadata mismatch')
  gd=Path(self.git('rev-parse','--absolute-git-dir').decode().strip())
  headbytes=(gd/'HEAD').read_bytes();indexhash=sha((gd/'index').read_bytes())
  tree={}
  for row in self.git('ls-tree','-rz',source).split(b'\0'):
   if not row:continue
   meta,name=row.split(b'\t');mode,kind,oid=meta.split();name=name.decode()
   require(kind==b'blob' and mode in (b'100644',b'100755') and name not in tree,'Unexpected tree entry');tree[name]=(mode,oid.decode())
  index={}
  for row in self.git('ls-files','--stage','-z').split(b'\0'):
   if not row:continue
   meta,name=row.split(b'\t');mode,oid,stage=meta.split();name=name.decode()
   require(stage==b'0' and name not in index,'Unmerged/duplicate index entry');index[name]=(mode,oid.decode())
  require(index==tree and len(tree)==self.c['full_index_paths'],'Full index differs from target tree')
  flags={r[2:].decode():r[:1] for r in self.git('ls-files','-v','-z').split(b'\0') if r}
  required=set(self.c['materialize']);canonical=set(self.c['canonical_paths'])
  require(required<=tree.keys() and canonical<=required,'Invalid contract path set')
  bindings={b['path']:b for b in self.job['source_bindings']}
  require(len(bindings)==len(self.job['source_bindings']) and bindings.keys()<=required,'Invalid binding path set')
  rawcount=canoncount=total=0
  for rel,(mode,oid) in tree.items():
   self.remaining();p=self.path(rel)
   if not p.exists():
    require(rel not in required and flags.get(rel)==b'S','Missing materialized or non-sparse file: '+rel);continue
   require(p.is_file(),'Tracked path is not a file: '+rel)
   before=p.stat();h=hashlib.sha1(b'blob '+str(before.st_size).encode()+b'\0');h256=hashlib.sha256();chunks=[]
   keep=rel in canonical or (rel in bindings and bindings[rel]['hash_mode']=='utf8_lf')
   if keep:require(before.st_size<=64*1024*1024,'Canonical text cap exceeded: '+rel)
   with p.open('rb') as f:
    while True:
     self.remaining();chunk=f.read(1024*1024)
     if not chunk:break
     h.update(chunk);h256.update(chunk)
     if keep:chunks.append(chunk)
   after=p.stat();require((before.st_size,before.st_mtime_ns,before.st_ino)==(after.st_size,after.st_mtime_ns,after.st_ino),'File changed during audit: '+rel)
   data=b''.join(chunks) if keep else None
   if h.hexdigest()==oid:rawcount+=1
   else:
    require(rel in canonical and blob(data.replace(b'\r\n',b'\n'))==oid,'Dirty tracked file: '+rel);canoncount+=1
   if rel in bindings:
    b=bindings[rel];require(b['blob']==oid,'Binding blob mismatch: '+rel)
    require(b['hash_mode'] in ('binary','utf8_lf'),'Unknown binding hash mode')
    digest=h256.hexdigest() if b['hash_mode']=='binary' else sha(data.decode('utf-8-sig').replace('\r\n','\n').encode())
    require(digest==b['sha256'],'Binding content mismatch: '+rel)
   total+=before.st_size
  for rel in self.c['deleted_paths']:require(not self.path(rel).exists(),'Deleted path reappeared: '+rel)
  self.remaining();require((gd/'HEAD').read_bytes()==headbytes and sha((gd/'index').read_bytes())==indexhash,'HEAD/index changed during audit')
  require(self.git('rev-parse','HEAD').decode().strip()==source,'HEAD changed during audit')
  return dict(status='PASS',source=source,index_paths=len(tree),materialized_files=rawcount+canoncount,raw_blob_files=rawcount,crlf_canonical_files=canoncount,bytes=total,bindings=len(bindings),index_sha256=indexhash)
def main():
 require(len(sys.argv)==4,'Expected stage, job, contract')
 result=Audit(sys.argv[1],json.loads(Path(sys.argv[2]).read_bytes()),json.loads(Path(sys.argv[3]).read_bytes())).run()
 print(json.dumps(result))
if __name__=='__main__':
 try:main()
 except BaseException as e:print(json.dumps(dict(status='FAILED',error=str(e)[:3000])),file=sys.stderr);sys.exit(1)
