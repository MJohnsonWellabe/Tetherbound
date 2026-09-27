#!/usr/bin/env bash
# Chapter exit card T1 "Tidewake retained-five water route" (docs/ACCEPTANCE.md).
# Runs the card's fixed sequence at ONE checkout SHA and writes one results
# table (results.tsv) plus one log per step into the evidence directory.
#
#   tests/card_t1_tidewake_retained_five.sh [--stage=card|chain|regress|net|all] [--out=DIR]
#
#   card     tests/card_t1_tidewake_retained_five.gd: the integrated run
#            (declared Water arrival -> original five, no swimmer -> mount refused
#            -> every sheltered mandatory hop from the arrival -> mid-swim fight
#            pause -> drowning -> safe-shore recovery -> mid-water save/reload ->
#            continue to land)
#   chain    the four main-path direct alternatives (tests/smoke_water_hop_walked.gd)
#   regress  the F12#1..#6 evidence smokes/units, rerun unchanged
#   net      the F12 two-peer smokes and proofs, rerun unchanged
#
# Serial on purpose (shared 4-core box). Each step: its own XDG_DATA_HOME.
set -uo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
stage="all"
out="$repo/ralph/reports/TIDEWAKE/b/card_t1"
for arg in "$@"; do
	case "$arg" in
		--stage=*) stage="${arg#--stage=}" ;;
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
if [ "$stage" = card ] || [ "$stage" = all ]; then
	run card_integrated 5400 "${G[@]}" --script tests/card_t1_tidewake_retained_five.gd
fi
if [ "$stage" = chain ] || [ "$stage" = all ]; then
	run chain_direct_0_3 1800 "${G[@]}" --script tests/smoke_water_hop_walked.gd -- --variant=direct --from=0 --to=3
fi
if [ "$stage" = regress ] || [ "$stage" = all ]; then
	run f12_2_smoke_water_swimming 300 "${G[@]}" --script tests/smoke_water_swimming.gd
	run f12_2_smoke_water_swimming_original_five 300 "${G[@]}" --script tests/smoke_water_swimming.gd -- --original-five
	run f12_2_smoke_water_player_death 200 "${G[@]}" --script tests/smoke_water_player_death.gd
	run f12_1_smoke_water_combat_pause 400 "${G[@]}" --script tests/smoke_water_combat_pause.gd
	run f12_3_smoke_water_mounted_swimming 300 "${G[@]}" --script tests/smoke_water_mounted_swimming.gd
	run f12_3_smoke_water_dismount_state 300 "${G[@]}" --script tests/smoke_water_dismount_state.gd
	run f12_4_smoke_water_reconnect_save 200 "${G[@]}" --script tests/smoke_water_reconnect_save.gd
	run f12_4_smoke_water_mounted_reconnect_save 200 "${G[@]}" --script tests/smoke_water_mounted_reconnect_save.gd
	run f12_6_smoke_water_closed_gate_seal 400 "${G[@]}" --script tests/smoke_water_closed_gate_seal.gd
	run f12_6_smoke_water_sealed_anchor_reload 300 "${G[@]}" --script tests/smoke_water_sealed_anchor_reload.gd
	run f12_units 900 "${G[@]}" --script tests/run_tests.gd -- \
		--only=test_water_closed_gate_seals.gd,test_water_recovery_closed_seals.gd,test_water_mount_dismount_replication.gd,test_water_mounted_replication.gd,test_swim_state.gd,test_water_traversal_save.gd
fi
if [ "$stage" = net ] || [ "$stage" = all ]; then
	run net_water_swimming 900 tools/net/run_net_smoke.sh water_swimming --out="$out/net/water_swimming"
	run net_water_mounted_swimming 900 tools/net/run_net_smoke.sh water_mounted_swimming --out="$out/net/water_mounted_swimming"
	run proof_f12_combat_pause_two_peer 2500 tools/net/run_two_peer_proof.sh \
		tools/net/proof_scenarios/f12_combat_pause_two_peer.json --out="$out/proof/f12_combat_pause_two_peer"
	run proof_f12_remote_rider_identity_reconnect 1900 tools/net/run_two_peer_proof.sh \
		tools/net/proof_scenarios/f12_remote_rider_identity_reconnect.json --out="$out/proof/f12_remote_rider_identity_reconnect"
fi
cat "$out/results.tsv"
