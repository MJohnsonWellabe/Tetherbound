def bounded_child(argv,data=None,timeout=45):
 # Windows communicate() writes stdin before entering its timed wait. Put that
 # entire operation in a worker; the caller deadline covers even blocked stdin.
 # No temporary files or source/lease writes are needed for read-only queries.
 import threading,time
 deadline=time.monotonic()+timeout
 child=subprocess.Popen(argv,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,env=ENV)
 result={};done=threading.Event()
 def communicate():
  try:result['output']=child.communicate(data)
  except BaseException as exc:result['error']=exc
  finally:done.set()
 worker=threading.Thread(target=communicate,daemon=True);worker.start()
 completed=done.wait(max(0,deadline-time.monotonic()))
 if not completed or time.monotonic()>=deadline:
  if child.poll() is None:child.kill()
  require(done.wait(5),'Owned Git helper did not finish cleanup after deadline')
  raise subprocess.TimeoutExpired(argv,timeout)
 if 'error' in result:raise result['error']
 stdout,stderr=result['output']
 require(len(stdout)+len(stderr)<=64*1024**2,'Git helper output exceeded 64 MiB')
 if child.returncode:raise subprocess.CalledProcessError(child.returncode,argv,output=stdout,stderr=stderr)
 return stdout

def git(*args,data=None,store=None):
 location=['--git-dir='+str(store)] if store else ['-C',str(STAGE)]
 return bounded_child([GIT,'-c','gc.auto=0','-c','maintenance.auto=false','-c','core.fsmonitor=false',*location,*args],data=data,timeout=45)
