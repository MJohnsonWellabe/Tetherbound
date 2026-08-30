#!/usr/bin/env bash
# Group one whole-board capture into the sheets a cohesion pass is actually
# judged from, then build each with the project's own contact_sheet.gd.
#
#   tools/stage_world_board_sheets.sh
#
# WHY NOT ONE SHEET. `.claude/skills/visual-judge` is right that seeing the
# survey at once is the point -- a palette that drifts between locations is
# invisible one image at a time. But a whole-board pass is ~75 frames, and
# contact_sheet.gd's 3-up grid puts that on a strip about 10,000px tall. Every
# viewer downscales it, and at that scale the sheet answers nothing: the
# defects it exists to expose (value drift, palette drift, one band reading as
# a different game) are exactly what disappears first.
#
# So: one sheet per QUESTION, each holding one framing at one time of day
# across all seven stands. That is the comparison EXIT_CRITERION section J
# actually asks for -- do band 2 and band 4 look like the same world under the
# same sun -- and it is only answerable when the sun is genuinely held fixed
# across the tiles, which the mixed sheet cannot do.
#
# Staging is by COPY rather than symlink: contact_sheet.gd reads through
# Godot's res:// filesystem, which does not follow symlinks out of the
# project, and a sheet built from broken links fails silently as a sheet of
# nothing.
set -euo pipefail
cd "$(dirname "$0")/.."

SRC="shots/ground"
DEST="shots/world_board"
GODOT="${GODOT:-godot}"

if [ ! -d "$SRC" ]; then
  echo "no $SRC -- run tools/_capture_ground_and_sky.gd first" >&2
  exit 1
fi

rm -rf "$DEST"

# group name -> the filename pattern that belongs in it. Order matters only for
# reading convenience; contact_sheet.gd sorts within a directory itself.
stage() {
  local group="$1"; shift
  mkdir -p "$DEST/$group"
  local n=0
  for pattern in "$@"; do
    for f in $SRC/$pattern; do
      [ -e "$f" ] || continue
      cp -f "$f" "$DEST/$group/"
      n=$((n + 1))
    done
  done
  echo "  $group: $n frame(s)"
}

echo "staging:"
# The three cohesion sheets: one framing, one sun, all seven stands.
stage vista-day    'ground-*-day-vista.png'
stage vista-golden 'ground-*-golden-vista.png'
stage vista-night  'ground-*-night-vista.png'
# Near-field scatter and macro ground variation, day only -- both questions are
# about what the ground is made of, which night does not inform.
stage ground-day   'ground-*-day.png'
stage high-day     'ground-*-day-high.png'
# Everything that is its own subject rather than part of the seven-stand sweep.
stage extras       'landmark-*.png' 'water-*.png' 'ground-02-band2-stone-root-cloudy.png' \
                   'ground-02-band2-stone-root-fog.png' 'ground-02-band2-stone-root-rain.png'

echo "sheeting:"
for dir in "$DEST"/*/; do
  group="$(basename "$dir")"
  "$GODOT" --headless --path . --script tools/contact_sheet.gd -- \
    "--dir=$DEST/$group" "--out=res://$DEST/$group/_sheet.png" >/dev/null 2>&1 || {
      echo "  $group: contact_sheet.gd FAILED" >&2; continue; }
  echo "  $group -> $DEST/$group/_sheet.png"
done
