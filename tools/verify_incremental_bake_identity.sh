#!/usr/bin/env bash
# Prove the per-region bake is identical to itself, region by region.
#
#   tools/verify_incremental_bake_identity.sh [godot-binary]
#
# `build_playground_terrain.gd` bakes every pixel from `(config, world_x,
# world_z)` alone -- no pixel reads a neighbour, there is no blur/erosion/flow
# pass. That is the claim the region-set feature depends on: a sub-rectangle
# baked in isolation must come out identical to what baking it as part of a
# larger run would have written there. This is the test of that claim, not
# an assertion that it holds.
#
# Method: take two ADJACENT regions from the real, committed
# data/config/terrain_playground.json (so this exercises the actual shipped
# config, not a synthetic stand-in). Bake both together into one scratch
# directory ("as part of a bake"). Bake the second one ALONE into a second
# scratch directory. Compare that region's DECODED content (height_range,
# height_map, control_map, color_map pixels) between the two runs via
# `tools/_probe_ow5b_region_content_diff.gd`.
#
# NOT a raw byte/`cmp` comparison of the two `.res` files -- an earlier
# version of this script did that and failed, 3297 of 331558 bytes differing
# from right where the region's compressed image payload starts. That looked
# like proof of neighbour-dependence. It was not: baking the SAME single
# region twice, in two runs that never involved any other region, produced
# two files differing in content bytes AND total size, while their DECODED
# maps were pixel-for-pixel identical. Terrain3D's on-disk serialization
# (most likely the compression step -- the divergent byte is always right at
# a ZSTD frame's magic number) is not byte-reproducible run to run; the data
# it encodes is. So this compares the data, which is the thing the region-set
# feature actually promises.
#
# Deliberately does NOT touch data/terrain/playground or
# data/config/terrain_playground.json. Both scratch directories are deleted
# on exit, success or failure.
#
# Exit codes: 0 identical, 1 differ or something failed to bake and the
# message says what.
set -uo pipefail

GODOT="${1:-${GODOT:-godot}}"
cd "$(dirname "$0")/.."

# Two adjacent regions inside the corridor's own bounds (x[-1024,1024]
# z[-512,7680] at 512m pitch => columns -2..1, rows -1..14). (-2,-1) is the
# world's own SW corner region -- picked for no reason other than "definitely
# in bounds and definitely adjacent to another in-bounds region."
PAIR="-2:-1,-1:-1"
SOLO="-1:-1"
PAIR_DIR="res://data/terrain/_probe_identity_pair"
SOLO_DIR="res://data/terrain/_probe_identity_solo"
PAIR_ABS="$(pwd)/data/terrain/_probe_identity_pair"
SOLO_ABS="$(pwd)/data/terrain/_probe_identity_solo"
# Terrain3D's own naming for region_location (col=-1, row=-1): a negative
# axis gets a bare sign ("-01"), a non-negative axis gets a leading underscore
# ("_00") -- confirmed against the 4 files data/terrain/playground already
# has today (terrain3d-01-01.res, terrain3d-01_00.res, terrain3d_00-01.res,
# terrain3d_00_00.res, for locations (-1,-1) (-1,0) (0,-1) (0,0)).
REGION_FILE="terrain3d-01-01.res"

cleanup() {
  rm -rf "$PAIR_ABS" "$SOLO_ABS"
}
trap cleanup EXIT

rm -rf "$PAIR_ABS" "$SOLO_ABS"

echo "baking regions $PAIR together into $PAIR_DIR ..."
"$GODOT" --headless --path . --script scripts/world/build_playground_terrain.gd \
  -- "--regions=$PAIR" "--data-dir=$PAIR_DIR" >/tmp/bake_identity_pair.log 2>&1
if [ ! -f "$PAIR_ABS/$REGION_FILE" ]; then
  echo "verify FAILED: paired bake did not produce $REGION_FILE -- see /tmp/bake_identity_pair.log"
  tail -40 /tmp/bake_identity_pair.log
  exit 1
fi

echo "baking region $SOLO alone into $SOLO_DIR ..."
"$GODOT" --headless --path . --script scripts/world/build_playground_terrain.gd \
  -- "--regions=$SOLO" "--data-dir=$SOLO_DIR" >/tmp/bake_identity_solo.log 2>&1
if [ ! -f "$SOLO_ABS/$REGION_FILE" ]; then
  echo "verify FAILED: solo bake did not produce $REGION_FILE -- see /tmp/bake_identity_solo.log"
  tail -40 /tmp/bake_identity_solo.log
  exit 1
fi

echo "comparing decoded content ..."
"$GODOT" --headless --path . --script tools/_probe_ow5b_region_content_diff.gd \
  -- "$PAIR_DIR/$REGION_FILE" "$SOLO_DIR/$REGION_FILE"
RESULT=$?

if [ "$RESULT" -eq 0 ]; then
  echo "IDENTICAL: region $SOLO baked as part of a 2-region run == baked alone (decoded content)"
else
  echo "verify FAILED: region $SOLO's decoded content differs between the paired bake and the solo bake."
  echo "incremental baking is UNSAFE -- some pixel is not a pure function of (config, world_x, world_z)."
fi
exit "$RESULT"
