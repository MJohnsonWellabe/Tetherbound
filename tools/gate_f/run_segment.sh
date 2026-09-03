#!/usr/bin/env bash
#
# Gate F segment runner: the two canonical Godot invocations, the zombie guard,
# and the capture smoke gate, in one place so the operator never types either
# command by hand.
#
#   tools/gate_f/run_segment.sh S01                 # logic mode (fast)
#   tools/gate_f/run_segment.sh --capture X07       # capture mode under xvfb
#   tools/gate_f/run_segment.sh --overhead          # section 8 self-measurement
#
# The segment argument is either a bare id (resolved to
# tools/gate_f/segments/<id>.json) or a path to a step-script.
#
# ## Why this script exists rather than a documented command line
#
# Three things about running Gate F are non-obvious, each already paid for:
#
#   1. `--headless` together with `--rendering-driver opengl3` HANGS FOREVER.
#      No error, no crash, exit 124 from `timeout`. docs/AGENT_WORKFLOW.md calls
#      it the single most expensive trap in this repo. The two modes below are
#      the only two shapes that work, and neither can be typed into the other
#      by accident because this script owns both.
#
#   2. A hung capture leaves a ZOMBIE. It keeps running after the lane gives up,
#      pinned to a directory that may since have been deleted, burning CPU.
#      Three such orphans were found running 33-57 minutes; the contention they
#      then caused made the original misdiagnosis look correct. So this kills
#      orphans before and after every batch.
#
#   3. A capture that fails at 1920x1080 must be RECORDED as having fallen back,
#      not silently re-run smaller. Protocol section A.4: the smoke gates the
#      lane, and a substitution is part of the run record.
#
# ## Restart protection
#
# A segment directory that already exists is never written into. A restarted
# segment must be renamed `-superseded-<n>` first, and this script says so and
# stops rather than doing it for you: which of two attempts is the evidence is
# an operator decision, and a script that renamed automatically would make it
# silently.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

GODOT="${GODOT:-$HOME/.cache/tetherbound-art/godot}"
SEGMENT_DIR="tools/gate_f/segments"
HARNESS="tools/gate_f/operator_harness.gd"
CAPTURE_SMOKE="tools/capture_diag_minimal.gd"

# Capture resolution and its recorded fallback. 1920x1080 is the protocol's
# ask; 1280x800 is the handheld-shaped fallback the rest of this repo's capture
# tooling already uses.
CAPTURE_W=1920
CAPTURE_H=1080
FALLBACK_W=1280
FALLBACK_H=800

MODE="logic"
ALLOW_NO_CAPTURE="no"
SEGMENT=""
RUN_DIR="${GATE_F_RUN_DIR:-}"

usage() {
	cat <<'EOF'
usage: tools/gate_f/run_segment.sh [--capture] [--overhead] [--run-dir DIR] <segment-id-or-path>

  --capture      run under xvfb + opengl3 so screenshot steps produce PNGs.
                 Gated on tools/capture_diag_minimal.gd succeeding first.
  --allow-no-capture
                 run a segment that declares captures in LOGIC mode anyway,
                 acknowledging that its evidence half is void. The segment can
                 never be marked complete. Without it, that combination is
                 refused -- see the CD-1 gate below.
  --overhead     run the section 8 instrumentation-overhead self-measurement
                 instead of a segment. Takes no segment argument.
  --run-dir DIR  write into an existing run directory instead of making a new
                 ralph/reports/gate-f-run-<stamp>/. Also settable as
                 GATE_F_RUN_DIR, which is how a batch keeps every segment of one
                 run together.

Environment: GODOT (path to the binary, default $HOME/.cache/tetherbound-art/godot)
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--capture) MODE="capture"; shift ;;
		--overhead) MODE="overhead"; shift ;;
		--allow-no-capture) ALLOW_NO_CAPTURE="yes"; shift ;;
		--run-dir) RUN_DIR="$2"; shift 2 ;;
		-h|--help) usage; exit 0 ;;
		-*) echo "unknown flag: $1" >&2; usage; exit 2 ;;
		*) SEGMENT="$1"; shift ;;
	esac
done

# --- zombie guard -------------------------------------------------------------
#
# docs/AGENT_WORKFLOW.md's own recipe. A Godot whose cwd reads "(deleted)" is
# pinned to a worktree that has been pruned out from under it and can never do
# anything useful again; anything else is left alone, because killing a lane's
# live run to tidy up is worse than the orphan.
kill_orphans() {
	local killed=0
	for pid in $(pgrep -f "godot" 2>/dev/null || true); do
		[[ "$pid" == "$$" ]] && continue
		local cwd
		cwd="$(readlink "/proc/$pid/cwd" 2>/dev/null || echo "")"
		if [[ "$cwd" == *"(deleted)"* ]]; then
			echo "run_segment: killing orphan godot $pid (cwd $cwd)"
			kill -9 "$pid" 2>/dev/null || true
			killed=$((killed + 1))
		fi
	done
	[[ $killed -gt 0 ]] && echo "run_segment: killed $killed orphan(s)"
	return 0
}

kill_orphans
trap kill_orphans EXIT

# --- resolve paths ------------------------------------------------------------

if [[ ! -x "$GODOT" ]]; then
	echo "run_segment: no Godot at $GODOT (set GODOT=/path/to/godot)" >&2
	exit 1
fi

if [[ ! -d .godot/imported ]]; then
	echo "run_segment: no import cache. Run: $GODOT --headless --path . --import" >&2
	echo "run_segment: without it, resources fail to load and viewpoints render empty instead of erroring." >&2
	exit 1
fi

if [[ -z "$RUN_DIR" ]]; then
	RUN_DIR="ralph/reports/gate-f-run-$(date -u +%Y%m%dT%H%M%SZ)"
fi
mkdir -p "$RUN_DIR"

SHA="$(git rev-parse HEAD 2>/dev/null || echo unknown)"
RUN_ID="$(basename "$RUN_DIR")"

if [[ "$MODE" == "overhead" ]]; then
	SEGMENT_ID="overhead"
	SEGMENT_PATH=""
else
	if [[ -z "$SEGMENT" ]]; then
		echo "run_segment: no segment given" >&2
		usage
		exit 2
	fi
	if [[ -f "$SEGMENT" ]]; then
		SEGMENT_PATH="$SEGMENT"
	elif [[ -f "$SEGMENT_DIR/$SEGMENT.json" ]]; then
		SEGMENT_PATH="$SEGMENT_DIR/$SEGMENT.json"
	else
		echo "run_segment: no such segment '$SEGMENT' (looked for $SEGMENT_DIR/$SEGMENT.json)" >&2
		exit 1
	fi
	SEGMENT_ID="$(basename "$SEGMENT_PATH" .json)"
fi

OUT_DIR="$RUN_DIR/$SEGMENT_ID"

# --- CD-1's runner-side gate --------------------------------------------------
#
# A segment whose step-script contains a planned capture may not be launched in
# logic mode. That is not a style rule: it is what the run against candidate
# f082bdf6 actually did. Every journey and study segment went through this
# script WITHOUT --capture, the harness wrote 9,231 manifest rows saying
# `file: null`, each capture step reported PASS, and the run was handed to
# Phase B as complete evidence with no prescribed screenshot in it anywhere.
#
# The harness has its own pre-flight and will BLOCK on the same fact. This gate
# is here as well, and deliberately, because the two catch it at different
# costs: the harness catches it after a 60-second world stand-up, and this
# catches it before Godot starts. A run that is going to refuse should refuse
# in the first second.
#
# --allow-no-capture forwards the harness's acknowledged-degraded flag, for a
# developer running a capture-bearing segment for its logic. It still cannot
# produce a complete segment.
segment_plans_captures() {
	local path="$1"
	[[ -f "$path" ]] || return 1
	grep -Eq '"action"[[:space:]]*:[[:space:]]*"capture(_seq)?"' "$path"
}

# Which evidence lane the segment declares (section H/G split, owner decision
# 2026-08-27). `both` is what every segment written before the split means and
# is the default, so an unconverted segment behaves exactly as it did.
segment_evidence_lane() {
	local path="$1"
	[[ -f "$path" ]] || { echo both; return; }
	local lane
	lane="$(grep -Eo '"evidence_lane"[[:space:]]*:[[:space:]]*"[a-z]+"' "$path" \
		| head -n1 | grep -Eo '"[a-z]+"$' | tr -d '"')"
	echo "${lane:-both}"
}

EVIDENCE_LANE="both"
if [[ -n "$SEGMENT_PATH" ]]; then
	EVIDENCE_LANE="$(segment_evidence_lane "$SEGMENT_PATH")"
fi

# The evidence split's runner-side consequence. A LOGIC lane is *supposed* to
# run headless with its capture steps handed to a named capture lane -- so
# CD-1's refusal below, which exists to stop a capture-bearing segment being run
# where it cannot take pictures, must not fire on it. That is not a hole in
# CD-1: the harness still checks, before step 1, that the capture lane named in
# the file exists, declares itself a capture lane, and accepts every id handed
# to it. A delegation nobody accepted is a BLOCKER there. The debt moves; it
# does not evaporate.
if [[ "$MODE" == "logic" && "$EVIDENCE_LANE" == "logic" ]] && segment_plans_captures "$SEGMENT_PATH"; then
	echo "run_segment: $SEGMENT_ID declares evidence_lane=logic. Its prescribed captures are"
	echo "run_segment:            DELEGATED to its declared capture lane, not taken here, and the"
	echo "run_segment:            harness refuses to start if that lane does not accept them."
elif [[ "$MODE" == "logic" && -n "$SEGMENT_PATH" ]] && segment_plans_captures "$SEGMENT_PATH"; then
	if [[ "$ALLOW_NO_CAPTURE" != "yes" ]]; then
		echo "run_segment: $SEGMENT_ID declares planned captures and this is LOGIC mode." >&2
		echo "run_segment: logic mode has no display server, so every one of those captures would" >&2
		echo "             be written as file:null while the steps reported PASS. That is coverage" >&2
		echo "             defect CD-1 and it is how a whole Gate F run produced no screenshots." >&2
		echo "run_segment: use --capture, or --allow-no-capture to run it for its logic knowing" >&2
		echo "             the segment CANNOT be marked complete." >&2
		exit 2
	fi
	echo "run_segment: WARNING -- $SEGMENT_ID plans captures and is running WITHOUT a display"
	echo "run_segment:            server by explicit --allow-no-capture. INVENTORY.json will"
	echo "run_segment:            mark every planned shot absent and the segment incomplete."
fi

# Restart protection. Deliberately refuses rather than renaming: see the header.
if [[ -e "$OUT_DIR" ]]; then
	echo "run_segment: $OUT_DIR already exists." >&2
	echo "run_segment: a restarted segment gets its previous attempt renamed FIRST, by hand:" >&2
	echo "             mv '$OUT_DIR' '$OUT_DIR-superseded-1'" >&2
	echo "run_segment: which attempt is the evidence is an operator decision, not this script's." >&2
	exit 1
fi
mkdir -p "$OUT_DIR"

# --- run ----------------------------------------------------------------------

HARNESS_ARGS=(--gatef-out="$OUT_DIR" --gatef-run-id="$RUN_ID" --gatef-sha="$SHA")
if [[ -n "$SEGMENT_PATH" ]]; then
	HARNESS_ARGS+=(--gatef-segment="$SEGMENT_PATH")
fi
if [[ "$MODE" == "overhead" ]]; then
	HARNESS_ARGS+=(--gatef-mode=overhead)
fi
if [[ "$ALLOW_NO_CAPTURE" == "yes" ]]; then
	HARNESS_ARGS+=(--gatef-allow-no-capture)
fi

run_logic() {
	# Plain --headless, NO rendering driver. This is correct and fast; it is
	# specifically --headless WITH a driver that hangs.
	echo "run_segment: logic mode -> $OUT_DIR"
	"$GODOT" --headless --path . --script "$HARNESS" -- "${HARNESS_ARGS[@]}"
}

# Returns 0 if the smoke wrote a PNG at WxH. Exit 2 from the smoke means
# "headless process", which is a wrong invocation, not a renderer fault.
smoke_at() {
	local w="$1" h="$2"
	echo "run_segment: capture smoke at ${w}x${h}..."
	if timeout 120 xvfb-run -a -s "-screen 0 ${w}x${h}x24" \
			"$GODOT" --path . --rendering-driver opengl3 --resolution "${w}x${h}" \
			--script "$CAPTURE_SMOKE" -- --gatef-out="$OUT_DIR"; then
		return 0
	fi
	local rc=$?
	if [[ $rc -eq 124 ]]; then
		echo "run_segment: capture smoke TIMED OUT at ${w}x${h}." >&2
		echo "run_segment: that is the --headless-plus-driver hang signature. This script does not" >&2
		echo "             pass --headless in capture mode, so investigate the environment, not the flags." >&2
	fi
	return 1
}

run_capture() {
	local w="$CAPTURE_W" h="$CAPTURE_H"
	local substituted="no"
	if ! smoke_at "$w" "$h"; then
		echo "run_segment: 1920x1080 smoke failed; trying the ${FALLBACK_W}x${FALLBACK_H} fallback."
		w="$FALLBACK_W"; h="$FALLBACK_H"
		if ! smoke_at "$w" "$h"; then
			echo "run_segment: capture smoke failed at both sizes. NOT running the segment in capture mode." >&2
			echo "run_segment: fix the invocation before blaming the capture script, the scene, or the box." >&2
			cat > "$OUT_DIR/CAPTURE_UNAVAILABLE.md" <<EOF
# Capture unavailable

\`tools/capture_diag_minimal.gd\` could not write a PNG at ${CAPTURE_W}x${CAPTURE_H}
or at ${FALLBACK_W}x${FALLBACK_H} on this box, so no capture-mode segment was run.

Every planned shot for this segment is therefore absent. Per protocol section C.4
an absent frame is evidence: re-run in logic mode to get the manifest rows with
\`file: null\`, and record this file as the reason.
EOF
			return 1
		fi
		substituted="yes"
	fi
	# The substitution is part of the run record, not a detail the operator is
	# expected to remember. Protocol section A.4.
	cat > "$OUT_DIR/CAPTURE_RESOLUTION.json" <<EOF
{
  "requested": [$CAPTURE_W, $CAPTURE_H],
  "used": [$w, $h],
  "substituted": $( [[ "$substituted" == "yes" ]] && echo true || echo false ),
  "why": "$( [[ "$substituted" == "yes" ]] && echo "capture smoke failed at ${CAPTURE_W}x${CAPTURE_H}; fell back and recorded it" || echo "capture smoke passed at the requested size" )",
  "smoke": "capture_smoke.png"
}
EOF
	echo "run_segment: capture mode at ${w}x${h} -> $OUT_DIR"
	xvfb-run -a -s "-screen 0 ${w}x${h}x24" \
		"$GODOT" --path . --rendering-driver opengl3 --resolution "${w}x${h}" \
		--script "$HARNESS" -- "${HARNESS_ARGS[@]}" --gatef-capture
}

if [[ "$MODE" == "capture" && "$EVIDENCE_LANE" == "logic" ]]; then
	echo "run_segment: WARNING -- $SEGMENT_ID is the LOGIC lane and is being run under xvfb." >&2
	echo "run_segment:            It will take no frame and keep no continuous record, and every" >&2
	echo "run_segment:            physics frame will be rasterised in software for nothing. Run it" >&2
	echo "run_segment:            without --capture; run its capture lane with it." >&2
fi

STATUS=0
if [[ "$MODE" == "capture" ]]; then
	run_capture || STATUS=$?
else
	run_logic || STATUS=$?
fi

# CD-2's post-step: the harness computes the inventory, and the runner reads its
# verdict out loud. A batch script watching exit codes must not have to open a
# JSON file to find out that a segment produced nothing.
if [[ -f "$OUT_DIR/INVENTORY.json" ]]; then
	if grep -q '"complete": true' "$OUT_DIR/INVENTORY.json"; then
		echo "run_segment: INVENTORY.json says $SEGMENT_ID is COMPLETE."
	else
		echo "run_segment: INVENTORY.json says $SEGMENT_ID is INCOMPLETE -- see $OUT_DIR/INCOMPLETE.md" >&2
	fi
elif [[ "$MODE" != "overhead" ]]; then
	echo "run_segment: no INVENTORY.json was written; the segment did not reach its close." >&2
fi

# The run-level half of the ledger. A logic lane is complete when it has done
# what ITS LANE owed; whether the frames it handed over actually exist is a
# question about the whole run directory, and this is where it gets asked.
if [[ "$EVIDENCE_LANE" == "logic" && -f "$OUT_DIR/DELEGATED.md" ]]; then
	echo "run_segment: $SEGMENT_ID delegated prescribed frames -- see $OUT_DIR/DELEGATED.md"
	echo "run_segment: check the debt over the whole run with:"
	echo "             tools/gate_f/run_inventory.py '$RUN_DIR'"
fi

echo "run_segment: $SEGMENT_ID finished with status $STATUS; artefacts in $OUT_DIR"
exit "$STATUS"
