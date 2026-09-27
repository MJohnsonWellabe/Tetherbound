#!/bin/bash
cd /home/user/Tetherbound
D=/tmp/claude-0/confirm_main
run() { ~/godot-bin/godot --headless --path . --fixed-fps 60 --script tests/smoke_water_named_c2c3.gd -- --seeds=24 --case=$1 $2 --party-level=43 --json=$D/G_$1.json > $D/RUN_$1.txt 2>&1; }
( run calder; run venn ) &
( run tess; run nerissa; run aquaryn --starter=ripplet ) &
wait
echo ALLDONE > $D/done
