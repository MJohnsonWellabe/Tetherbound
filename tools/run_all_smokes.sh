#!/usr/bin/env bash
# STAGE B 0.E. Runs every tests/smoke_*.gd sequentially and reports one
# SUMMARY.md a human or a lane report can paste in whole.
#
# This is the "run all 149 locally" instrument the Stage B plan's Wave 0 row
# 0.E names -- used once per wave by a 7.B-style sweep, not a CI entry point
# (CI keeps running its own named shard jobs; this script exists for the
# times someone needs the WHOLE smoke suite's answer in one place, on
# demand, without re-deriving which shard runs which file).
#
#   tools/run_all_smokes.sh [--only=<substring>] [--outdir=<dir>]
#
# Env:
#   SMOKE_TIMEOUT_S=900   per-smoke wall-clock budget (seconds). A smoke that
#                         runs past this is killed and recorded as a timeout,
#                         not left to hang the whole sweep.
#   RETRIES=1             attempts per smoke before it counts as failed. This
#                         is a REPORTING knob, not a green-washing one: the
#                         summary always shows every attempt's own exit code
#                         and marks a smoke that needed more than one attempt
#                         as FLAKY rather than folding it into a bare PASS --
#                         docs/AGENT_WORKFLOW.md's "a retry that turns 0-for-1
#                         into green is a finding, not a pass" applies here
#                         exactly as it does in CI.
#
# Each smoke gets its own XDG_DATA_HOME under <outdir>/homes/<smoke>/ so one
# smoke's save cannot leak into the next one's "returning player" branch
# (tools/flake_rate.sh's own header explains why that matters) and so smokes
# could in principle run in parallel later without fighting over user://.
#
# Exit code: 0 only if every smoke's LAST attempt passed. Non-zero otherwise,
# so this can gate something if a future lane wants it to.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

only=""
outdir=""
for arg in "$@"; do
	case "$arg" in
		--only=*) only="${arg#--only=}" ;;
		--outdir=*) outdir="${arg#--outdir=}" ;;
		*)
			echo "unknown argument: $arg" >&2
			echo "usage: run_all_smokes.sh [--only=<substring>] [--outdir=<dir>]" >&2
			exit 2
			;;
	esac
done

timeout_s="${SMOKE_TIMEOUT_S:-900}"
retries="${RETRIES:-1}"
if [ -z "$outdir" ]; then
	outdir="/tmp/run_all_smokes-$(date +%Y%m%d-%H%M%S)-$$"
fi
mkdir -p "$outdir"

godot_bin="${GODOT_BIN:-godot}"
if ! command -v "$godot_bin" >/dev/null 2>&1; then
	if [ -x "$HOME/godot-bin/godot" ]; then
		godot_bin="$HOME/godot-bin/godot"
	else
		echo "godot binary not found on PATH and no \$HOME/godot-bin/godot; set GODOT_BIN" >&2
		exit 2
	fi
fi

# `smoke_net_*.gd` is excluded (Stage B Wave 0 lane 0.F review, item 7): each
# one launches multiple real peer PROCESSES via tools/net/run_net_smoke.sh,
# with its own port/XDG_DATA_HOME isolation and orphan-kill by TB_NET_RUN_ID.
# A plain smoke sweep must never launch a peer process outside that isolation
# -- it has no run id to sweep by and no port-collision handling, so two
# sweeps (or a sweep beside a net smoke run) would silently collide.
mapfile -t smokes < <(find tests -maxdepth 1 -name 'smoke_*.gd' ! -name 'smoke_net_*.gd' -printf '%f\n' | sort)
if [ -n "$only" ]; then
	# Comma-separated substrings, same composition rule as tests/run_tests.gd's
	# own --only=: a file matches if ANY selector is a substring of its name.
	IFS=',' read -r -a selectors <<<"$only"
	filtered=()
	for f in "${smokes[@]}"; do
		for sel in "${selectors[@]}"; do
			case "$f" in
				*"$sel"*) filtered+=("$f"); break ;;
			esac
		done
	done
	smokes=("${filtered[@]}")
fi

if [ "${#smokes[@]}" -eq 0 ]; then
	echo "no smoke files matched (--only='${only}')" >&2
	exit 2
fi

echo "run_all_smokes: ${#smokes[@]} smoke(s), timeout=${timeout_s}s, retries=${retries}, out=${outdir}"

summary="$outdir/SUMMARY.md"
{
	echo "# run_all_smokes summary"
	echo
	echo "Generated $(date -u +%Y-%m-%dT%H:%M:%SZ). ${#smokes[@]} smoke(s), timeout=${timeout_s}s, RETRIES=${retries}."
	echo
	echo "| Smoke | Exit | Seconds | Distinct ERROR: lines | Attempts |"
	echo "|---|---|---|---|---|"
} >"$summary"

overall_status=0

for smoke_file in "${smokes[@]}"; do
	smoke_name="${smoke_file%.gd}"
	home_dir="$outdir/homes/$smoke_name"
	rm -rf "$home_dir"
	mkdir -p "$home_dir"
	log_path="$outdir/${smoke_name}.log"

	attempt=0
	exit_code=1
	elapsed=0
	: >"$log_path"
	while [ "$attempt" -lt "$retries" ]; do
		attempt=$((attempt + 1))
		{
			echo "::group:: ${smoke_name} attempt ${attempt}/${retries}"
		} >>"$log_path"
		start=$(date +%s)
		XDG_DATA_HOME="$home_dir" timeout "${timeout_s}s" \
			"$godot_bin" --headless --path . --script "tests/${smoke_file}" \
			>>"$log_path" 2>&1
		exit_code=$?
		end=$(date +%s)
		elapsed=$((end - start))
		{
			if [ "$exit_code" -eq 124 ]; then
				echo "${smoke_name} attempt ${attempt}/${retries}: TIMEOUT after ${elapsed}s (budget ${timeout_s}s)"
			else
				echo "${smoke_name} attempt ${attempt}/${retries}: exit=${exit_code} (${elapsed}s)"
			fi
			echo "::endgroup::"
		} >>"$log_path"
		if [ "$exit_code" -eq 0 ]; then
			break
		fi
	done

	distinct_errors=$(grep -c '^ERROR:' "$log_path" 2>/dev/null || true)
	# distinct, not raw count -- docs/AGENT_WORKFLOW.md §6: the count is not
	# stable (it varies with what streamed in) but the DISTINCT SET is.
	distinct_errors=$(grep '^ERROR:' "$log_path" 2>/dev/null | sed 's/[0-9][0-9.]\+/N/g' | sort -u | wc -l | tr -d ' ')

	if [ "$exit_code" -eq 0 ]; then
		status_word="PASS"
		if [ "$attempt" -gt 1 ]; then
			status_word="FLAKY(pass on attempt ${attempt}/${retries})"
		fi
	else
		status_word="FAIL"
		overall_status=1
	fi

	echo "  ${smoke_name}: ${status_word} exit=${exit_code} ${elapsed}s errors=${distinct_errors}"
	echo "| ${smoke_name} | ${exit_code} | ${elapsed} | ${distinct_errors} | ${attempt}/${retries} |" >>"$summary"
done

{
	echo
	if [ "$overall_status" -eq 0 ]; then
		echo "All ${#smokes[@]} smoke(s) passed (on their last attempt)."
	else
		echo "One or more smokes failed. See individual logs under ${outdir}."
	fi
} >>"$summary"

echo
echo "summary: ${summary}"
exit "$overall_status"
