#!/usr/bin/env bash
# Capture the missing half of the owner's 19-shot UI screenshot suite
# (spec §23), for the visual critic loop.
#
#   tools/capture_ui_suite.sh [godot-binary]
#
# Same xvfb + Compatibility-renderer invocation as tools/survey.sh — see that
# file's own header for the renderer caveat (trustworthy for composition,
# layout and colour; not for lighting-quality judgements). Software
# rendering, so booting the meadows world takes minutes; this script boots it
# exactly ONCE and shoots every missing frame in that single session.
set -uo pipefail

GODOT="${1:-${GODOT:-godot}}"
cd "$(dirname "$0")/.."

xvfb-run -a -s "-screen 0 1920x1080x24" \
  "$GODOT" --path . --rendering-driver opengl3 \
  --script tools/capture_ui_suite.gd 2>&1 \
  | grep -viE "ALSA|libpulse|pcm\.c|conf\.c|confmisc|snd_"

echo ""
echo "shots/_diag now has:"
ls -1 shots/_diag/*.png 2>/dev/null | sort
