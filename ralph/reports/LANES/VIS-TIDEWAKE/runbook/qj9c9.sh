#!/bin/bash
# F39#9 arm c9: clustered collider-free dune grass, driftwood, rocks and shrubs around the First Shore catch spot (14-18 m out).
R=/home/user/Tetherbound/ralph/reports/LANES/VIS-TIDEWAKE/runbook
cd /home/user/Tetherbound; [ -x /dev/shm/godot/godot ] || bash $R/setup_shm.sh
export XDG_DATA_HOME=/dev/shm/xdg QJ_LANE=VIS-TIDEWAKE
L=/dev/shm/run/queue.log; D=/dev/shm/run
step() { n=$1; shift; [ -f $D/$n.done ] && return 0; echo "$(date -u +%H:%M:%S) START $n" >> $L; "$@"; rc=$?; echo "$(date -u +%H:%M:%S) END $n rc=$rc" >> $L; [ $rc = 0 ] && touch $D/$n.done; return $rc; }
[ -d /dev/shm/dotgodot/imported ] && [ -f $D/import.done ] || step import godot --headless --path . --import
step qj9c9 python3 tools/visual_judge/quick_judge.py run F39#9 --overlay $R/ov_c9.json --name c9
