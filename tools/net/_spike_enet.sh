#!/usr/bin/env bash
# Spike S1 launcher: starts one headless Godot host and N headless Godot
# clients, each with its own XDG_DATA_HOME (the isolation pattern from
# tools/flake_rate.sh), waits for all of them, prints exit codes and peak RSS,
# and sweeps orphans on exit.
#
#   tools/net/_spike_enet.sh [peers] [port]
#
# Reference only, for docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md Wave 0
# lane 0.C. Not the real net harness launcher (that is
# tools/net/run_net_smoke.sh, lane 0.F).
#
# Env:
#   GODOT_BIN=path       godot binary (default: ~/godot-bin/godot)
#   SPIKE_OUT=dir        where logs/homes/rss samples go (default: /tmp/spike-enet-$$)

set -uo pipefail

peers="${1:-1}"
port="${2:-9999}"
godot="${GODOT_BIN:-$HOME/godot-bin/godot}"
out="${SPIKE_OUT:-/tmp/spike-enet-$$}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

mkdir -p "$out"
echo "logs/homes: $out  (peers=$peers port=$port)"

pids=()
rss_pids=()

cleanup() {
	for pid in "${pids[@]:-}"; do
		kill "$pid" 2>/dev/null || true
	done
	for rp in "${rss_pids[@]:-}"; do
		kill "$rp" 2>/dev/null || true
	done
	# Orphan sweep: anything still running this spike script that we lost track of.
	pgrep -f "_spike_enet.gd" 2>/dev/null | while read -r p; do
		kill "$p" 2>/dev/null || true
	done
}
trap cleanup EXIT

sample_rss() {
	# Appends one RSS sample (KB) per line to $2 for pid $1 until it exits.
	local pid="$1" outfile="$2"
	: >"$outfile"
	while kill -0 "$pid" 2>/dev/null; do
		ps -o rss= -p "$pid" 2>/dev/null >>"$outfile"
		sleep 0.2
	done
}

peak_rss() {
	[ -s "$1" ] && tr -d ' ' <"$1" | sort -n | tail -1 || echo "?"
}

start_time=$(date +%s.%N)

host_home="$out/home-host"
mkdir -p "$host_home"
XDG_DATA_HOME="$host_home" "$godot" --headless --path "$repo_root" \
	--script tools/net/_spike_enet.gd -- --role=host --port="$port" --peers="$peers" \
	>"$out/host.log" 2>&1 &
host_pid=$!
pids+=("$host_pid")
sample_rss "$host_pid" "$out/host.rss" &
rss_pids+=("$!")
echo "host pid=$host_pid log=$out/host.log"

sleep 0.5 # let the host bind its port before any client dials in

client_pids=()
for i in $(seq 1 "$peers"); do
	home="$out/home-client-$i"
	mkdir -p "$home"
	XDG_DATA_HOME="$home" "$godot" --headless --path "$repo_root" \
		--script tools/net/_spike_enet.gd -- --role=client --port="$port" \
		>"$out/client-$i.log" 2>&1 &
	cpid=$!
	pids+=("$cpid")
	client_pids+=("$cpid")
	sample_rss "$cpid" "$out/client-$i.rss" &
	rss_pids+=("$!")
	echo "client-$i pid=$cpid log=$out/client-$i.log"
done

host_code=0
wait "$host_pid"
host_code=$?

client_codes=()
for cpid in "${client_pids[@]}"; do
	wait "$cpid"
	client_codes+=("$?")
done

end_time=$(date +%s.%N)
elapsed=$(awk -v a="$start_time" -v b="$end_time" 'BEGIN{printf "%.2f", b-a}')

echo
echo "=== spike_enet: wall-clock ${elapsed}s ==="
echo "host: exit=$host_code peak_rss_kb=$(peak_rss "$out/host.rss")"
for i in $(seq 1 "$peers"); do
	idx=$((i - 1))
	echo "client-$i: exit=${client_codes[$idx]} peak_rss_kb=$(peak_rss "$out/client-$i.rss")"
done

fail=0
[ "$host_code" -eq 0 ] || fail=1
for c in "${client_codes[@]}"; do
	[ "$c" -eq 0 ] || fail=1
done
exit "$fail"
