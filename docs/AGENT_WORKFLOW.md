# Agent workflow — how Tetherbound is developed

**Status:** canonical process document, 2026-09-02. Replaces `ralph/conventions.md`,
`ralph/COORDINATED_RUN.md`, `ralph/PROMPT.md`, `ralph/START_HERE.md` and the dated
coordinator handovers (all now under `archive/ralph/`). The hard project rules stay in
`CLAUDE.md`; this file is about *how work gets done*.

## 1. Two tiers, one owner of judgment

**Senior orchestrator (Fable).** Owns everything that needs product judgment:
understanding the game, choosing the next gate, decomposing it into bounded tasks,
architecture decisions, assigning work, reviewing evidence, visual judgment, merge
decisions, integration, roadmap maintenance, gate acceptance. The orchestrator does
not personally do mechanical work that a cheaper agent can do reliably.

**Lower-tier agents (Sonnet, Haiku).** Own bounded work with a written brief:
inventories, investigations, test writing, isolated bug fixes, small systems,
asset cleanup, file moves, reference fixes, documentation drafts, regression runs,
capture runs, blind visual critiques.

The orchestrator verifies every important claim a lower-tier agent makes. A
self-report is not evidence. On this project a "nothing to fix" from a config read
was wrong three times in one week; "landed" and "confirmed by play" are different
states and are tracked separately.

**Model choice by task shape:**

| Task | Tier |
|---|---|
| Inventory, grep, count, list, collect screenshots | Haiku |
| Investigate a bug with evidence, write a bounded fix + test, draft a doc | Sonnet |
| Blind visual critique of frames (code-blind, told nothing about what changed) | Sonnet |
| World composition, encounter identity, pacing, art direction, gate acceptance | Fable |
| Rebuild of a system that has failed 3+ tuning rounds | Fable designs, Sonnet implements |

## 2. Task size and shape

A task is the right size when one agent can, in one session: understand it from the
brief, implement it, test it for real, commit it, and have it reviewed. Target 30–90
minutes of agent work. If a task exceeds that without a clear finish, the agent
checkpoints, reports the blocker, and hands back for decomposition.

Never put several unrelated systems in one brief. Never let two agents independently
invent the same contract (a regional layout, a reward curve, an objective sequence, a
spawn table). The orchestrator settles the contract first, then hands out slices.

**Every brief contains:** the branch to work on (from current `main`); the player-visible
outcome; the exact files the agent owns and the files it must not touch; the tests it
must run; whether the change is visual (and therefore needs a render + blind judge);
the completion-report format below; and a stop condition.

## 3. Parallelism rule

Parallelize agents that touch independent files. Serialize agents whose changes are
coupled. Each agent gets an explicit ownership list; a collision on a shared file
(`playground_hud.gd`, `game_state.gd`, `playground_world.gd`, `vegetation.json`,
`grass_field.json`) is a reason to serialize, not to hope.

Only one Godot process at a time per 4-core box for renders. Tests can run beside a
render, but renders cannot run beside renders.

## 4. Completion contract

Every implementation agent ends with this report, and the orchestrator reads it against
the actual branch, not the summary:

- files changed;
- functionality implemented (player-visible terms);
- tests run, with the exact command and pass/fail counts;
- runtime validation performed (which smoke or probe actually exercised the path);
- screenshots, if the change is visual, with the path to the frames and the judge verdict;
- known limitations and anything deliberately not done;
- commit hash and branch.

A report without a commit hash is not complete. A report whose test claim cannot be
reproduced from the branch is treated as failed.

## 5. Branches, CI and landing

- Work on a branch from current `main`. `ralph/<TASK>` is the shipping prefix (CI runs on
  it); `claude/<task>` is used by orchestrator sessions; `scratch/<x>` is watched by
  nothing and is for throwaways. Branches cannot be deleted from a session; do not push
  junk.
- **Never push to `main` directly.** Land through a pull request (or the manual
  consolidation workflow). Verify with `git merge-base --is-ancestor <sha> origin/main`,
  never with a badge or a summary line.
- **A CI run under five minutes is not a verification.** A full run is 35–45 minutes.
  `ci.yml` skips every code job when the diff against the base is documentation-only.
  The base is now the merge-base with `main` for branch pushes (fixed 2026-09-02), so a
  report-only head commit no longer hides an unverified code commit, but a docs-only
  *branch* still skips legitimately — check the run duration and that code jobs ran.
- **`RETRIES: 3` in the smoke jobs hides a consistent first-attempt failure.** A
  ~21-minute step is three ~7-minute attempts. A test that goes 0-for-1 and then passes
  is a finding, not a pass.
- Fast-forward only. If `main` moved, merge `main` forward (never rebase a branch another
  agent is live on) and push again.
- `[skip ci]` is for WIP checkpoints only. The commit you want verified carries no marker.
- A landed branch does not reliably publish a Windows build: `release.yml` runs on pushes
  to `main` made by humans and on explicit dispatch. Before telling the owner a fix is
  playable, check the release asset timestamp.

## 6. Testing rules

- Unit suite: `godot --headless --path . --script tests/run_tests.gd` (about 28 minutes
  on a 4-core box; `-- --only=<file>::<test>` runs one). Smoke: `godot --headless --path .
  --script tests/smoke_<name>.gd`.
- Run the tests the task names plus `tests/smoke_art.gd` for anything touching creature
  data or models; the full suite for save-format or autoload changes.
- Tests must exercise real behaviour: real parsed input events for controller/UI focus,
  real open/close cycles for modals, persisted player-facing state for saves, the actual
  construction sequence for building. A test that passes because the feature is absent is
  worse than no test. A green check is not evidence until something has seen it go red for
  the right reason.
- Address inventory by item identity, never by slot offset. Six harness failures in one
  day were fixed-slot lookups going stale.
- If a test is red because the implementation is wrong, fix the implementation.
- **A world boot is its own test, and grep it for `ERROR:`, not for `SCRIPT ERROR`.**
  `godot --headless --path . --script tests/smoke_playground.gd` before any push that
  touches world, spawn, creature or encounter code. The reason is a defect that shipped:
  a G-2 guard threw on every single world build, non-fatally, so the smokes still printed
  OK while Godot exited non-zero and no unit test covered it at all.
  Then grep the log for `^ERROR:` — **`SCRIPT ERROR` alone is not enough**. GDScript
  raises `SCRIPT ERROR`, but the engine's own subsystems raise plain `ERROR:`, and a
  narrower grep silently passes those. Found on 2026-09-04, when a native
  `ERROR: Parameter "material" is null` from the alpha-resize path sat in a run whose
  `SCRIPT ERROR` count was zero and was only noticed by reading a CI log by eye. Expect a
  small number of known-benign `ERROR:` lines; the check is that the set does not grow,
  which means reading them rather than counting them. **The count is not stable and must not
  be the bar** — `ERROR: Parameter "material" is null` was observed 1, 2, 2 and 3 times across
  four runs of near-identical trees on 2026-09-04, because it comes off alpha creature builds
  whose number varies with what streamed in. A rule written against the count would fire on
  noise and be switched off within a day; a rule written against the distinct set caught the
  real thing (a native error the `SCRIPT ERROR` grep never saw) and stayed quiet on the rest.

## 7. Renders and visual judgment

- Capture invocation (never `--headless` together with a rendering driver; it hangs
  forever and leaves a zombie):

  ```
  xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
    --resolution 1280x720 --script tools/survey.gd
  ```

  `tools/survey.sh` wraps this. Re-import (`godot --headless --path . --import`) after
  any asset or bake change before capturing, or the frames show the old asset.
- Frames from this box come from the Compatibility renderer under software GL: trust
  composition, silhouette, colour relationships, scale and geometry; do not trust fine
  lighting or post-processing. Only the ROG Ally measures frame time.
- Every visual-affecting change is judged by a **code-blind** sub-agent using
  `.claude/skills/visual-judge/SKILL.md`, given the frames and `docs/reference/` and
  nothing about what changed. Stop after two consecutive rounds that name no new defect
  and move no measured axis; record the ceiling and the mechanism that blocks it.
- Prove by number: crop medians, luminance, pixel-diff percentages, decided before the
  render. Four chronic visual items each failed 3–5 tuning rounds and were then fixed by a
  clean restart that root-caused them; tuning rounds are not progress.
- Weigh a critic's finding against owner intent before acting on it. The critic once
  shrank the starters because a rubric said the human should dominate the frame; the
  owner wants creatures to loom.

## 8. Evidence hygiene

- Commit the written verdict and at most one contact sheet per round, named
  `_sheet*.png` (a leading underscore is what the ignore rules let through). Do not
  commit per-frame screenshots or telemetry `.jsonl`/`.csv`; `.gitignore` refuses them
  under the capture-round directories of `ralph/reports/`. 2.8 GB of payload
  accumulated in three days before this rule. The one exception is a Gate F run
  directory (`ralph/reports/gate-f-*/`): the protocol requires its prescribed captures
  and save handoffs in the tree, the harness checks that with `git check-ignore`, and a
  run is 50–80 MB, so run the authoritative pass once, not twelve times.
- Owner playtests and directives are recorded verbatim in `docs/owner/` and outrank every
  other document for what they cover. A fresh owner reproduction reopens any item a
  ledger says is fixed.
- When an owner report conflicts with a passing test, check which build they actually
  played (release asset time) before assuming the test lies.

## 9. Definition of done

- **Child task:** its player-facing acceptance criterion holds on current `main`, its
  tests pass, its visual evidence passes if visual, no adjacent core verb regressed, and
  the orchestrator has verified it — not just read the report.
- **Gate:** the continuous player path named in `docs/ROADMAP.md` produces the intended
  experience end to end, recorded with the evidence template there. Every child having a
  commit is not a gate passing.
- **Chapter:** `docs/acceptance/MEADOWS_EXIT_CRITERION.md` and the Gate F protocol.

## 10. Do not

- Do not cold-read `archive/`. It is history.
- Do not reopen retired backlogs from git history as new work.
- Do not rewrite a working system to produce a diff.
- Do not invent a design decision; ask when two materially different game behaviours are
  both defensible and nothing in `CLAUDE.md`, the owner records or `docs/decisions/`
  settles it.
- Do not declare success because code exists.

## 11. Unattended coordination

Every delegation or CI run you will not watch live ends with either a known result or an
armed follow-up (`send_later` or a scheduled wake-up), never neither. Re-arm on every
check-in until the work is actually done. Read the whole CI run, job by job. Cloud
lane sessions are not reachable by message; check their `status_bucket` on every
check-in, because a lane that stops to ask a question pushes nothing and looks idle.
See `.claude/skills/overnight-coordination/SKILL.md`.
