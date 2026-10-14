from pathlib import Path
import ast,hashlib,subprocess,time,os,json,sys
R=Path(__file__).resolve().parent
source=(R/'swap_stage.py').read_text();tree=ast.parse(source)
scope={'subprocess':subprocess,'ENV':dict(os.environ)}
for name in ('require','bounded_child'):
 node=next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name==name)
 exec(compile(ast.Module(body=[node],type_ignores=[]),'actual_swap_functions','exec'),scope)
run=scope['bounded_child'];results=[]
payload=b'x'*1024**2
assert run([sys.executable,'-c','import sys;sys.stdout.buffer.write(sys.stdin.buffer.read())'],payload,3)==payload
results.append({'case':'large stdin echo','status':'PASS'})
for name,code,data in [('blocked stdin','import time;time.sleep(10)',payload),('stalled child','import time;time.sleep(10)',b''),('late zero exit','import time;time.sleep(.5)',b'')]:
 start=time.monotonic()
 try:run([sys.executable,'-c',code],data,.1);raise AssertionError('deadline accepted')
 except subprocess.TimeoutExpired:pass
 elapsed=time.monotonic()-start;assert elapsed<2
 results.append({'case':name,'status':'PASS_REJECTED','elapsed_seconds':elapsed})
try:run([sys.executable,'-c','import sys;sys.exit(7)'],b'',3);raise AssertionError('nonzero accepted')
except subprocess.CalledProcessError as exc:assert exc.returncode==7
results.append({'case':'nonzero exit','status':'PASS_REJECTED'})
original_clock=time.monotonic
clock_values=iter([0.0,0.01,10.0])
try:
 time.monotonic=lambda:next(clock_values)
 try:run([sys.executable,'-c','pass'],b'',3);raise AssertionError('late completed event accepted')
 except subprocess.TimeoutExpired:pass
finally:time.monotonic=original_clock
results.append({'case':'completed event observed beyond terminal deadline','status':'PASS_REJECTED'})
report={'status':'PASS','cases':results,'swap_sha256':hashlib.sha256(source.encode()).hexdigest(),'native_access':False,'engine_launches':0}
(R/'cpu-git-deadline.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report))
