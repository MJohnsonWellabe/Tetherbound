# Tetherbound — Workflow

**What this is.** How work gets done here: how it's chosen, sized, delegated,
tested, judged, landed, and when to stop. It replaces `AGENT_WORKFLOW.md`,
`archive/ralph/conventions.md`, `archive/ralph/COORDINATED_RUN.md`, `archive/ralph/PROMPT.md`,
`archive/ralph/START_HERE.md`, the dated coordinator handovers and the goal/handoff
document pattern.

The hard rules are in `AGENTS.md` / `CLAUDE.md`. What "done" means is in
`ACCEPTANCE.md`. This file is about *how*.

---

# 1. The execution principle

> **A region or system is not done because code and data exist. It is done when
> the complete player path produces the intended Tetherbound experience.**

Everything below is in service of that one sentence.

## 1.1 Spec-driven delivery, with one owner decision point

The owner settles **what the game must do** in the existing owning design file
and its acceptance criterion before implementation starts. Record the decision,
its scope and the spec commit in STATE. An unresolved pillar, story, art-bar or
hard-rule choice remains a spec question; an agent must not answer it by coding.
Once the spec is settled, agents execute, inspect, test and judge the work
without asking the owner to review each design note, code diff or test result.
Before an unattended Meadows-to-later-regions run, inventory each next
criterion against its owning spec and an observable pass/fail witness. Work
the settled slices in dependency order; keep genuinely undecided product
choices open and continue independent slices. No count of passing checks
alone closes a chapter.
For the current four-chapter pass, ROADMAP §3 registers exactly **15 feature
requests F01–F15** and seven supporting X01–X07 workstreams. Each F row,
its owning design sections and ACCEPTANCE §6.1 are that feature's PRD; do
not invent a parallel PRD file or use the 13 chapter cards/31 roadmap steps
as feature-request IDs. Claude starts with F01 and the Meadows M1–M4 cards,
then F06–F08/C1–C3, F09–F11/S1–S3 and F12–F15/T1–T3. Split each active F
into 30–90 minute work orders after checking current code and evidence. Each
work order names its F/X ID, one criterion, baseline, exact owned paths,
expected player result, proof, dependencies and exclusions. Put the ID and
criterion in its draft PR's Anchor, update STATE with actual progress and
revise estimates when evidence changes. A failed card names the next repair,
not a request for routine owner review.
ROADMAP §3 also fixes the session ownership sequence: session 1 owns F01–F04,
then separate sessions own F05, F06 and so on through F15. A run ending before
its assigned F rows pass creates a continuation of the same batch from STATE
and current main; it does not hand the next feature to a new session as if the
unfinished one were accepted. The next batch starts only after merged evidence
closes the previous F rows and, at chapter boundaries, its integrated cards.
An agent's own completion report is never its review: another agent (or an
independent review pass with no implementation context) checks the actual diff,
runtime evidence and criterion before landing. If an automated or agent check
cannot establish a criterion, mark it **unproven**, keep that criterion open and
continue independent work. Do not turn missing proof into a passing checkbox.

Route work by its source, not by its apparent size:

| Lane | Entry anchor | Proof and write-back |
|---|---|---|
| Feature | A settled new or changed player-visible requirement in GAME_BIBLE or the owning design file, with observable acceptance in ACCEPTANCE or that spec. | Named criterion → named test or ordinary-play witness → result on an identified build. Write implementation decisions back to the owning design/TECHNICAL file. If the spec is silent, settle it before changing behavior. |
| Bug | A current build demonstrably violates an existing accepted criterion or an explicit owner report. | Reproduce the failure, preferably with a test that fails before the fix and passes after; run the affected real player path. Strengthen the test that allowed the escape and update STATE. A new behavior request is a Feature, even if it is called a bug. |
| Task | A cited repository rule, dependency, maintenance defect or measured cost, with no intended player-behavior change. | Name the invariant, show focused regression evidence and verify that player behavior did not change. Do not invent a product requirement to justify housekeeping. |
| Hotfix | A released build has a confirmed severe regression and the normal path is too slow. | First establish the affected package and last working package; prefer a reversible rollback where authorized. A patch still gets build and affected-path checks. Reconcile the fix, tests and STATE on main after the incident. A CI failure alone is not a production incident. |

For any lane that changes the game, use this delivery chain:

1. **Anchor.** State the spec/criterion or defect, its baseline commit/package,
   the player-visible result and what is out of scope. A new-area architecture
   decision goes in TECHNICAL or the owning design file, not a disposable
   parallel spec. Only an unresolved product decision returns to the owner.
2. **Slice.** Make a bounded branch and draft PR from current main. The PR
   carries a traceability table: requirement/criterion, named test or gameplay
   witness, expected result, observed result and build/commit. No `TBD` counts
   as coverage. Every changed behavior has a row; a Task names its invariant.
3. **Build and prove.** Implement a small slice, run focused tests and the
   ordinary runtime path that can falsify the claim. For a Bug, demonstrate the
   pre-fix failure when feasible. For visual work, capture the production camera
   in motion and use the blind judgment in ACCEPTANCE. Do not count a test that
   mirrors a constant or a staged screenshot as player-path proof.
4. **Independent agent review.** Inspect the PR's exact diff against the
   settled spec, hard rules, neighboring behavior, evidence and migration/
   authority effects. Record findings in the PR; fix them and repeat affected
   checks. This replaces routine human code-owner and post-merge QA review.
5. **Integration gate.** Check CI's actual jobs, then verify the PR combined
   with current main. Re-run affected checks when either side changed. A skipped
   export, retried smoke, or green docs-only job is not a passing game build.
   Land only the exact reviewed and verified head through a PR; confirm the
   commit on main. Report a criterion as accepted only at the scope its evidence
   supports, and write the result and remaining gaps into STATE.

This deliberately uses the repo's current live document set (§11), CI and
runtime witnesses. It does not create four files per feature, a second task
tracker, or a claim that every spec has a meaningful test merely because a row
exists. A chapter still requires its continuous ACCEPTANCE path; small PRs do
not add up to chapter acceptance by themselves.

---

# 2. Two tiers, one owner of judgment

**Senior orchestrator.** Owns everything needing product judgment: understanding
the game, choosing what's next, decomposing it into bounded tasks, architecture
decisions, assigning work, reviewing evidence, visual judgment, merge decisions,
integration, acceptance. The orchestrator does **not** personally do mechanical
work a cheaper agent can do reliably.

**Lower-tier agents.** Own bounded work with a written brief: inventories,
investigations, test writing, isolated bug fixes, small systems, asset cleanup,
file moves, reference fixes, documentation drafts, regression runs, capture
runs, blind visual critiques.

Different dated documents in this repo have called the senior tier Fable, Astra
or Opus and the implementation tier Sonnet, Sol or Haiku. **These are the same
two-tier concept under different names**, not three systems.

| Task shape | Tier |
|---|---|
| Inventory, grep, count, list, collect captures | cheapest |
| Investigate a bug with evidence; write a bounded fix + test; draft a doc | mid |
| Blind visual critique of frames (told nothing about what changed) | mid |
| World composition, encounter identity, pacing, art direction, acceptance | orchestrator |
| Rebuild of a system that has failed 3+ tuning rounds | orchestrator designs, mid implements |

**The orchestrator verifies every important claim a lower-tier agent makes.** A
self-report is not evidence. "Nothing to fix" from a config read was wrong three
times in one week. "Landed" and "confirmed by play" are different states and are
tracked separately.

**Reserve deliberate reasoning for judgment calls; move fast on routine
execution.** Picking which gap matters most, deciding how a fix should work, and
reviewing your own evidence honestly before claiming something is done — these
deserve real thought. Writing the code once the approach is settled, running
tests, capturing evidence — do these quickly, and don't re-litigate a decision
already settled in the Bible or in `ACCEPTANCE.md`.

---

# 3. Choosing and shaping work

## 3.1 A lane needs written acceptance criteria, not a task list

**A lane pointed at tasks drifts** once the obvious ones are done or a
distraction appears. That is how a lane meant to finish the Meadows spent two
weeks on an automated campaign-proof harness one bug-fix at a time: each step
was reasonable, and nothing caught the accumulation because there was no written
"what does done look like" to check against.

A lane pointed at **written acceptance criteria** has a standard it keeps
checking itself against, independent of which task it's on. Every lane's brief
contains:

- **What done looks like**, concretely enough to check — named criteria with a
  source (a section of `ACCEPTANCE.md`, a measurable target, a named reference
  game and the specific lesson to take from it). Reuse an existing criterion
  rather than re-deriving one.
- **What is explicitly out of scope**, named specifically enough to self-check
  rather than inferred from a task list's silence.
- **An order of work**, so a session facing several true things to do next
  doesn't pick whichever is most interesting.
- **Where progress and results get written** (`STATE.md`, and a report directory
  for evidence).

## 3.2 Task size

A task is the right size when one agent can, in one session: understand it from
the brief, implement it, test it for real, commit it, and have it reviewed.
Target **30–90 minutes**. Past that without a clear finish, checkpoint, report
the blocker, and hand back for decomposition.

Never put several unrelated systems in one brief. Never let two agents
independently invent the same contract — a regional layout, a reward curve, an
objective sequence, a spawn table. The orchestrator settles the contract first,
then hands out slices.

**Every brief contains:** the branch (from current `main`); the player-visible
outcome; the exact files the agent owns and the files it must not touch; the
tests to run; whether the change is visual (and so needs a render and possibly a
blind judge); the completion-report format (§6); and a stop condition.

## 3.3 Only the orchestrator reads the whole stack

**A delegated subagent reads its brief, not the full directive stack.**
Re-deriving `AGENTS.md` + Bible + `ACCEPTANCE.md` + `STATE.md` on every scoped
task wastes context, and on a long session it is the visible cause of turns that
read for minutes and produce nothing. If a subagent's brief turns out to need
something the brief didn't include, that is a **brief-writing defect to fix**,
not a reason for every subagent to re-read everything.

## 3.4 Verify a document's claims against source

**A document's claim about what is or isn't implemented is unverified until you
have read the source.** A goal document once asserted "no combat code has
changed" — a reasonable inference from that lane's own recent activity — and it
was simply wrong: a prior lane had substantially implemented three rungs of a
combat system without any document being updated.

This is "a self-report is not evidence," extended to documents. **A document is
itself a report, written at a point in time, and goes stale the moment something
else lands.** Audit source before assuming a gap, and before assuming something
is already handled. Cite functions, config values and commit hashes.

---

# 4. Parallelism and the render lock

Parallelize agents that touch independent files. Serialize agents whose changes
are coupled. Each agent gets an explicit ownership list; a collision on a shared
file (`playground_hud.gd`, `game_state.gd`, `playground_world.gd`,
`vegetation.json`, `grass_field.json`) is a reason to serialize, not to hope.

**One Godot process at a time per machine for renders.**

The lock covers **writes, not reads**. It exists because import, export and
render all write `.godot/imported/`, and two processes writing that cache
corrupt each other's import state. It does not exist because Godot cannot run
twice.

- **Locked:** anything that imports, re-imports, exports, or renders frames.
- **Not locked:** unit tests, headless smokes and probes against an
  already-imported project. These only read the cache. Running them behind the
  render lock serializes work with no conflict, and is the single largest
  avoidable throughput loss on a one-box run.

Two narrow exceptions to the read carve-out: a smoke that builds a full
Terrain3D world can exhaust RAM when two run at once, so serialize **world**
smokes against each other; and any run that would trigger a re-import takes the
write lock.

**Queue by player-path priority, never first-come.** A lane on the critical
playable path outranks a lane whose criterion is deferred polish. A deferred
task holding the lock while playable-path lanes wait is a scheduling defect —
preempt it.

**When the lock is the ceiling, widen the box before waiting on it.** Additional
git worktrees each carry their own `.godot/` and therefore their own import
cache, so renders in separate worktrees do not conflict — the cost is disk and
one cold import each. And CI runs jobs in parallel on other machines: push the
branch and read the run rather than serializing validation locally.

**When several sessions share one machine**, use a plain local file **not
tracked by git** (e.g. `RENDER_LOCK.json` at a fixed path outside any worktree)
holding `{held_by, since_utc}`. Claim it before any capture/import/export step,
release it immediately after including on crash or abort, give a priority order
across sessions rather than first-come, and reclaim a stale lock after two
hours. A git-tracked lock loses the race it exists to prevent.

---

# 5. Testing

- **Unit suite:** `godot --headless --path . --script tests/run_tests.gd`
  (~28 minutes on a 4-core box). One file or one method:
  `-- --only=<file>::<test>`. A selector matching nothing is a hard error, so a
  typo can't silently run and pass the whole suite. Shard with `-- --shard=I/N`.
- **Smoke:** `godot --headless --path . --script tests/smoke_<name>.gd`
- Run the tests the task names, plus `tests/smoke_art.gd` for anything touching
  creature data or models, plus the **full** suite for save-format or autoload
  changes.
- **Tests must exercise real behaviour**: real parsed input events for
  controller/UI focus, real open/close cycles for modals, persisted
  player-facing state for saves, the actual construction sequence for building.
  **A test that passes because the feature is absent is worse than no test.** A
  green check is not evidence until something has seen it go red for the right
  reason.
- **Address inventory by item identity, never by slot offset.** Six harness
  failures in one day were fixed-slot lookups going stale.
- If a test is red because the implementation is wrong, **fix the
  implementation.** Never skip, disable or quarantine a test to get green.
- **A world boot is its own test.** Run
  `godot --headless --path . --script tests/smoke_playground.gd` before any push
  touching world, spawn, creature or encounter code. Then grep the log for
  `^ERROR:` — **`SCRIPT ERROR` alone is not enough.** GDScript raises
  `SCRIPT ERROR`, but the engine's own subsystems raise plain `ERROR:`, and a
  narrower grep silently passes those. A native `ERROR: Parameter "material" is
  null` once sat in a run whose `SCRIPT ERROR` count was zero.
  **The count is not stable and must not be the bar** — that same error appeared
  1, 2, 2 and 3 times across four runs of near-identical trees, because it comes
  off alpha creature builds whose number varies with what streamed in. Check
  that the **distinct set** of error lines does not grow, which means reading
  them rather than counting them.

---

# 6. The completion contract

Every implementation agent ends with this report, and the orchestrator reads it
**against the actual branch**, not against the summary:

- files changed;
- functionality implemented, in player-visible terms;
- tests run, with the exact command and pass/fail counts;
- runtime validation performed — which smoke or probe actually exercised the path;
- captures, if visual, with the path to the frames and the judge verdict if one
  was required;
- known limitations and anything deliberately not done;
- **commit hash and branch.**

A completion report without a commit hash is not complete; read-only or delegated design work instead identifies its exact baseline and artifact, and the orchestrator commits the combined authorized result. A report whose test claim cannot
be reproduced from the branch is treated as failed.

**For implementation tasks, a written finding alone is not a checkpoint.** Explicitly requested research/design reports are deliverables and must not trigger unauthorized code work. A turn producing only a report — no
diff, no commit, no test run, no render — does not close a checkpoint interval,
even when it correctly diagnoses something real. Diagnosis is real work and
belongs in the report, but it is not a stopping point on its own.

---

# 7. Renders and visual judgment

**Capture invocation — never `--headless` together with a rendering driver. It
hangs forever and leaves a zombie.**

```
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
  --resolution 1280x720 --script tools/survey.gd
```

`tools/survey.sh` wraps this. `--headless` remains correct and fast for **tests**,
which render nothing.

- **Re-import after any asset or bake change before capturing**
  (`godot --headless --path . --import`), or the frames come back
  pixel-identical to the pre-change asset.
- A fresh container has no `.godot/` import cache — import once before any
  script-driven capture, or viewpoints silently render flat rather than erroring.
- `tools/capture_diag_minimal.gd` is a 120-second smoke for this invocation
  shape. If it can't write a PNG, fix the invocation before blaming the capture
  script, the scene or the box.
- **Hung captures leave zombie processes.** Before pruning a worktree, kill
  anything whose `/proc/<pid>/cwd` reads `(deleted)`.

The judging protocol, the two bar questions, the stopping rule and when a blind
judge is required are all in **`ACCEPTANCE.md` §4**.

---

# 8. Branches, CI and landing

- Work on a branch from current `main`. `ralph/<task>` is the lane prefix,
  `claude/<task>` the orchestrator prefix, `scratch/<x>` for throwaways.
- **CI runs only on `pull_request` events and on pushes to `main`.** A branch
  with no pull request is **never verified** — open a draft PR early and batch
  pushes to it (a newer push cancels the run in flight on the same ref).
- **Never push to `main` directly.** Land through a pull request. A ready PR
  with a settled spec, filled proof mapping, independent agent review and the
  required CI/process checks is eligible for GitHub auto-merge without owner
  code review. GitHub branch protection requires `ci-gate` and `traceability`.
  Verify the landing with `git merge-base --is-ancestor <sha> origin/main`,
  never with a badge or a summary line.
- **A CI run under five minutes is not a verification.** A full run is 35–45
  minutes. CI skips every code job when the diff against the base is
  documentation-only — check the run duration **and** that code jobs actually
  ran.
- **`RETRIES: 3` in the smoke jobs hides a consistent first-attempt failure.** A
  ~21-minute step is three ~7-minute attempts. **A test that goes 0-for-1 and
  then passes is a finding, not a pass.**
- Fast-forward only. If `main` moved, merge `main` forward — never rebase a
  branch another agent is live on — and push again.
- `[skip ci]` is for WIP checkpoints only. The commit you want verified carries
  no marker.
- **A landed branch publishes the rolling development download automatically.**
  Release exports, boots and packages the game before replacing the asset/tag;
  failure leaves the previous download in place and is an open release defect.
  Before telling the owner a fix is playable, verify the asset timestamp and
  `latest` tag against the landed commit. The owner has playtested stale builds.
- Do not rewrite history on a branch someone else is on. No empty commits or
  close-and-reopen to kick CI.

---

# 9. Evidence hygiene

- Commit the **written verdict** and at most **one contact sheet per round**,
  named `_sheet*.png` (the leading underscore is what the ignore rules let
  through). Do **not** commit per-frame screenshots or telemetry `.jsonl`/`.csv`
  — 2.8 GB of payload accumulated in three days before this rule, and 49 % of
  commits in one window were evidence dumps.
- Owner feedback is recorded in `STATE.md`'s feedback section and outranks every
  other document for what it covers. **A fresh owner reproduction reopens any
  item a ledger says is fixed.**
- When an owner report conflicts with a passing test, **check which build they
  actually played** before assuming the test lies.
- Report trees grow without bound and every fresh orientation pays their read
  cost. Keep live status in `STATE.md` under its size cap (§11); retain older evidence in its existing location/Git history and link the exact relevant verdict. Do not create new dated archives or move evidence gratuitously.

---

# 10. Definition of done

- **Child task.** Its player-facing acceptance criterion holds on current
  `main`; its tests pass; its visual evidence passes if visual; no adjacent core
  verb regressed; and the orchestrator has **verified** it, not just read the
  report.
- **Region or system.** The continuous player path produces the intended
  experience end to end. Every child having a commit is not a region passing.
- **Chapter.** `ACCEPTANCE.md` in full — A1–A11, system/chapter gates, visual and audio bars, density, co-op and device/reliability proof.

---

# 11. Documents

**Do not create new dated documents.** No `GOAL_<date>.md`, no
`HANDOFF_<date>.md`, no `DIRECTIVE_<date>.md`, no new `README` in a report
directory that duplicates status. That pattern produced sixty-odd stale files
and a routing layer that was six days and two superseded handoffs out of date,
and it is retired.

The authorized live document set is:

| File | Holds |
|---|---|
| AGENTS.md = CLAUDE.md | hard rules, precedence, routing |
| docs/GAME_BIBLE.md | product identity, pillars, canon and four chapters |
| docs/PRODUCT.md | audience, positioning, store copy, platform/price, success/cuts |
| docs/design/COMBAT.md, CREATURES.md, BOSSES.md | combat, individuals and named fights |
| docs/design/WORLD.md, SYSTEMS.md, PROGRESSION.md | authored world, support systems, rewards/economy/pacing |
| docs/design/UX.md, MULTIPLAYER.md, ART_DIRECTION.md, AUDIO.md | presentation, controls and shared-play contracts |
| docs/ACCEPTANCE.md | evidence required for completion |
| docs/ROADMAP.md | dependency order, estimates and cuts |
| docs/WORKFLOW.md | process |
| docs/STATE.md | live status, next work, feedback/dependencies |
| docs/TECHNICAL.md | architecture, source/run map and migration risks |

Session state, progress and owner feedback go in STATE, updated in place and kept under25KB. Remove obsolete repetition using Git history and existing evidence references; do not create dated archive/status documents to evade the cap. Evidence artifacts remain in ralph/reports/<LANE>/; they are not a parallel status ledger. `.github/pull_request_template.md` is the process input form and creates no new source of product truth. No new live planning/status documents, no dated documents, no per-session goals/handoffs.

The plan-rewrite recovery and findings are in ralph/reports/PLAN-REWRITE/FINDINGS.md. Archive sources are historical context, not automatic work assignments. Unsuperseded owner instructions retain their scope. Read exact recovered sources when necessary; do not cold-read the whole archive routinely, and do not claim every archived constraint fits in one short Bible.

A design target must name built/partial/not-built grounding, owning source/config/test, concrete behavior and out-of-scope. When superseding an archived decision, record what changed and why in the owning existing document. A report-only task may legitimately produce evidence instead of code; do not interpret the stop rule as permission to start unauthorized implementation.

---

# 12. Stop conditions

These apply to any session, and matter most in a long unsupervised window where
nothing else will catch drift in real time.

- **Two unsuccessful attempts at the same fix or the same measurement** is the
  signal to change approach or move to the next-highest-value work — not to keep
  spinning.
- **Two consecutive report-only turns** is the same signal. Change strategy or
  hand off for decomposition. Do not keep re-documenting the same finding hoping
  the next read produces a different result.
- **"Flake" is not a root cause.** Re-run a job only to confirm a failure that
  reproduces identically on the base branch, or one that died before any test
  body ran, or one that passed earlier on this exact commit — at most once. A
  second failure is real.
- **An open owner decision does not halt the session.** Record it clearly in
  `STATE.md`, take the conservative option, skip that specific piece if you
  can't, and continue with the next-highest-value work in scope. Do not wait for
  an answer nobody is there to give.
- **When a goal's acceptance criteria are genuinely met, or a real ceiling is
  reached**, write it up and move to the next goal in the stated order. Don't
  linger past a genuine completion, and don't skip ahead while an earlier goal
  still has clear unmet criteria and available time.
- **Commit and land continuously.** A day of work sitting as one giant
  unreviewed diff at the end is itself a risk. Smaller landed increments mean
  drift is caught at the next check-in instead of buried.
- **Measurement infrastructure is not the deliverable.** If a window is spending
  more time fixing a harness than fixing the game the harness measures, stop and
  re-scope.

---

# 13. Do not

- Do not cold-read `archive/` routinely. Consult exact recovered constraints when the task needs them; owner sources keep their applicable authority.
- Do not reopen retired backlogs from git history as new work.
- Do not rewrite a working system just to produce a diff.
- Do not skip, disable or quarantine a test to get green.
- Do not invent a design decision — see AGENTS precedence and STATE decisions; preserve hard rules while independent authorized work continues.
- Do not declare success because code exists.
- Do not create a new dated document.
