#!/usr/bin/env bash
# Chapter exit card T3 "Tidewake ending and continuation" (docs/ACCEPTANCE.md).
# Runs the card's fixed sequence at ONE checkout SHA and writes one results
# table (results.tsv) plus one log per step into the evidence directory.
#
#   tests/card_t3_tidewake_ending.sh [--out=DIR]
#
#   card     tools/net/proof_scenarios/card_t3_tidewake_ending.json: ONE two-peer run,
#            dock exchange settled once -> Guardian freed (host releases through the
#            real release menu at a full five, guest accepts with room) -> both cross
#            home -> Grandpa names each current team -> credits once each -> disk
#            reload -> safe completed world, repeat greeting, no sequel prompt
#   dock     F15 paid-debit crash/retry proofs (crash after send, after delta, commit
#            delta lost), rerun unchanged
#   return   tests/test_tidewake_return_cadence.gd: the measured physical return, A7
#   ending   tests/test_homecoming_ending_invariants.gd + tests/test_regional_homecoming.gd,
#            tests/smoke_regional_credits_reload.gd, and the real-save reload proof
#
# Serial on purpose (shared 4-core box). Each step: its own XDG_DATA_HOME.
set -uo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="$repo/ralph/reports/TIDEWAKE/full/card_t3"
for arg in "$@"; do
	case "$arg" in
		--out=*) out="${arg#--out=}" ;;
		*) echo "unknown argument $arg" >&2; exit 2 ;;
	esac
done
godot="${GODOT:-$HOME/godot-bin/godot}"
mkdir -p "$out"
sha="$(git -C "$repo" rev-parse HEAD)"
dirty="$(git -C "$repo" status --porcelain --untracked-files=no | wc -l)"
echo "$sha dirty_tracked_files=$dirty" > "$out/SHA.txt"
[ -f "$out/results.tsv" ] || printf 'step\texit\telapsed_s\tsha\tlast_verdict_line\tlog\n' > "$out/results.tsv"

run() { # run <step-name> <timeout-s> <command...>
	local name="$1" limit="$2"
	shift 2
	local log="$out/$name.log" data started code verdict
	data="$(mktemp -d)"
	started="$(date +%s)"
	echo "== $name: $*" | tee "$log"
	(cd "$repo" && XDG_DATA_HOME="$data" timeout "${limit}s" "$@") >> "$log" 2>&1
	code=$?
	verdict="$(grep -E 'OK|PASS|FAIL|passed|failed|failures|checks|Summary|RESULT' "$log" | grep -v '^== ' | tail -1 | tr '\t' ' ' | cut -c1-240)"
	printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$code" "$(( $(date +%s) - started ))" "${sha:0:10}" "$verdict" "${log#$repo/}" >> "$out/results.tsv"
	echo "== $name exit=$code" | tee -a "$log"
	rm -rf "$data"
}

G=("$godot" --headless --path .)
P=tools/net/run_two_peer_proof.sh
S=tools/net/proof_scenarios
run card_t3_two_peer 2700 "$P" "$S/card_t3_tidewake_ending.json" --out="$out/proof/card_t3_two_peer"
run f15_dock_crash_after_send 2000 "$P" "$S/f15_dock_crash_after_send.json" --out="$out/proof/f15_dock_crash_after_send"
run f15_dock_crash_after_delta 2000 "$P" "$S/f15_dock_crash_after_delta.json" --out="$out/proof/f15_dock_crash_after_delta"
run f15_dock_commit_delta_lost 2000 "$P" "$S/f15_dock_commit_delta_lost.json" --out="$out/proof/f15_dock_commit_delta_lost"
run f15_homecoming_real_save_reload 2000 "$P" "$S/f15_homecoming_real_save_reload.json" --out="$out/proof/f15_homecoming_real_save_reload"
run return_cadence 900 "${G[@]}" --script tests/run_tests.gd -- --only=test_tidewake_return_cadence.gd
run ending_units 900 "${G[@]}" --script tests/run_tests.gd -- --only=test_homecoming_ending_invariants.gd,test_regional_homecoming.gd
run credits_reload_smoke 600 "${G[@]}" --script tests/smoke_regional_credits_reload.gd
