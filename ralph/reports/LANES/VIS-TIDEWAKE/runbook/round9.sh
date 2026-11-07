#!/bin/bash
# Rounds 9-10: Tidewake rain trio (rain_fog+grade+veil) and current_bands, each vs the r8b base.
R=/home/user/Tetherbound/ralph/reports/LANES/VIS-TIDEWAKE/runbook
cd /home/user/Tetherbound; export XDG_DATA_HOME=/dev/shm/xdg
L=/dev/shm/run/queue.log; D=/dev/shm/run
while pgrep -f "round8.sh" >/dev/null; do sleep 30; done
step() { n=$1; shift; [ -f $D/$n.done ] && return 0; echo "$(date -u +%H:%M:%S) START $n" >> $L; "$@"; rc=$?; echo "$(date -u +%H:%M:%S) END $n rc=$rc" >> $L; [ $rc = 0 ] && touch $D/$n.done; return $rc; }
arm() { python3 $R/ov.py apply $R/$1 && $R/look.sh $2; rc=$?; python3 $R/ov.py revert; return $rc; }
step r9cand arm ov_r9.json r9c
step r10cand arm ov_r10.json r10c
