#!/usr/bin/env bash
# F19#5 Tidewake checkpoint chain. Runs tidewake_piece_runner.gd once per
# segment (fresh process), each loading the previous checkpoint's save, and
# writes tests/fixtures/earned_saves/tidewake_<nn>_<slug>/{save,receipt.json,PROVENANCE.json}.
#   tools/earned_saves/run_tidewake_chain.sh [first_segment] [start_dir] [log_dir]
set -u
REPO="$(cd "$(dirname "$0")/../.." && pwd)"; cd "$REPO"
GODOT="${GODOT:-godot}"
# Critical path with the same five. 06_swimmer/07_late (optional swim mount)
# are a recorded GAP: the saddle routes to the homestead Workbench (RD-15).
SEGS=(01_opening 02_reedhaven 03_brine 04_shellwatch 05_tidal 07a_salt_bex 07b_calder 07c_venn 07d_nerissa 08_ending)
FIRST="${1:-01_opening}"; F=tests/fixtures/earned_saves
if [[ ! " ${SEGS[*]} " == *" $FIRST "* ]]; then
  echo "Unknown/retired first segment; use the saved 07a/07b/07c/07d split pieces" >&2; exit 2
fi
LIMIT="${CHAIN_TIMEOUT:-1800}"
if [[ ! $LIMIT =~ ^[0-9]+$ ]] || (( LIMIT < 1 || LIMIT > 1800 )); then
  echo "CHAIN_TIMEOUT must be 1..1800 seconds; split longer work" >&2; exit 2
fi
START="${2:-$F/tidewake_arrival_generated}"; LOGS="${3:-/tmp/tidewake_chain_logs}"
mkdir -p "$LOGS"; prev=""; started=0
for seg in "${SEGS[@]}"; do
  if [[ $seg == "$FIRST" ]]; then started=1; fi
  if [[ $started == 0 ]]; then prev="$F/tidewake_$seg"; continue; fi
  from="${prev:-$START}"; out="$F/tidewake_$seg"
  echo "CHAIN START $seg from=$from $(TZ=America/Chicago date '+%F %T CT')"
  cmd="$GODOT --headless --path . --script tools/earned_saves/tidewake_piece_runner.gd -- --segment=$seg --from=$REPO/$from --out=$REPO/$out"
  timeout "$LIMIT" $cmd > "$LOGS/$seg.log" 2>&1; code=$?
  grep -E "TIDEWAKE PIECE RESULT" "$LOGS/$seg.log" | tail -1
  if [[ $code != 0 ]] || grep -q "SCRIPT ERROR" "$LOGS/$seg.log" || [[ ! -f $out/receipt.json ]]; then
    echo "CHAIN STOP $seg exit=$code"; exit 1; fi
  python3 - "$out" "$from" "$seg" "$cmd" "$(git rev-parse HEAD)" <<'P'
import json,sys
out,frm,seg,cmd,commit=sys.argv[1:]
r=json.load(open(out+"/receipt.json"))
json.dump({"kind":"tidewake_checkpoint","criterion":"F19#5","segment":seg,"command":cmd,"commit":commit,
 "start_save":frm,"lineage_root":"tests/fixtures/earned_saves/tidewake_arrival_generated (generated arrival, prior_earned_play=false)",
 "injections":[],"shortcuts":r.get("disclosures",[]),"passed":r["passed"],
 "chain_disclosures":["Order 03_brine then 04_shellwatch: the Shellwatch helper continues from Tovin's Brine victory",
  "06_swimmer catches a swimmer and releases one of the five (helper design), so UIDs change at 06; the handoff check compares each save with the next segment's Load",
  "07_late remounts the 06 swimmer by the late helper's own input step: a mount is not saved",
  "Water helpers accept the F32 renewable stock receipt in place of the legacy harvest flag (coordinator-approved)",
  "06_swimmer (optional swim mount + saddle) skipped as a recorded GAP (coordinator-agreed): WORLD §6 owner retained-team override; the saddle routes to the homestead Workbench (RD-15, HOMESTEAD §2) and the helper is stale; the critical path runs 07a_salt_bex through 07d_nerissa with the same five",
  "Start lineage is the generated tidewake arrival, not an earned Meadows end save",
  "03_brine: Tovin fight bound raised 180 s wall to 600 s SIM (coordinator-approved duration budget; victory still required): generated L20 ground belt, terrapup lead 0.8x vs water; actual fight length is the 'Tovin fight length' note in receipt.json helper_receipts",
  "Every Tidewake helper trainer/alpha fight bound (Shellwatch _fight_trainer, Tidal Aquaryn, late fight_bound_ms) is a 600 s SIM duration budget (coordinator-approved); victory still required; each fight's length is a '<id> fight length N s sim' note in receipt.json helper_receipts"]},open(out+"/PROVENANCE.json","w"),indent=2)
P
  echo "CHAIN DONE $seg $(TZ=America/Chicago date '+%F %T CT')"; prev="$out"
done
echo "CHAIN COMPLETE"
