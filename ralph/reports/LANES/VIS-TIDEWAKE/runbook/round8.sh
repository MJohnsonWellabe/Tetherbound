#!/bin/bash
# Round 8: moonlit blue night grade (F39#30b) vs a fresh base with stars ON.
R=/home/user/Tetherbound/ralph/reports/LANES/VIS-TIDEWAKE/runbook
cd /home/user/Tetherbound; export XDG_DATA_HOME=/dev/shm/xdg
L=/dev/shm/run/queue.log; D=/dev/shm/run
while pgrep -f "round7.sh" >/dev/null; do sleep 30; done
step() { n=$1; shift; [ -f $D/$n.done ] && return 0; echo "$(date -u +%H:%M:%S) START $n" >> $L; "$@"; rc=$?; echo "$(date -u +%H:%M:%S) END $n rc=$rc" >> $L; [ $rc = 0 ] && touch $D/$n.done; return $rc; }
cand() { python3 $R/ov.py apply $R/ov_r8.json && $R/look.sh r8c; rc=$?; python3 $R/ov.py revert; return $rc; }
step r8base $R/look.sh r8b
step r8cand cand
