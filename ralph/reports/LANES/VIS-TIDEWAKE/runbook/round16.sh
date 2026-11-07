#!/bin/bash
# Round 16: calmer sand ripples (judges: striped dark banding at dawn/golden) vs a fresh base (r14 ON).
R=/home/user/Tetherbound/ralph/reports/LANES/VIS-TIDEWAKE/runbook
cd /home/user/Tetherbound; export XDG_DATA_HOME=/dev/shm/xdg
L=/dev/shm/run/queue.log; D=/dev/shm/run
step() { n=$1; shift; [ -f $D/$n.done ] && return 0; echo "$(date -u +%H:%M:%S) START $n" >> $L; "$@"; rc=$?; echo "$(date -u +%H:%M:%S) END $n rc=$rc" >> $L; [ $rc = 0 ] && touch $D/$n.done; return $rc; }
arm() { python3 $R/ov.py apply $R/$1 && $R/look.sh $2; rc=$?; python3 $R/ov.py revert; return $rc; }
step r16base $R/look.sh r16b
step r16cand arm ov_r16.json r16c
