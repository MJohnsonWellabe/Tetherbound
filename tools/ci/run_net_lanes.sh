#!/usr/bin/env bash
# Run a verify-multiplayer-shard job's net smokes in parallel LANES.
#
#   tools/ci/run_net_lanes.sh "<lane 1 files>" "<lane 2 files>" ...
#
# Each argument is one lane: a space-separated list of tests/smoke_net_*.gd
# files, run one after another through tools/net/run_net_smoke.sh. Lanes run
# at the same time (CI-SPEED, owner 2026-10-07): a net smoke spends most of
# its time with two peer processes booting the world, and a 4-vCPU runner
# fits two smokes side by side (measured locally: two_peers_boot 169 s alone,
# 185/188 s for two at once; three at once missed the 180 s hello budget, so
# the plan uses two). The harness already isolates concurrent runs: each run
# has its own run id, XDG_DATA_HOME per peer, ENet port stride and
# OS-reserved control ports (tests/helpers/net_harness.gd).
#
# Per smoke: its own process session (setsid), swept on every exit path, and
# a NET_SMOKE_TIMEOUT_SECONDS guard so one hung smoke fails on its own rather
# than holding its lane until the job limit cancels every other lane too.
# Output goes to a per-smoke log, printed as one ::group:: when the smoke
# ends (under a lock, so two lanes never interleave lines). RETRIES as
# before (1: a net smoke that only passes on retry is a finding).
set -uo pipefail

RETRIES="${RETRIES:-1}"
SMOKE_TIMEOUT="${NET_SMOKE_TIMEOUT_SECONDS:-1200}"
OUT="${NET_OUT_DIR:-/tmp/net-ci}"

for tool in setsid flock timeout; do
	command -v "$tool" >/dev/null || {
		echo "::error::$tool is required to run net smoke lanes"
		exit 1
	}
done

logs="$(mktemp -d)"
lock="$logs/print.lock"
results="$logs/results.tsv"
: > "$results"

sweep_group() {
	local pgid="$1"
	[ -n "$pgid" ] || return 0
	kill -TERM -- "-${pgid}" 2>/dev/null || true
	for _ in $(seq 1 20); do
		kill -0 -- "-${pgid}" 2>/dev/null || break
		sleep 0.1
	done
	kill -KILL -- "-${pgid}" 2>/dev/null || true
}

run_lane() {
	local lane="$1"
	shift
	local active="" status=0 f name n run_status started log
	trap 'sweep_group "$active"; exit 130' INT TERM HUP
	for f in "$@"; do
		name="$(basename "$f" .gd)"
		name="${name#smoke_net_}"
		n=0
		while [ "$n" -lt "$RETRIES" ]; do
			n=$((n + 1))
			log="$logs/lane${lane}-${name}-${n}.log"
			started=$(date +%s)
			echo "lane ${lane}: smoke_net_${name}.gd attempt ${n}/${RETRIES} started"
			setsid timeout -k 30 "$SMOKE_TIMEOUT" tools/net/run_net_smoke.sh "$name" --out="$OUT" > "$log" 2>&1 &
			active=$!
			if wait "$active"; then run_status=0; else run_status=$?; fi
			sweep_group "$active"
			wait "$active" 2>/dev/null || true
			active=""
			local secs=$(( $(date +%s) - started ))
			[ "$run_status" -eq 124 ] && echo "TIMED OUT after ${SMOKE_TIMEOUT} s (NET_SMOKE_TIMEOUT_SECONDS)" >> "$log"
			(
				flock 9
				echo "::group::smoke_net_${name}.gd attempt ${n}/${RETRIES} (lane ${lane}, exit ${run_status}, ${secs} s)"
				cat "$log"
				echo "::endgroup::"
				if [ "$run_status" -ne 0 ]; then
					echo "::error::smoke_net_${name}.gd failed on attempt ${n}/${RETRIES} (lane ${lane}, exit ${run_status})"
				fi
			) 9>"$lock"
			printf '%s\t%s\t%s\t%s\t%s\n' "$lane" "$name" "$n" "$run_status" "$secs" >> "$results"
			[ "$run_status" -eq 0 ] && continue 2
		done
		status=1
	done
	return "$status"
}

pids=()
cleanup() {
	for pid in "${pids[@]}"; do kill -TERM "$pid" 2>/dev/null || true; done
	for pid in "${pids[@]}"; do wait "$pid" 2>/dev/null || true; done
}
trap 'cleanup; exit 130' INT TERM HUP

lane=0
for files in "$@"; do
	lane=$((lane + 1))
	# shellcheck disable=SC2086
	[ -n "${files// /}" ] || continue
	# shellcheck disable=SC2086
	run_lane "$lane" $files &
	pids+=("$!")
done

status=0
for pid in "${pids[@]}"; do
	wait "$pid" || status=1
done

echo "lane	smoke	attempt	exit	seconds"
cat "$results"
exit "$status"
