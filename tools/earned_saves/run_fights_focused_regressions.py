"""Root-only focused native runner. Dry by default; never stages or imports files."""
import argparse
import ctypes
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import time


def digest_file(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for block in iter(lambda: f.read(1024 * 1024), b''): h.update(block)
    return h.hexdigest()


def verdict(code, natural, stdout, stderr, methods):
    if not natural or code != 0: return False
    if re.search(r'^\s*(?:SCRIPT ERROR|ERROR|Parse Error|Shader compilation failed|FAIL)\b', stdout+'\n'+stderr, re.M): return False
    found = re.findall(r'^\s*ok\s+(test_\w+)\s*$', stdout, re.M)
    summaries = re.findall(r'^(\d+) test\(s\), (\d+) failed\s*$', stdout, re.M)
    return sorted(found) == sorted(methods) and len(found) == len(set(found)) and summaries == [(str(len(methods)), '0')]


def capacity():
    class Memory(ctypes.Structure):
        _fields_ = [('length', ctypes.c_ulong), ('load', ctypes.c_ulong)] + [(n, ctypes.c_ulonglong) for n in ['total_phys','avail_phys','total_page','avail_page','total_virtual','avail_virtual','extended']]
    memory = Memory(); memory.length = ctypes.sizeof(memory)
    if not ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(memory)): raise RuntimeError('Cannot read RAM')
    return {'ram': memory.avail_phys, 'C': shutil.disk_usage('C:/').free, 'D': shutil.disk_usage('D:/').free}


def enough(values):
    return values['ram'] >= 2*1024**3 and values['C'] >= 10*1024**3 and values['D'] >= 20*1024**3


def verify_stage(packet):
    stage = Path(packet['stage'])
    head = subprocess.check_output(['git','-c','gc.auto=0','-c','maintenance.auto=false','-C',str(stage),'rev-parse','HEAD'], text=True).strip()
    if head != packet['basis']: raise RuntimeError('Stage HEAD differs from pinned basis')
    mismatches = []
    for name, expected in packet['closure_sha256_lf'].items():
        path = stage / name
        if not path.is_file() or hashlib.sha256(path.read_bytes().replace(b'\r\n',b'\n')).hexdigest() != expected: mismatches.append(name)
    if mismatches: raise RuntimeError('Stage closure differs: '+json.dumps(mismatches))


def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--packet',type=Path,required=True); ap.add_argument('--job',choices=['selection','altar'],required=True); ap.add_argument('--out',type=Path,required=True); ap.add_argument('--execute',action='store_true')
    args = ap.parse_args(); packet = json.loads(args.packet.read_text(encoding='utf-8'))
    job = packet['jobs'][args.job]
    if not args.out.is_absolute() or args.out.drive.lower() != 'd:' or args.out.exists(): raise ValueError('Output must be absent absolute D: directory')
    command = [packet['engine'],'--headless','--path',packet['stage'],'--script','tools/run_one_test.gd','--',job['test']]
    if not args.execute:
        print(json.dumps({'command':command,'out':str(args.out),'seconds':job['seconds'],'execute':False},indent=2));return
    if digest_file(Path(__file__)) != packet['supervisor_sha256']: raise RuntimeError('Supervisor hash mismatch')
    if digest_file(packet['engine']) != packet['engine_sha256']: raise RuntimeError('Engine hash mismatch')
    verify_stage(packet)
    query = "@(Get-CimInstance Win32_Process | Where-Object { $_.Name -match '^(Godot.*|Blender.*)\\.exe$' }).Count"
    count = subprocess.check_output(['pwsh','-NoProfile','-Command',query],text=True).strip()
    if count != '0': raise RuntimeError('Another engine exists or process check is ambiguous')
    if not enough(capacity()): raise RuntimeError('Admission floors not met')
    args.out.mkdir(); home = args.out/'home'; home.mkdir()
    env = os.environ.copy();env.update(APPDATA=str(home),LOCALAPPDATA=str(home),USERPROFILE=str(home),HOME=str(home))
    env.update(GIT_CONFIG_COUNT='2',GIT_CONFIG_KEY_0='gc.auto',GIT_CONFIG_VALUE_0='0',GIT_CONFIG_KEY_1='maintenance.auto',GIT_CONFIG_VALUE_1='false')
    result = {'passed':False,'job':args.job,'basis':packet['basis'],'overlay_source':packet['overlay_source'],'command':command,'packet_sha256':digest_file(args.packet)}
    process = None;started=time.monotonic();stop='not_started'
    try:
        with (args.out/'stdout.log').open('xb') as stdout, (args.out/'stderr.log').open('xb') as stderr:
            process = subprocess.Popen(command,cwd=packet['stage'],env=env,stdout=stdout,stderr=stderr,creationflags=subprocess.CREATE_NO_WINDOW)
            result['pid']=process.pid
            while process.poll() is None:
                if time.monotonic()-started >= job['seconds']:stop='timeout';break
                if sum(p.stat().st_size for p in args.out.rglob('*') if p.is_file()) >= 160*1024**2:stop='output_cap';break
                if not enough(capacity()):stop='capacity_floor';break
                time.sleep(0.5)
            else:stop='natural_exit'
            if process.poll() is None:
                subprocess.run(['taskkill','/PID',str(process.pid),'/T','/F'],capture_output=True,check=True);process.wait(timeout=10)
        result.update(exit_code=process.returncode,stop=stop)
        verify_stage(packet)
        output_bytes=sum(p.stat().st_size for p in args.out.rglob('*') if p.is_file())
        result['output_bytes']=output_bytes
        stdout=(args.out/'stdout.log').read_text(encoding='utf-8',errors='replace');stderr=(args.out/'stderr.log').read_text(encoding='utf-8',errors='replace')
        result['passed']=output_bytes < 160*1024**2 and verdict(process.returncode,stop=='natural_exit',stdout,stderr,job['methods'])
    except Exception as error: result['error']=str(error)
    finally:
        if process is not None and process.poll() is None:
            subprocess.run(['taskkill','/PID',str(process.pid),'/T','/F'],capture_output=True);process.wait(timeout=10)
        result['seconds']=time.monotonic()-started
        (args.out/'supervisor.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(result,indent=2))
    if not result['passed']:raise SystemExit(1)


if __name__=='__main__':main()
