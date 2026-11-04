#!/bin/bash
# Resumable round-1 chain: each step leaves /dev/shm/run/<step>.done. quick_judge caches captures by tree.
R=/home/user/Tetherbound/ralph/reports/LANES/VIS-TIDEWAKE/runbook
cd /home/user/Tetherbound; export XDG_DATA_HOME=/dev/shm/xdg QJ_LANE=VIS-TIDEWAKE
L=/dev/shm/run/queue.log; D=/dev/shm/run
[ -x /dev/shm/godot/godot ] || $R/setup_shm.sh
step() { [ -f $D/$1.done ] && return 0; echo "$(date -u +%H:%M:%S) START $1" >> $L; shift_n=$1; shift; "$@"; rc=$?; echo "$(date -u +%H:%M:%S) END $shift_n rc=$rc" >> $L; [ $rc = 0 ] && touch $D/$shift_n.done; }
[ -f $D/ov_applied.json ] && git diff --quiet data/config || python3 $R/ov.py revert 2>/dev/null
[ -d /dev/shm/dotgodot/imported ] && [ -f $D/import.done ] || step import godot --headless --path . --import
step r1 python3 tools/visual_judge/quick_judge.py run F39#1 F39#2 F39#3 F39#15 F39#16 F39#17 F39#5 F39#14 F39#8 F39#22 --overlay $R/ov_c1.json --name r1
step r1b python3 tools/visual_judge/quick_judge.py run F39#4 F39#6 F39#24 --overlay $R/ov_r1b.json --name r1b
step lookbase $R/look.sh base
lookc1() { python3 $R/ov.py apply $R/ov_c1.json && $R/look.sh c1; rc=$?; python3 $R/ov.py revert; return $rc; }
step lookc1 lookc1
