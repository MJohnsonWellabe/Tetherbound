#!/bin/bash
cd /home/user/Tetherbound; R=ralph/reports/LANES/NEAR6-TW/runbook; D=.artifacts/run; L=$D/queue.log
export QJ_LANE=NEAR6-TW
until grep -q "CHAIN11 DONE" $L; do sleep 30; done
step() { n=$1; shift; [ -f $D/$n.done ] && return 0; echo "$(date -u +%H:%M:%S) START $n" >> $L; "$@" >> $D/$n.log 2>&1; rc=$?; echo "$(date -u +%H:%M:%S) END $n rc=$rc" >> $L; [ $rc = 0 ] && touch $D/$n.done; return 0; }
step c24 python3 tools/visual_judge/quick_judge.py capture 'F39#24' --name c24
step c16 python3 tools/visual_judge/quick_judge.py capture 'F39#16' --name c16
echo "$(date -u +%H:%M:%S) CHAIN12 DONE" >> $L
