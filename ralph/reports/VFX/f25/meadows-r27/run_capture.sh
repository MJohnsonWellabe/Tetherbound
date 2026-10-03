#!/bin/bash
# usage: run_capture.sh <out_dir> [harness args...]
OUT="$1"; shift
cd /home/user/Tetherbound
export LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe
START=$(date +%s)
xvfb-run -a -s "-screen 0 1920x1080x24" timeout 3000 godot --path . --rendering-method gl_compatibility \
  --resolution 1920x1080 --fixed-fps 60 --script tests/smoke_move_effects_library.gd -- --out="$OUT" "$@" > "$OUT.log" 2>&1
RC=$?
echo "EXIT=$RC SECONDS=$(( $(date +%s) - START ))" >> "$OUT.log"
echo "EXIT=$RC SECONDS=$(( $(date +%s) - START ))"
grep -E "^F25 batch|SCRIPT ERROR|ERROR:" "$OUT.log" | head -20
