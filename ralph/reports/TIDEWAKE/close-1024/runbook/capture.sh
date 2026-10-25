#!/usr/bin/env bash
# Tidewake fixed-camera capture (CPU, Low/Compatibility). Usage:
#   capture.sh <out_name> <camera_set.json> "<extra args>"
# e.g. capture.sh fc3 F39-look.json "--views=veilfall-vista,veilfall-vista-rain --tidewake-look-sections=current_flow,veilfall_mountain_candidate"
# Run from the repo root on a clean, pushed HEAD: --source-sha must be a real
# full SHA (a -dirty suffix is refused). One Godot process at a time.
set -u
cd "$(git rev-parse --show-toplevel)"
python3 -c "import json;json.load(open('data/config/tidewake_look.json'));json.load(open('data/config/water_world.json'))" || exit 1
SHA=$(git rev-parse HEAD)
OUT=$HOME/cap/$1
rm -rf "$OUT"; mkdir -p "$HOME/cap"
timeout 1800 xvfb-run -a -s "-screen 0 1920x1080x24" "$HOME/godot-bin/godot" --path . \
  --rendering-method gl_compatibility --rendering-driver opengl3 --resolution 1920x1080 \
  --script res://tools/capture_tidewake_f13_5.gd -- --out="$OUT" \
  --camera-set=res://tools/visual_judge/camera_sets/$2 --source-sha="$SHA" \
  --capture-size=1920x1080 --preset=Low ${3:-} > "$OUT.log" 2>&1
echo "$1 EXIT $?"
