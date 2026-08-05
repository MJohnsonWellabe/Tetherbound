#!/usr/bin/env bash
# Ralph — spawn a fresh agent per story until the backlog is gated.
#
#   scripts/ralph/ralph.sh [max_iterations]     # default 10
#
# Based on Geoffrey Huntley's Ralph pattern, via github.com/snarktank/ralph, with
# ONE deliberate change: upstream Ralph marks a story done when typecheck and
# tests pass. On this project that condition has been wrong four separate times —
# a green suite over an uncallable function, a roof six metres in the air, four
# art rounds spent on a texture that was not on screen, and a save system nothing
# invoked passing its own persistence test. So here a story is done when a BLIND
# JUDGE says so, and the tests are merely what you must pass to reach it.
# `scripts/ralph/prompt.md` is where that rule lives.
#
# The other divergence: upstream keeps learnings in `progress.txt`. This repo
# already has the stronger version — `docs/decisions/` and `docs/reviews/` — so
# the prompt points there instead of starting a parallel memory that would drift
# from them.
#
# Each iteration is a NEW agent with a clean context. The only things that cross
# the boundary are git history, prd.json, and those two doc directories. That is
# the whole point: context does not degrade across a long run, and anything worth
# knowing has to be written down somewhere durable rather than remembered.

set -uo pipefail
cd "$(dirname "$0")/../.."

MAX="${1:-10}"
PROMPT="scripts/ralph/prompt.md"
PRD="prd.json"

command -v claude >/dev/null 2>&1 || { echo "the 'claude' CLI is not on PATH"; exit 1; }
[ -f "$PRD" ] || { echo "no $PRD — run: python3 scripts/ralph/build_prd.py"; exit 1; }

remaining() { python3 -c "
import json;d=json.load(open('$PRD'))
print(sum(1 for s in d['stories'] if not s['passes']))"; }

next_story() { python3 -c "
import json;d=json.load(open('$PRD'))
o=[s for s in d['stories'] if not s['passes']]
print(f\"{o[0]['id']}  {o[0]['story']}\" if o else '')"; }

echo "Ralph: $(remaining) stories ungated, max $MAX iterations"

for i in $(seq 1 "$MAX"); do
	left="$(remaining)"
	if [ "$left" -eq 0 ]; then
		echo "Ralph: backlog is fully gated after $((i-1)) iterations"
		exit 0
	fi

	echo ""
	echo "=== iteration $i/$MAX — $left ungated — next: $(next_story)"

	# A fresh process every time. Deliberately NOT --continue and NOT --resume:
	# a loop that carries its own context is just one long agent, and loses the
	# property this whole design exists for.
	claude -p "$(cat "$PROMPT")" --permission-mode acceptEdits
	code=$?

	if [ "$code" -ne 0 ]; then
		# Do not treat a crashed iteration as a finished one. The story is still
		# `passes: false`, so the next iteration picks it up again from a clean
		# context — which is usually what an agent that ran out of room needed.
		echo "Ralph: iteration $i exited $code; the story stays open"
	fi

	# The loop's own honesty check. An iteration that commits nothing and gates
	# nothing has not moved, and running nine more of it will not help.
	if [ "$(remaining)" -eq "$left" ]; then
		echo "Ralph: iteration $i gated nothing (still $left)"
	fi
done

echo ""
echo "Ralph: stopped after $MAX iterations with $(remaining) stories ungated"
