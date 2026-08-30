#!/usr/bin/env bash
# Measure the real pass rate of a smoke script by running it N times back to
# back and counting. Not a CI entry point: a measuring instrument for the
# reliability lane, so a "flaky" claim is a number rather than an impression.
#
#   tools/flake_rate.sh <smoke-name> <runs> [-- extra godot user args]
#
# Writes one log per run under the run directory it prints, and finishes with
# the pass count and the distinct failure lines it saw.
set -uo pipefail

smoke="${1:?usage: flake_rate.sh <smoke-name> <runs> [-- extra args]}"
runs="${2:?usage: flake_rate.sh <smoke-name> <runs> [-- extra args]}"
shift 2
[ "${1:-}" = "--" ] && shift

out="${FLAKE_OUT:-/tmp/flake-${smoke}-$$}"
mkdir -p "$out"
echo "logs: $out"

pass=0
fail=0
for i in $(seq 1 "$runs"); do
	start=$(date +%s)
	if godot --headless --path . --script "tests/smoke_${smoke}.gd" ${1:+-- "$@"} \
			>"$out/run-$i.log" 2>&1; then
		pass=$((pass + 1))
		verdict=PASS
	else
		fail=$((fail + 1))
		verdict=FAIL
	fi
	echo "run $i: $verdict ($(($(date +%s) - start))s)"
done

echo
echo "=== ${smoke}: ${pass}/${runs} passed, ${fail} failed ==="
grep -h "FAIL:" "$out"/*.log 2>/dev/null | sort | uniq -c | sort -rn
