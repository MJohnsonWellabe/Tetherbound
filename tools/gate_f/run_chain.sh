#!/usr/bin/env bash
#
# Run the whole S01 -> S10e journey chain into ONE run directory, in order, and
# keep going past a segment that fails so the run produces an account rather
# than stopping at the first red.
#
# Why this exists: every segment's entry save is `seed_save` from
# `run://<prev>-exit.json`, so the chain is only a chain if every segment writes
# into the same GATE_F_RUN_DIR. Six previous Gate F attempts ran segments one at
# a time by hand and none of them finished the chapter.
#
#   tools/gate_f/run_chain.sh                       # whole chain, new run dir
#   tools/gate_f/run_chain.sh --run-dir DIR S05 S06 # resume named segments
#
# Per-segment wall clock lands in <run-dir>/CHAIN_LOG.tsv, which is the pacing
# study's wall-clock half.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

CHAIN=(S01 S02 S03 S04 S05 S06 S07 S08 S09 S10a S10b S10c S10d S10e)
RUN_DIR="${GATE_F_RUN_DIR:-}"
SEGMENTS=()

while [[ $# -gt 0 ]]; do
	case "$1" in
		--run-dir) RUN_DIR="$2"; shift 2 ;;
		-h|--help) echo "usage: $0 [--run-dir DIR] [segment...]"; exit 0 ;;
		*) SEGMENTS+=("$1"); shift ;;
	esac
done

[[ ${#SEGMENTS[@]} -eq 0 ]] && SEGMENTS=("${CHAIN[@]}")

if [[ -z "$RUN_DIR" ]]; then
	RUN_DIR="ralph/reports/gate-f-run-$(date -u +%Y%m%dT%H%M%SZ)"
fi
mkdir -p "$RUN_DIR"
export GATE_F_RUN_DIR="$RUN_DIR"

LOG="$RUN_DIR/CHAIN_LOG.tsv"
[[ -f "$LOG" ]] || printf 'segment\tstarted_utc\twall_s\texit\tP\tF\tSKIP\n' > "$LOG"

echo "run_chain: run dir $RUN_DIR"
echo "run_chain: segments ${SEGMENTS[*]}"

for seg in "${SEGMENTS[@]}"; do
	started="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
	t0=$SECONDS
	echo "=== $seg  ($started) ==="
	tools/gate_f/run_segment.sh --run-dir "$RUN_DIR" "$seg" 2>&1 \
		| tee "$RUN_DIR/$seg.console.log"
	rc=${PIPESTATUS[0]}
	wall=$((SECONDS - t0))

	# Verdict counts come from the segment's own INVENTORY.json, which is what
	# the harness itself computed -- not re-derived here, so the chain log and
	# the segment agree by construction.
	counts="$(python3 - "$RUN_DIR/$seg/INVENTORY.json" <<'PY'
import json, sys
try:
    s = json.load(open(sys.argv[1]))["steps"]
    print("%d\t%d\t%d" % (s.get("pass", 0), s.get("fail", 0), s.get("skipped", 0)))
except Exception:
    print("?\t?\t?")
PY
)"
	printf '%s\t%s\t%d\t%d\t%s\n' "$seg" "$started" "$wall" "$rc" "$counts" >> "$LOG"
	echo "=== $seg done rc=$rc wall=${wall}s  ($counts) ==="

	# A segment that never wrote its exit save cannot hand off, so the rest of
	# the chain would replay the previous segment's state and quietly lie. Stop
	# and say so instead.
	if [[ "$seg" != "S01" && "$seg" != "S10e" ]]; then
		if ! compgen -G "$RUN_DIR/$seg/saves/$seg-exit.json" > /dev/null; then
			echo "run_chain: $seg wrote no exit save -- the chain cannot continue past it." >&2
			echo "run_chain: stopping here rather than running $seg+1 against stale state." >&2
			exit 3
		fi
	fi
done

echo "run_chain: chain complete. Log: $LOG"
cat "$LOG"
