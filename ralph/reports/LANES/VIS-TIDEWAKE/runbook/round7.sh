#!/bin/bash
# Round 7: F39#5 re-judge on the wake_trail base (coordinator 10:49): tune wake_trail only.
R=/home/user/Tetherbound/ralph/reports/LANES/VIS-TIDEWAKE/runbook
cd /home/user/Tetherbound; export XDG_DATA_HOME=/dev/shm/xdg
L=/dev/shm/run/queue.log; D=/dev/shm/run
step() { n=$1; shift; [ -f $D/$n.done ] && return 0; echo "$(date -u +%H:%M:%S) START $n" >> $L; "$@"; rc=$?; echo "$(date -u +%H:%M:%S) END $n rc=$rc" >> $L; [ $rc = 0 ] && touch $D/$n.done; return $rc; }
step r7 python3 tools/visual_judge/quick_judge.py run F39#5 F39#14 --overlay $R/ov_r7.json --name r7
