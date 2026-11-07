#!/bin/bash
# Round 12: Veilfall fall sheet standoff 0.8 -> 3.0 m (the dark rock ridge clips through the sheet) vs a fresh base (night + rain ON).
R=/home/user/Tetherbound/ralph/reports/LANES/VIS-TIDEWAKE/runbook
cd /home/user/Tetherbound; export XDG_DATA_HOME=/dev/shm/xdg
L=/dev/shm/run/queue.log; D=/dev/shm/run
step() { n=$1; shift; [ -f $D/$n.done ] && return 0; echo "$(date -u +%H:%M:%S) START $n" >> $L; "$@"; rc=$?; echo "$(date -u +%H:%M:%S) END $n rc=$rc" >> $L; [ $rc = 0 ] && touch $D/$n.done; return $rc; }
arm() { python3 $R/ov.py apply $R/$1 && $R/look.sh $2; rc=$?; python3 $R/ov.py revert; return $rc; }
step r12base $R/look.sh r12b
step r12cand arm ov_r12.json r12c
