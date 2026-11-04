#!/bin/bash
# Coordinator 15:00: batch 17 failed smoke_net_water_alpha (host peer silent >15 s on the client's Water crossing).
# Run the smoke with this lane's batch-17 arms ON (HEAD) and OFF (ov_b17off.json), one Godot at a time.
R=/home/user/Tetherbound/ralph/reports/LANES/VIS-TIDEWAKE/runbook
cd /home/user/Tetherbound; export XDG_DATA_HOME=/dev/shm/xdg GODOT_BIN=/usr/local/bin/godot
L=/dev/shm/run/queue.log; D=/dev/shm/run
while pgrep -f "round17.sh" >/dev/null; do sleep 20; done
run() { echo "$(date -u +%H:%M:%S) START net-$1" >> $L; s=$(date +%s)
  flock /tmp/claude-0/work/godot.lock timeout 1500 tools/net/run_net_smoke.sh water_alpha --out=$D/net_$1 > $D/net_$1.log 2>&1; rc=$?
  echo "$(date -u +%H:%M:%S) END net-$1 rc=$rc wall=$(( $(date +%s)-s ))s" >> $L; }
run on
python3 $R/ov.py apply $R/ov_b17off.json && run off; python3 $R/ov.py revert
