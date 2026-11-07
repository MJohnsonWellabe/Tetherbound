#!/bin/bash
# NEAR6-TW resumable chain: wait for import, then one quick_judge capture per item (.done markers).
cd /home/user/Tetherbound; R=ralph/reports/LANES/NEAR6-TW/runbook; D=.artifacts/run; mkdir -p $D; L=$D/queue.log
export QJ_LANE=NEAR6-TW
while pgrep -f -- "--import" >/dev/null; do sleep 30; done
step() { n=$1; shift; [ -f $D/$n.done ] && return 0; echo "$(date -u +%H:%M:%S) START $n" >> $L; "$@" >> $D/$n.log 2>&1; rc=$?; echo "$(date -u +%H:%M:%S) END $n rc=$rc" >> $L; [ $rc = 0 ] && touch $D/$n.done; return 0; }
step r6  python3 tools/visual_judge/quick_judge.py run 'F39#6'  --overlay $R/ov_r6.json  --name r6
step r27 python3 tools/visual_judge/quick_judge.py run 'F39#27' --overlay $R/ov_r27.json --name r27
step r14 python3 tools/visual_judge/quick_judge.py run 'F39#14' --overlay $R/ov_r14.json --name r14
step r19 python3 tools/visual_judge/quick_judge.py run 'F39#19' --overlay $R/ov_r19.json --name r19
step r7  python3 tools/visual_judge/quick_judge.py run 'F39#7'  --overlay $R/ov_r7.json  --name r7
echo "$(date -u +%H:%M:%S) CHAIN DONE" >> $L
