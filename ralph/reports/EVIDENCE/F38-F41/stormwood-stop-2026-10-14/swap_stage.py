"""Root-only preserving b9 -> 868 transition. Importing this module is read-only.

All filesystem mutation is gated by the real owner lock and capacity checks.
Failure retains the verified backup and any intermediate source state; no rollback
or lease overwrite is attempted after a conflict.
"""
import contextlib,ctypes,datetime,hashlib,json,os,pathlib,shutil,stat,subprocess,sys
from ctypes import wintypes

ROOT=pathlib.Path(__file__).absolute().parent
EXPECTED_ROOT=pathlib.Path('D:/tetherbound/.artifacts/codex-look-stormwood/native-868a7b5c8c/from-b9d7edeb7f-r3')
STAGE=pathlib.Path('C:/CodexTemp/tetherbound-native-service')
GITDIR=pathlib.Path('D:/tetherbound/source/.git/worktrees/tetherbound-native-service')
BACKUP=pathlib.Path('D:/tetherbound/.artifacts/codex-look-stormwood/stage-swap-backup-b9-to-868-r3')
OWNER=pathlib.Path('C:/CodexTemp/tetherbound-native-owner.json')
LOCK=pathlib.Path('C:/CodexTemp/tetherbound-native-owner.lock')
THREAD='01a13307-fea3-7ae0-a0cf-ecd8f0e0d502'
OLD='b9d7edeb7f18d7ca2192f018016d4126f1910f91'
TARGET='868a7b5c8c4d89483a85f2ce0f6c7c7bb2c558ee'
INDEX_SHA='8564bb8b52f74c58803830eb8562798a00af80804039c1be217eea885cf096f4'
GIT='C:/Users/mattj/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/git/mingw64/bin/git.exe'
ENV=dict(os.environ,GIT_NO_LAZY_FETCH='1',GIT_OPTIONAL_LOCKS='0',GIT_TERMINAL_PROMPT='0')
GIB=1024**3

def require(condition,message):
 if not condition:raise RuntimeError(message)
def sha(data):return hashlib.sha256(data).hexdigest()
def blob(data):return hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
def matches_blob(path,data,expected):
 if blob(data)==expected:return True
 # Raw blob identity comes first, including a tracked raw-CRLF blob.
 text_extensions={'.gd','.gdshader','.gdshaderinc','.godot','.tscn','.tres','.json','.md','.txt','.cfg','.ini','.yml','.yaml','.toml','.csv','.py','.ps1','.sh','.xml','.svg','.import','.uid','.glsl','.mjs','.js','.cjs'}
 if pathlib.PurePosixPath(path).suffix.lower() not in text_extensions or b'\0' in data:return False
 try:data.decode('utf-8',errors='strict')
 except UnicodeDecodeError:return False
 return blob(data.replace(b'\r\n',b'\n'))==expected

def validate_absolute(path):
 path=pathlib.Path(path)
 require(path.is_absolute() and '..' not in path.parts,'Absolute bounded path required')
 chain=[*reversed(path.parents),path]
 for item in chain:
  try:info=item.lstat()
  except FileNotFoundError:continue
  require(not stat.S_ISLNK(info.st_mode) and not getattr(info,'st_file_attributes',0)&stat.FILE_ATTRIBUTE_REPARSE_POINT,'Reparse point forbidden: '+str(item))
  if item!=path:require(stat.S_ISDIR(info.st_mode),'Non-directory path ancestor: '+str(item))
 require(os.path.normcase(str(path.resolve(strict=False)))==os.path.normcase(str(path)),'Resolved path changed: '+str(path))
 return path

def safe_path(anchor,relative):
 anchor=validate_absolute(anchor)
 require(isinstance(relative,str) and bool(relative) and '\\' not in relative,'Unsafe relative path')
 parts=relative.split('/')
 require(all(p not in ('','.','..') and ':' not in p and not p.endswith((' ','.')) for p in parts),'Relative path escapes or aliases its root')
 rel=pathlib.PurePosixPath(relative)
 require(not rel.is_absolute(),'Absolute child path forbidden')
 dest=validate_absolute(anchor.joinpath(*parts))
 require(dest.resolve(strict=False).is_relative_to(anchor.resolve(strict=False)),'Resolved child escapes approved root')
 return dest

def read_regular(path):
 path=validate_absolute(path);require(path.is_file(),'Required regular file missing: '+str(path))
 return path.read_bytes()

class LockedFile:
 def __init__(self,path,stream):self.path=path;self.stream=stream
 def assert_held(self):
  require(not self.stream.closed,'Required OS file lock is no longer held')
  self.stream.fileno()

@contextlib.contextmanager
def locked_file(path,writable=False,share_read=False):
 """OPEN_EXISTING; never creates/truncates a lock or owner file.

 Windows share mode excludes writes/deletion for the handle lifetime. A source
 handle may share reads; owner and root lock handles are exclusive.
 """
 import msvcrt
 path=validate_absolute(path)
 kernel=ctypes.WinDLL('kernel32',use_last_error=True)
 create=kernel.CreateFileW
 create.argtypes=[wintypes.LPCWSTR,wintypes.DWORD,wintypes.DWORD,ctypes.c_void_p,wintypes.DWORD,wintypes.DWORD,wintypes.HANDLE]
 create.restype=wintypes.HANDLE
 access=0x80000000|(0x40000000 if writable else 0)
 handle=create(str(path),access,1 if share_read else 0,None,3,0x00200000,None)
 if handle==ctypes.c_void_p(-1).value:raise ctypes.WinError(ctypes.get_last_error())
 try:fd=msvcrt.open_osfhandle(handle,os.O_BINARY|(os.O_RDWR if writable else os.O_RDONLY))
 except BaseException:
  kernel.CloseHandle.argtypes=[wintypes.HANDLE];kernel.CloseHandle(handle);raise
 with os.fdopen(fd,'r+b' if writable else 'rb') as stream:
  yield LockedFile(path,stream)

def capacity_snapshot():
 class Performance(ctypes.Structure):
  _fields_=[('cb',wintypes.DWORD)]+[(n,ctypes.c_size_t) for n in ('CommitTotal','CommitLimit','CommitPeak','PhysicalTotal','PhysicalAvailable','SystemCache','KernelTotal','KernelPaged','KernelNonpaged','PageSize')]+[(n,wintypes.DWORD) for n in ('HandleCount','ProcessCount','ThreadCount')]
 data=Performance();data.cb=ctypes.sizeof(data)
 get=ctypes.WinDLL('psapi',use_last_error=True).GetPerformanceInfo
 get.argtypes=[ctypes.POINTER(Performance),wintypes.DWORD];get.restype=wintypes.BOOL
 if not get(ctypes.byref(data),data.cb):raise ctypes.WinError(ctypes.get_last_error())
 require(data.PageSize>0 and data.CommitLimit>=data.CommitTotal,'Invalid physical/commit telemetry')
 return dict(C=shutil.disk_usage('C:/').free,D=shutil.disk_usage('D:/').free,physical=data.PhysicalAvailable*data.PageSize,commit=(data.CommitLimit-data.CommitTotal)*data.PageSize)

def assert_capacity(snapshot,budget):
 for key in ('C','D','physical','commit'):
  require(type(snapshot.get(key)) is int and snapshot[key]>=0,'Missing/invalid capacity counter: '+key)
 for key in ('C','D','memory'):
  require(type(budget.get(key)) is int and budget[key]>=0,'Invalid capacity budget: '+key)
 require(snapshot['C']>=int(10.5*GIB),'C admission reserve below 10.5 GiB')
 require(snapshot['D']>=21*GIB,'D admission reserve below 21 GiB')
 require(snapshot['C']-budget['C']>=10*GIB,'C write/preservation headroom would cross 10 GiB')
 require(snapshot['D']-budget['D']>=20*GIB,'D write/preservation headroom would cross 20 GiB')
 require(snapshot['physical']-budget['memory']>=2*GIB,'Physical memory reserve below 2 GiB after buffers')
 require(snapshot['commit']-budget['memory']>=2*GIB,'Commit headroom below 2 GiB after buffers')

def allocation(size):return ((size+4095)//4096)*4096
def capacity_budget(contents,preserved,pack_bytes,index_bytes):
 # Count full new payload allocations, all raw preserved bytes including index,
 # HEAD and lease, index replacement/lock copies, pack+index growth and metadata.
 c=sum(allocation(len(data)) for data in contents.values())+4096*sum(len(pathlib.PurePosixPath(p).parts)-1 for p in contents)+1024**2
 preservation=sum(allocation(len(data)) for data in preserved.values())
 d=preservation+2*allocation(pack_bytes)+2*allocation(index_bytes)+16*1024**2
 memory=sum(len(data) for data in contents.values())+pack_bytes+max([len(x) for x in preserved.values()]+[0])
 return dict(C=c,D=d,memory=memory,preservation_bytes=preservation,C_metadata_and_owner_allowance_bytes=1024**2,D_metadata_allowance_bytes=16*1024**2)

class MutationGate:
 def __init__(self,lock,budget,snapshot=capacity_snapshot):self.lock=lock;self.budget=budget;self.snapshot=snapshot
 def check(self):self.lock.assert_held();assert_capacity(self.snapshot(),self.budget)
 def run(self,action,*args,**kwargs):
  self.check()
  return action(*args,**kwargs)

def validate_owner(raw,source):
 owner=json.loads(raw.decode('utf-8-sig'))
 require(owner.get('thread')==THREAD and owner.get('reserved') is True and owner.get('allow_native_launch') is True,'Exact root authorization fields required')
 require(owner.get('source')==source,'Incoming owner.source differs from exact source HEAD')
 require(not any(owner.get(k) for k in ('active_process_id','active_session_id','run_id','processes')),'Native lease is not idle')
 return owner

def mkdir_checked(anchor,relative,gate):
 dest=safe_path(anchor,relative)
 current=anchor
 for part in relative.split('/'):
  current=safe_path(current,part)
  if not current.exists():gate.run(current.mkdir)
  require(validate_absolute(current).is_dir(),'Preservation parent is not a directory')
 return dest

def write_new(anchor,relative,data,gate):
 dest=safe_path(anchor,relative)
 if '/' in relative:mkdir_checked(anchor,relative.rsplit('/',1)[0],gate)
 dest=safe_path(anchor,relative)
 gate.check()
 with dest.open('xb') as f:f.write(data);f.flush();os.fsync(f.fileno())
 actual=read_regular(safe_path(anchor,relative))
 require(len(actual)==len(data) and sha(actual)==sha(data),'Saved raw backup verification failed: '+relative)

def verify_backups(backup,records):
 for rel,record in records.items():
  raw=read_regular(safe_path(backup,rel))
  require(len(raw)==record['bytes'] and sha(raw)==record['sha256'],'Saved raw backup changed: '+rel)

def source_snapshot_matches(gitdir,head_bytes,index_bytes):
 require(read_regular(safe_path(gitdir,'HEAD'))==head_bytes,'Source HEAD bytes changed; preserve intermediate state')
 require(read_regular(safe_path(gitdir,'index'))==index_bytes,'Source index bytes changed; preserve intermediate state')

def final_owner_cas(lock,gate,owner_path,expected_owner,gitdir,expected_head,expected_index,target):
 """No compare-close-replace gap: owner write uses the compared exclusive handle.

 HEAD/index remain open with write/delete sharing denied throughout the compare
 and owner write. The real owner lock is also held by the caller.
 """
 lock.assert_held();gate.check()
 with locked_file(safe_path(gitdir,'HEAD'),share_read=True) as head:
  with locked_file(safe_path(gitdir,'index'),share_read=True) as index:
   with locked_file(owner_path,writable=True) as lease:
    require(head.stream.read()==expected_head and expected_head.strip()==target.encode(),'Final source HEAD CAS failed; preserve intermediate state')
    require(index.stream.read()==expected_index,'Final source index CAS failed; preserve intermediate state')
    current=lease.stream.read()
    require(current==expected_owner,'Final raw owner CAS failed; preserve changed lease and intermediate state')
    owner=validate_owner(current,OLD)
    owner.update(source=target,updated_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),purpose='Service lane reserved; Meadows first Medium OFF exact source prepared; no native writer')
    replacement=(json.dumps(owner,indent=2)+'\n').encode()
    gate.check();lock.assert_held()
    # Keep all three protected handles open. No stale snapshot or rename window.
    lease.stream.seek(0);lease.stream.write(replacement);lease.stream.truncate();lease.stream.flush();os.fsync(lease.stream.fileno())
    lease.stream.seek(0);require(lease.stream.read()==replacement,'Final owner write verification failed; retain backup')
 return sha(replacement)

def bounded_child(argv,data=None,timeout=45):
 # Windows communicate() writes stdin before entering its timed wait. Put that
 # entire operation in a worker; the caller deadline covers even blocked stdin.
 # No temporary files or source/lease writes are needed for read-only queries.
 import threading,time
 deadline=time.monotonic()+timeout
 child=subprocess.Popen(argv,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,env=ENV)
 result={};done=threading.Event()
 def communicate():
  try:result['output']=child.communicate(data)
  except BaseException as exc:result['error']=exc
  finally:done.set()
 worker=threading.Thread(target=communicate,daemon=True);worker.start()
 completed=done.wait(max(0,deadline-time.monotonic()))
 if not completed or time.monotonic()>=deadline:
  if child.poll() is None:child.kill()
  require(done.wait(5),'Owned Git helper did not finish cleanup after deadline')
  raise subprocess.TimeoutExpired(argv,timeout)
 if 'error' in result:raise result['error']
 stdout,stderr=result['output']
 require(len(stdout)+len(stderr)<=64*1024**2,'Git helper output exceeded 64 MiB')
 if child.returncode:raise subprocess.CalledProcessError(child.returncode,argv,output=stdout,stderr=stderr)
 return stdout

def git(*args,data=None,store=None):
 location=['--git-dir='+str(store)] if store else ['-C',str(STAGE)]
 return bounded_child([GIT,'-c','gc.auto=0','-c','maintenance.auto=false','-c','core.fsmonitor=false',*location,*args],data=data,timeout=45)


def tree(ref,store=None):
 result={}
 for line in git('ls-tree','-rz',ref,store=store).split(b'\0'):
  if not line:continue
  meta,p=line.split(b'\t');mode,kind,oid=meta.decode().split();require(kind=='blob','Unsupported source tree entry')
  result[p.decode()]=(mode,oid)
 return result

def index_tree():
 result={}
 for line in git('ls-files','--stage','-z').split(b'\0'):
  if not line:continue
  meta,p=line.split(b'\t');mode,oid,s=meta.decode().split();require(s=='0','Unmerged index entry')
  result[p.decode()]=(mode,oid)
 return result

def assert_no_native_processes():
 pw='C:/Users/mattj/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/powershell/pwsh.exe'
 code="$ErrorActionPreference='Stop';$Rows=@(Get-CimInstance Win32_Process | Where-Object { $_.Name -match '^(Godot.*|Blender.*)\\.exe$' -or ($_.Name -eq 'git.exe' -and $_.CommandLine -like '*tetherbound-native-service*') });if($Rows.Count){throw 'Native stage process exists'}"
 subprocess.run([pw,'-NoProfile','-Command',code],env=ENV,check=True,timeout=20,capture_output=True)

def audit_stage(phase):
 pins={'source_preflight.py': 'd4cb5bce3664f35f05c576f6fd691411cf71c5c6d78e7fa1aaec3a8d5517d7d2', 'source-contract.json': '7098b8faddac87bdfe63f3b7b657dfd276efb89b711e64c7d494303669cfcc31', 'source-contract-before.json': '2c982721dd26f49437ba286dd046ba0ec96912c642058b7c77deb594beaed8bf', 'source-job-before.json': 'ed5a549340e4a7e141410ddb594fe1000d10157481a5e8ea2a1b7d80c8d5d45d'}
 for name,digest in pins.items():require(sha(read_regular(safe_path(ROOT,'shared/'+name)))==digest,'Bounded source audit pin differs: '+name)
 before=phase=='before'
 job_path=safe_path(ROOT,'shared/source-job-before.json' if before else 'shared/native-job.json')
 contract_path=safe_path(ROOT,'shared/source-contract-before.json' if before else 'shared/source-contract.json')
 code=subprocess.run(['C:/Users/mattj/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe',str(safe_path(ROOT,'shared/source_preflight.py')),str(STAGE),str(job_path),str(contract_path)],env=ENV,capture_output=True,timeout=45)
 require(len(code.stdout)+len(code.stderr)<=1024**2,'Source audit output exceeded cap')
 require(code.returncode==0,'Bounded source audit failed: '+code.stderr[:3000].decode(errors='replace'))
 result=json.loads(code.stdout);contract=json.loads(read_regular(contract_path))
 require(result['status']=='PASS' and result['source']==(OLD if before else TARGET) and result['index_paths']==contract['full_index_paths'] and result['materialized_files']>=len(contract['materialize']) and result['bindings']==(0 if before else 794),'Incomplete full-index/raw-blob source audit')
 return result

def execute_transition(lock):
 require(os.path.normcase(str(ROOT))==os.path.normcase(str(EXPECTED_ROOT)),'Wrong packet location')
 for path in (ROOT,STAGE,GITDIR,BACKUP,OWNER,LOCK):validate_absolute(path)
 require(not BACKUP.exists(),'Preservation root already exists; retain it and review')
 require(not safe_path(ROOT,'stage-swap-result.json').exists(),'Transition result already exists')
 require(not safe_path(GITDIR,'index.lock').exists(),'Git index lock exists')
 bound_bytes=read_regular(safe_path(ROOT,'source-bindings.json'))
 require(sha(bound_bytes)=='c63448e19ec0fd0509fddbde0a039115fe16c276f95c33f67fd278005a869d65','Source binding digest changed')
 inventory_bytes=read_regular(safe_path(ROOT,'transition-inventory.json'))
 require(sha(inventory_bytes)=='e5c7c3701bf0e8d811eabb10d2b51a50b3241385cf3b57ae97fb33247593461d','Transition inventory digest changed')
 inventory=json.loads(inventory_bytes);bound_source=json.loads(bound_bytes)
 job=json.loads(read_regular(safe_path(ROOT,'shared/native-job.json')))
 require(job['status']=='PREPARED' and job['launch_allowed'] is False and job['source_commit']==TARGET and job['native_transition_from']==OLD,'Exact unadmitted transition job required')
 require(job['source_bindings']==bound_source['source_bindings'] and len(job['source_bindings'])==794,'Exact 794 source bindings required')
 owner_bytes=read_regular(OWNER);validate_owner(owner_bytes,OLD)
 require(git('rev-parse','HEAD').decode().strip()==OLD,'Exact old HEAD required')
 require(pathlib.Path(git('rev-parse','--absolute-git-dir').decode().strip())==GITDIR,'Unexpected worktree metadata root')
 common=pathlib.Path(git('rev-parse','--path-format=absolute','--git-common-dir').decode().strip())
 require(common==pathlib.Path('D:/tetherbound/source/.git'),'Unexpected Git object-store root')
 validate_absolute(common);safe_path(common,'objects/pack')
 before_audit=audit_stage('before')
 head_bytes=read_regular(safe_path(GITDIR,'HEAD'));index_bytes=read_regular(safe_path(GITDIR,'index'))
 require(head_bytes.strip()==OLD.encode() and sha(index_bytes)==INDEX_SHA==before_audit['index_sha256'],'Exact detached old HEAD/index bytes required')
 pack=read_regular(safe_path(ROOT,'source.pack'))
 require(sha(pack)=='94fd634931f27acdeb2425d5a21e6899bf15706c407e4e6fc0ae8d78df69e1d7','Pack digest changed')
 # All target reads occur in the existing artifact-local proof store BEFORE
 # native pack import. It has no remote or partial-clone configuration.
 store=safe_path(ROOT,'offline-native.git');config=read_regular(safe_path(store,'config')).lower()
 require(b'remote ' not in config and b'promisor' not in config and b'partialclone' not in config,'Offline proof store has remote configuration')
 before=tree(OLD);after=tree(TARGET,store)
 require(index_tree()==before,'Full native index must match exact old tree')
 delta=sorted(p for p in before.keys()|after.keys() if before.get(p)!=after.get(p))
 require(delta==[r['path'] for r in inventory['transition_delta']],'Exact transition paths changed')
 write=inventory['planned_writes'];bound={b['path']:b for b in job['source_bindings']}
 require(len(write)==len(set(write)) and set(bound).issubset(write),'Invalid materialization list')
 deletes=[p for p in delta if p not in after and safe_path(STAGE,p).exists()]
 touched=sorted(set(write)|set(deletes));originals={}
 # Resolve and reject reparse points for deletion, write and preservation paths
 # before reading any of their contents, even before backup creation.
 for p in touched:
  dest=safe_path(STAGE,p);safe_path(BACKUP,'files/'+p)
  if dest.exists():originals[p]=read_regular(dest)
 preserved={'index':index_bytes,'HEAD':head_bytes,'owner.json':owner_bytes,**{'files/'+p:b for p,b in originals.items()}}
 for rel in [*preserved,'recovery.json','backup-manifest.json']:safe_path(BACKUP,rel)
 contents={}
 raw=git('cat-file','--batch',data=('\n'.join(after[p][1] for p in write)+'\n').encode(),store=store);offset=0
 for p in write:
  require(after[p][0] in ('100644','100755'),'Unsupported materialized file mode')
  end=raw.index(b'\n',offset);header=raw[offset:end].split();require(len(header)==3 and header[1]==b'blob','Missing required target blob')
  size=int(header[2]);data=raw[end+1:end+1+size];offset=end+size+2
  require(blob(data)==after[p][1],'Raw target blob differs')
  if p in bound:require(bound[p]['blob']==after[p][1] and sha(data)==bound[p]['sha256'],'Bound target payload differs')
  contents[p]=data
 for p,data in originals.items():
  expected=before[p][1] if p in before else after[p][1]
  require(matches_blob(p,data,expected),'Preserve unexplained existing payload: '+p)
 budget=capacity_budget(contents,preserved,len(pack),len(index_bytes))
 gate=MutationGate(lock,budget)
 gate.check() # Explicit full preservation/write/commit budget before ANY write.
 source_snapshot_matches(GITDIR,head_bytes,index_bytes)
 require(read_regular(OWNER)==owner_bytes,'Lease changed before preservation')
 gate.run(lambda:validate_absolute(BACKUP).mkdir())
 records={rel:dict(bytes=len(data),sha256=sha(data)) for rel,data in preserved.items()}
 for rel,data in preserved.items():write_new(BACKUP,rel,data,gate)
 recovery=dict(old=OLD,target=TARGET,writes=write,deletes=deletes,previously_absent=[p for p in write if p not in originals],capacity_budget=budget,raw_backup_records=records)
 write_new(BACKUP,'recovery.json',(json.dumps(recovery,indent=2)+'\n').encode(),gate)
 write_new(BACKUP,'backup-manifest.json',(json.dumps(records,indent=2)+'\n').encode(),gate)
 verify_backups(BACKUP,records) # Verified raw bytes before even pack import.
 source_snapshot_matches(GITDIR,head_bytes,index_bytes)
 require(read_regular(OWNER)==owner_bytes,'Lease changed before pack import')
 gate.run(git,'index-pack','--stdin',data=pack)
 require(tree(TARGET)==after,'Imported native target differs from prepared target')
 verify_backups(BACKUP,records)
 source_snapshot_matches(GITDIR,head_bytes,index_bytes)
 require(read_regular(OWNER)==owner_bytes,'Lease changed before source writes')
 for p,data in contents.items():
  dest=safe_path(STAGE,p)
  if p in originals:
   require(read_regular(dest)==originals[p],'Source changed since raw preservation: '+p)
   require(read_regular(safe_path(BACKUP,'files/'+p))==originals[p],'Saved raw source backup changed: '+p)
  else:require(not dest.exists(),'New untracked collision: '+p)
  if '/' in p:mkdir_checked(STAGE,p.rsplit('/',1)[0],gate)
  dest=safe_path(STAGE,p);gate.run(dest.write_bytes,data)
  require(read_regular(dest)==data,'Source write verification failed: '+p)
 for p in deletes:
  dest=safe_path(STAGE,p);require(read_regular(dest)==originals[p],'Deletion target changed since raw preservation')
  require(read_regular(safe_path(BACKUP,'files/'+p))==originals[p],'Deletion backup changed')
  gate.run(dest.unlink)
 source_snapshot_matches(GITDIR,head_bytes,index_bytes)
 verify_backups(BACKUP,records)
 index=''.join((f'{after[p][0]} {after[p][1]}\t{p}\n' if p in after else f'0 {"0"*40}\t{p}\n') for p in sorted(set(delta)|set(write)))
 gate.run(git,'update-index','--index-info',data=index.encode())
 excluded=[p for p in delta if p in after and p not in write and not safe_path(STAGE,p).exists()]
 if excluded:gate.run(git,'update-index','--skip-worktree','--stdin',data=('\n'.join(excluded)+'\n').encode())
 require(index_tree()==after,'Full index differs from target tree')
 verify_backups(BACKUP,records)
 gate.run(git,'update-ref','--no-deref','HEAD',TARGET,OLD)
 after_audit=audit_stage('after')
 final_head=read_regular(safe_path(GITDIR,'HEAD'));final_index=read_regular(safe_path(GITDIR,'index'))
 require(final_head.strip()==TARGET.encode() and sha(final_index)==after_audit['index_sha256'],'Final detached target HEAD/index differs from full audit')
 verify_backups(BACKUP,records)
 owner_sha=final_owner_cas(lock,gate,OWNER,owner_bytes,GITDIR,final_head,final_index,TARGET)
 result=dict(status='SOURCE_PREPARED_NOT_ADMITTED',old_source=OLD,source=TARGET,delta_paths=len(delta),canonical_files=len(write),bound_files=len(bound),full_index_matches_target_tree=True,tracked_clean=True,owner_sha256=owner_sha,source_preflight_before=before_audit,source_preflight_after=after_audit,raw_backup_manifest=records,capacity_budget=budget,engines_launched=0)
 write_new(ROOT,'stage-swap-result.json',(json.dumps(result,indent=2)+'\n').encode(),gate)
 print(json.dumps(result))

def main():
 require(sys.argv[1:]==['--root-authorized'],'Explicit root lease authorization required; preparation only')
 assert_capacity(capacity_snapshot(),dict(C=0,D=0,memory=0))
 # The Python entry point owns the actual OS lock, including direct invocation.
 with locked_file(LOCK,writable=True) as lock:
  assert_no_native_processes()
  execute_transition(lock)

if __name__=='__main__':main()
