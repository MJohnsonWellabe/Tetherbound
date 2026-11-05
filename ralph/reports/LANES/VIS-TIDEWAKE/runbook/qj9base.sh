#!/bin/bash
# F39#9: pinned-wild tests, then the seeded Tidewake catch base capture.
R=/home/user/Tetherbound/ralph/reports/LANES/VIS-TIDEWAKE/runbook
cd /home/user/Tetherbound; [ -x /dev/shm/godot/godot ] || bash $R/setup_shm.sh
export XDG_DATA_HOME=/dev/shm/xdg QJ_LANE=VIS-TIDEWAKE
L=/dev/shm/run/queue.log; D=/dev/shm/run
step() { n=$1; shift; [ -f $D/$n.done ] && return 0; echo "$(date -u +%H:%M:%S) START $n" >> $L; "$@"; rc=$?; echo "$(date -u +%H:%M:%S) END $n rc=$rc" >> $L; [ $rc = 0 ] && touch $D/$n.done; return $rc; }
[ -d /dev/shm/dotgodot/imported ] && [ -f $D/import.done ] || step import godot --headless --path . --import
tests() { timeout 900 godot --headless --path . -s tests/run_tests.gd -- --only=test_capture_catch_pinned_wild.gd,test_capture_catch_pinned_tidewake_wild.gd,test_tidewake_look_profile.gd > $D/test_q9.out 2>&1; grep -q " 0 failed" $D/test_q9.out; }
step test9 tests
step qj9base python3 tools/visual_judge/quick_judge.py capture F39#9 --name base9
