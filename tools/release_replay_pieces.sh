#!/usr/bin/env bash
# ACCEPTANCE §7 release reliability, solo pieces on the EXPORTED binary
# (WORKFLOW §8.1 rule 9: proven in pieces, each from its committed handoff save).
#   tools/release_replay_pieces.sh <tidewake|cloudreach> <out root> [piece ...]
# Each piece runs in a fresh exported process with an isolated user dir
# (XDG_DATA_HOME), entered through the title's --release-route (f26_export_bootstrap).
# Prints one "REPLAY <region> <piece> PASS|FAIL <seconds>" line per piece and
# retains each saved checkpoint so split successors load exactly that state.
set -u
REGION="${1:?tidewake|cloudreach}"; ROOT="${2:?out root}"; shift 2
if [[ $REGION != tidewake && $REGION != cloudreach ]]; then
  echo "Unknown region: $REGION (expected tidewake|cloudreach)" >&2; exit 2
fi
REPO="$(cd "$(dirname "$0")/.." && pwd)"; F="$REPO/tests/fixtures/earned_saves"
BIN="${RELEASE_BIN:-$REPO/build/linux/Tetherbound.x86_64}"
# Resolve before the exported process changes directory. A relative output
# root otherwise names different checkpoints to the runner and this shell.
ROOT=$(python3 -c 'import pathlib,sys; print(pathlib.Path(sys.argv[1]).resolve())' "$ROOT") || exit 2
BIN=$(python3 -c 'import pathlib,sys; print(pathlib.Path(sys.argv[1]).resolve())' "$BIN") || exit 2
LIMIT="${PIECE_TIMEOUT:-1800}"
if [[ ! $LIMIT =~ ^[0-9]+$ ]] || (( LIMIT < 1 || LIMIT > 1800 )); then
  echo "PIECE_TIMEOUT must be 1..1800 seconds; split longer work at a saved checkpoint" >&2; exit 2
fi
declare -A FROM
if [[ $REGION == tidewake ]]; then
  RUNNER=res://tools/earned_saves/tidewake_piece_runner.gd; MARK="TIDEWAKE PIECE RESULT"
  FROM=([01_opening]=tidewake_arrival_generated [02_reedhaven]=tidewake_01_opening
    [03_brine]=tidewake_02_reedhaven [04_shellwatch]=tidewake_03_brine [05_tidal]=tidewake_04_shellwatch
    [07a_salt_bex]=tidewake_05_tidal [07b_calder]=@07a_salt_bex
    [07c_venn]=@07b_calder [07d_nerissa]=@07c_venn [08_ending]=@07d_nerissa)
  DEFAULT=(02_reedhaven 03_brine 04_shellwatch 05_tidal 07a_salt_bex 07b_calder 07c_venn 07d_nerissa 08_ending)
else
  RUNNER=res://tools/earned_saves/cloudreach_chain_runner.gd; MARK="CLOUDREACH PIECE RESULT"
  FROM=([01_arrival_gate]=cloudreach_arrival_generated [02_broken_causeways]=cloudreach_01_arrival_gate
    [03_flight_training]=cloudreach_02_broken_causeways [04_high_roost]=cloudreach_03_flight_training
    [05_stronghold]=cloudreach_04_high_roost [06_veyra_relay]=cloudreach_05_generated_veyra_boundary
    [07_stormward_handoff]=cloudreach_06_veyra_relay)
  DEFAULT=(01_arrival_gate 02_broken_causeways 03_flight_training 04_high_roost 05_stronghold 06_veyra_relay 07_stormward_handoff)
fi
PIECES=("$@"); [[ ${#PIECES[@]} == 0 ]] && PIECES=("${DEFAULT[@]}")
mkdir -p "$ROOT" || exit 1
failed=0
for piece in "${PIECES[@]}"; do
  out="$ROOT/$piece"
  if [[ $REGION == tidewake && $piece == 07_human_late ]]; then
    echo "REPLAY FAIL combined route retired: use 07a_salt_bex 07b_calder 07c_venn 07d_nerissa"; failed=1; break
  fi
  if [[ -z ${FROM[$piece]+set} || -e $out ]]; then
    echo "REPLAY $REGION $piece FAIL unknown piece or existing output"; failed=1; break
  fi
  from="$F/${FROM[$piece]}"
  if [[ ${FROM[$piece]} == @* ]]; then from="$ROOT/${FROM[$piece]#@}"; fi
  if [[ ! -d $from/save ]]; then
    echo "REPLAY $REGION $piece FAIL missing saved predecessor $from"; failed=1; break
  fi
  if [[ ${FROM[$piece]} == @* ]]; then
    python3 "$REPO/tools/earned_saves/validate_piece_receipt.py" "$from" "${FROM[$piece]#@}" || { failed=1; break; }
  fi
  user=$(mktemp -d); started=$(date +%s)
  (cd "$REPO/build/linux" && XDG_DATA_HOME="$user" timeout "$LIMIT" "$BIN" --headless -- \
    --release-route=$RUNNER --segment=$piece --from="$from" --out="$out") > "$ROOT/$piece.log" 2>&1
  code=$?; secs=$(( $(date +%s) - started )); rm -rf "$user"
  result=$(grep -E "$MARK" "$ROOT/$piece.log" | tail -1)
  if [[ $code == 0 ]] && [[ $result == *'"passed":true'* ]] && ! grep -q "SCRIPT ERROR" "$ROOT/$piece.log" \
      && python3 "$REPO/tools/earned_saves/validate_piece_receipt.py" "$out" "$piece"; then
    echo "REPLAY $REGION $piece PASS ${secs}s"
  else
    echo "REPLAY $REGION $piece FAIL ${secs}s exit=$code ${result:0:400}"; failed=1
  fi
  [[ -f $out/receipt.json ]] && cp "$out/receipt.json" "$ROOT/$piece.receipt.json"
  # Keep successful saves and failed diagnostics; no successor may silently
  # fall back to a generated boundary when its earned predecessor failed.
  [[ $failed == 0 ]] || break
done
exit $failed
