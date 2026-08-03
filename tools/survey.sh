#!/usr/bin/env bash
# Capture the fixed-viewpoint survey, for the visual critic loop.
#
#   tools/survey.sh [godot-binary]
#
# Needs a virtual framebuffer and software Vulkan:
#   apt-get install -y xvfb mesa-vulkan-drivers
#
# RENDERER CAVEAT, which belongs in any critique made from these frames.
#
# This uses Godot's COMPATIBILITY renderer, not the Forward+ the game ships.
# That is not a preference. Software Vulkan (lavapipe) was installed and does
# render Forward+, but Terrain3D segfaults under it during region streaming —
# reproduced consistently, crash inside terrain setup, before any capture.
# Compatibility renders the same scene without complaint.
#
# What that costs: Compatibility is a different pipeline, not a lower-quality
# Forward+. No SSAO, no volumetric fog, no SDFGI, and shadows are implemented
# differently. So these frames are TRUSTWORTHY for composition, terrain shape,
# silhouette, colour relationships and camera framing, and NOT trustworthy for
# fine judgements about lighting quality or post-processing.
#
# On a machine with a real GPU, switch this to `vulkan` and the caveat lifts.
set -uo pipefail

GODOT="${1:-${GODOT:-godot}}"
cd "$(dirname "$0")/.."

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
