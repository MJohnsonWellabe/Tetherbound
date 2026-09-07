#!/usr/bin/env bash
# Fixed-viewpoint captures for the visual critic loop.
# Water/default use Compatibility; Stormwood uses its native Vulkan capture.
# Usage: tools/survey.sh [--water|--stormwood] [godot-binary] [output-directory]
# Compatibility frames do not prove Forward+ lighting or post-processing.
set -uo pipefail

GODOT="${GODOT:-godot}"
MODE=default
OUT_ARG=""
POSITIONAL_COUNT=0
for arg in "$@"; do
  case "$arg" in
    --water) MODE=water ;;
    --stormwood) MODE=stormwood ;;
    *)
      if [ "$POSITIONAL_COUNT" -eq 0 ]; then GODOT="$arg"; else OUT_ARG="$arg"; fi
      POSITIONAL_COUNT=$((POSITIONAL_COUNT + 1))
      ;;
  esac
done
cd "$(dirname "$0")/.."
if [ "$MODE" = "stormwood" ]; then
  OUT_DIR="${STORMWOOD_SURVEY_OUT:-${OUT_ARG:-shots/stormwood-foundation}}"
  mkdir -p "$OUT_DIR"
  LOG_PATH="$OUT_DIR/survey.log"
  STORMWOOD_SURVEY_OUT="$OUT_DIR" "$GODOT" --path . --rendering-driver vulkan --resolution 1280x720 \
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
  echo "stormwood capture renderer: Godot Forward+ on the configured GPU (see capture log header)" | tee -a "$LOG_PATH"
  echo "stormwood survey wrote ${COUNT} frames and ${OUT_DIR}/_sheet.png"
  exit 0
fi

SCRIPT=tools/survey.gd
OUT=shots
if [ "$MODE" = water ]; then
  SCRIPT=tools/survey_water.gd
  OUT=shots/water
fi
mkdir -p "$OUT"
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    # Keep the render window off the desktop; this is a real display, not headless.
    "$GODOT" --path . --rendering-driver opengl3 --resolution 1280x720 \
      --position -10000,-10000 --log-file "$OUT/engine.log" --script "$SCRIPT" \
      2>&1 | tee "$OUT/survey.log"
    ;;
  *)
    xvfb-run -a -s "-screen 0 1280x720x24" \
      "$GODOT" --path . --rendering-driver opengl3 --resolution 1280x720 \
      --log-file "$OUT/engine.log" --script "$SCRIPT" 2>&1 \
      | grep -viE "ALSA|libpulse|pcm\.c|conf\.c|confmisc|snd_"
    ;;
esac
RUN_EXIT=${PIPESTATUS[0]}
if [ "$MODE" = water ]; then
  # Known extension shutdown failures may follow completed captures; surface the
  # exit code but require the current-run completion manifest and all six files.
  COUNT=$(find "$OUT" -maxdepth 1 -name '[0-9][0-9]-*.png' | wc -l)
  if grep -qE 'SCRIPT ERROR:|^ERROR:' "$OUT/engine.log"; then
    echo "Water survey FAILED: runtime errors in $OUT/engine.log"
    exit 1
  fi
  if [ "$COUNT" -ne 6 ] || ! grep -Eq '"complete"[[:space:]]*:[[:space:]]*true' "$OUT/metadata.json"; then
    echo "Water survey FAILED: frames=$COUNT engine_exit=$RUN_EXIT"
    exit 1
  fi
  echo "Water survey wrote six frames to $OUT (engine_exit=$RUN_EXIT)"
  exit 0
fi
# Preserve the legacy default's frame-based shutdown acceptance (D06).
COUNT=$(ls -1 shots/*.png 2>/dev/null | wc -l)
if [ "$COUNT" -eq 0 ]; then
  echo "survey FAILED: no frames written"
  exit 1
fi
echo "survey wrote ${COUNT} frames to shots/"
