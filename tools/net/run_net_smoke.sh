#!/usr/bin/env bash
# Net smoke launcher. Stage B Wave 0 lane 0.F.
# docs/specs/MP_NET_HARNESS_CONTRACT.md §2, §10.
#
#   tools/net/run_net_smoke.sh <smoke-name> [--peers=N] [--out=dir]
#
# <smoke-name> is the file's name without the `smoke_net_` prefix or `.gd`
# suffix, e.g. `two_peers_boot` for tests/smoke_net_two_peers_boot.gd.
#
# Sets TB_NET_RUN_ID (read back by tests/helpers/net_harness.gd, and stamped
# into every peer's own argv -- see net_harness.gd::_spawn_peer for why that
# has to be a literal command-line token and not only an environment
# variable: `pgrep -f` matches a process's COMMAND LINE, not its environ),
# runs the coordinator, tails SUMMARY.md as it appears, and kills every
# process still carrying this run's id on EVERY exit path -- the
# tools/gate_f/run_segment.sh zombie-guard pattern, and the flake_rate.sh
# isolation rule (one machine, many runs, no shared user://).
#
# --peers is accepted for forward compatibility with the contract's own
# `run_net_smoke.sh <smoke> [--peers=N] [--out=dir]` signature, but in Wave 0
# a smoke's own peer count is fixed by what its script calls `launch()` with
# (declared in its own `# peers: N` header) -- this script does not itself
# decide how many processes a smoke stands up. It is exported as
# TB_NET_PEERS for a smoke that chooses to read it.
set -uo pipefail

usage() {
	echo "usage: tools/net/run_net_smoke.sh <smoke-name> [--peers=N] [--out=dir]" >&2
}

smoke="${1:-}"
if [ -z "$smoke" ]; then
	usage
	exit 2
fi
shift

peers=2
out=""
for arg in "$@"; do
	case "$arg" in
		--peers=*) peers="${arg#--peers=}" ;;
		--out=*) out="${arg#--out=}" ;;
		*)
			echo "unknown argument: $arg" >&2
			usage
			exit 2
			;;
	esac
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
godot="${GODOT_BIN:-${GODOT:-$HOME/godot-bin/godot}}"
out="${out:-/tmp}"

script="$repo_root/tests/smoke_net_${smoke}.gd"
if [ ! -f "$script" ]; then
	echo "no such smoke: $script" >&2
	exit 2
fi

run_id="net-$(date -u +%Y%m%dT%H%M%SZ)-$$"
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
run_dir="${out%/}/net-${smoke}-${stamp}"
mkdir -p "$run_dir"

export TB_NET_RUN_ID="$run_id"
export TB_NET_OUT_DIR="$run_dir"
export TB_NET_PEERS="$peers"

echo "run id:  $run_id"
echo "run dir: $run_dir"
echo "smoke:   tests/smoke_net_${smoke}.gd  (--peers=${peers} advisory, see this script's header)"

kill_orphans() {
	local matches
	matches="$(pgrep -f "TB_NET_RUN_ID=${run_id}" 2>/dev/null || true)"
	if [ -n "$matches" ]; then
		local n
		n="$(printf '%s\n' "$matches" | wc -l)"
		echo "run_net_smoke: sweeping ${n} process(es) tagged run ${run_id}"
		# shellcheck disable=SC2086
		kill $matches 2>/dev/null || true
		sleep 0.3
		# shellcheck disable=SC2086
		kill -9 $matches 2>/dev/null || true
	fi
}
trap kill_orphans EXIT

kill_orphans # in the unlikely case a stale run shares this shell pid

# Tail SUMMARY.md as it appears, in the background, so a human or a CI log
# shows the verdict without waiting for the coordinator to fully exit first.
(
	waited=0
	while [ ! -f "$run_dir/SUMMARY.md" ] && [ "$waited" -lt 3600 ]; do
		sleep 1
		waited=$((waited + 1))
	done
	[ -f "$run_dir/SUMMARY.md" ] && tail -f "$run_dir/SUMMARY.md" 2>/dev/null
) &
tail_pid=$!

"$godot" --headless --path "$repo_root" --script "$script"
code=$?

kill "$tail_pid" 2>/dev/null || true
wait "$tail_pid" 2>/dev/null || true

if [ -f "$run_dir/SUMMARY.md" ]; then
	echo
	echo "=== $run_dir/SUMMARY.md ==="
	cat "$run_dir/SUMMARY.md"
else
	echo "(no SUMMARY.md written to $run_dir)"
fi

exit "$code"
