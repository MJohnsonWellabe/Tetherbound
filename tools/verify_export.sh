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
# 180 was not a margin, it was a coin flip, and on 2026-08-16 it started
# landing tails. The exported build reached its EXPORT-CHECK line and then hit
# the 180s wall, killing every branch that went through ralph-merge's
# rebase-and-dispatch path -- the export job only runs on `main` or a dispatch,
# so a branch could pass CI on push and fail on the identical tree minutes
# later. Measured from user://boot_log.txt at the time, a world build was
# 188s: water 137s, vegetation scatter 45s, everything else ~6s. 420 was the
# tourniquet raised against that number (EXP1, 2026-08-16): not a fix, just
# enough margin to stop the bleeding while the real fix (PERF2, water.gd's
# redundant noise stacks) landed.
#
# EXP1, re-measured 2026-08-17 after confirming PERF2 is on `main`: three
# back-to-back runs of THIS SCRIPT, this exact exported binary, this box.
# user://boot_log.txt world-build time (the same metric the 188s figure
# above used): 52s, 46s, 45s -- water is now ~20s (was 137s) and vegetation
# scatter ~12s (was 45s), matching PERF2's own fix plus, apparently, real
# margin against `road_polylines()`'s uncached per-candidate rebuild (PERF1,
# still unlanded) that a release export's optimizer absorbs better than the
# `--headless --script` debug-editor runs this project's other timing notes
# are usually measured with -- **the two are not comparable numbers.** The
# figure that actually matters here is the one `timeout` below wraps: total
# wall-clock of the xvfb+opengl3 process, `time`-measured directly, worst of
# three runs 69s (the other two: 65s, and the first run wasn't isolated).
# ~20s of that is engine/window/xvfb startup and teardown outside boot_log's
# own window, which the 188s-vs-180s figures above never separated out either.
#
# 150 is ~2.2x the measured 69s -- the same margin ratio the original 420-vs-
# 188 tourniquet used, on today's real number instead of a stale one. Drop it
# further only after PERF1 lands and this gets re-measured again; raise it
# back toward 420 without hesitation if a future measurement ever needs it --
# this number tracks the game, not the other way around.
#
# RAISED 150 -> 420, 2026-08-17, taking that last sentence at its word.
# VEG-CORRIDOR landed the corridor-wide scatter fill and the world went from
# 26,985 to 102,192 instances (3.79x); the exported build then died on this
# timeout at ~155s wall-clock having printed its own EXPORT-CHECK line with
# props=102007, i.e. it BOOTED fine and was killed before a clean exit. The
# guard did exactly its job -- it caught a real, intended, measured change in
# what the game is -- and the 69s it was calibrated against is now stale.
#
# VEG-SITING, 2026-08-18. Paying the debt the paragraph above left open.
# `HARVEST-ALL` and `VEG-CORRIDOR` together had already taken the corridor's
# instance count to 102,192; VEG-SITING's own trail-biased canopy siting (see
# scatter_rules.gd::_place_corridor_fill) adds another ~29k on top of that,
# to 131,515 -- the corridor-wide density this file's 420s was always an
# interim stand-in for. Worst of three runs of THIS EXACT COMMAND (the
# already-exported binary, this box, no re-export between runs -- same
# methodology EXP1 used): 191.7s, 192.8s, 194.4s. 420 was already only 2.16x
# the worst of those, thinner margin than EXP1's own 2.2x target and the
# reason this needed re-measuring rather than being left alone. 430 is
# 2.2x-of-194.4s (427.7s), rounded up. Re-measure again, the same way, if a
# future lane raises corridor density further -- do not assume 420-vs-430's
# old headroom still holds after another multiplier.
( cd "$OUT" && timeout 430 xvfb-run -a -s "-screen 0 640x480x24" \
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
#
# EXP1, 2026-08-17: this used to pipe `strings` straight into `grep -qF` per
# path, three times, and under this script's own `set -o pipefail` that is a
# real bug, not a flake -- `grep -q` exits the instant it finds a match,
# SIGPIPEs the still-running `strings`, and pipefail then reports the
# pipeline's status as `strings`' 141 (killed by SIGPIPE) instead of grep's 0,
# even though the match WAS found. Reproduced deterministically on this file
# (552MB pck, three-for-three) with `bash -c 'set -o pipefail; strings -a
# FILE | grep -qF PATTERN; echo "${PIPESTATUS[@]}"'` printing `141 0`. Scan
# once into a file instead of piping into a short-circuiting consumer three
# times -- correct AND faster (one full scan of the pck instead of three).
STRINGS_OUT="$OUT/pck_strings.txt"
strings -a "$OUT/Tetherbound.pck" > "$STRINGS_OUT"
for path in "data/terrain/playground" "data/config/art.json" "data/creatures/species.json"; do
  if ! grep -qF "$path" "$STRINGS_OUT"; then
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
