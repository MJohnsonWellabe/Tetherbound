#!/bin/bash
# After r14: ship r27's rim ON (commit + tests under godot.lock), then r19, r7, r6b, r1.
cd /home/user/Tetherbound; R=ralph/reports/LANES/NEAR6-TW/runbook; D=.artifacts/run; L=$D/queue.log
export QJ_LANE=NEAR6-TW
while pgrep -f "quick_judge.py run F39#14" >/dev/null; do sleep 15; done
grep -q "END r14" $L || echo "$(date -u +%H:%M:%S) END r14 (watched)" >> $L
if [ ! -f $D/ship27.done ]; then
  cp /tmp/claude-0/-home-user-Tetherbound/32bd1f93-8a53-58d5-8b27-8aa52b98c747/scratchpad/test_near6_tw_judged_on.gd tests/
  python3 -c "
import json; from pathlib import Path
c=Path('data/config/water_character_rim.json'); d=json.loads(c.read_text()); d['enabled']=True; d['_why_on']='ON (owner 4 Nov 2026: land every judged improvement): NEAR6-TW qj/r27 F39#27 CPU 6.03 -> 6.23 (three code-blind judges all higher, calibrated; anchor RMSE 0.79 caveat).'; c.write_text(json.dumps(d,indent=2)+'\n')"
  flock /tmp/claude-0/work/godot.lock godot --headless --path . --script tests/run_tests.gd -- --only=test_near6_tw_judged_on,test_creature_rim,test_texture_import_policy > $D/tests27.log 2>&1
  echo "$(date -u +%H:%M:%S) TESTS r27 rc=$? $(grep -E 'passed|failed' $D/tests27.log | tail -1)" >> $L
  grep -q " 0 failed" $D/tests27.log && git add data/config/water_character_rim.json tests/test_near6_tw_judged_on.gd && git commit -qm "NEAR6-TW: F39#27 water_character_rim ON (CPU 6.03 -> 6.23)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01GPgpLTKzzXGFZKjksjVoRW" && git push -q origin tb/near6-tw-1104
  touch $D/ship27.done
fi
step() { n=$1; shift; [ -f $D/$n.done ] && return 0; echo "$(date -u +%H:%M:%S) START $n" >> $L; "$@" >> $D/$n.log 2>&1; rc=$?; echo "$(date -u +%H:%M:%S) END $n rc=$rc" >> $L; [ $rc = 0 ] && touch $D/$n.done; return 0; }
step r19 python3 tools/visual_judge/quick_judge.py run 'F39#19' --overlay $R/ov_r19.json --name r19
step r7  python3 tools/visual_judge/quick_judge.py run 'F39#7'  --overlay $R/ov_r7.json  --name r7
step r6b python3 tools/visual_judge/quick_judge.py run 'F39#6'  --overlay $R/ov_r6b.json --name r6b
step r1  python3 tools/visual_judge/quick_judge.py run 'F39#1'  --overlay $R/ov_r1.json  --name r1
echo "$(date -u +%H:%M:%S) CHAIN4 DONE" >> $L
