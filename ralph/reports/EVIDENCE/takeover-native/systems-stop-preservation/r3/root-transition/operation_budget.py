"""One monotonic work/cleanup budget per operation; no child resets it."""
import time,os
class BudgetExpired(TimeoutError):pass
class OperationBudget:
 def __init__(self,work_seconds=115.0,total_seconds=120.0,clock=time.monotonic,started=None):
  if not 0<work_seconds<=115 or not work_seconds<total_seconds<=120:raise ValueError('115/120 ceilings and cleanup reserve required')
  self.clock=clock;self.started=clock() if started is None else started;self.work_end=self.started+work_seconds;self.total_end=self.started+total_seconds
  self.cleanup_end=None
 def remaining(self,cleanup=False):
  end=(min(self.total_end,self.cleanup_end) if self.cleanup_end is not None else self.total_end) if cleanup else self.work_end
  remaining=end-self.clock()
  if remaining<=0:raise BudgetExpired('Aggregate cleanup deadline' if cleanup else 'Aggregate work deadline')
  return remaining
 def begin_cleanup(self):
  # Calling cleanup twice never grants another five seconds.
  if self.cleanup_end is None:self.cleanup_end=min(self.total_end,self.clock()+5.0)
  return self.remaining(cleanup=True)
 def child_timeout(self,ceiling=1.0,cleanup=False):return min(ceiling,self.remaining(cleanup))
 def check(self,cleanup=False):self.remaining(cleanup)
 def snapshot(self):return dict(elapsed=self.clock()-self.started,work_remaining=max(0,self.work_end-self.clock()),total_remaining=max(0,self.total_end-self.clock()),cleanup_started=self.cleanup_end is not None)

def read_bytes(path,budget,cleanup=False):
 chunks=[]
 budget.check(cleanup)
 with path.open('rb') as stream:
  while True:
   budget.check(cleanup);chunk=stream.read(1024*1024);budget.check(cleanup)
   if not chunk:break
   chunks.append(chunk)
 budget.check(cleanup)
 return b''.join(chunks)

def write_bytes(path,data,budget,cleanup=False,exclusive=False):
 budget.check(cleanup)
 with path.open('xb' if exclusive else 'wb') as stream:
  for start in range(0,len(data),1024*1024):
   budget.check(cleanup);stream.write(data[start:start+1024*1024]);budget.check(cleanup)
  stream.flush();budget.check(cleanup);os.fsync(stream.fileno());budget.check(cleanup)
 budget.check(cleanup)

def digest_bytes(data,hasher,budget,cleanup=False):
 for start in range(0,len(data),1024*1024):
  budget.check(cleanup);hasher.update(memoryview(data)[start:start+1024*1024])
 budget.check(cleanup)
 return hasher.hexdigest()
