"""CPU-only tests of the actual transition guards; never calls main/execute_transition.

Real Windows handle sharing and junctions are exercised only in this packet's
uniquely named fixture directory. No native-stage/owner/lock access occurs.
"""
from pathlib import Path
import ast,copy,hashlib,importlib.util,json,os,subprocess,sys,uuid
sys.dont_write_bytecode=True
ROOT=Path(__file__).absolute().parent
spec=importlib.util.spec_from_file_location('transition_under_test',ROOT/'swap_stage.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
F=ROOT/('cpu-transition-fixtures-'+uuid.uuid4().hex);F.mkdir()
lockpath=F/'root-owner.lock';lockpath.write_bytes(b'fixture lock unchanged')
POS=[];NEG=[]
def good():return dict(C=30*m.GIB,D=40*m.GIB,physical=8*m.GIB,commit=8*m.GIB)
zero=dict(C=0,D=0,memory=0)
def expect(name,action,fragment=None):
 try:action()
 except (RuntimeError,OSError,ValueError) as exc:
  if fragment is not None:assert fragment in str(exc),(name,repr(exc))
  NEG.append(dict(case=name,error=type(exc).__name__,message=str(exc)))
 else:raise AssertionError('Invalid case accepted: '+name)
def rawowner(**changes):
 owner=dict(thread=m.THREAD,reserved=True,allow_native_launch=True,source=m.OLD,active_process_id=None,active_session_id=None,run_id=None,processes=[],extra_metadata='retain me')
 owner.update(changes);return (json.dumps(owner,indent=2)+'\n').encode()

with m.locked_file(lockpath,writable=True) as lock:
 lock.assert_held();POS.append('actual_exclusive_fixture_root_lock')
 expect('second_root_lock_handle_rejected',lambda:m.locked_file(lockpath,writable=True).__enter__())
 events=[]
 for key,low in [('C',int(10.5*m.GIB)-1),('D',21*m.GIB-1),('physical',2*m.GIB-1),('commit',2*m.GIB-1)]:
  snapshot=good();snapshot[key]=low
  gate=m.MutationGate(lock,zero,lambda s=snapshot:s)
  expect('pre_import_low_'+key,lambda:gate.run(events.append,'UNSAFE_IMPORT'),key if key in ('C','D') else None)
  assert events==[]
 for key in ['C','D','physical','commit']:
  snapshot=good();snapshot.pop(key)
  expect('missing_counter_'+key,lambda s=snapshot:m.MutationGate(lock,zero,lambda:s).run(events.append,'UNSAFE_WRITE'),'capacity counter')
  assert not events
 for value in [True,float('nan'),1.25,-1]:
  snapshot=good();snapshot['C']=value
  expect('invalid_counter_'+repr(value),lambda s=snapshot:m.MutationGate(lock,zero,lambda:s).run(events.append,'UNSAFE_WRITE'),'capacity counter')
 for key in ('C','D','memory'):
  budget=zero.copy();budget[key]=-1
  expect('negative_budget_'+key,lambda b=budget:m.MutationGate(lock,b,good).run(events.append,'UNSAFE_WRITE'),'capacity budget')
 snapshot=good();snapshot['D']=21*m.GIB
 expect('preservation_bytes_exceed_D_headroom',lambda:m.MutationGate(lock,dict(C=0,D=2*m.GIB,memory=0),lambda:snapshot).run(events.append,'UNSAFE_BACKUP'),'preservation headroom')
 snapshot=good();snapshot['C']=int(10.5*m.GIB)
 expect('stage_write_bytes_exceed_C_headroom',lambda:m.MutationGate(lock,dict(C=m.GIB,D=0,memory=0),lambda:snapshot).run(events.append,'UNSAFE_STAGE_WRITE'),'preservation headroom')
 for key in ('physical','commit'):
  snapshot=good();snapshot[key]=2*m.GIB
  expect('buffer_headroom_'+key,lambda s=snapshot:m.MutationGate(lock,dict(C=0,D=0,memory=4096),lambda:s).run(events.append,'UNSAFE_WRITE'))
 def unavailable():raise OSError('fixture telemetry unavailable')
 expect('telemetry_failure_before_mutation',lambda:m.MutationGate(lock,zero,unavailable).run(events.append,'UNSAFE_WRITE'),'telemetry unavailable')
 assert not events;POS.append('all_resource_refusals_before_import_or_write_callback')
 snapshot=dict(C=int(10.5*m.GIB),D=21*m.GIB,physical=2*m.GIB+4096,commit=2*m.GIB+4096)
 m.assert_capacity(snapshot,dict(C=int(.5*m.GIB),D=m.GIB,memory=4096));POS.append('exact_capacity_boundaries')
 budget=m.capacity_budget({'new':b'x'*4100},{'files/old':b'y'*8193,'index':b'i'*4097,'HEAD':b'h','owner.json':b'o'},260286,4097)
 assert budget['C']==8192+1024**2 and budget['preservation_bytes']==12288+8192+4096+4096
 assert budget['D']>=budget['preservation_bytes']+2*m.allocation(260286)+2*m.allocation(4097)+16*1024**2
 POS.append('budget_counts_raw_preservation_index_head_owner_pack_and_buffers')
 gate=m.MutationGate(lock,zero,good)
 safe=F/'safe';safe.mkdir();outside=F/'outside';outside.mkdir();(outside/'canary').write_bytes(b'untouched')
 for relative in ['../outside/canary','/outside','D:/outside','a/../../outside','file:stream','a\\..\\outside','a/','a//b','trailing.','trailing ']:
  expect('unsafe_path_'+relative,lambda r=relative:m.safe_path(safe,r))
 assert m.safe_path(safe,'files/nested/raw.bin')==safe/'files/nested/raw.bin';POS.append('missing_contained_path_allowed')
 pw='C:/Users/mattj/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/powershell/pwsh.exe'
 for name,target in [('outside-link',outside),('inside-link',safe)]:
  junction=safe/name
  code="New-Item -ItemType Junction -Path '"+str(junction)+"' -Target '"+str(target)+"' -ErrorAction Stop | Out-Null"
  subprocess.run([pw,'-NoProfile','-Command',code],check=True,capture_output=True,timeout=15)
  expect('backup_ancestor_junction_'+name,lambda j=junction:m.safe_path(j,'files/old'),'Reparse point')
  expect('deletion_source_junction_'+name,lambda n=name:m.safe_path(safe,n+'/canary'),'Reparse point')
  # Remove only this fixture junction itself; never recurse into its target.
  assert junction.is_junction() and junction.parent==safe
  junction.rmdir()
 assert (outside/'canary').read_bytes()==b'untouched';POS.append('real_junctions_refused_without_accessing_canary')
 backup=F/'verified-backup';backup.mkdir()
 preserved={'index':b'raw-index\x00','HEAD':(m.OLD+'\n').encode(),'owner.json':rawowner(),'files/crlf.gd':b'raw\r\ntext\r\n','files/binary.dll':b'\x00\xff\r\n'}
 records={rel:dict(bytes=len(data),sha256=m.sha(data)) for rel,data in preserved.items()}
 for rel,data in preserved.items():m.write_new(backup,rel,data,gate)
 m.verify_backups(backup,records);POS.append('raw_backup_write_readback_length_sha_verified')
 for rel in preserved:
  path=m.safe_path(backup,rel);original=path.read_bytes();path.write_bytes(b'X'+original[1:])
  expect('raw_backup_corruption_'+rel,lambda:m.verify_backups(backup,records),'Saved raw backup changed')
  path.write_bytes(original)
 # Raw CRLF must not be normalized while preserving or comparing backup bytes.
 (backup/'files/crlf.gd').write_bytes(preserved['files/crlf.gd'].replace(b'\r\n',b'\n'))
 expect('newline_normalized_backup_refused',lambda:m.verify_backups(backup,records),'Saved raw backup changed')
 (backup/'files/crlf.gd').write_bytes(preserved['files/crlf.gd'])
 m.verify_backups(backup,records)
 # Retain the accepted raw-first blob oracle unchanged in behavior.
 for name,data,expected_path,expected in [
  ('raw_crlf',b'a\r\n','x.gd',m.blob(b'a\r\n')),
  ('canonical_text',b'a\r\n','x.gd',m.blob(b'a\n')),
  ('raw_binary',b'\x00\xff\r\n','x.dll',m.blob(b'\x00\xff\r\n'))]:
  assert m.matches_blob(expected_path,data,expected),name;POS.append('blob_'+name)
 for name,path,data in [('binary_no_normalization','x.dll',b'a\r\n'),('nul_text','x.gd',b'a\x00\r\n'),('invalid_utf8','x.gd',b'\xff\r\n'),('unknown_extension','x.unknown',b'a\r\n')]:
  assert not m.matches_blob(path,data,m.blob(data.replace(b'\r\n',b'\n')));NEG.append(dict(case='blob_'+name,error='False',message='Rejected expected mismatch'))
 meta=F/'metadata';meta.mkdir();owner=F/'owner.json';head=(m.TARGET+'\n').encode();idx=b'fixture index after transition'
 def reset():
  (meta/'HEAD').write_bytes(head);(meta/'index').write_bytes(idx);owner.write_bytes(rawowner())
 def cas(g=gate):return m.final_owner_cas(lock,g,owner,rawowner(),meta,head,idx,m.TARGET)
 reset();cas();assert json.loads(owner.read_bytes())['source']==m.TARGET and json.loads(owner.read_bytes())['extra_metadata']=='retain me';POS.append('valid_final_owner_source_CAS_preserves_other_fields')
 for name,mutation in [
  ('raw_lease_whitespace',lambda:owner.write_bytes(rawowner()+b' ')),
  ('owner_source_changed',lambda:owner.write_bytes(rawowner(source='other'))),
  ('owner_thread_changed',lambda:owner.write_bytes(rawowner(thread='other'))),
  ('owner_new_activity',lambda:owner.write_bytes(rawowner(active_process_id=123))),
  ('source_head_changed',lambda:(meta/'HEAD').write_bytes((m.OLD+'\n').encode())),
  ('source_index_changed',lambda:(meta/'index').write_bytes(b'X'+idx[1:]))]:
  reset();mutation();before_owner=owner.read_bytes();before_head=(meta/'HEAD').read_bytes();before_index=(meta/'index').read_bytes()
  expect('final_CAS_'+name,cas,'CAS failed')
  assert owner.read_bytes()==before_owner and (meta/'HEAD').read_bytes()==before_head and (meta/'index').read_bytes()==before_index
 reset()
 for name,changes in [('wrong_source',dict(source='other')),('unreserved',dict(reserved=False)),('not_authorized',dict(allow_native_launch=False)),('wrong_root',dict(thread='other')),('active_run',dict(run_id='other'))]:
  expect('incoming_owner_'+name,lambda c=changes:m.validate_owner(rawowner(**c),m.OLD))
 reset()
 with m.locked_file(owner,writable=True):expect('competing_owner_handle_refuses_CAS',cas)
 assert owner.read_bytes()==rawowner()
 calls=[0]
 def dropping_capacity():
  calls[0]+=1;s=good()
  if calls[0]>=2:s['D']=0
  return s
 expect('capacity_drops_inside_CAS_before_write',lambda:cas(m.MutationGate(lock,zero,dropping_capacity)),'D admission')
 assert owner.read_bytes()==rawowner();POS.append('late_capacity_failure_preserves_owner_and_source')
 # On the second capacity check, all source/owner handles are open. Verify OS
 # denies competing writes and an atomic owner replacement before our write.
 calls=[0];blocked=[];replacement=F/'foreign-owner.tmp';replacement.write_bytes(b'foreign')
 def probe_handles():
  calls[0]+=1
  if calls[0]==2:
   for path in [lockpath,owner,meta/'HEAD',meta/'index']:
    try:path.write_bytes(b'UNSAFE')
    except PermissionError:blocked.append(path.name)
    else:raise AssertionError('Expected actual OS lock: '+str(path))
   try:os.replace(replacement,owner)
   except PermissionError:blocked.append('owner-replace')
   else:raise AssertionError('Owner replacement was not locked out')
  return good()
 reset();cas(m.MutationGate(lock,zero,probe_handles));assert len(blocked)==5 and replacement.exists();POS.append('real_OS_handles_block_concurrent_root_owner_HEAD_index_write_and_owner_replace')
 retained_lock=lock
expect('closed_root_lock_refuses_mutation',lambda:m.MutationGate(retained_lock,zero,good).run(lambda:None),'no longer held')
assert lockpath.read_bytes()==b'fixture lock unchanged'

# Audit ordering against the actual executable, not a second implementation.
source=(ROOT/'swap_stage.py').read_text(encoding='utf-8-sig');module=ast.parse(source)
functions={n.name:ast.get_source_segment(source,n) for n in module.body if isinstance(n,(ast.FunctionDef,ast.AsyncFunctionDef))}
body=functions['execute_transition'];main=functions['main'];final=functions['final_owner_cas']
assert body.index('budget=capacity_budget')<body.index('gate.check()')<body.index('gate.run(lambda:validate_absolute(BACKUP).mkdir())')
assert body.index('verify_backups(BACKUP,records)')<body.index("gate.run(git,'index-pack'")<body.index('gate.run(dest.write_bytes')
assert 'gate.run(dest.unlink)' in body and "gate.run(git,'update-index'" in body and "gate.run(git,'update-ref'" in body
assert main.index('assert_capacity(')<main.index('with locked_file(LOCK,writable=True)')<main.index('execute_transition(lock)')
assert 'os.replace' not in final and 'current==expected_owner' in final and "validate_owner(current,OLD)" in final
assert final.index('current==expected_owner')<final.index('lease.stream.write(replacement)')
POS.append('actual_executable_mutation_order_and_CAS_audit')
result=dict(status='PASS_CPU_ONLY',supervisor_scope='Transition guard tests; capture oracle unchanged',swap_sha256=m.sha((ROOT/'swap_stage.py').read_bytes()),positive_cases=len(POS),negative_cases=len(NEG),positive=POS,negative=NEG,fixture_directory=str(F),native_stage_written=False,native_owner_or_lock_accessed=False,engines_launched=0,authorized_transition_executed=False,limitations='Guard functions and real fixture-file OS sharing exercised; native stage mutation path not executed.')
(ROOT/'cpu-transition-guard-verification.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps(dict(status=result['status'],positive_cases=len(POS),negative_cases=len(NEG),fixture_directory=str(F)),indent=2))
