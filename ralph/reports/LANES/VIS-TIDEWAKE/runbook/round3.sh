#!/bin/bash
# Round 3: F39-look + T2-current matrix, base vs Veilfall near candidates (rock detail, crag relief, falls).
R=/home/user/Tetherbound/ralph/reports/LANES/VIS-TIDEWAKE/runbook
cd /home/user/Tetherbound; export XDG_DATA_HOME=/dev/shm/xdg
L=/dev/shm/run/queue.log; D=/dev/shm/run
while pgrep -f "round2.sh" >/dev/null; do sleep 30; done
step() { n=$1; shift; [ -f $D/$n.done ] && return 0; echo "$(date -u +%H:%M:%S) START $n" >> $L; "$@"; rc=$?; echo "$(date -u +%H:%M:%S) END $n rc=$rc" >> $L; [ $rc = 0 ] && touch $D/$n.done; return $rc; }
cand() { python3 $R/ov.py apply $R/ov_r3.json && $R/look.sh r3c; rc=$?; python3 $R/ov.py revert; return $rc; }
step r3base $R/look.sh r3b
step r3cand cand
