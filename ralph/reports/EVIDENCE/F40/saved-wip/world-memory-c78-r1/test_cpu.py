import copy, hashlib, json
from pathlib import Path
from analyze_trace import analyze, CORE, PREFIX

root=Path(__file__).resolve().parent
fixture=root/'cpu-fixture-r1'
fixture.mkdir(exist_ok=False)
checks=[]
def row(phase,sequence):
    return {'phase':phase,'sequence':sequence,'elapsed_ms':sequence*10000,'ticks_ms':50000+sequence*10000,'static_bytes':1000+sequence*10,'static_peak_bytes':9000,'progress':-1,'total':-1,'packed_payload_bytes':0 if phase=='fill_far_dry_released' else -1,'main_count':5,'far_count':3,'fill_count':7,'alpine_count':2}
def run(label,rows,fail=False):
    path=fixture/(label+'.log')
    path.write_text('Godot fixture only; no engine ran\n'+''.join(PREFIX+json.dumps(r)+'\n' for r in rows),encoding='utf-8')
    try:
        result=analyze(path)
    except (ValueError,TypeError):
        if not fail: raise
        checks.append(label);return None
    assert not fail,label
    assert result['capture_pass'] is False
    checks.append(label);return result
rows=[row(p,i) for i,p in enumerate(CORE)]
assert run('complete_trace_still_not_capture_pass',rows)['status']=='TRACE_COMPLETE_UNREVIEWED'
assert run('interrupted_before_fill_collection_finishes',rows[:5])['last_phase']=='fill_collect_begin'
assert run('no_trace_does_not_invent_phase',[])['last_phase'] is None
for label,index,key,value in [('sequence_gap',5,'sequence',9),('unknown_phase',4,'phase','invented'),('clock_regression',5,'ticks_ms',0),('boolean_memory',2,'static_bytes',True),('negative_memory',2,'static_bytes',-1),('misaligned_payload',7,'packed_payload_bytes',3),('unreleased_payload',11,'packed_payload_bytes',4)]:
    bad=copy.deepcopy(rows);bad[index][key]=value;run(label,bad,True)
bad=copy.deepcopy(rows);bad[5]['phase']='fill_collect_begin';run('duplicate_boundary',bad,True)
progress=copy.deepcopy(rows[:3])+[row('ellipse_progress',3),row('ellipse_progress',4)]
progress[-1]['elapsed_ms']=progress[-2]['elapsed_ms']+9999
run('periodic_rate_limit',progress,True)
bad=copy.deepcopy(rows[:2])+[row('fill_generate_progress',2)];run('progress_in_wrong_stage',bad,True)
bad=copy.deepcopy(rows[:14])+[row('alpine_bucket_uploaded',14)];run('upload_without_bucket_boundary',bad,True)
full=copy.deepcopy(rows[:3])+[row('ellipse_progress',i) for i in range(3,67)]
for phase in CORE[3:14]:full.append(row(phase,len(full)))
full.append(row('alpine_buckets_ready',len(full)))
for i in range(6):full.append(row('alpine_bucket_uploaded',len(full)))
for phase in CORE[14:]:full.append(row(phase,len(full)))
assert len(full)==87
assert run('max_record_count_preserves_terminal_boundary',full)['record_count']==87
bad=copy.deepcopy(full);bad.append(row('alpine_returned',87));run('record_cap',bad,True)
report={'status':'CPU_PASS_NATIVE_UNRUN','checks':checks,'check_count':len(checks),'engine_launches':0,'native_stage_accessed':False,'actual_owner_accessed':False,'analyzer_sha256':hashlib.sha256((root/'analyze_trace.py').read_bytes()).hexdigest(),'fixtures':'Synthetic saved log text only. No execution or memory observations claimed.'}
(fixture/'report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report))
