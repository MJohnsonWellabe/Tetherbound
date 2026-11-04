#!/bin/bash
# Round 5: look matrix, base (r3 ON) vs unshadowed Veilfall falls.
R=/home/user/Tetherbound/ralph/reports/LANES/VIS-TIDEWAKE/runbook
cd /home/user/Tetherbound; export XDG_DATA_HOME=/dev/shm/xdg
L=/dev/shm/run/queue.log; D=/dev/shm/run
true
step() { n=$1; shift; [ -f $D/$n.done ] && return 0; echo "$(date -u +%H:%M:%S) START $n" >> $L; "$@"; rc=$?; echo "$(date -u +%H:%M:%S) END $n rc=$rc" >> $L; [ $rc = 0 ] && touch $D/$n.done; return $rc; }
cand() { python3 $R/ov.py apply $R/ov_r5.json && $R/look.sh r5c; rc=$?; python3 $R/ov.py revert; return $rc; }
step r5base $R/look.sh r5b
step r5cand cand
