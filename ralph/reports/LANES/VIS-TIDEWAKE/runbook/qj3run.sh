#!/bin/bash
# F39#3 arm d3: bigger Lantern Cove drift arch (5 -> 8 m, lantern posts 2.6 -> 3.4 m) and two extra collider-free stepped terrace walls at Drowned Garden.
R=/home/user/Tetherbound/ralph/reports/LANES/VIS-TIDEWAKE/runbook
cd /home/user/Tetherbound; [ -x /dev/shm/godot/godot ] || bash $R/setup_shm.sh
export XDG_DATA_HOME=/dev/shm/xdg QJ_LANE=VIS-TIDEWAKE
L=/dev/shm/run/queue.log; D=/dev/shm/run
step() { n=$1; shift; [ -f $D/$n.done ] && return 0; echo "$(date -u +%H:%M:%S) START $n" >> $L; "$@"; rc=$?; echo "$(date -u +%H:%M:%S) END $n rc=$rc" >> $L; [ $rc = 0 ] && touch $D/$n.done; return $rc; }
[ -d /dev/shm/dotgodot/imported ] && [ -f $D/import.done ] || step import godot --headless --path . --import
step qj3d3 python3 tools/visual_judge/quick_judge.py run F39#3 --overlay $R/ov_d3.json --name d3
