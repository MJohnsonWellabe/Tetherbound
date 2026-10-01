"""Read-only frozen evidence analysis. Output confined to this independent dir."""
from pathlib import Path
import json, hashlib, subprocess, math
OUT=Path(__file__).resolve().parent; PACK=OUT.parent; ROOT=Path('D:/tetherbound/redesign-hub')
H=lambda b:hashlib.sha256(b).hexdigest()
freeze=json.loads((PACK/'freeze.json').read_bytes()); receipt=json.loads((PACK/'receipt.json').read_bytes())
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT).decode().strip()==freeze['head']=='8189ef734addce12d446c6c9a0f9d4016a0d657d'
assert not subprocess.check_output(['git','diff','--name-only'],cwd=ROOT).strip()
hashes={name:H((PACK/name).read_bytes()) for name in freeze['files_sha256']}
assert hashes==freeze['files_sha256']
assert receipt['same_source'] and receipt['source']==receipt['head_after']==freeze['head']
for name,pin in receipt['source_after'].items(): assert H((ROOT/name).read_bytes())==pin
for run in receipt['runs']: assert hashes[run['label']+'.txt']==run['raw_sha256']
lines=(PACK/'native.txt').read_text().splitlines()
observations=[json.loads(l.removeprefix('OPENING_PRODUCTION_OBSERVATION ')) for l in lines if l.startswith('OPENING_PRODUCTION_OBSERVATION ')]
terminal=observations[-1]; diagnostic=json.loads((PACK/'diagnostic.json').read_bytes())
assert terminal==diagnostic['terminal']
assert terminal['slide_count']==6 and terminal['slide_point_counts']==[2]*6
assert terminal['refusal']=='actual production contact observation cap' and not terminal['checked_start']
assert terminal['authored_road_hint']=='' and terminal['request'][0]==-8.0 and terminal['request'][2]==8.0
points=terminal['slide_contacts']; assert len(points)==8 and terminal['slide_contacts_are_capped_prefix']
live=terminal['live_contacts']; assert len(live)==2
identities={(p['collider_rid'],p['collider_shape']) for p in points}
assert identities=={(p['collider_rid'],p['collider_shape']) for p in live}
assert len(identities)==2 and live[0]['normal']==[0.0,1.0,0.0] and abs(live[1]['normal'][1])<1e-6
campaign=json.loads(next(l.removeprefix('FRESH CAMPAIGN RESULT ') for l in reversed(lines) if l.startswith('FRESH CAMPAIGN RESULT ')))
assert not campaign['requested_prefix_passed'] and not campaign['campaign_complete'] and campaign['checkpoints']==[]
nav=(ROOT/'tests/helpers/opening_geometry_navigator.gd').read_text(); gather=(ROOT/'tests/helpers/gate_a_npc_gather_segment.gd').read_text()
assert 'contacts += collision.get_collision_count()\n\t\t\t\tif contacts > CONTACTS:' in nav
assert 'const CONTACTS := 8' in nav
assert '_player.get_slide_collision(index).get_collider()' in gather
result={'scope':'EVIDENCE_CONSTRAINTS_ONLY; no source gate or runtime completion disposition','head':freeze['head'],
        'freeze_sha256':H((PACK/'freeze.json').read_bytes()),'verified_frozen_hashes':hashes,
        'receipt_exit_codes':{r['label']:r['native_exit'] for r in receipt['runs']},
        'receipt_elapsed_seconds':{r['label']:r['elapsed_seconds'] for r in receipt['runs']},
        'campaign_elapsed_seconds':campaign['elapsed_seconds'],'requested_prefix_passed':campaign['requested_prefix_passed'],
        'exact_cached_contact_total':sum(terminal['slide_point_counts']),'cached_manifold_counts':terminal['slide_point_counts'],
        'logged_contact_prefix_count':len(points),'logged_contact_identities':sorted(identities),
        'distinct_logged_points_excluding_slide':len({json.dumps({k:v for k,v in p.items() if k!='slide'},sort_keys=True) for p in points}),
        'live_recovery_travel_m':math.sqrt(sum(x*x for x in terminal['live_recovery_travel'])),
        'safe_margin':terminal['safe_margin'],'live_normals':[p['normal'] for p in live],
        'callback_own_us':terminal['callback_own_us'],'on_floor':terminal['on_floor'],'on_wall':terminal['on_wall'],
        'recoveries':terminal['recoveries'],'road_hint':terminal['authored_road_hint'],'engine_executed_by_reviewer':False,
        'tracked_or_git_writes_by_reviewer':False,'analysis_script_sha256':H(Path(__file__).read_bytes())}
assert {name:H((PACK/name).read_bytes()) for name in hashes}==hashes
(OUT/'evidence-analysis.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'scope':result['scope'],'frozen_hashes_verified':len(hashes),'exact_cached_total':result['exact_cached_contact_total'],'pure_floor':False}))
