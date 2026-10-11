#!/usr/bin/env bash
# F19#5 Cloudreach checkpoint chain. See tools/earned_saves/cloudreach_chain_runner.gd.
#   tools/earned_saves/run_cloudreach_chain.sh <start checkpoint dir> <out root> [first segment] [--accelerated]
# One fresh Godot process per segment; each loads the previous segment's save and
# stops the chain on the first failure (the previous dir stays the last good save).
set -u
START="${1:?start checkpoint dir}"; ROOT="${2:?out root}"; FIRST="${3:-01_arrival_gate}"; EXTRA="${4:-}"
GODOT="${GODOT:-godot}"
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
SEGMENTS=(01_arrival_gate 02_broken_causeways 03_flight_training 04_high_roost 05_stronghold 06_veyra_relay 07_stormward_handoff)
SLUGS=(arrival_gate broken_causeways flight_training high_roost stronghold veyra_relay stormward_handoff)
mkdir -p "$ROOT"
started=0; prev="$START"
for i in "${!SEGMENTS[@]}"; do
  seg="${SEGMENTS[$i]}"; dir="$ROOT/cloudreach_${seg}"
  if [[ "$seg" == "$FIRST" ]]; then started=1; fi
  if [[ $started == 0 ]]; then prev="$dir"; continue; fi
  echo "CHAIN START $seg $(TZ=America/Chicago date +%FT%T%Z)"
  (cd "$REPO" && timeout "${CHAIN_TIMEOUT:-7200}" "$GODOT" --headless --path . \
     --script tools/earned_saves/cloudreach_chain_runner.gd -- \
     --segment="$seg" --from="$prev" --out="$dir" $EXTRA) > "$ROOT/${seg}.log" 2>&1
  code=$?
  grep -E "CLOUDREACH PIECE RESULT" "$ROOT/${seg}.log" | tail -1 | cut -c1-600
  if [[ $code != 0 ]] || grep -q "SCRIPT ERROR" "$ROOT/${seg}.log"; then
    echo "CHAIN STOP $seg exit=$code (last good: $prev)"; exit 1
  fi
  echo "CHAIN DONE $seg $(TZ=America/Chicago date +%FT%T%Z)"
  prev="$dir"
done
echo "CHAIN COMPLETE"
