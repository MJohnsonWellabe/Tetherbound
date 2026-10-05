#!/usr/bin/env bash
# Run one verify-multiplayer-shard job's net smokes: two lanes side by side.
#
#   tools/ci/run_net_lanes.sh <out-dir> "<lane a files>" "<lane b files>"
#
# A two-peer smoke uses about half of a 4-vCPU runner (measured 50%), and
# two side by side each took 1.10x as long as one alone (both PASS). So each
# job runs two plan bins (tools/ci/net_shards.py) at once, and each runner
# does about twice the work for its ~2 min of checkout and Godot setup.
#
# Isolation: each smoke already gets its own run id, out dir and home
# (run_net_smoke.sh). Each lane gets its own ENet port range through
# TB_NET_ENET_BASE (the run-id hash alone collides 1 time in 400). Control
# ports are OS-assigned (net_harness.gd).
#
# Each smoke's output goes to its own log, printed afterwards in a
# `::group::` per smoke. Every failure is an `::error::` naming the smoke and
# lane. A planned smoke without a result (its lane died) also fails by name.
set -uo pipefail

out=${1:?out dir}
lane_files_a=${2-}
lane_files_b=${3-}
RETRIES=${RETRIES:-1}
# Below the 32768+ ephemeral range; 20 apart = the harness's per-run stride.
ENET_BASE=${NET_LANES_ENET_BASE:-27801}

command -v setsid >/dev/null || {
  echo "::error::setsid is required to contain each net smoke's process tree"
  exit 1
}
mkdir -p "$out/logs"
results="$out/results.tsv"
: > "$results"

run_lane() {
  local lane=$1 files=$2 base=$3
  local active=""
  cleanup_active_group() {
    local pgid="${active:-}"
    [ -n "$pgid" ] || return 0
    # The runner, coordinator and OS.create_process peers all inherit the
    # smoke's own process group: sweep it on success, failure and cancel.
    kill -TERM -- "-${pgid}" 2>/dev/null || true
    for _ in $(seq 1 20); do
      kill -0 -- "-${pgid}" 2>/dev/null || break
      sleep 0.1
    done
    kill -KILL -- "-${pgid}" 2>/dev/null || true
    wait "$pgid" 2>/dev/null || true
    active=""
  }
  trap 'cleanup_active_group; exit 130' INT TERM HUP
  local f name log n rc
  for f in $files; do
    name="$(basename "$f" .gd)"
    name="${name#smoke_net_}"
    log="$out/logs/${lane}-${name}.log"
    n=0
    rc=1
    until [ "$n" -ge "$RETRIES" ]; do
      n=$((n + 1))
      echo "=== smoke_net_${name}.gd attempt ${n}/${RETRIES} (lane ${lane}, ENet base ${base})" >> "$log"
      TB_NET_ENET_BASE="$base" setsid tools/net/run_net_smoke.sh "$name" --out="$out/lane-${lane}" >> "$log" 2>&1 &
      active=$!
      if wait "$active"; then rc=0; else rc=$?; fi
      cleanup_active_group
      [ "$rc" -eq 0 ] && break
    done
    printf '%s\t%s\t%s\t%s\n' "$lane" "$name" "$rc" "$n" >> "$results"
  done
}

lane_pids=()
stop_lanes() {
  for pid in "${lane_pids[@]}"; do kill -TERM "$pid" 2>/dev/null || true; done
  wait 2>/dev/null || true
}
trap 'stop_lanes; exit 130' INT TERM HUP

started=$(date +%s)
run_lane a "$lane_files_a" "$ENET_BASE" & lane_pids+=($!)
run_lane b "$lane_files_b" "$((ENET_BASE + 20))" & lane_pids+=($!)
wait "${lane_pids[@]}"
echo "both lanes done in $(( $(date +%s) - started )) s"

status=0
for lane in a b; do
  if [ "$lane" = a ]; then files=$lane_files_a; else files=$lane_files_b; fi
  for f in $files; do
    name="$(basename "$f" .gd)"
    name="${name#smoke_net_}"
    row=$(awk -F'\t' -v l="$lane" -v s="$name" '$1==l && $2==s' "$results")
    rc=$(printf '%s' "$row" | cut -f3)
    tries=$(printf '%s' "$row" | cut -f4)
    if [ -z "$row" ]; then verdict="NO RESULT"; elif [ "$rc" = 0 ]; then verdict=PASS; else verdict="FAIL (exit ${rc})"; fi
    echo "::group::smoke_net_${name}.gd lane ${lane}: ${verdict}"
    cat "$out/logs/${lane}-${name}.log" 2>/dev/null || true
    echo "::endgroup::"
    if [ "$verdict" != PASS ]; then
      echo "::error::smoke_net_${name}.gd ${verdict} (lane ${lane}${tries:+, ${tries} attempt(s)})"
      status=1
    fi
  done
done
exit "$status"
