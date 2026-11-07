#!/bin/bash
# look.sh <arm>: F39-look + T2-current via capture_tidewake_f13_5 (shared godot.lock)
ARM=$1; cd /home/user/Tetherbound; export XDG_DATA_HOME=/dev/shm/xdg; SHA=$(git rev-parse HEAD)
for SET in F39-look T2-current; do
  OUT=/dev/shm/cap/look_$ARM/$SET; rm -rf $OUT
  exec 9>/tmp/claude-0/work/godot.lock; flock 9; exec 8>/tmp/claude-0/work/scene.lock; flock 8
  echo "$(date -u +%H:%M:%S) START look $ARM/$SET" >> /dev/shm/run/queue.log
  timeout 5400 xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-method gl_compatibility --rendering-driver opengl3 --resolution 1920x1080 --script res://tools/capture_tidewake_f13_5.gd -- --out=$OUT --camera-set=res://tools/visual_judge/camera_sets/$SET.json --source-sha=$SHA --capture-size=1920x1080 --preset=Low > /dev/shm/cap/look_$ARM.$SET.log 2>&1
  echo "$(date -u +%H:%M:%S) END look $ARM/$SET rc=$? n=$(ls $OUT 2>/dev/null | wc -l)" >> /dev/shm/run/queue.log
  flock -u 8; flock -u 9
done
