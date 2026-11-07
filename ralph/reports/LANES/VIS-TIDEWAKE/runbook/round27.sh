#!/bin/bash
# Round 27: water night dim (water.gdshader night_dim driven by the day cycle; judges: neon shoreline band, snow-bright night) vs a fresh base.
# Runs the water tests first (the shader and water_surface.gd changed).
R=/home/user/Tetherbound/ralph/reports/LANES/VIS-TIDEWAKE/runbook
cd /home/user/Tetherbound; export XDG_DATA_HOME=/dev/shm/xdg
L=/dev/shm/run/queue.log; D=/dev/shm/run
[ -x /dev/shm/godot/godot ] || $R/setup_shm.sh
step() { n=$1; shift; [ -f $D/$n.done ] && return 0; echo "$(date -u +%H:%M:%S) START $n" >> $L; "$@"; rc=$?; echo "$(date -u +%H:%M:%S) END $n rc=$rc" >> $L; [ $rc = 0 ] && touch $D/$n.done; return $rc; }
arm() { python3 $R/ov.py apply $R/$1 && $R/look.sh $2; rc=$?; python3 $R/ov.py revert; return $rc; }
tests() { flock /tmp/claude-0/work/godot.lock timeout 900 godot --headless --path . -s tests/run_tests.gd -- --only=test_tidewake_look_profile.gd,test_water_offshore_material.gd,test_water_surface_material.gd > $D/test_r27.out 2>&1; grep -q " 0 failed" $D/test_r27.out; }
[ -d /dev/shm/dotgodot/imported ] && [ -f $D/import.done ] || step import godot --headless --path . --import
step test27 tests
step r27base $R/look.sh r27b
step r27cand arm ov_r27.json r27c
