#!/usr/bin/env bash
# Measure the real pass rate of a smoke script by running it N times and
# counting. Not a CI entry point: a measuring instrument for the reliability
# lane, so a "flaky" claim is a number rather than an inherited impression.
#
#   tools/flake_rate.sh <smoke-name> <runs> [-- extra godot user args]
#
# Env:
#   FLAKE_JOBS=N        how many runs at once (default 1). Each parallel run
#                       gets its own XDG_DATA_HOME so they cannot share a save.
#   FLAKE_KEEP_SAVES=1  let a run see the save the previous run left.
#   FLAKE_OUT=dir       where the per-run logs go.
#
# CI gives every job a fresh runner, so attempt 1 of every smoke meets an EMPTY
# `user://`. Runs on one machine do not: run 2 onward find run 1's save and take
# the returning-player branch instead. So every run here gets its own empty one,
# and FLAKE_KEEP_SAVES chains them -- which is what a CI RETRY attempt actually
# sees, since the retry loop runs on the same runner as attempt 1.
set -uo pipefail

smoke="${1:?usage: flake_rate.sh <smoke-name> <runs> [-- extra args]}"
runs="${2:?usage: flake_rate.sh <smoke-name> <runs> [-- extra args]}"
shift 2
[ "${1:-}" = "--" ] && shift

jobs="${FLAKE_JOBS:-1}"
out="${FLAKE_OUT:-/tmp/flake-${smoke}-$$}"
mkdir -p "$out"
echo "logs: $out (${jobs} at a time)"

one_run() {
	local i="$1"; shift
	local home="$out/home-$i"
	if [ -z "${FLAKE_KEEP_SAVES:-}" ]; then
		rm -rf "$home"
	fi
	mkdir -p "$home"
	local start; start=$(date +%s)
	XDG_DATA_HOME="$home" godot --headless --path . \
		--script "tests/smoke_${smoke}.gd" ${1:+-- "$@"} \
		>"$out/run-$i.log" 2>&1
	local code=$?
	echo "$code" >"$out/exit-$i"
	if [ "$code" -eq 0 ]; then
		echo "run $i: PASS ($(($(date +%s) - start))s)"
	else
		echo "run $i: FAIL exit=$code ($(($(date +%s) - start))s)"
	fi
}

running=0
for i in $(seq 1 "$runs"); do
	one_run "$i" "$@" &
	running=$((running + 1))
	if [ "$running" -ge "$jobs" ]; then
		wait -n
		running=$((running - 1))
	fi
done
wait

pass=0
fail=0
for i in $(seq 1 "$runs"); do
	if [ "$(cat "$out/exit-$i" 2>/dev/null)" = "0" ]; then
		pass=$((pass + 1))
	else
		fail=$((fail + 1))
	fi
done

echo
echo "=== ${smoke}: ${pass}/${runs} passed, ${fail} failed ==="
grep -h "FAIL:" "$out"/run-*.log 2>/dev/null | sed 's/[0-9][0-9.]\+/N/g' \
	| sort | uniq -c | sort -rn
