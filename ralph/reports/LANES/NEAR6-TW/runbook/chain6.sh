#!/bin/bash
# After r6b: r20 (F39#20 gather nodes hidden in the fight ring), then r1 (F39#1 shore ecology).
cd /home/user/Tetherbound; R=ralph/reports/LANES/NEAR6-TW/runbook; D=.artifacts/run; L=$D/queue.log
export QJ_LANE=NEAR6-TW
while pgrep -f "quick_judge.py run F39#6" >/dev/null; do sleep 15; done
grep -q "END r6b" $L || { echo "$(date -u +%H:%M:%S) END r6b (watched)" >> $L; ls .artifacts/qj/r6b/k/JUDGE_PROMPT_FILLED.txt >/dev/null 2>&1 && touch $D/r6b.done; }
step() { n=$1; shift; [ -f $D/$n.done ] && return 0; echo "$(date -u +%H:%M:%S) START $n" >> $L; "$@" >> $D/$n.log 2>&1; rc=$?; echo "$(date -u +%H:%M:%S) END $n rc=$rc" >> $L; [ $rc = 0 ] && touch $D/$n.done; return 0; }
step r20 python3 tools/visual_judge/quick_judge.py run 'F39#20' --overlay $R/ov_r20.json --name r20
step r1  python3 tools/visual_judge/quick_judge.py run 'F39#1'  --overlay $R/ov_r1.json  --name r1
echo "$(date -u +%H:%M:%S) CHAIN6 DONE" >> $L
