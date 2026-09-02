#!/usr/bin/env bash
# Visual-parity evidence capture (VP program, docs/VISUAL_PARITY_LANES.md).
# Runs the capture tools serially, builds contact sheets, copies frames into an
# evidence dir, then measures the perf proxy. Env: GODOT, RES (default
# 1280x720), LIGHT=1 skips combat/buildings, REPO overrides the checkout.
# VP_FAST=1: fast-iteration mode. Defaults RES to 960x540 (still overridable
# by an explicit RES) and passes --fast to every capture tool's user args, so
# each tool (see their own headers) halves its settle waits and disables
# MSAA/SSAA. Use for quick local loops, not for evidence that ships.
#   tools/vp_capture.sh <evidence_dir> [locations --only list, comma separated]
set -uo pipefail
cd "${REPO:-$(cd "$(dirname "$0")/.." && pwd)}"
GODOT=${GODOT:-$HOME/.cache/tetherbound-art/godot}
if [ -n "${VP_FAST:-}" ]; then
  RES=${RES:-960x540}
else
  RES=${RES:-1280x720}
fi
EV=$1; ONLY=${2:-}
mkdir -p "$EV"
LOG=$EV/capture.log
FILTER='ALSA|libpulse|pcm\.c|conf\.c|confmisc|snd_|set_use_vsync|audio driver|ERR_CANT_OPEN'
run_render() { # name script [extra args...]
  local name=$1; shift; local script=$1; shift
  local args=("$@")
  if [ -n "${VP_FAST:-}" ]; then
    local found_dashdash=""
    for a in "${args[@]}"; do [ "$a" = "--" ] && found_dashdash=1; done
    if [ -n "$found_dashdash" ]; then
      args+=("--fast")
    else
      args+=("--" "--fast")
    fi
  fi
  echo "=== $name  $(date -u +%H:%M:%S)" | tee -a "$LOG"
  local t0=$SECONDS
  timeout 5400 xvfb-run -a -s "-screen 0 ${RES}x24" "$GODOT" --path . \
    --rendering-driver opengl3 --resolution ${RES} --script "$script" "${args[@]}" 2>&1 \
    | grep -vE "$FILTER" | tail -40 >> "$LOG"
  echo "--- $name exit=${PIPESTATUS[0]} took=$((SECONDS-t0))s" | tee -a "$LOG"
}
rm -rf shots/locations shots/ground shots/combat shots/buildings shots/*.png shots/_sheet*.png
if [ -n "$ONLY" ]; then
  run_render locations tools/_capture_locations.gd -- "--only=$ONLY"
else
  run_render locations tools/_capture_locations.gd
fi
run_render survey tools/survey.gd
run_render ground_and_sky tools/_capture_ground_and_sky.gd
[ -n "${LIGHT:-}" ] || run_render combat tools/survey_combat.gd
[ -n "${LIGHT:-}" ] || run_render buildings tools/capture_buildings.gd
# contact sheets
for d in locations ground combat buildings; do
  [ -d shots/$d ] || continue
  "$GODOT" --headless --path . --script tools/contact_sheet.gd -- --dir=res://shots/$d --out=res://shots/_sheet_$d.png 2>&1 | grep -vE "$FILTER" | tail -3 >> "$LOG"
done
"$GODOT" --headless --path . --script tools/contact_sheet.gd 2>&1 | grep -vE "$FILTER" | tail -3 >> "$LOG"
# copy evidence
mkdir -p "$EV/locations" "$EV/survey" "$EV/ground" "$EV/combat" "$EV/buildings"
cp shots/locations/*.png "$EV/locations/" 2>/dev/null
cp shots/*.png "$EV/survey/" 2>/dev/null
cp shots/ground/*.png "$EV/ground/" 2>/dev/null
cp shots/combat/*.png "$EV/combat/" 2>/dev/null
cp shots/buildings/*.png "$EV/buildings/" 2>/dev/null
# frame stats
python3 tools/frame_stats.py "$EV"/locations/*.png "$EV"/survey/*.png "$EV"/ground/*.png > "$EV/frame_stats.txt" 2>&1
# perf proxy (fixed 1280x720 series)
echo "=== perf_render_stats $(date -u +%H:%M:%S)" | tee -a "$LOG"
timeout 3600 xvfb-run -a -s "-screen 0 1280x720x24" "$GODOT" --path . --rendering-driver opengl3 --resolution 1280x720 \
  --script tools/perf_render_stats.gd -- --label=$(basename "$EV") --views=${PERF_VIEWS:-band1_open,village_high,hall_approach} --settle=${PERF_SETTLE:-120} --resettle=${PERF_RESETTLE:-60} --sample=${PERF_SAMPLE:-20} 2>&1 | grep -vE "$FILTER" > "$EV/perf_render_stats.txt"
echo "--- perf exit=${PIPESTATUS[0]}" | tee -a "$LOG"
timeout 1800 "$GODOT" --headless --path . --script tools/perf_scatter_density.gd 2>&1 | grep -vE "$FILTER" > "$EV/perf_scatter_density.txt"
echo "=== DONE $(date -u +%H:%M:%S)" | tee -a "$LOG"
find "$EV" -name '*.png' | wc -l | sed 's/^/pngs=/' | tee -a "$LOG"
