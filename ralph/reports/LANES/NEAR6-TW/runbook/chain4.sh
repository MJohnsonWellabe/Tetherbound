#!/bin/bash
# After r14: ship r27's rim ON (commit + tests under godot.lock), then r19, r7, r6b, r1.
cd /home/user/Tetherbound; R=ralph/reports/LANES/NEAR6-TW/runbook; D=.artifacts/run; L=$D/queue.log
export QJ_LANE=NEAR6-TW
while pgrep -f "quick_judge.py run F39#14" >/dev/null; do sleep 15; done
grep -q "END r14" $L || echo "$(date -u +%H:%M:%S) END r14 (watched)" >> $L
if [ ! -f $D/ship27.done ]; then
  python3 -c "
import json; from pathlib import Path
c=Path('data/config/water_character_rim.json'); d=json.loads(c.read_text()); d['enabled']=True; c.write_text(json.dumps(d,indent=2)+'\n')"
  flock /tmp/claude-0/work/godot.lock godot --headless --path . --script tests/run_tests.gd -- --only=test_near6_tw_judged_on,test_creature_rim,test_texture_import_policy > $D/tests27.log 2>&1
  echo "$(date -u +%H:%M:%S) TESTS r27 rc=$? $(grep -E 'passed|failed' $D/tests27.log | tail -1)" >> $L
  touch $D/ship27.done
fi
step() { n=$1; shift; [ -f $D/$n.done ] && return 0; echo "$(date -u +%H:%M:%S) START $n" >> $L; "$@" >> $D/$n.log 2>&1; rc=$?; echo "$(date -u +%H:%M:%S) END $n rc=$rc" >> $L; [ $rc = 0 ] && touch $D/$n.done; return 0; }
step r19 python3 tools/visual_judge/quick_judge.py run 'F39#19' --overlay $R/ov_r19.json --name r19
step r7  python3 tools/visual_judge/quick_judge.py run 'F39#7'  --overlay $R/ov_r7.json  --name r7
step r6b python3 tools/visual_judge/quick_judge.py run 'F39#6'  --overlay $R/ov_r6b.json --name r6b
step r1  python3 tools/visual_judge/quick_judge.py run 'F39#1'  --overlay $R/ov_r1.json  --name r1
echo "$(date -u +%H:%M:%S) CHAIN4 DONE" >> $L
