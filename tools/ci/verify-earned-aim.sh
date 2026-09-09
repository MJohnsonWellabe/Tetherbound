#!/usr/bin/env bash
set -euo pipefail

# Independent profiles and full first-attempt receipts; never retry a failed case.
aim_run_root=$(mktemp -d "${RUNNER_TEMP:-/tmp}/earned-aim.XXXXXX")
echo "Earned aim receipts: $aim_run_root"

verify_aim_case() {
  local name=$1 script=$2 checks=$3
  shift 3
  local case_root="$aim_run_root/$name"
  mkdir -p "$case_root/config" "$case_root/data" "$case_root/cache"
  echo "::group::Earned aim $name (first and only attempt)"
  set +e
  timeout --kill-after=5s 30s env \
    XDG_CONFIG_HOME="$case_root/config" \
    XDG_DATA_HOME="$case_root/data" \
    XDG_CACHE_HOME="$case_root/cache" \
    godot --headless --path . --script "$script" "$@" 2>&1 | tee "$case_root/engine.log"
  local statuses=("${PIPESTATUS[@]}")
  set -e
  echo "::endgroup::"
  # Inspect the entire log, including errors before a printed success summary.
  local log_errors=0
  if grep -niE 'SCRIPT ERROR|(^|[[:space:]])ERROR:' "$case_root/engine.log"; then
    log_errors=1
  fi
  if (( statuses[0] != 0 )); then
    echo "::error::Earned aim $name exited ${statuses[0]}; no retry"
    return "${statuses[0]}"
  fi
  if (( statuses[1] != 0 || log_errors != 0 )); then
    echo "::error::Earned aim $name has a log-write or native script/error failure"
    return 1
  fi
  if ! grep -Fxq "PHASE_PROOF checks=$checks failures=[]" "$case_root/engine.log"; then
    echo "::error::Earned aim $name did not complete all $checks checks"
    return 1
  fi
}

verify_aim_case windup tools/aim_cancel_windup_probe.gd 19
verify_aim_case hud tools/aim_cancel_hud_probe.gd 8
verify_aim_case eight-tick tools/aim_eight_tick_probe.gd 5
verify_aim_case natural-guard tools/aim_natural_guard_probe.gd 8 -- --verify-readiness
