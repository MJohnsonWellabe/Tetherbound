#!/bin/bash
# Round 20: Veilfall fall sheet with more stream relief and a less opaque core (judges: flat white slab) vs r19b (same tree).
R=/home/user/Tetherbound/ralph/reports/LANES/VIS-TIDEWAKE/runbook
cd /home/user/Tetherbound; export XDG_DATA_HOME=/dev/shm/xdg
L=/dev/shm/run/queue.log; D=/dev/shm/run
step() { n=$1; shift; [ -f $D/$n.done ] && return 0; echo "$(date -u +%H:%M:%S) START $n" >> $L; "$@"; rc=$?; echo "$(date -u +%H:%M:%S) END $n rc=$rc" >> $L; [ $rc = 0 ] && touch $D/$n.done; return $rc; }
arm() { python3 $R/ov.py apply $R/$1 && $R/look.sh $2; rc=$?; python3 $R/ov.py revert; return $rc; }
[ -x /dev/shm/godot/godot ] || $R/setup_shm.sh
[ -d /dev/shm/dotgodot/imported ] && [ -f $D/import.done ] || step import godot --headless --path . --import
step r20cand arm ov_r20.json r20c
