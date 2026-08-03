#!/usr/bin/env bash
# Capture a fight in progress, for the visual critic loop.
#
#   tools/survey_combat.sh [godot-binary]
#
# Same renderer caveat as tools/survey.sh: Compatibility rather than the
# Forward+ the game ships, because Terrain3D segfaults under software Vulkan.
# Composition, silhouette, colour and HUD readability are trustworthy here;
# lighting quality and frame times are not.
#
# And the creatures are coloured capsules. These frames are for judging whether
# the ARENA reads — both fighters visible, distinguishable, trainer in shot,
# bars where the eye already is. CLAUDE.md forbids judging creature appeal on
# placeholders and these frames cannot answer that question.
set -uo pipefail

GODOT="${1:-${GODOT:-godot}}"
cd "$(dirname "$0")/.."

xvfb-run -a -s "-screen 0 1280x720x24" \
  "$GODOT" --path . --rendering-driver opengl3 --resolution 1280x720 \
  --script tools/survey_combat.gd 2>&1 \
  | grep -viE "ALSA|libpulse|pcm\.c|conf\.c|confmisc|snd_"

# Godot can abort on shutdown with this extension loaded; the frames are already
# written by then, so the file count is the check, not the exit code. See
# docs/decisions/D06.
COUNT=$(ls -1 shots/combat/*.png 2>/dev/null | wc -l)
if [ "$COUNT" -eq 0 ]; then
  echo "combat survey FAILED: no frames written"
  exit 1
fi
echo "combat survey wrote ${COUNT} frames to shots/combat/"
