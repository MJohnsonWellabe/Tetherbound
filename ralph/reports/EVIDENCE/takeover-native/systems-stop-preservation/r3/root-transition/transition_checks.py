"""Pure budget/hash oracles plus root-only resource and bounded Git readers."""
import ctypes,hashlib,shutil,subprocess,time
GIB=1024**3
TEXT_SUFFIXES=('.gd','.godot','.tscn','.tres','.json','.gdshader','.gdshaderinc','.gdextension','.gltf','.obj','.mtl','.svg','.import','.md','.txt','.py','.ps1','.yml','.yaml','.cfg','.ini','.csv','.sh','.bat','.gitignore','.gitattributes','.uid')
def blob_id(data):return hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
def canonical_candidate(path,raw):
 if not str(path).lower().endswith(TEXT_SUFFIXES):raise AssertionError(('Binary raw blob differs',str(path)))
 return raw.decode('utf-8').replace('\r\n','\n').encode('utf-8')
def assert_canonical(path,raw,canonical,expected):
 assert blob_id(canonical)==expected,('Canonical object identity differs',str(path))
 assert canonical_candidate(path,raw)==canonical,('Dirty materialized file',str(path))
def peak_budget(existing_sizes,target_sizes,index_bytes,head_bytes,metadata_bytes,entries,path_bytes,pack_bytes,object_count):
 values=[*existing_sizes,*target_sizes,index_bytes,head_bytes,metadata_bytes,entries,path_bytes,pack_bytes,object_count]
 assert all(isinstance(x,int) and x>=0 for x in values)
 index_bound=max(index_bytes,entries*256+path_bytes+1024*1024)
 reserve=max(8*1024**2,entries*512+path_bytes*6)
 backup=sum(existing_sizes)+index_bytes+head_bytes+metadata_bytes
 writes=sum(target_sizes)
 imported=pack_bytes*2+object_count*128+1024*1024
 return dict(C= writes+imported+index_bound+reserve,D=backup+index_bound*2+reserve,
  components=dict(backup=backup,target_writes=writes,pack_import=imported,target_index_bound=index_bound,metadata_journal_reserve_each_drive=reserve))
def assert_resources(snapshot,budget=None,admission=False):
 budget=budget or {'C':0,'D':0}
 for drive,stop,entry in [('C',10*GIB,int(10.5*GIB)),('D',20*GIB,21*GIB)]:
  available=snapshot[drive]
  assert available>= (entry if admission else stop),('Resource floor',drive,available)
  assert available-budget[drive]>=stop,('Peak budget would cross stop floor',drive,available,budget[drive])
 assert snapshot['physical']>=2*GIB,'Physical memory floor'
 assert snapshot['commit']>=2*GIB,'Commit headroom floor'
def resource_snapshot():
 class Performance(ctypes.Structure):
  _fields_=[('cb',ctypes.c_ulong)]+[(n,ctypes.c_size_t) for n in ('CommitTotal','CommitLimit','CommitPeak','PhysicalTotal','PhysicalAvailable','SystemCache','KernelTotal','KernelPaged','KernelNonpaged','PageSize')]+[(n,ctypes.c_ulong) for n in ('HandleCount','ProcessCount','ThreadCount')]
 p=Performance();p.cb=ctypes.sizeof(p)
 assert ctypes.windll.psapi.GetPerformanceInfo(ctypes.byref(p),p.cb),'Memory counters unavailable'
 return dict(C=shutil.disk_usage('C:/').free,D=shutil.disk_usage('D:/').free,physical=p.PhysicalAvailable*p.PageSize,commit=(p.CommitLimit-p.CommitTotal)*p.PageSize)
def batch_blobs(git,root,ids,max_total=64*1024**2):
 ids=list(dict.fromkeys(ids))
 if not ids:return {}
 rows=git(root,'cat-file','--batch-check',data=('\n'.join(ids)+'\n').encode()).decode().splitlines()
 assert len(rows)==len(ids)
 sizes={}
 for oid,row in zip(ids,rows):
  fields=row.split();assert len(fields)==3 and fields[:2]==[oid,'blob'],('Missing canonical blob',oid)
  sizes[oid]=int(fields[2])
 assert sum(sizes.values())<=max_total,'Bounded canonical batch exceeds 64 MiB; refuse'
 result={}
 for start in range(0,len(ids),128):
  chunk=ids[start:start+128];raw=git(root,'cat-file','--batch',data=('\n'.join(chunk)+'\n').encode());cursor=0
  for oid in chunk:
   end=raw.index(b'\n',cursor);assert raw[cursor:end].split()==[oid.encode(),b'blob',str(sizes[oid]).encode()]
   cursor=end+1;b=raw[cursor:cursor+sizes[oid]];cursor+=sizes[oid]
   assert raw[cursor:cursor+1]==b'\n' and blob_id(b)==oid;cursor+=1;result[oid]=b
  assert cursor==len(raw)
 return result
