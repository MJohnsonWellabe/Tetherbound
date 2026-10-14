from pathlib import Path
import sys,importlib.util,json,unittest,subprocess
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P/'root-transition'))
spec=importlib.util.spec_from_file_location('reviewed_transition',P/'root-transition/transition_paths.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class Clock:
 def __init__(self):self.value=0.0
 def __call__(self):return self.value
class Process:
 def __init__(self,clock,duration,cleanup_overrun=False):self.clock=clock;self.left=duration;self.returncode=None;self.killed=False;self.cleanup_overrun=cleanup_overrun;self.waits=[]
 def communicate(self,input=None,timeout=None):
  self.waits.append(timeout)
  elapsed=min(timeout,self.left);self.clock.value+=elapsed;self.left-=elapsed
  if self.left>0:raise subprocess.TimeoutExpired('CPU fake child',timeout)
  self.returncode=0;return b'CPU',b''
 def poll(self):return self.returncode
 def kill(self):self.killed=True;self.returncode=-9
 def wait(self,timeout):
  self.waits.append(timeout)
  if self.cleanup_overrun:self.clock.value+=timeout+0.1
  return self.returncode
class Checks(unittest.TestCase):
 def setUp(self):
  self.clock=Clock();m.BUDGET=m.OperationBudget(clock=self.clock);m.WATCH=False;self.original=m.subprocess.Popen;self.created=[]
 def tearDown(self):m.subprocess.Popen=self.original
 def factory(self,duration,overrun=False):
  def create(*args,**kwargs):
   p=Process(self.clock,duration,overrun);self.created.append(p);return p
  return create
 def test_actual_git_function_uses_cumulative_deadline(self):
  m.subprocess.Popen=self.factory(60)
  self.assertEqual(m.git(P,'CPU_FIRST'),b'CPU')
  with self.assertRaises(TimeoutError):m.git(P,'CPU_SECOND')
  self.assertEqual(self.clock.value,115)
  self.assertTrue(self.created[-1].killed)
  self.assertTrue(all(0<x<=1 for x in self.created[-1].waits[:-1]))
  self.assertLessEqual(self.created[-1].waits[-1],5)
 def test_actual_git_cleanup_overrun_rejected(self):
  self.clock.value=114;m.subprocess.Popen=self.factory(30,True)
  with self.assertRaises(TimeoutError):m.git(P,'CPU_OVERRUN')
  self.assertTrue(self.created[-1].killed);self.assertGreater(self.clock.value,120)
 def test_no_child_starts_after_work_budget(self):
  self.clock.value=115;m.subprocess.Popen=self.factory(1)
  with self.assertRaises(TimeoutError):m.git(P,'CPU_MUST_NOT_START')
  self.assertEqual(len(self.created),0)
 def test_file_hash_loop_uses_same_budget(self):
  original_check=m.BUDGET.check
  def tick(*args,**kwargs):self.clock.value+=40;return original_check(*args,**kwargs)
  m.BUDGET.check=tick
  with self.assertRaises(TimeoutError):m.sha(b'x'*(4*1024**2))
result=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(Checks))
(P/'cpu-aggregate-integration.json').write_text(json.dumps(dict(status='PASS' if result.wasSuccessful() else 'FAIL',tests=result.testsRun,real_transition_functions=True,simulated_children=True,stage_access=False,engine_launched=False),indent=2)+'\n')
raise SystemExit(not result.wasSuccessful())
