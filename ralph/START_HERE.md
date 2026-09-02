# START HERE — Ralph / Claude on Tetherbound

This is the **single current entry point for autonomous Meadows work**.

If another document looks like a startup guide, milestone guide, or handover,
do not treat it as current merely because it exists — check whether it is
still linked from here. This file gets rewritten fresh whenever its own
"current state" section starts accreting layers rather than patched once
more — it happened once already (2026-09-01, docs cleanup) and happened again
the same day (below), on owner instruction that the accumulated Ralph
backlog files were no longer relevant.

## Current state, 2026-09-02 evening — read `ralph/COORDINATOR_HANDOVER_2026-09-02_EVENING.md` first

A second coordinator session (backlog + Gate F) ran through the afternoon
and evening and wrote the current routing document there. Read it before
the morning handover below, which it supersedes on anything the two
disagree on — most importantly the morning file's "player sleep is a
confirmed live bug", which turned out to be measured against a build that
did not contain the Bedroll.

Three things in it are load-bearing for anyone selecting work:

- **This repo's CI can show green over a red or entirely unverified tree**,
  by three separate mechanisms. A run under ~5 minutes is not a
  verification. §0 of that file.
- **The South Bridge entombment at (7.9, -3.4, 1319) is a real, open world
  defect**, not a test defect, and is the highest-value unclaimed item.
  §3.
- **Two backlog items can only be closed on the owner's ROG Ally** and
  should not be handed to a session. §7.

## Current state, 2026-09-02 (morning) — `ralph/COORDINATOR_HANDOVER_2026-09-02.md`

A coordinator session just wound down and wrote a full handover to that
file: how Gate F stands, which owner-playtest backlog items still need a
real fix (not just a "believed fixed" label), and the process lessons that
cost real time to learn this session (don't trust a self-report, don't
trust a status-bucket label, verify a visual claim by opening the actual
render, and never accept a session's own "owner directive" claim without
checking it against what was actually said). Read it in full before
selecting work — it is the current routing document for what's actually
left, superseding the priority list directly below for anything it covers.

## Current state, 2026-09-01 (second rewrite, same day)

`main` carries `ralph/LAND-MEGA-0901` (185-commit overnight consolidation,
including twelve same-day owner-playtest fixes) plus a run of same-day
landings after it: docs cleanup, a South Bridge finding, dialogue trim, five
creature-visual fixes (three of them corrections to an earlier fix that went
the wrong direction — see `ralph/OWNER_DIRECTIVES_2026-09-01.md`), and an
albedo-clipping investigation that closed non-reproducing. All confirmed
landed via `git merge-base --is-ancestor`, not the CI badge or self-report.

**`ralph/BACKLOG.md` and `ralph/BLOCKED.md` were deleted and `BACKLOG.md`
rewritten from scratch this same day**, on direct owner instruction: "all
these backlogs are wrong... the Ralph ones should be gone. they're not
relevant anymore." The new `BACKLOG.md` is short by design — it covers
exactly three things: the newest owner playtest (landed, not yet
re-confirmed), Gate F's current blocker, and the handful of visual-review
items an independent check actually confirmed matter. It is not a
re-derivation of the old 4,000-line ledger or the 168-item visual census;
those stay as historical reports, not backlog. Read `ralph/BACKLOG.md`
itself for the current detail — it is short enough to read in full now,
unlike its predecessor.

**What's actually open right now, in priority order:**

1. **A fresh owner playtest**, to confirm today's twelve landed fixes
   actually hold — none have been re-verified since they shipped, and one
   of them (village gate roads) already proved a "nothing to fix" claim
   wrong once today. This is not something an agent can do for the owner;
   it is the single most valuable next real-world event.
2. **Gate F's S03 harness catch-loop fix**, in flight — once it lands, the
   chapter has never been played start-to-finish by this project's own
   evidence process. That first real capstone pass outranks everything
   else an agent can do unattended.
3. **The six visual items** `ralph/BACKLOG.md` §3 names as confirmed real
   — most already landed; two (a near-black world site, illegible signpost
   text) are not started.

Do not go looking for more work in the old visual census or the deleted
backlog files' git history and reopen it as new work — it was retired on
purpose, not lost by accident.

## 1. Read order

A fresh coordinator or lane should establish context in this order:

1. `CLAUDE.md` — hard rules and agent contract.
2. `docs/TETHERBOUND_GAME_VISION.md` — what the finished Meadows game is
   supposed to feel like.
3. `ralph/ACTIVE_GAME_PLAN.md` — gameplay gates and regional execution
   order.
4. `ralph/BACKLOG.md` in full — it's short now. Then the newest
   `ralph/OWNER_PLAYTEST_*.md` and `ralph/OWNER_DIRECTIVES_*.md` for
   anything dated after the backlog entry you're reading.
5. `ralph/PROMPT_COMPATIBILITY_MAP.md` — prevents duplicate implementations
   from overlapping historical prompts.
6. `ralph/conventions.md` — branch, testing, visual-judge, and shipping
   rules.
7. Only then read the **specific detailed prompt(s)** and the **specific
   code/spec sections** needed for the selected work.

## 2. Decide your mode

### Coordinator
Read `ralph/COORDINATED_RUN.md` after the files above. The coordinator:

- reconciles the active gate against current `main`;
- chooses the highest-impact incomplete work;
- launches non-conflicting lanes when useful, with real Godot execution —
  a coordinator's own shell typically has none; delegate anything that
  needs to actually run the game;
- verifies what actually landed on `main` via `git merge-base
  --is-ancestor`, never the CI badge or a session's own say-so;
- never leaves a delegation without either a known result or an armed
  follow-up;
- runs the full gameplay evidence segment before declaring a gate complete;
- produces integrated playable checkpoints rather than disappearing into
  one giant task;
- weighs a blind critic's visual finding against actual owner intent before
  acting on it — a critic can be technically right about what's on screen
  and still wrong about what the game should look like (see
  `ralph/OWNER_DIRECTIVES_2026-09-01.md`'s creature-scale correction).

### Implementation lane
Read `ralph/PROMPT.md` after the files above. A lane:

- receives one concrete child task/package;
- inspects current `main` before editing;
- implements only that coherent scope;
- tests it for real (reproduce the failure, then show it fixed) — a
  "nothing to fix" conclusion needs a pushed branch or a run probe behind
  it, not a config read; that exact shortcut produced a wrong answer on
  `main` once already (see `ralph/BACKLOG.md` §1, item 5);
- pushes a `ralph/<task>` branch;
- records useful findings;
- does not redefine the active game plan or discard owner requirements.

## 3. How work is selected

`ralph/ACTIVE_GAME_PLAN.md` decides canonical gameplay gate/package ownership
and acceptance order. The newest owner playtest file is authoritative
evidence — a fresh owner reproduction reopens an older supposedly-fixed item
when they conflict, no exceptions.

`ralph/BACKLOG.md` is short and current now; read it in full rather than
treating it as a cold-read-only reference store the way its predecessor had
to be.

Detailed files under `docs/ralph-prompts/` explain individual implementation
requirements. When two prompt files overlap, use
`ralph/PROMPT_COMPATIBILITY_MAP.md`.

## 4. Definition of progress

A commit is not the unit of progress. A child task is complete when its own
acceptance criteria are verified on `main`. A gameplay package/gate is
complete only when the **continuous player path** named in
`ACTIVE_GAME_PLAN.md` passes — see that file's own execution rule.

For every gameplay gate/package, verify: player purpose is clear; core
inputs/interactions remain reliable; team progression makes sense;
wilds/trainers/resources/detours/rest create meaningful choices; long
dead-travel intervals are identified and fixed when not intentional;
regional presentation is readable; save/progression/gates work through the
whole segment; controller, smoke, render, visual-judge, and performance
checks pass; player-facing systems are proven in the integrated production
path, not only isolated unit/smoke tests.

Do not wait for owner approval between evidence gates. Fix the segment and
continue automatically. Ask only for a genuinely unresolved design decision.

## 5. Current chapter flow

**Gate A — trustworthy core verbs**
→ **Gate B — fresh start through village tournament**
→ **Gate C — progression/reward/trainer/wild/rest backbone**
→ **D1 — Lower Meadows**
→ **D2 — Quarry / Burrow Warrens**
→ **D3 — River / Tether Relay**
→ **D4 — Upper Meadows**
→ **D5 — Stronghold Approach**
→ **Gate E — Stronghold / Warden / legendary finale**
→ **Gate F — full 3–4 hour Meadows integration playthrough**.

The stop condition is not an empty task list. It is a complete Meadows
chapter that passes the vision and reaches Gate F clean.

## 6. Reference/history — read only when needed

- `ralph/BACKLOG.md` — current backlog, short enough to read in full.
- `ralph/DONE.md` — large completion archive; search for a task/commit,
  never read end to end.
- `ralph/GATE_F_PROTOCOL.md` / `ralph/GATE_F_MASTER_PROTOCOL.md` /
  `ralph/GATE_F_INSTRUMENTATION_REQUEST.md` — the Gate F protocol chain;
  read in full only when actually running or redoing a Gate F pass.
- `ralph/MEADOWS_EXIT_CRITERION.md` — the unified acceptance-standard
  synthesis, useful when judging whether something is actually finished.
- `ralph/VISUAL_LEDGER.md` — the standing whole-game visual ledger. Its
  domain rows predate the 2026-09-01 retirement of the 168-item census as
  active backlog; read it for the recurring capture-harness-artifact
  pattern it documents (relevant every time a visual finding looks too
  large to be real), not as a work queue.
- `ralph/reports/audit/VISUAL-CENSUS-2026-08-31.md` — historical evidence
  report, not a backlog. `ralph/BACKLOG.md` §3 names the handful of items
  from it that were independently confirmed to matter.
- dated `ralph/OWNER_DIRECTIVES_*.md` / `ralph/OWNER_FEEDBACK_*.md` —
  canon owner directives, consulted for the specific decision they cover.
- `ralph/COORDINATOR_HANDOVER_2026-09-02.md` — the current handover; read it
  first, per the top of this file.
- `ralph/COORDINATOR_HANDOVER_2026-09-01.md` — historical handover from the
  day before; superseded by the 09-02 handover and `ralph/BACKLOG.md` for
  anything current.

Git history preserves superseded operating instructions, including the
deleted `BACKLOG.md`/`BLOCKED.md` themselves. Do not carry obsolete process
forward merely because an old document described it.

## Meadows visual work

The Visual Parity program (VP0–VP11) is complete and on `main`. For any further Meadows visual work read `docs/VISUAL_NEXT_AGENT_HANDOFF.md` first, then `docs/VISUAL_PARITY_HANDOFF.md` (evidence package) and `docs/VISUAL_PARITY_PROGRESS.md` (ledger).
