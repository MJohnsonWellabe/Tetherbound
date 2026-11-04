#!/bin/bash
cd /home/user/Tetherbound; D=.artifacts/run; L=$D/queue.log
export QJ_LANE=NEAR6-TW
flock /tmp/claude-0/work/godot.lock godot --headless --path . --import > .artifacts/import3.log 2>&1
echo "$(date -u +%H:%M:%S) IMPORT3 rc=$?" >> $L
step() { n=$1; shift; [ -f $D/$n.done ] && return 0; echo "$(date -u +%H:%M:%S) START $n" >> $L; "$@" >> $D/$n.log 2>&1; rc=$?; echo "$(date -u +%H:%M:%S) END $n rc=$rc" >> $L; [ $rc = 0 ] && touch $D/$n.done; return 0; }
step c10 python3 tools/visual_judge/quick_judge.py capture 'F41#10' --name c10
echo "$(date -u +%H:%M:%S) CHAIN17 DONE" >> $L
