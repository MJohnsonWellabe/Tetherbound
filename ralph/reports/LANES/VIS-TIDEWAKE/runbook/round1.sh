#!/bin/bash
# Import, then round 1 (QJ 10 rows), round 1b (creatures), then look matrix base + c1.
R=/home/user/Tetherbound/ralph/reports/LANES/VIS-TIDEWAKE/runbook
cd /home/user/Tetherbound; export XDG_DATA_HOME=/dev/shm/xdg QJ_LANE=VIS-TIDEWAKE
L=/dev/shm/run/queue.log
echo "$(date -u +%H:%M:%S) START import" >> $L
godot --headless --path . --import > /dev/shm/import.log 2>&1
echo "$(date -u +%H:%M:%S) END import rc=$?" >> $L
python3 tools/visual_judge/quick_judge.py run F39#1 F39#2 F39#3 F39#15 F39#16 F39#17 F39#5 F39#14 F39#8 F39#22 --overlay $R/ov_c1.json --name r1 > /dev/shm/run/r1.out 2>&1
echo "$(date -u +%H:%M:%S) END QJ r1 rc=$?" >> $L
python3 tools/visual_judge/quick_judge.py run F39#4 F39#6 F39#24 --overlay $R/ov_r1b.json --name r1b > /dev/shm/run/r1b.out 2>&1
echo "$(date -u +%H:%M:%S) END QJ r1b rc=$?" >> $L
$R/look.sh base
python3 $R/ov.py apply $R/ov_c1.json && $R/look.sh c1; python3 $R/ov.py revert
echo "$(date -u +%H:%M:%S) END round1 all" >> $L
