"""Prepared diagnostic; engine execution requires a fresh explicit ROOT grant."""
import argparse
import hashlib
import json
import re
import shutil
import subprocess
import time
from pathlib import Path

REPO=Path('D:/tetherbound/redesign-vfx')
ENGINE='C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe'
PINS=[('baseline','9a6dbc823c4a4b05695ac00be51150312fee470f'),
      ('candidate','05ccfe3b3449727ddf8a18b070565c0ea22e5314')]
FIXTURE_SHA='b887637bcf76b6549d60368b4eafbed0177b86c370c87500d045ea6d06edf759'
ROOT_OUT=Path('D:/tetherbound/vfx-r24-combined-runtime')
HIDDEN=subprocess.CREATE_NO_WINDOW

def git(*args):
    return subprocess.check_output(['git',*args],cwd=REPO,text=True).strip()

def census():
    command="Get-CimInstance Win32_Process -Filter \"Name LIKE '%Godot%'\" | Select-Object ProcessId,ParentProcessId,Name,CommandLine | ConvertTo-Json -Compress"
    result=subprocess.run(['powershell','-NoProfile','-Command',command],capture_output=True,text=True,timeout=12,creationflags=HIDDEN)
    if result.returncode: raise RuntimeError(result.stderr)
    if not result.stdout.strip(): return []
    rows=json.loads(result.stdout)
    return rows if isinstance(rows,list) else [rows]

def descendants(rows,owned):
    changed=True
    while changed:
        changed=False
        for row in rows:
            pid,parent=int(row['ProcessId']),int(row['ParentProcessId'])
            if parent in owned and pid not in owned:
                owned.add(pid)
                changed=True

def write(path,data):
    path.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8',newline='\n')

def launch(label,pin,fixture,owned):
    run=ROOT_OUT/label
    run.mkdir()
    frames=run/'originals'
    command=[ENGINE,'--path',str(REPO),'--rendering-method','gl_compatibility',
        '--resolution','1920x1080','--write-movie',str(run/'motion.avi'),'--fixed-fps','30',
        '--script','res://.tmp/f25-r24/capture.gd','--','--batch=mastery',
        '--families=fireball,ice_shard_volley,root_stone_spikes','--ranks=1,3,5',
        '--out='+str(frames).replace('\\','/')]
    assert git('rev-parse','HEAD')==pin and not git('status','--porcelain','--untracked-files=no')
    observed_fixture_sha=hashlib.sha256(fixture.read_bytes()).hexdigest()
    assert observed_fixture_sha==FIXTURE_SHA
    before_processes=census()
    assert not before_processes, 'Exclusive engine slot occupied; stop without killing foreign processes'
    paths=subprocess.check_output(['git','ls-files','-z','scripts/vfx','assets/vfx','data/config/vfx.json',
        'data/moves/moves.json','data/config/audio.json','tests/smoke_move_effects_library.gd'],cwd=REPO).decode().split('\0')
    hashes={path:hashlib.sha256((REPO/path).read_bytes()).hexdigest() for path in paths if path and (REPO/path).is_file()}
    write(run/'before-native-source-hashes.json',{'source_commit':pin,'sha256_checkout_bytes':hashes,
        'fixture_sha256_lf':observed_fixture_sha,'prelaunch_godot_processes':before_processes,
        'cache_policy':'Existing owned .godot reused; no concurrent import/render/export writer',
        'command':command,'scope':'Nine selected synthetic visual cases, no earned route, performance or full-craft acceptance'})
    start=time.monotonic()
    code=None
    timed_out=False
    foreign=[]
    cleanup=[]
    process=None
    try:
        with (run/'native.txt').open('w',encoding='utf-8') as log:
            process=subprocess.Popen(command,cwd=REPO,stdout=log,stderr=subprocess.STDOUT,creationflags=HIDDEN)
            owned.add(process.pid)
            while True:
                rows=census()
                descendants(rows,owned)
                foreign=[row for row in rows if int(row['ProcessId']) not in owned]
                if foreign: raise RuntimeError('Foreign engine writer appeared during exclusive slot')
                remaining=150-(time.monotonic()-start)
                if remaining<=0:
                    timed_out=True
                    raise TimeoutError('Owned native process reached 150s external deadline')
                try:
                    code=process.wait(timeout=min(2,remaining))
                    break
                except subprocess.TimeoutExpired:
                    pass
    finally:
        rows=census()
        descendants(rows,owned)
        for row in rows:
            if int(row['ProcessId']) in owned:
                subprocess.run(['taskkill','/PID',str(row['ProcessId']),'/T','/F'],capture_output=True,creationflags=HIDDEN)
                cleanup.append(int(row['ProcessId']))
        if process is not None and code is None:
            try: code=process.wait(timeout=12)
            except subprocess.TimeoutExpired: code=-1
        after_processes=census()
        raw=(run/'native.txt').read_text(encoding='utf-8',errors='replace') if (run/'native.txt').exists() else ''
        errors=[line for line in raw.splitlines() if re.search(r'SCRIPT ERROR|ERROR:|Parse Error|Shader compilation failed',line)]
        unchanged=git('rev-parse','HEAD')==pin and not git('status','--porcelain','--untracked-files=no')
        unchanged=unchanged and all(hashlib.sha256((REPO/path).read_bytes()).hexdigest()==digest for path,digest in hashes.items())
        unchanged=unchanged and hashlib.sha256(fixture.read_bytes()).hexdigest()==observed_fixture_sha
        report=json.loads((frames/'results.json').read_text()) if (frames/'results.json').exists() else None
        pngs=sorted(frames.glob('*.png')) if frames.exists() else []
        expected=report is not None and len(report.get('cases',[]))==9 and len(pngs)==27
        expected=expected and not report.get('failures') and all(row['end_slots']==0 for row in report['cases'])
        write(run/'native-receipt.json',{'source_commit':pin,'command':command,'exit_code':code,
            'timed_out':timed_out,'elapsed_seconds':round(time.monotonic()-start,3),
            'tracked_process_ids':sorted(owned),'owned_cleanup':cleanup,'foreign_processes':foreign,
            'godot_processes_remaining':after_processes,'source_unchanged':unchanged,'errors':errors,
            'nine_cases_27_originals_zero_end_leases':bool(expected),'fixture_sha256_lf':FIXTURE_SHA,
            'unit_and_light_preflight':'No repeat; R17 unchanged light/budget proof reused',
            'scope':'Synthetic native materials/phase/coverage only; no full craft, real HP/player/co-op/Medium/device acceptance'})
        if after_processes or code!=0 or timed_out or errors or not unchanged or not expected:
            raise RuntimeError(label+' RED; raw artifacts retained; no automatic retry')

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--execute-after-explicit-root-grant',action='store_true')
    args=parser.parse_args()
    if not args.execute_after_explicit_root_grant:
        print(json.dumps({'prepared_only':True,'source_pins':PINS,'expected_cases':18,'expected_pngs':54,
            'requires':'Independent source gate then fresh ROOT exclusive engine grant; never execute based on empty census alone'}))
        return
    assert git('branch','--show-current')=='tb/vfx'
    assert not git('status','--porcelain','--untracked-files=no')
    assert not ROOT_OUT.exists(), 'Fresh evidence root required; never overwrite originals'
    assert not census(), 'Exclusive slot occupied'
    # Read all candidate helpers before the baseline checkout removes this bundle.
    bundle=Path(__file__).resolve().parent
    fixture_bytes=(bundle/'capture-fixture.gd.txt').read_bytes()
    assert hashlib.sha256(fixture_bytes).hexdigest()==FIXTURE_SHA
    wrapper_bytes=Path(__file__).read_bytes()
    staging=REPO/'.tmp/f25-r24'
    staging.mkdir(exist_ok=True)
    fixture=staging/'capture.gd'
    fixture.write_bytes(fixture_bytes)
    ROOT_OUT.mkdir()
    (ROOT_OUT/'run_combined.py').write_bytes(wrapper_bytes)
    (ROOT_OUT/'capture-fixture.gd.txt').write_bytes(fixture_bytes)
    original_head=git('rev-parse','HEAD')
    owned=set()
    try:
        for label,pin in PINS:
            subprocess.run(['git','switch','--detach',pin],cwd=REPO,check=True)
            launch(label,pin,fixture,owned)
    finally:
        remaining=census()
        if any(int(row['ProcessId']) in owned for row in remaining):
            write(ROOT_OUT/'cleanup-blocked.json',{'remaining':remaining,'restore_not_attempted':True})
            raise RuntimeError('Owned process still live; do not restore tracked source')
        subprocess.run(['git','switch','tb/vfx'],cwd=REPO,check=True)
        write(ROOT_OUT/'restoration.json',{'starting_head':original_head,'restored_head':git('rev-parse','HEAD'),
            'tracked_clean':not git('status','--porcelain','--untracked-files=no'),'godot_processes_remaining':census(),
            'gpu_token':'Release explicitly to ROOT only after confirming zero owned processes'})
    print(json.dumps({'combined_native':'PASS','baseline_and_candidate':PINS,'original_pngs':54,
        'no_acceptance_closure':True,'root_out':str(ROOT_OUT)}))

if __name__=='__main__': main()
