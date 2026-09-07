#!/usr/bin/env bash
# Capture the fixed-viewpoint survey, for the visual critic loop.
#
#   tools/survey.sh [godot-binary]
#   tools/survey.sh --stormwood [godot-binary] [output-directory]
#
# Capture with the shipped Compatibility renderer (project.godot and D01).
# On Linux without a display, provide a virtual framebuffer and OpenGL driver.
# Do not force Vulkan: that changes the project's rendering backend and has
# failed during Stormwood asset loading on the Windows capture machine.
set -uo pipefail

GODOT="${1:-${GODOT:-godot}}"
MODE="meadows"
if [ "${1:-}" = "--stormwood" ]; then
  MODE="stormwood"
  shift
  GODOT="${1:-${GODOT:-godot}}"
fi
cd "$(dirname "$0")/.."

if [ "$MODE" = "stormwood" ]; then
  OUT_DIR="${STORMWOOD_SURVEY_OUT:-${2:-shots/stormwood-foundation}}"
  mkdir -p "$OUT_DIR"
  LOG_PATH="$OUT_DIR/survey.log"
  STORMWOOD_SURVEY_OUT="$OUT_DIR" "$GODOT" --path . --rendering-driver opengl3 --resolution 1280x720 \
    --script tools/survey_stormwood.gd 2>&1 | tee "$LOG_PATH"
  STATUS=${PIPESTATUS[0]}
  if [ "$STATUS" -ne 0 ]; then
    echo "stormwood survey FAILED: capture process exited ${STATUS}"
    exit "$STATUS"
  fi
  COUNT=$(find "$OUT_DIR" -maxdepth 1 -type f -name '*.png' ! -name '_sheet.png' | wc -l)
  if [ "$COUNT" -ne 8 ]; then
    echo "stormwood survey FAILED: expected 8 frames, found ${COUNT}"
    exit 1
  fi
  "$GODOT" --headless --path . --script tools/contact_sheet.gd -- \
    --dir="$OUT_DIR" --out="$OUT_DIR/_sheet.png" 2>&1 | tee -a "$LOG_PATH"
  SHEET_STATUS=${PIPESTATUS[0]}
  if [ "$SHEET_STATUS" -ne 0 ] || [ ! -f "$OUT_DIR/_sheet.png" ]; then
    echo "stormwood survey FAILED: contact sheet was not written"
    exit 1
  fi
  echo "stormwood capture renderer: shipped Godot Compatibility/OpenGL (D01; see capture log header)" | tee -a "$LOG_PATH"
  echo "stormwood survey wrote ${COUNT} frames and ${OUT_DIR}/_sheet.png"
  exit 0
fi

# Godot aborts on shutdown after rendering with this extension loaded; the
# frames are already written by then. The exit code is therefore not the check
# — the file count is. See docs/decisions/D06.
xvfb-run -a -s "-screen 0 1280x720x24" \
  "$GODOT" --path . --rendering-driver opengl3 --resolution 1280x720 \
  --script tools/survey.gd 2>&1 \
  | grep -viE "ALSA|libpulse|pcm\.c|conf\.c|confmisc|snd_"

COUNT=$(ls -1 shots/*.png 2>/dev/null | wc -l)
if [ "$COUNT" -eq 0 ]; then
  echo "survey FAILED: no frames written"
  exit 1
fi
if grep -q . <<<"$(ls shots/*.png 2>/dev/null)"; then
  echo "survey wrote ${COUNT} frames to shots/"
fi
