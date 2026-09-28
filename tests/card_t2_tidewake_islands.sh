#!/usr/bin/env bash
# Chapter exit card T2 "Tidewake islands, fights and art" (docs/ACCEPTANCE.md §6).
# Runs the card's feeder sequence at ONE checkout SHA and writes one results
# table (results.tsv) plus one log per step into the evidence directory.
#
#   tests/card_t2_tidewake_islands.sh [--out=DIR] [--only=step,step]
#
#   islands   tests/smoke_tidewake_dry_run.gd: every Tidewake segment by controller
#             input, the same five, no mount; save / reset / load after each (F13#0)
#   loops     tests/smoke_water_loops_shortcuts.gd: four land loops, three shortcuts (F13#1)
#   pockets   tests/smoke_water_pocket_walk_claim.gd --real-tidecoil: eight pockets
#             walked and paid (F13#2)
#   chains    tests/smoke_tidewake_b_chain_route.gd --continuous: six local chains in
#             one run with real swims, then save / reset / load and re-greeting (F13#3)
#   ledgers   tests/smoke_tidewake_b_route_depletion.gd + the four-character ledger
#             unit: supplies solvent without a new catch or repeated wild (F13#4)
#   currents  tests/smoke_tidewake_b_current_restore.gd + current-flow unit (F14#2)
#   guardian  per-participant Guardian units (F14#3-#5)
#   named_c2  tests/smoke_water_named_c2c3.gd, 24 seeds x 3 starters: Tess, Calder
#             and Venn against the option-(c) top-fight bar; Aquaryn and Tidecoil
#             against the named-wild ruling (F14#0 C2)
#
# Not in this script, and cited from their own evidence folders:
#   - Nerissa's in-world C2 (render.yml cells, tests/batch_tidewake_named_inworld_c2.gd);
#   - the C3 captures and their fixed-rubric judges
#     (ralph/reports/TIDEWAKE/phase1/C3_RUBRIC.md);
#   - the 1920x1080 opengl3 device-profile frames and their code-blind 7-inch
#     readability verdict.
#
# Serial on purpose (shared 4-core box). Each step gets its own XDG_DATA_HOME.
set -uo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="$repo/ralph/reports/TIDEWAKE/phase1/card_t2"
only=""
for arg in "$@"; do
	case "$arg" in
		--out=*) out="${arg#--out=}" ;;
		--only=*) only=",${arg#--only=}," ;;
		*) echo "unknown argument $arg" >&2; exit 2 ;;
	esac
done
godot="${GODOT:-godot}"
mkdir -p "$out"
sha="$(git -C "$repo" rev-parse HEAD)"
dirty="$(git -C "$repo" status --porcelain --untracked-files=no | wc -l)"
echo "$sha dirty_tracked_files=$dirty" > "$out/SHA.txt"
[ -f "$out/results.tsv" ] || printf 'step\texit\telapsed_s\tsha\tlast_verdict_line\tlog\n' > "$out/results.tsv"

run() { # run <step-name> <timeout-s> <command...>
	local name="$1" limit="$2"
	shift 2
	if [ -n "$only" ] && [[ "$only" != *",$name,"* ]]; then
		return
	fi
	local log="$out/$name.log" data started code verdict
	data="$(mktemp -d)"
	started="$(date +%s)"
	echo "== $name: $*" | tee "$log"
	(cd "$repo" && XDG_DATA_HOME="$data" timeout "${limit}s" "$@") >> "$log" 2>&1
	code=$?
	verdict="$(grep -E 'OK|PASS|FAIL|passed|failed|failures|checks|Summary|RESULT|WATER_C2C3 done' "$log" | grep -v '^== ' | tail -1 | tr '\t' ' ' | cut -c1-240)"
	printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$code" "$(( $(date +%s) - started ))" "${sha:0:10}" "$verdict" "${log#$repo/}" >> "$out/results.tsv"
	echo "== $name exit=$code" | tee -a "$log"
	rm -rf "$data"
}

G=("$godot" --headless --path .)
F=("$godot" --headless --path . --fixed-fps 60)
run islands 7200 "${G[@]}" --script tests/smoke_tidewake_dry_run.gd
run loops 3600 "${G[@]}" --script tests/smoke_water_loops_shortcuts.gd
run pockets 3600 "${F[@]}" --script tests/smoke_water_pocket_walk_claim.gd -- --real-tidecoil
run chains 10800 "${G[@]}" --script tests/smoke_tidewake_b_chain_route.gd -- --continuous
run ledgers 3600 "${G[@]}" --script tests/smoke_tidewake_b_route_depletion.gd
run ledger_units 900 "${G[@]}" --script tests/run_tests.gd -- --only=test_tidewake_b_four_character_ledger.gd
run currents 1800 "${G[@]}" --script tests/smoke_tidewake_b_current_restore.gd
run current_units 900 "${G[@]}" --script tests/run_tests.gd -- --only=test_water_current_flow_states.gd
run guardian_units 900 "${G[@]}" --script tests/run_tests.gd -- --only=test_legendary_per_participant.gd,test_water_guardian_legacy.gd,test_water_guardian_solo_win.gd
run named_c2 10800 "${F[@]}" --script tests/smoke_water_named_c2c3.gd -- --seeds=24 --case=tess,calder,venn,aquaryn,tidecoil --party-level=43 --json="$out/named_c2.json"
