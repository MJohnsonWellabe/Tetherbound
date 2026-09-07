# Common rules for Stage B Wave 1 lanes (state and save separation)

You are one lane of Stage B, the multiplayer conversion. The plan is
`docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md`; your wave is its Wave 1. Read the plan's §1–§4
and your own row before your brief. `docs/AGENT_WORKFLOW.md` §4 (completion contract) and §6
(testing rules) bind you; `CLAUDE.md`'s hard rules bind everyone.

- **Worktree, not the shared tree.** Every lane runs in its own git worktree (the orchestrator
  provisions it). First command: `git log --oneline -1` — your base must be the commit your brief
  names or later. Commit in the worktree as you go; do not push; the orchestrator merges.
- **Commit trailers, every commit, verbatim:**
  ```
  Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01S4VY6ina6NxjKad5XtDim2
  ```
- **Godot:** `~/godot-bin/godot` 4.7-stable. A fresh worktree has no import cache: run
  `godot --headless --path . --import || true` then `godot --headless --path . --import` once.
  Always `--headless`; never with a rendering driver. Private `XDG_DATA_HOME` for anything that
  writes `user://`. Other lanes share the 4-core box: `--only=` while developing, sequential
  smokes, the full suite only when your brief says so.
- **Seen red first.** Every new test is broken deliberately once and the failure recorded as a
  break/fail/revert triple. A test that never went red does not ship. Once each — do not sample.
- **Proportionate proof (owner instruction, 2026-09-06).** CI is the gate. Run the unit tests
  your change touches and **three to six** smokes chosen for what it reaches; add
  `smoke_playground` only if you touched world, spawn, creature or encounter code, and read its
  `^ERROR:` set once. Engine exit-time notices (`resources still in use at exit`, leaked
  `ObjectDB` instances) are not findings and are never compared across runs. A smoke that fails
  identically on your base is one routed sentence, not an investigation.
- **Report** at `ralph/reports/<LANE>-0905/REPORT.md` in the repo's format (H1, header block with
  lane/branch/base sha, `| Item | Verdict |`, commands with counts, triples, findings). If the
  tooling refuses a `.md`, put the full text in your final message.
- **Stop condition:** all items done, or two serious attempts on one item produced no new
  evidence — commit what works, record what you tried, report. Never weaken a test to pass.
- **Do not** add an autoload, edit `project.godot`, change a pure module's API, or change
  player-facing solo behaviour.
