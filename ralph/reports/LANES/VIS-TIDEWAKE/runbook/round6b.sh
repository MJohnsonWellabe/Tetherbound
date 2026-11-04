#!/bin/bash
# Round 6b: stronger stars + deep-navy night sky top, vs the round 5 base frames.
R=/home/user/Tetherbound/ralph/reports/LANES/VIS-TIDEWAKE/runbook
cd /home/user/Tetherbound; export XDG_DATA_HOME=/dev/shm/xdg
L=/dev/shm/run/queue.log; D=/dev/shm/run
while pgrep -f "round6.sh" >/dev/null; do sleep 20; done
step() { n=$1; shift; [ -f $D/$n.done ] && return 0; echo "$(date -u +%H:%M:%S) START $n" >> $L; "$@"; rc=$?; echo "$(date -u +%H:%M:%S) END $n rc=$rc" >> $L; [ $rc = 0 ] && touch $D/$n.done; return $rc; }
cand() { python3 $R/ov.py apply $R/ov_r6b.json && $R/look.sh r6d; rc=$?; python3 $R/ov.py revert; return $rc; }
step r6bcand cand
