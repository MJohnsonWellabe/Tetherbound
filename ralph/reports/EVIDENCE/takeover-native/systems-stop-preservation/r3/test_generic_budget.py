from pathlib import Path
import sys,unittest,json,tempfile,hashlib
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P/'root-transition'))
from operation_budget import *
class Clock:
 def __init__(self):self.now=0.0
 def __call__(self):return self.now
 def advance(self,n):self.now+=n
class Checks(unittest.TestCase):
 def test_cumulative_children_no_reset(self):
  clock=Clock();budget=OperationBudget(clock=clock)
  clock.advance(60);self.assertEqual(budget.child_timeout(120),55)
  clock.advance(54);self.assertEqual(budget.child_timeout(120),1)
  clock.advance(1)
  with self.assertRaises(BudgetExpired):budget.child_timeout(120)
 def test_cleanup_aggregate_and_no_reset(self):
  clock=Clock();budget=OperationBudget(clock=clock);clock.advance(114)
  self.assertEqual(budget.begin_cleanup(),5);clock.advance(4)
  self.assertEqual(budget.begin_cleanup(),1);clock.advance(1)
  with self.assertRaises(BudgetExpired):budget.check(cleanup=True)
 def test_cleanup_after_work_expiry(self):
  clock=Clock();budget=OperationBudget(clock=clock);clock.advance(115)
  with self.assertRaises(BudgetExpired):budget.check()
  self.assertEqual(budget.begin_cleanup(),5);clock.advance(5)
  with self.assertRaises(BudgetExpired):budget.child_timeout(10,cleanup=True)
 def test_parent_remaining_passed_to_child(self):
  clock=Clock();parent=OperationBudget(clock=clock);clock.advance(11)
  child=OperationBudget(parent.remaining(),parent.remaining(cleanup=True),clock=clock)
  clock.advance(104)
  with self.assertRaises(BudgetExpired):child.check()
  self.assertEqual(child.begin_cleanup(),5);clock.advance(5)
  with self.assertRaises(BudgetExpired):child.check(cleanup=True)
 def test_overrun_rejected_after_child_returns(self):
  clock=Clock();budget=OperationBudget(clock=clock);clock.advance(114)
  self.assertEqual(budget.child_timeout(30),1);clock.advance(6)
  with self.assertRaises(BudgetExpired):budget.check()
  with self.assertRaises(BudgetExpired):budget.begin_cleanup()
 def test_chunk_loops_enforce_shared_budget(self):
  with tempfile.TemporaryDirectory(dir=P) as directory:
   path=Path(directory)/'fixture.bin';path.write_bytes(b'x'*(3*1024**2))
   class TickingClock(Clock):
    def __call__(self):self.now+=1;return self.now
   with self.assertRaises(BudgetExpired):read_bytes(path,OperationBudget(5,10,clock=TickingClock()))
   with self.assertRaises(BudgetExpired):write_bytes(Path(directory)/'out.bin',b'x'*(5*1024**2),OperationBudget(5,10,clock=TickingClock()))
   with self.assertRaises(BudgetExpired):digest_bytes(b'x'*(6*1024**2),hashlib.sha256(),OperationBudget(5,10,clock=TickingClock()))
 def test_caps_cannot_expand(self):
  for work,total in [(116,120),(115,121),(120,120),(0,120)]:
   with self.assertRaises(ValueError):OperationBudget(work,total)
result=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(Checks))
(P/'generic-budget-results.json').write_text(json.dumps(dict(status='PASS' if result.wasSuccessful() else 'FAIL',tests=result.testsRun,stage_access=False,engine_launched=False),indent=2)+'\n')
raise SystemExit(not result.wasSuccessful())
