import json,re,subprocess,time
from pathlib import Path

repo=Path('D:/tetherbound/redesign-vfx')
engine='C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe'
evidence=Path('D:/tetherbound/vfx-r14-runtime')
native=Path('D:/tetherbound/vfx-identities-native-r14')
pin=subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip()
assert pin=='89a075c6d7b'[:0]+pin and pin.startswith('89a075c6d7')
assert not subprocess.check_output(['git','status','--porcelain','--untracked-files=no'],cwd=repo,text=True).strip()
assert not evidence.exists() and not native.exists()
evidence.mkdir()

def processes():
    command="Get-CimInstance Win32_Process -Filter \"Name LIKE '%Godot%'\" | Select-Object ProcessId,ParentProcessId,Name,CommandLine | ConvertTo-Json -Compress"
    r=subprocess.run(['powershell','-NoProfile','-Command',command],capture_output=True,text=True,timeout=12,creationflags=subprocess.CREATE_NO_WINDOW)
    if r.returncode:raise RuntimeError(r.stderr)
    if not r.stdout.strip():return []
    value=json.loads(r.stdout)
    return value if isinstance(value,list) else [value]

assert not processes(), 'Shared engine slot is occupied'
receipts=[]

def run(label,args,timeout):
    assert not processes(), 'Another Godot process appeared before launch'
    command=[engine,*args]
    begin=time.monotonic()
    tracked=set()
    timed_out=False
    with (evidence/(label+'.txt')).open('w',encoding='utf-8') as log:
        p=subprocess.Popen(command,cwd=repo,stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
        tracked.add(p.pid)
        time.sleep(.25)
        snapshot=processes()
        changed=True
        while changed:
            changed=False
            for row in snapshot:
                if int(row['ParentProcessId']) in tracked and int(row['ProcessId']) not in tracked:
                    tracked.add(int(row['ProcessId']));changed=True
        try:code=p.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            timed_out=True
            subprocess.run(['taskkill','/PID',str(p.pid),'/T','/F'],capture_output=True,creationflags=subprocess.CREATE_NO_WINDOW)
            code=p.wait(timeout=12)
    remaining=processes()
    cleanup=[]
    for row in remaining:
        owned=int(row['ProcessId']) in tracked or int(row['ParentProcessId']) in tracked
        if owned and 'redesign-vfx' in str(row.get('CommandLine','')).replace('\\','/'):
            subprocess.run(['taskkill','/PID',str(row['ProcessId']),'/T','/F'],capture_output=True,creationflags=subprocess.CREATE_NO_WINDOW)
            cleanup.append(row['ProcessId'])
    after=processes()
    raw=(evidence/(label+'.txt')).read_text(encoding='utf-8',errors='replace')
    errors=[line for line in raw.splitlines() if re.search(r'SCRIPT ERROR|ERROR:|Parse Error|Shader compilation failed',line)]
    receipt={'source_commit':pin,'command':command,'exit_code':code,'timed_out':timed_out,
             'elapsed_seconds':round(time.monotonic()-begin,3),'tracked_process_ids':sorted(tracked),
             'owned_orphan_cleanup':cleanup,'godot_processes_remaining':after,'errors':errors,
             'scope':'Selected light lease check or synthetic production-node presentation; no gameplay/HP/performance/full craft proof'}
    if label=='native':receipt['movie_limit']='Godot movie-maker fixed30fps; synthetic0.7s identity travel; not real frame-time, HP or gameplay timing proof'
    (evidence/(label+'-receipt.json')).write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
    receipts.append(receipt)
    print(json.dumps({'phase':label,'exit_code':code,'errors':errors,'elapsed_seconds':receipt['elapsed_seconds'],'all_godot_gone':not after}),flush=True)
    assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip()==pin
    assert not subprocess.check_output(['git','status','--porcelain','--untracked-files=no'],cwd=repo,text=True).strip()
    return code==0 and not timed_out and not errors and not after

unit=run('light-unit',['--headless','--path',str(repo),'--script','res://tests/run_tests.gd','--',
                     '--only=test_move_effects.gd::test_light_cap_is_global_idempotent_and_reclaims_existing_lease'],60)
if unit:
    run('native',['--path',str(repo),'--rendering-method','gl_compatibility','--resolution','1920x1080',
                  '--write-movie',str(evidence/'identities-motion.avi'),'--fixed-fps','30',
                  '--script','res://tests/smoke_move_effects_library.gd','--','--batch=identities','--out='+str(native).replace('\\','/')],120)
else:print('Native waits for selected unit/parser repair; failed unit log retained',flush=True)
(evidence/'batch-receipt.json').write_text(json.dumps({'source_commit':pin,'runs':receipts,'all_godot_gone':not processes()},indent=2)+'\n',encoding='utf-8')
