#!/usr/bin/env bash
# Run an EXPORTED build and prove the player is standing on ground.
#
#   tools/verify_export.sh [godot-binary]
#
# This exists because a shipped Windows build fell through the world forever and
# every check the project had said it was fine. 107 unit tests, seven smoke
# tests, and an export step that confirmed the .exe was a genuine PE binary over
# 10MB — all green, on a build with no terrain in it at all.
#
# What broke: Godot exports a GDExtension's shared library FLAT next to the
# executable, but the engine looks for it at the library's `res://` path
# relative to the executable — `addons/terrain_3d/bin/`. So Terrain3D never
# loaded, `ClassDB.class_exists("Terrain3D")` was false, `_build_terrain()`
# returned null, and the player spawned in mid-air over nothing.
#
# The general lesson, which is the third time this session: a test that exercises
# a different mechanism from the thing it is checking is testing the mechanism.
# Every smoke test runs the project from source in the editor's own runtime,
# where addons load from `res://` and always work. None of them ran an export.
# So this runs the export.
#
# Exit codes: 0 all good, 1 something is wrong and the message says what.
set -uo pipefail

GODOT="${1:-${GODOT:-godot}}"
cd "$(dirname "$0")/.."

OUT="build/linux"
rm -rf "$OUT"
mkdir -p "$OUT"

echo "exporting..."
"$GODOT" --headless --path . --export-release "Linux Test" "$OUT/Tetherbound.x86_64" >/dev/null 2>&1
if [ ! -f "$OUT/Tetherbound.pck" ]; then
  echo "verify FAILED: no .pck was produced"
  exit 1
fi

# Godot writes GDExtension libraries flat; the loader wants them at their
# res:// path. Mirror them, exactly as the shipping zip must.
tools/stage_gdextension_libs.sh "$OUT"

# Run the EXPORTED BINARY, not `godot --main-pack`.
#
# That distinction is the whole point and it is not pedantry: `--main-pack` runs
# the pack under the EDITOR binary, where `res://` is still a real directory on
# disk. The bug that shipped — a terrain-data check reading the OS filesystem
# instead of the resource pack — PASSES under `--main-pack` and fails in a real
# export. Testing an export with the editor tests the editor.
echo "running the exported build..."
LOG="$OUT/run.log"
#
# `--quit-after` rather than a timeout kill: `print()` is buffered, so a build
# killed mid-run flushes nothing and every positive check reads as a failure.
# Letting it exit on its own is the difference between "the world never
# reported spawning the player" and knowing where they spawned.
( cd "$OUT" && timeout 180 xvfb-run -a -s "-screen 0 640x480x24" \
  ./Tetherbound.x86_64 --rendering-driver opengl3 --verify-export > run.log 2>&1 )
RAN=$?

FAIL=0

# 1. The extension loaded. Without it there is no terrain and no floor.
if grep -q "No baked terrain at" "$LOG"; then
  echo "verify FAILED: the exported build cannot see its own terrain data."
  echo "  The player falls through the world forever. The data is usually"
  echo "  present in the .pck and the CHECK is what is wrong — anything reading"
  echo "  res:// through the OS filesystem succeeds in the editor and fails"
  echo "  in an export."
  FAIL=1
fi
if grep -q "Terrain3D addon is not installed" "$LOG"; then
  echo "verify FAILED: Terrain3D did not load in the exported build."
  echo "  The player will fall through the world forever. Check that the"
  echo "  extension libraries are staged at addons/terrain_3d/bin/ next to the"
  echo "  executable, not flat beside it."
  FAIL=1
fi
if grep -q "GDExtension dynamic library not found" "$LOG"; then
  echo "verify FAILED: a GDExtension library is missing from the export."
  grep -m3 "Can't open dynamic library" "$LOG" | sed 's/^/  /'
  FAIL=1
fi

# 2. Data loaded by string path at run time is in the pack. None of it is
#    traceable by the exporter's dependency scan, so none of it is guaranteed.
for path in "data/terrain/playground" "data/config/art.json" "data/creatures/species.json"; do
  if ! strings -a "$OUT/Tetherbound.pck" | grep -qF "$path"; then
    echo "verify FAILED: '$path' is not in the .pck."
    FAIL=1
  fi
done

# 3. The creatures found ground. This is the symptom that reaches a player:
#    the encounter director reports it when a spawn point has nothing under it.
if grep -q "no ground under" "$LOG"; then
  echo "verify FAILED: creatures could not find the ground in the exported build."
  grep -m3 "no ground under" "$LOG" | sed 's/^/  /'
  FAIL=1
fi

# 4. The world stood itself up, and said so.
if ! grep -q "EXPORT-CHECK" "$LOG"; then
  echo "verify FAILED: the exported build never reported its state."
  echo "  It did not reach the end of world setup. See $LOG."
  FAIL=1
else
  grep -m1 -o "EXPORT-CHECK.*" "$LOG" | sed 's/^/  /'
  if grep -q "terrain=NO" "$LOG" || grep -q "ground_at_spawn=NaN" "$LOG"; then
    echo "verify FAILED: no terrain under the player in the exported build."
    echo "  This is the bug that ships as 'you fall forever'."
    FAIL=1
  fi
fi

# 5. It ran to a clean exit rather than dying on the way.
#
# The liveness signal is the EXIT CODE, not a printed line, because a release
# export strips `print()` — checking for "[playground] spawned at" reported a
# failure on a build that was working perfectly. Errors and warnings still come
# through, which is why every check above is an error signature; this one exists
# so that "no errors" cannot be satisfied by crashing before producing any.
if [ "$RAN" -ne 0 ]; then
  echo "verify FAILED: the exported build did not reach a clean exit (code $RAN)."
  grep -m5 -iE "error|crash|signal" "$LOG" | sed 's/^/  /'
  FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then
  echo "export: OK — extension loaded, data present, ground found."
  grep -m1 "\[playground\] spawned at" "$LOG" | sed 's/^/  /'
  grep -m1 "scattered" "$LOG" | sed 's/^/  /'
fi
exit "$FAIL"
