#!/usr/bin/env bash
# Routes piece driver (F49#0). One Godot at a time; each piece loads the previous piece's out dir.
#   RB=~/rb PIECE_TIMEOUT=43200 tools/earned_saves/routes_kit/chain.sh <start dir|none> <step>...
#   step = runner:segment:name   runner: gen (generate_boundary_save, segment = profile)
#                                        cr (cloudreach_chain_runner)  tw (tidewake_piece_runner, incl. training_tN_*)
#                                        sw (stormwood_chain_runner)
#                                        ea (earned_chain_runner, generated-origin Meadows lineage: relay/sigils/hall/warden/tidewake_handoff)
# Writes $RB/<name>/ (save/, receipt.json) and $RB/<name>.log; prints START/END/STOP lines. Skips a step whose out dir has a receipt.
# Run detached: nohup setsid chain.sh ... > $RB/x_chain.out 2>&1 < /dev/null & disown
# The checkout must stay clean and at one SHA for the whole run (runners refuse a dirty tree; altar pieces need their
# predecessor's exact SHA): edit and commit in a separate worktree, never in the run checkout.
set -u
RB="${RB:-$HOME/rb}"; REPO="$(cd "$(dirname "$0")/../../.." && pwd)"; cd "$REPO"
prev="$1"; shift
for step in "$@"; do
  IFS=: read -r runner seg name <<<"$step"
  out="$RB/$name"; log="$RB/$name.log"
  if [[ -f "$out/receipt.json" || -f "$out/$seg/receipt.json" || ( "$runner" == gen && -d "$out" ) ]]; then echo "SKIP $name"; prev="$out"; [[ $runner == ea ]] && prev="$out/$seg"; continue; fi
  rm -rf "$out"
  echo "START $name $seg $(date -u +%FT%TZ) sha=$(git rev-parse --short HEAD)"; t0=$(date +%s)
  case $runner in
    gen) args=(--script tools/earned_saves/generate_boundary_save.gd -- --profile="$seg" --slot=0 --out="$out");;
    cr) args=(--script tools/earned_saves/cloudreach_chain_runner.gd -- --segment="$seg" --from="$prev" --out="$out");;
    tw) args=(--script tools/earned_saves/tidewake_piece_runner.gd -- --segment="$seg" --from="$prev" --out="$out");;
    sw) args=(--script tools/earned_saves/stormwood_chain_runner.gd -- --segment="$seg" --from="$prev" --out="$out");;
    ea) h=(); [[ "$prev" != none ]] && h=(--handoff-from="$prev")
        args=(--script tools/earned_saves/earned_chain_runner.gd -- --segment="$seg" --save-dir="$out/$seg/save" --receipt="$out/$seg/receipt.json" "${h[@]}" --generated-fixture);;
  esac
  timeout "${PIECE_TIMEOUT:-21600}" godot --headless --fixed-fps 60 --path . "${args[@]}" > "$log" 2>&1
  code=$?; echo "END $name exit=$code wall=$(( $(date +%s)-t0 ))s"
  grep -E "PIECE RESULT|CHAIN RESULT|BOUNDARY SAVE" "$log" | tail -1 | cut -c1-600
  if [[ $code != 0 ]]; then echo "STOP at $name (last good $prev)"; exit 1; fi
  prev="$out"; [[ $runner == ea ]] && prev="$out/$seg"
done
echo COMPLETE
