#!/bin/bash
# F39#12 arm n12 (CREATURES-RALPH raised nest bed) then F39#13 arm w13 (Blender workbench), after f16.
R=/home/user/Tetherbound/ralph/reports/LANES/VIS-TIDEWAKE/runbook
cd /home/user/Tetherbound; [ -x /dev/shm/godot/godot ] || bash $R/setup_shm.sh
export XDG_DATA_HOME=/dev/shm/xdg QJ_LANE=VIS-TIDEWAKE
L=/dev/shm/run/queue.log; D=/dev/shm/run
step() { n=$1; shift; [ -f $D/$n.done ] && return 0; echo "$(date -u +%H:%M:%S) START $n" >> $L; "$@"; rc=$?; echo "$(date -u +%H:%M:%S) END $n rc=$rc" >> $L; [ $rc = 0 ] && touch $D/$n.done; return $rc; }
while pgrep -f "qj16f16[.]sh" >/dev/null; do sleep 20; done
[ -d /dev/shm/dotgodot/imported ] && [ -f $D/import.done ] || step import godot --headless --path . --import
step qj12n12 python3 tools/visual_judge/quick_judge.py run F39#12 --overlay $R/ov_n12.json --name n12 > $D/qj12n12.out 2>&1
step qj13w13 python3 tools/visual_judge/quick_judge.py run F39#13 --overlay $R/ov_w13.json --name w13 > $D/qj13w13.out 2>&1
