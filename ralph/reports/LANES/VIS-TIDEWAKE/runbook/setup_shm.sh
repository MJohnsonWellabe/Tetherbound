#!/bin/bash
# VIS-TIDEWAKE: rebuild the RAM-disk workspace after a container restart (disk allowance is full;
# .godot, captures, judge rounds, Godot binary, xdg and mesa cache all live in /dev/shm).
set -e
cd /home/user/Tetherbound
mkdir -p /dev/shm/godot /dev/shm/dotgodot /dev/shm/artifacts /dev/shm/cap /dev/shm/xdg /dev/shm/run /dev/shm/mesa_cache /tmp/claude-0/work
[ -x /dev/shm/godot/godot ] || { curl -sSLo /dev/shm/godot/g.zip https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip && unzip -qo /dev/shm/godot/g.zip -d /dev/shm/godot && rm /dev/shm/godot/g.zip && ln -sf /dev/shm/godot/Godot_v4.7-stable_linux.x86_64 /dev/shm/godot/godot; }
ln -sfn /dev/shm/godot/godot /usr/local/bin/godot
rm -rf /root/.cache/mesa_shader_cache; ln -sfn /dev/shm/mesa_cache /root/.cache/mesa_shader_cache
ln -sfn /dev/shm/dotgodot .godot; ln -sfn /dev/shm/artifacts .artifacts
ln -sfn /dev/shm/cap ralph/reports/VISUAL/phase2/tidewake/vt
grep -q '^.godot$' .git/info/exclude || printf '.godot\n.artifacts\nralph/reports/VISUAL/phase2/tidewake/vt\ntools/visual_judge/quick_judge.py\n' >> .git/info/exclude
echo "setup ok"
python3 /home/user/Tetherbound/ralph/reports/LANES/VIS-TIDEWAKE/runbook/quick_judge_find_frame.patch.py
