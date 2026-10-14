"""Read bounded saved logs only. Does not start processes or access a stage."""
import argparse, hashlib, json
from pathlib import Path

PREFIX='CLOUDREACH_COVER_MEMORY '
CORE=['look_begin','rails_done','cover_begin','ellipse_done','fill_collect_begin','fill_collect_done','fill_cells_ready','fill_buffers_ready','fill_near_released','fill_dry_released','fill_far_released','fill_far_dry_released','fill_returned','alpine_begin','alpine_returned','cover_returned']
PERIODIC={'ellipse_progress','fill_collect_progress','fill_generate_progress','alpine_generate_progress'}
EXTRA={'alpine_buckets_ready','alpine_bucket_uploaded'}
FIELDS=['sequence','elapsed_ms','ticks_ms','static_bytes','static_peak_bytes','progress','total','packed_payload_bytes','main_count','far_count','fill_count','alpine_count']

def analyze(path):
    path=Path(path)
    if path.stat().st_size>32*1024*1024:
        raise ValueError('stdout exceeds existing combined-log ceiling')
    data=path.read_bytes()
    records=[]; core=[]; periodic=[]; uploads=0; previous=None
    for line in data.decode('utf-8-sig',errors='strict').splitlines():
        if not line.startswith(PREFIX):
            continue
        row=json.loads(line[len(PREFIX):])
        if not isinstance(row,dict) or set(row)!=set(FIELDS+['phase']):
            raise ValueError('Unexpected trace schema')
        if any(type(row[k]) is not int for k in FIELDS):
            raise ValueError('Trace counter must be an integer')
        phase=row['phase']
        if phase not in CORE and phase not in PERIODIC and phase not in EXTRA:
            raise ValueError('Unknown phase')
        if row['sequence']!=len(records) or len(records)>=87:
            raise ValueError('Sequence/record cap differs')
        if any(row[k]<0 for k in FIELDS if k not in ('progress','total','packed_payload_bytes')):
            raise ValueError('Negative counter')
        if any(row[k]<-1 for k in ('progress','total','packed_payload_bytes')):
            raise ValueError('Unknown-size sentinel differs')
        if row['packed_payload_bytes']!=-1 and row['packed_payload_bytes']%4:
            raise ValueError('Packed size is not float32 aligned')
        if previous and (row['elapsed_ms']<previous['elapsed_ms'] or row['ticks_ms']<previous['ticks_ms']):
            raise ValueError('Time regressed')
        if phase in CORE:
            if len(core)>=len(CORE) or phase!=CORE[len(core)]:
                raise ValueError('Missing/duplicate/out-of-order boundary')
            core.append(phase)
        if phase in PERIODIC:
            previous_ms=periodic[-1]['elapsed_ms'] if periodic else 0
            if len(periodic)>=64 or row['elapsed_ms']-previous_ms<10000:
                raise ValueError('Periodic rate/cap differs')
            required={'ellipse_progress':'cover_begin','fill_collect_progress':'fill_collect_begin','fill_generate_progress':'fill_cells_ready','alpine_generate_progress':'alpine_begin'}[phase]
            if not core or core[-1]!=required:
                raise ValueError('Progress outside owning stage')
            periodic.append(row)
        if phase in EXTRA:
            if not core or core[-1]!='alpine_begin':
                raise ValueError('Alpine marker outside owning stage')
            if phase=='alpine_bucket_uploaded':
                if not any(r['phase']=='alpine_buckets_ready' for r in records):
                    raise ValueError('Alpine upload without bucket boundary')
                uploads+=1
                if uploads>6:
                    raise ValueError('Unexpected alpine bucket count')
            elif any(r['phase']==phase for r in records):
                raise ValueError('Duplicate alpine boundary')
        if phase=='fill_far_dry_released' and row['packed_payload_bytes']!=0:
            raise ValueError('Final caller-release payload is not zero')
        records.append(row); previous=row
    observations=[]
    for row in records:
        observations.append(dict(row,static_delta_from_look_begin=row['static_bytes']-records[0]['static_bytes']))
    complete=core==CORE
    return {'status':'TRACE_COMPLETE_UNREVIEWED' if complete else 'TRACE_PARTIAL_NOT_CAPTURE_PASS',
            'stdout_sha256':hashlib.sha256(data).hexdigest(),'record_count':len(records),
            'last_phase':records[-1]['phase'] if records else None,'completed_boundaries':core,
            'missing_boundaries':CORE[len(core):],'records':observations,
            'interpretation':'Engine allocator snapshots only. Cumulative peak can predate this phase. Unfinished final phase is a location clue, not sole-cause proof. No exact peak, settled GPU, physical-headroom, savings or visual acceptance claim.',
            'clock_scope':'ticks_ms is engine uptime, not UTC. elapsed_ms is relative to look_begin; do not directly subtract supervisor-clock samples.',
            'capture_pass':False,'native_launches_by_analyzer':0}

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--stdout',required=True,type=Path)
    parser.add_argument('--output',required=True,type=Path)
    args=parser.parse_args()
    result=analyze(args.stdout)
    # Preserve prior analysis and raw artifacts.
    with args.output.open('x',encoding='utf-8') as stream:
        json.dump(result,stream,indent=2); stream.write('\n')
    print(json.dumps({k:result[k] for k in ('status','record_count','last_phase','capture_pass')}))
