#!/bin/bash
# Round 2: wait for r1b, merge origin/main, then three split arms (resumable via .done markers).
R=/home/user/Tetherbound/ralph/reports/LANES/VIS-TIDEWAKE/runbook
cd /home/user/Tetherbound; export XDG_DATA_HOME=/dev/shm/xdg QJ_LANE=VIS-TIDEWAKE
L=/dev/shm/run/queue.log; D=/dev/shm/run
while pgrep -f "quick_judge.py run F39#4" >/dev/null; do sleep 30; done
step() { n=$1; shift; [ -f $D/$n.done ] && return 0; echo "$(date -u +%H:%M:%S) START $n" >> $L; "$@"; rc=$?; echo "$(date -u +%H:%M:%S) END $n rc=$rc" >> $L; [ $rc = 0 ] && touch $D/$n.done; return $rc; }
merge_main() {
  mv -f tools/visual_judge/quick_judge.py $D/qj_local_backup.py 2>/dev/null
  git fetch -q --depth=1 origin main && git merge -q --no-edit origin/main || return 1
  python3 $R/qj_patch.py && git add tools/visual_judge/quick_judge.py && git commit -qm "quick_judge: Tidewake water__ frame lookup; tool-forced frames under qj_tmp/ (VIS-TIDEWAKE)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01GPgpLVbtXj8gnkAJSeZhjU"
  for b in tidewake meadows cloudreach stormwood; do mkdir -p /dev/shm/cap/qj_tmp_$b ralph/reports/VISUAL/phase2/$b; ln -sfn /dev/shm/cap/qj_tmp_$b ralph/reports/VISUAL/phase2/$b/qj_tmp; done
  grep -q qj_tmp .git/info/exclude || echo "ralph/reports/VISUAL/phase2/*/qj_tmp" >> .git/info/exclude
  git push -q origin tb/vis-tidewake-1104
  godot --headless --path . --import > /dev/shm/import2.log 2>&1
}
# merge_main is not run here: no merge base in this shallow clone and no disk to deepen it (66 MB free).
step r2a python3 tools/visual_judge/quick_judge.py run F39#1 F39#2 F39#3 F39#15 --overlay $R/ov_r2a.json --name r2a
step r2b python3 tools/visual_judge/quick_judge.py run F39#16 F39#5 F39#14 --overlay $R/ov_r2b.json --name r2b
step r2c python3 tools/visual_judge/quick_judge.py run F39#5 F39#14 --overlay $R/ov_r2c.json --name r2c
