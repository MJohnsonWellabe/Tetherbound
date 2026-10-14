exec((__import__('pathlib').Path(__file__).parent/'build_r3.py').read_text())
s=(F/'root-transition/transition_paths.py').read_text()
s=s.replace('import hashlib,json,os,subprocess,sys,time','import hashlib,json,os,subprocess,sys,time\nBOOT=time.monotonic()')
pin=sha(P/'root-transition/operation_budget.py')
s=s.replace('from transition_checks import *',"from transition_checks import *\nassert hashlib.sha256((Path(__file__).resolve().parent/'operation_budget.py').read_bytes()).hexdigest()=='"+pin+"'\nfrom operation_budget import OperationBudget,read_bytes,write_bytes,digest_bytes\nBUDGET=OperationBudget(started=BOOT)")
s=re.sub(r"O=Path\([^\n]+", "O=PACKET/'offline.git'",s)
s=s.replace("OLD='5650c507e69ed0a7b6feaf72d1f345e406c98109'",f"OLD='{OLD}'").replace('preserved-sysc836-from565-r2','preserved-sysc836-fromb9-r3')
s=s.replace('len(changed)==50',f'len(changed)=={len(changed)}').replace('len(payload)==2022007',f"len(payload)=={pack['bytes']}").replace('09aff8a87f219a628cb04dded7d8df36c8ee5b170114249a5b36403335356ad2',pack['sha256'])
s=s.replace("sha=lambda b:hashlib.sha256(b).hexdigest()",'''def check_budget():BUDGET.check(cleanup=BUDGET.cleanup_end is not None)
def read_file(path):return read_bytes(path,BUDGET,cleanup=BUDGET.cleanup_end is not None)
def write_file(path,data):return write_bytes(path,data,BUDGET,cleanup=BUDGET.cleanup_end is not None)
def sha(data):return digest_bytes(data,hashlib.sha256(),BUDGET,cleanup=BUDGET.cleanup_end is not None)
def blob_id(data):
 h=hashlib.sha1(b'blob '+str(len(data)).encode()+b'\\0')
 return digest_bytes(data,h,BUDGET,cleanup=BUDGET.cleanup_end is not None)
''')
s=s.replace('def guard():\n if WATCH:', 'def guard():\n check_budget()\n if WATCH:')
s=s.replace("if b['kind']=='gitblob':return hashlib.sha1(b'blob '+str(len(data)).encode()+b'\\0'+data).hexdigest()==b['blob']", "if b['kind']=='gitblob':return blob_id(data)==b['blob']")
s=s.replace(' started=time.monotonic();process=subprocess.Popen', ' guard();process=subprocess.Popen')
s=s.replace("   assert time.monotonic()-started<120,('Bounded Git command timeout',args)\n   try:out,err=process.communicate(input=supplied,timeout=1);break", "   try:out,err=process.communicate(input=supplied,timeout=BUDGET.child_timeout());guard();break")
s=s.replace("  if process.poll() is None:process.kill()\n  process.wait(timeout=5)\n  raise", "  if process.poll() is None:process.kill()\n  BUDGET.begin_cleanup()\n  process.wait(timeout=BUDGET.child_timeout(5,cleanup=True))\n  BUDGET.check(cleanup=True)\n  raise")
s=s.replace(" (B/name).write_text(json.dumps(value,indent=2)+'\\n',encoding='utf-8',newline='\\n')", " write_file(B/name,(json.dumps(value,indent=2)+'\\n').encode('utf-8'))")
s=s.replace(' global WATCH,REMAINING', ' global WATCH,REMAINING,BUDGET')
s=s.replace(" assert sys.argv[1:] in (['--artifact-check'],['--root-authorized-under-lock'])", " if sys.argv[1:]!=['--artifact-check']:\n  assert len(sys.argv)==6 and sys.argv[1]=='--root-authorized-under-lock' and sys.argv[2]=='--work-seconds' and sys.argv[4]=='--total-seconds'\n  BUDGET=OperationBudget(float(sys.argv[3]),float(sys.argv[5]),started=BOOT)\n guard()")
s=s.replace("  state.update(status='FAILED_PRESERVE_INTERMEDIATE_STATE',error=str(e));save", "  BUDGET.begin_cleanup()\n  state.update(status='FAILED_PRESERVE_INTERMEDIATE_STATE',error=str(e),time_budget=BUDGET.snapshot());save")
s=s.replace("  if sys.argv[1:]==['--root-authorized-under-lock'] and B.exists():save('failure.json',dict(status='FAILED_PRESERVE_INTERMEDIATE_STATE',error=str(error),remaining=REMAINING))", "  BUDGET.begin_cleanup()\n  if sys.argv[1:2]==['--root-authorized-under-lock'] and B.exists():save('failure.json',dict(status='FAILED_PRESERVE_INTERMEDIATE_STATE',error=str(error),remaining=REMAINING,time_budget=BUDGET.snapshot()))")
s=s.replace("with lock.open('xb') as h:h.write(newindex.read_bytes());h.flush();os.fsync(h.fileno())", "write_bytes(lock,read_file(newindex),BUDGET,exclusive=True)\n  guard()")
s=s.replace("print(json.dumps(dict(status=state['status'],preservation=str(B))))", "guard();print(json.dumps(dict(status=state['status'],preservation=str(B),time_budget=BUDGET.snapshot())))")
# Rewrite native file reads/writes to chunked budget-aware IO; check every own loop.
class BoundedIO(ast.NodeTransformer):
 def visit_Call(self,node):
  node=self.generic_visit(node)
  if isinstance(node.func,ast.Attribute):
   if node.func.attr=='read_bytes' and not node.args:return ast.copy_location(ast.Call(ast.Name('read_file',ast.Load()),[node.func.value],[]),node)
   if node.func.attr=='write_bytes' and len(node.args)==1:return ast.copy_location(ast.Call(ast.Name('write_file',ast.Load()),[node.func.value,node.args[0]],[]),node)
  return node
 def visit_For(self,node):
  node=self.generic_visit(node);node.body.insert(0,ast.Expr(ast.Call(ast.Name('check_budget',ast.Load()),[],[])));return node
tree_ast=ast.parse(s)
for i,node in enumerate(tree_ast.body):
 if isinstance(node,(ast.FunctionDef,ast.AsyncFunctionDef)):tree_ast.body[i]=BoundedIO().visit(node)
ast.fix_missing_locations(tree_ast)
(P/'root-transition/transition_paths.py').write_text(ast.unparse(tree_ast)+'\n',encoding='utf-8',newline='\n')
print('Prepared shared-budget helper template; job hash awaits final pinning.')
