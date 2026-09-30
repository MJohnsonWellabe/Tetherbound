import json
import hashlib
import re
import subprocess
import time
from pathlib import Path

repo = Path('D:/tetherbound/redesign-vfx')
engine = 'C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe'
pin = '33fea6237a14d0a5daf0d2866b1323a49e82d58c'
evidence = Path('D:/tetherbound/vfx-r17-selected-runtime')
native = Path('D:/tetherbound/vfx-small-stones-selected-r17')
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip() == pin
assert not subprocess.check_output(['git','status','--porcelain','--untracked-files=no'],cwd=repo,text=True).strip()
assert not evidence.exists() and not native.exists()

def processes():
    command = "Get-CimInstance Win32_Process -Filter \"Name LIKE '%Godot%'\" | Select-Object ProcessId,ParentProcessId,Name,CommandLine | ConvertTo-Json -Compress"
    result = subprocess.run(['powershell','-NoProfile','-Command',command],capture_output=True,text=True,timeout=12,creationflags=subprocess.CREATE_NO_WINDOW)
    if result.returncode:
        raise RuntimeError(result.stderr)
    if not result.stdout.strip():
        return []
    rows = json.loads(result.stdout)
    return rows if isinstance(rows,list) else [rows]

assert not processes(), 'Shared GPU/engine slot occupied; requires explicit ROOT token even if empty'
evidence.mkdir()
tracked_files = subprocess.check_output(['git','ls-files','-z','scripts/vfx','assets/vfx',
    'data/config/vfx.json','tests/smoke_move_effects_library.gd','tests/test_move_effects.gd'],cwd=repo).decode().split('\0')
source_hashes = {path:hashlib.sha256((repo/path).read_bytes()).hexdigest()
                 for path in tracked_files if path and (repo/path).is_file()}
(evidence/'before-native-source-hashes.json').write_text(json.dumps({
    'source_commit':pin,'sha256_checkout_bytes':source_hashes,
    'selected_identity':'small-stones:r1','native_preflight_checks':18,
    'authorization':'Root explicit exclusive GPU grant required before invoking this wrapper',
    'prelaunch_godot_processes':[], 'cache_policy':'Existing owned .godot retained; no concurrent import/render/export writer',
},indent=2)+'\n',encoding='utf-8')
command = [engine,'--path',str(repo),'--rendering-method','gl_compatibility','--resolution','1920x1080',
           '--write-movie',str(evidence/'identities-motion.avi'),'--fixed-fps','30',
           '--script','res://tests/smoke_move_effects_library.gd','--','--batch=identities',
           '--identity=small-stones:r1',
           '--out='+str(native).replace('\\','/')]
begin = time.monotonic()
tracked = set()
timed_out = False
with (evidence/'native.txt').open('w',encoding='utf-8') as raw:
    process = subprocess.Popen(command,cwd=repo,stdout=raw,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
    tracked.add(process.pid)
    time.sleep(.25)
    snapshot = processes()
    changed = True
    while changed:
        changed = False
        for row in snapshot:
            if int(row['ParentProcessId']) in tracked and int(row['ProcessId']) not in tracked:
                tracked.add(int(row['ProcessId']))
                changed = True
    try:
        code = process.wait(timeout=150)
    except subprocess.TimeoutExpired:
        timed_out = True
        subprocess.run(['taskkill','/PID',str(process.pid),'/T','/F'],capture_output=True,creationflags=subprocess.CREATE_NO_WINDOW)
        code = process.wait(timeout=12)
cleanup = []
for row in processes():
    owned = int(row['ProcessId']) in tracked or int(row['ParentProcessId']) in tracked
    if owned and 'redesign-vfx' in str(row.get('CommandLine','')).replace('\\','/'):
        subprocess.run(['taskkill','/PID',str(row['ProcessId']),'/T','/F'],capture_output=True,creationflags=subprocess.CREATE_NO_WINDOW)
        cleanup.append(row['ProcessId'])
after = processes()
raw = (evidence/'native.txt').read_text(encoding='utf-8',errors='replace')
errors = [line for line in raw.splitlines() if re.search(r'SCRIPT ERROR|ERROR:|Parse Error|Shader compilation failed',line)]
end_pin = subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip()
dirty = subprocess.check_output(['git','status','--porcelain','--untracked-files=no'],cwd=repo,text=True).strip()
source_hashes_after = {path:hashlib.sha256((repo/path).read_bytes()).hexdigest() for path in source_hashes}
receipt = {'source_commit':pin,'command':command,'exit_code':code,'timed_out':timed_out,
           'elapsed_seconds':round(time.monotonic()-begin,3),'tracked_process_ids':sorted(tracked),
           'owned_orphan_cleanup':cleanup,'godot_processes_remaining':after,'errors':errors,
           'source_unchanged':end_pin==pin and not dirty and source_hashes_after==source_hashes,
           'selected_identity':'small-stones:r1','native_preflight_checks':18,
           'unit_reused':'R14 light lease, 27 assertions PASS; unchanged budget/test source, no full suite',
           'scope':'Synthetic production-node lifetime and visual candidate, not HP/player/combat/Medium/device/final craft acceptance',
           'movie_limit':'Fixed30fps synthetic0.7s travel; not real-time/performance proof'}
(evidence/'native-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'exit_code':code,'errors':errors,'source_unchanged':receipt['source_unchanged'],
                  'elapsed_seconds':receipt['elapsed_seconds'],'all_godot_gone':not after}),flush=True)
if code != 0 or timed_out or errors or after or not receipt['source_unchanged']:
    raise SystemExit(1)
