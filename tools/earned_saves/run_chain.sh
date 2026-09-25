#!/usr/bin/env bash
# Earned C1 chain driver. See tools/earned_saves/earned_chain_runner.gd header.
#   tools/earned_saves/run_chain.sh <seed> <chain_root> [first_segment]
# Each segment copies the previous segment's save into its own dir, runs one
# Godot process through the shared memory limiter, and stops the chain on the
# first failure (the previous segment's dir remains the last good save).
set -u
SEED="${1:?seed}"; ROOT="${2:?chain root}"; FIRST="${3:-opening_team}"
GODOT="${GODOT:-$HOME/godot-bin/godot}"
SLOT_WRAPPER="${SLOT_WRAPPER:-/tmp/claude-0/godot_slot.sh}"
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
SEGMENTS=(opening_team camp_tournament bridge warrens relay hall warden)
mkdir -p "$ROOT"
started=0; prev=""
for seg in "${SEGMENTS[@]}"; do
  if [[ "$seg" == "$FIRST" ]]; then started=1; fi
  if [[ $started == 0 ]]; then prev="$seg"; continue; fi
  dir="$ROOT/$seg"
  rm -rf "$dir"; mkdir -p "$dir"
  if [[ -n "$prev" ]]; then
    [[ -d "$ROOT/$prev/save" ]] || { echo "CHAIN missing previous save $ROOT/$prev/save"; exit 2; }
    cp -r "$ROOT/$prev/save" "$dir/save"
  else
    mkdir -p "$dir/save"
  fi
  echo "CHAIN START $seg $(date -u +%FT%TZ)"
  (cd "$REPO" && TB_WORLD_SEED="$SEED" timeout 5400 "$SLOT_WRAPPER" "$GODOT" --headless --path . \
     --script tools/earned_saves/earned_chain_runner.gd -- \
     --segment="$seg" --save-dir="$dir/save/" --receipt="$dir/receipt.json") > "$dir/log.txt" 2>&1
  code=$?
  grep -E "EARNED CHAIN RESULT" "$dir/log.txt" | tail -1
  if [[ $code != 0 ]] || grep -q "SCRIPT ERROR" "$dir/log.txt"; then
    echo "CHAIN STOP $seg exit=$code (last good save: ${prev:+$ROOT/$prev/save})"; exit 1
  fi
  echo "CHAIN DONE $seg $(date -u +%FT%TZ)"
  prev="$seg"
done
echo "CHAIN COMPLETE"
