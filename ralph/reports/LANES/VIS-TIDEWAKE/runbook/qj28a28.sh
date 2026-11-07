#!/bin/bash
# F39#28 arm a28: Heart Chamber crystal 113 -> 120 m (back wall at 124), out of the Nerissa fight ring.
R=/home/user/Tetherbound/ralph/reports/LANES/VIS-TIDEWAKE/runbook
cd /home/user/Tetherbound; [ -x /dev/shm/godot/godot ] || bash $R/setup_shm.sh
export XDG_DATA_HOME=/dev/shm/xdg QJ_LANE=VIS-TIDEWAKE
L=/dev/shm/run/queue.log; D=/dev/shm/run
step() { n=$1; shift; [ -f $D/$n.done ] && return 0; echo "$(date -u +%H:%M:%S) START $n" >> $L; "$@"; rc=$?; echo "$(date -u +%H:%M:%S) END $n rc=$rc" >> $L; [ $rc = 0 ] && touch $D/$n.done; return $rc; }
[ -d /dev/shm/dotgodot/imported ] && [ -f $D/import.done ] || step import godot --headless --path . --import
step qj28a28 python3 tools/visual_judge/quick_judge.py run F39#28 --overlay $R/ov_a28.json --name a28
