#!/usr/bin/env bash
# Run every smoke test, HEADLESS, and assert each one's own success line.
#
#   tools/run_smokes.sh [godot-binary]
#
# TWO mistakes are baked out of this script, both of which cost a full session.
#
# 1. RUN THEM HEADLESS. Every smoke's docstring says `godot --headless`, and
#    running them under xvfb with `--rendering-driver opengl3` instead makes
#    them render all ~18,000 scattered props for every one of the 10,800
#    physics frames smoke_traversal simulates. Measured: traversal took over
#    2400s under rendering and did not finish its second leg; headless it
#    passes in 191s. All seven together take about 200s. Nothing in these tests
#    looks at a pixel — the surveys do that, and they are a separate tool.
#
# 2. ASSERT THE POSITIVE. Grepping the output for "FAIL" and finding none is
#    NOT a pass: a test killed by `timeout` prints nothing at all and looks
#    identical to a clean run. Four smokes were reported green on exactly that
#    reasoning while they were in fact timing out. So this checks the exit code
#    AND the test's own "OK" line, and it is an error for either to be missing.
set -uo pipefail

GODOT="${1:-${GODOT:-/opt/godot/godot}}"
cd "$(dirname "$0")/.."

# `smoke_build` was written, committed and then never listed here, so for two
# milestones the build system's only automated check was one nobody ran. Adding
# a smoke file is not adding a smoke; the list is the runner, and a file missing
# from it fails in exactly the way this script's header warns about — silently,
# and looking identical to a pass.
SMOKES=(smoke_art smoke_playground smoke_input smoke_traversal smoke_combat smoke_catching smoke_aggression smoke_build smoke_persistence)
failed=0

# EVERY SMOKE STARTS FROM A NEW INSTALL.
#
# This was free until `scripts/world/save_director.gd` existed, because nothing
# in the shipping game ever loaded a save and a leftover `user://save_0.json`
# could not reach a running world. The game now restores slot 0 at boot and
# autosaves when a fight ends or a piece is placed, which means smoke_combat
# leaves a save behind and smoke_catching then boots into it — a party with a
# caught rabbit in it, at whatever HP the previous smoke left, deciding the
# outcome of a fight the next smoke thinks it set up itself.
#
# Nothing failed when that was measured. That is not reassuring: it makes the
# suite's result depend on the ORDER it ran in and on what the last run left on
# disk, which is precisely the "looks identical to a pass" failure this script's
# header exists to prevent. `smoke_build` already wiped the save for its own
# sake; this does it for all of them.
#
# `user://` is not reachable from bash, so it is reconstructed here. If the guess
# is wrong the wipe silently stops wiping — the exact dead-cleanup-step bug
# smoke_build's SAVE_PATH comment records — so a missing directory is reported
# rather than shrugged at.
if [[ -n "${APPDATA:-}" ]]; then
	USER_DATA="$APPDATA/Godot/app_userdata/Tetherbound"
else
	USER_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/godot/app_userdata/Tetherbound"
fi
if [[ ! -d "$USER_DATA" ]]; then
	echo "  note  no user data dir at $USER_DATA; smokes will run against whatever is there"
fi

for s in "${SMOKES[@]}"; do
	rm -f "$USER_DATA"/save_*.json
	start=$(date +%s)
	out="$("$GODOT" --headless --path . --script "tests/$s.gd" 2>&1)"
	code=$?
	elapsed=$(( $(date +%s) - start ))
	# Each smoke prints its own sentence; they do not share one format.
	line="$(printf '%s' "$out" | grep -E ': OK|smoke: OK' | head -1)"
	if [[ $code -ne 0 || -z "$line" ]]; then
		failed=$((failed + 1))
		printf '  FAIL  %-20s exit=%d %ds\n' "$s" "$code" "$elapsed"
		printf '%s' "$out" | grep -E 'FAIL|SCRIPT ERROR' | head -5 | sed 's/^/         /'
	else
		printf '  ok    %-20s %3ds  %s\n' "$s" "$elapsed" "$line"
	fi
done

echo
if [[ $failed -gt 0 ]]; then
	echo "$failed of ${#SMOKES[@]} smokes failed"
	exit 1
fi
echo "${#SMOKES[@]} smokes passed"
