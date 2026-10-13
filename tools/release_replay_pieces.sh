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
REPO="$(cd "$(dirname "$0")/.." && pwd)"; F="$REPO/tests/fixtures/earned_saves"
BIN="${RELEASE_BIN:-$REPO/build/linux/Tetherbound.x86_64}"
declare -A FROM
if [[ $REGION == tidewake ]]; then
  RUNNER=res://tools/earned_saves/tidewake_piece_runner.gd; MARK="TIDEWAKE PIECE RESULT"
  FROM=([01_opening]=tidewake_arrival_generated [02_reedhaven]=tidewake_01_opening
    [03_brine]=tidewake_02_reedhaven [04_shellwatch]=tidewake_03_brine [05_tidal]=tidewake_04_shellwatch
    [07_human_late]=tidewake_05_tidal [07a_salt_bex]=tidewake_05_tidal
    [07b_calder_venn]=@07a_salt_bex [07c_nerissa]=@07b_calder_venn [08_ending]=tidewake_07_human_late)
  DEFAULT=(02_reedhaven 03_brine 04_shellwatch 05_tidal 07a_salt_bex 07b_calder_venn 07c_nerissa 08_ending)
else
  RUNNER=res://tools/earned_saves/cloudreach_chain_runner.gd; MARK="CLOUDREACH PIECE RESULT"
  FROM=([01_arrival_gate]=cloudreach_arrival_generated [02_broken_causeways]=cloudreach_01_arrival_gate
    [03_flight_training]=cloudreach_02_broken_causeways [04_high_roost]=cloudreach_03_flight_training
    [05_stronghold]=cloudreach_04_high_roost [06_veyra_relay]=cloudreach_05_generated_veyra_boundary
    [07_stormward_handoff]=cloudreach_06_veyra_relay)
  DEFAULT=(01_arrival_gate 02_broken_causeways 03_flight_training 04_high_roost 05_stronghold 06_veyra_relay 07_stormward_handoff)
fi
PIECES=("$@"); [[ ${#PIECES[@]} == 0 ]] && PIECES=("${DEFAULT[@]}")
mkdir -p "$ROOT"; failed=0
for piece in "${PIECES[@]}"; do
  out="$ROOT/$piece"
  if [[ -z ${FROM[$piece]+set} || -e $out ]]; then
    echo "REPLAY $REGION $piece FAIL unknown piece or existing output"; failed=1; break
  fi
  from="$F/${FROM[$piece]}"
  if [[ ${FROM[$piece]} == @* ]]; then from="$ROOT/${FROM[$piece]#@}"; fi
  if [[ $REGION == tidewake && $piece == 08_ending && -f $ROOT/07c_nerissa/receipt.json ]]; then
    from="$ROOT/07c_nerissa"
  fi
  if [[ ! -d $from/save ]]; then
    echo "REPLAY $REGION $piece FAIL missing saved predecessor $from"; failed=1; break
  fi
  user=$(mktemp -d); started=$(date +%s)
  (cd "$REPO/build/linux" && XDG_DATA_HOME="$user" timeout "${PIECE_TIMEOUT:-1800}" "$BIN" --headless -- \
    --release-route=$RUNNER --segment=$piece --from="$from" --out="$out") > "$ROOT/$piece.log" 2>&1
  code=$?; secs=$(( $(date +%s) - started )); rm -rf "$user"
  result=$(grep -E "$MARK" "$ROOT/$piece.log" | tail -1)
  if [[ $code == 0 ]] && [[ $result == *'"passed":true'* ]] && ! grep -q "SCRIPT ERROR" "$ROOT/$piece.log"; then
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
