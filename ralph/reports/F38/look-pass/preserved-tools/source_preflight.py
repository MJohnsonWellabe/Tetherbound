"""Read-only source audit. Supervisor supplies the hard outer wall deadline."""
from pathlib import Path
import hashlib,json,os,stat,subprocess,sys,time
from concurrent.futures import ThreadPoolExecutor
from collections import deque
G='C:/Users/mattj/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/git/mingw64/bin/git.exe'
sha=lambda b:hashlib.sha256(b).hexdigest()
blob=lambda b:hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()
def require(value,why):
 if not value:raise RuntimeError(why)
class Audit:
 def __init__(self,stage,job,contract,seconds=40):
  self.stage=Path(stage).absolute();self.job=job;self.c=contract;self.start=time.monotonic();self.end=self.start+seconds
  self.timings={};self.counts={'directories_scanned':0,'tracked_paths_checked':0,'file_bytes_read':0,'sha256_binding_files':0}
 def timed(self,name,started):self.timings[name]=self.timings.get(name,0)+time.monotonic()-started
 def profile(self):return dict(elapsed_seconds=time.monotonic()-self.start,seconds_by_operation=self.timings,counts=self.counts)
 def remaining(self):
  left=self.end-time.monotonic();require(left>0,'Source preflight deadline exceeded');return left
 def git(self,*args):
  started=time.monotonic()
  e=dict(os.environ,GIT_NO_LAZY_FETCH='1',GIT_OPTIONAL_LOCKS='0',GIT_TERMINAL_PROMPT='0')
  r=subprocess.run([G,'-C',str(self.stage),'-c','gc.auto=0','-c','maintenance.auto=false','-c','core.fsmonitor=false',*args],capture_output=True,env=e,timeout=min(30,self.remaining()))
  self.remaining();require(len(r.stdout)+len(r.stderr)<=16*1024*1024,'Git output cap exceeded')
  require(r.returncode==0,'Bounded Git failed: '+args[0]+': '+r.stderr[:2000].decode(errors='replace'));self.timed('git',started);return r.stdout
 @staticmethod
 def signature(s):return (s.st_dev,s.st_ino,stat.S_IFMT(s.st_mode),s.st_size,s.st_mtime_ns)
 @staticmethod
 def regular(s):return stat.S_ISREG(s.st_mode) and not(getattr(s,'st_file_attributes',0)&0x400)
 def directory(self,rel):
  if rel in self.dirs:return self.dirs[rel]
  self.remaining();started=time.monotonic();p=self.stage/rel
  if rel:
   parent,name=rel.rsplit('/',1) if '/' in rel else ('',rel)
   entries=self.directory(parent)
   if entries is None or name not in entries:self.dirs[rel]=None;return None
   listed=entries[name].stat(follow_symlinks=False)
   require(stat.S_ISDIR(listed.st_mode) and not(getattr(listed,'st_file_attributes',0)&0x400),'Reparse or non-directory source parent: '+rel)
  info=p.lstat()
  require(stat.S_ISDIR(info.st_mode) and not(getattr(info,'st_file_attributes',0)&0x400),'Reparse or non-directory source parent: '+rel)
  with os.scandir(p) as scan:entries={e.name:e for e in scan}
  after=p.lstat();require(self.signature(info)==self.signature(after),'Directory changed during inventory: '+rel)
  self.dirs[rel]=entries;self.dir_snapshots[rel]=self.signature(after);self.counts['directories_scanned']+=1
  self.timed('directory_inventory',started);return entries
 def path(self,rel):
  require(isinstance(rel,str) and rel and not Path(rel).is_absolute() and '\\' not in rel and ':' not in rel and all(x not in ('','..','.') and not x.endswith((' ','.')) for x in rel.split('/')),'Unsafe source path')
  parent,name=rel.rsplit('/',1) if '/' in rel else ('',rel)
  entries=self.directory(parent);self.current_entry=None if entries is None else entries.get(name)
  self.counts['tracked_paths_checked']+=1
  return self.stage/rel
 def audit_file(self,rel,oid,p,bindings,canonical):
  started=time.monotonic();listed=p.lstat();require(self.regular(listed),'Reparse source path or tracked path is not a file: '+rel)
  h256=hashlib.sha256() if rel in bindings else None;chunks=[]
  keep=rel in canonical or (rel in bindings and bindings[rel].get('hash_mode','binary' if rel.endswith('.dll') else 'utf8_lf')=='utf8_lf')
  with p.open('rb') as f:
   before=os.fstat(f.fileno());require(self.regular(before) and self.signature(listed)==self.signature(before),'File replaced before audit: '+rel)
   h=hashlib.sha1(b'blob '+str(before.st_size).encode()+b'\0')
   if keep:require(before.st_size<=64*1024*1024,'Canonical text cap exceeded: '+rel)
   readbytes=0
   while True:
    self.remaining();chunk=f.read(1024*1024)
    if not chunk:break
    h.update(chunk);readbytes+=len(chunk)
    if h256 is not None:h256.update(chunk)
    if keep:chunks.append(chunk)
   require(self.signature(before)==self.signature(os.fstat(f.fileno())),'File changed during audit: '+rel)
  after=p.lstat();require(self.regular(after) and self.signature(before)==self.signature(after) and readbytes==before.st_size,'File changed during audit: '+rel)
  io_seconds=time.monotonic()-started;started=time.monotonic()
  data=b''.join(chunks) if keep else None
  if h.hexdigest()==oid:rawcount=1;canoncount=0
  else:
   require(rel in canonical and data is not None and b'\0' not in data,'Dirty tracked file: '+rel)
   data.decode('utf-8',errors='strict')
   require(blob(data.replace(b'\r\n',b'\n'))==oid,'Dirty tracked file: '+rel);rawcount=0;canoncount=1
  if rel in bindings:
   b=bindings[rel];require(b['blob']==oid,'Binding blob mismatch: '+rel)
   mode=b.get('hash_mode','binary' if rel.endswith('.dll') else 'utf8_lf');require(mode in ('binary','utf8_lf'),'Unknown binding hash mode')
   digest=h256.hexdigest()
   if digest!=b['sha256'] and mode=='utf8_lf':
    require(data is not None and b'\0' not in data,'Invalid bound text: '+rel)
    digest=sha(data.decode('utf-8',errors='strict').replace('\r\n','\n').encode())
   require(digest==b['sha256'],'Binding content mismatch: '+rel)
  return (rawcount,canoncount,readbytes,rel in bindings,io_seconds,time.monotonic()-started)
 def run(self):
  self.dirs={};self.dir_snapshots={};source=self.c['source'];require(self.job['source_commit']==source,'Contract/source mismatch')
  # Validate stage ancestors without following a reparse point.
  for ancestor in [self.stage,*self.stage.parents]:
   info=ancestor.lstat();require(stat.S_ISDIR(info.st_mode) and not(getattr(info,'st_file_attributes',0)&0x400),'Reparse stage ancestor')
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
  pending=deque()
  def collect():
   nonlocal rawcount,canoncount,total
   self.remaining();raw,canon,n,bound,io_seconds,canonical_seconds=pending.popleft().result(timeout=self.remaining())
   self.remaining();rawcount+=raw;canoncount+=canon;total+=n
   self.counts['file_bytes_read']+=n;self.counts['sha256_binding_files']+=int(bound)
   self.timings['file_io_hash_worker_seconds']=self.timings.get('file_io_hash_worker_seconds',0)+io_seconds
   self.timings['canonical_and_bindings_worker_seconds']=self.timings.get('canonical_and_bindings_worker_seconds',0)+canonical_seconds
  file_phase=time.monotonic()
  # Four workers/eight pending files: no unbounded queue, no cached hash verdicts.
  # Every worker streams fresh bytes and has the same aggregate deadline.
  with ThreadPoolExecutor(max_workers=4,thread_name_prefix='source-audit') as pool:
   for rel,(mode,oid) in tree.items():
    self.remaining();p=self.path(rel)
    if self.current_entry is None:
     require(rel not in required and flags.get(rel)==b'S','Missing materialized or non-sparse file: '+rel);continue
    pending.append(pool.submit(self.audit_file,rel,oid,p,bindings,canonical))
    if len(pending)>=8:collect()
   while pending:collect()
  self.timed('inventory_and_files_wall',file_phase)
  for rel in self.c['deleted_paths']:
   self.path(rel);require(self.current_entry is None,'Deleted path reappeared: '+rel)
  started=time.monotonic()
  for rel,signature in self.dir_snapshots.items():
   self.remaining();require(self.signature((self.stage/rel).lstat())==signature,'Directory changed during audit: '+rel)
  self.timed('directory_snapshot_recheck',started)
  self.remaining();require((gd/'HEAD').read_bytes()==headbytes and sha((gd/'index').read_bytes())==indexhash,'HEAD/index changed during audit')
  require(self.git('rev-parse','HEAD').decode().strip()==source,'HEAD changed during audit')
  self.remaining()
  return dict(status='PASS',source=source,index_paths=len(tree),materialized_files=rawcount+canoncount,raw_blob_files=rawcount,crlf_canonical_files=canoncount,bytes=total,bindings=len(bindings),index_sha256=indexhash,profile=self.profile())
def main():
 require(len(sys.argv)==4,'Expected stage, job, contract')
 audit=Audit(sys.argv[1],json.loads(Path(sys.argv[2]).read_bytes()),json.loads(Path(sys.argv[3]).read_bytes()))
 try:result=audit.run()
 except BaseException as e:
  print(json.dumps(dict(status='FAILED',error=str(e)[:3000],profile=audit.profile())),file=sys.stderr);sys.exit(1)
 print(json.dumps(result))
if __name__=='__main__':
 try:main()
 except Exception as e:print(json.dumps(dict(status='FAILED',error=str(e)[:3000])),file=sys.stderr);sys.exit(1)
