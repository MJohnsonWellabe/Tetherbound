#!/bin/bash
cd /home/user/Tetherbound; R=ralph/reports/LANES/NEAR6-TW/runbook; D=.artifacts/run; L=$D/queue.log
export QJ_LANE=NEAR6-TW
until grep -q "CHAIN DONE" $L; do sleep 30; done
step() { n=$1; shift; [ -f $D/$n.done ] && return 0; echo "$(date -u +%H:%M:%S) START $n" >> $L; "$@" >> $D/$n.log 2>&1; rc=$?; echo "$(date -u +%H:%M:%S) END $n rc=$rc" >> $L; [ $rc = 0 ] && touch $D/$n.done; return 0; }
step r6b python3 tools/visual_judge/quick_judge.py run 'F39#6' --overlay $R/ov_r6b.json --name r6b
echo "$(date -u +%H:%M:%S) CHAIN2 DONE" >> $L
