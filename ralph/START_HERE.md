# START HERE — Ralph / Claude on Tetherbound

This is the **single current entry point for autonomous Meadows work**.

If another document looks like a startup guide, milestone guide, or handover,
do not treat it as current merely because it exists — check whether it is
still linked from here. This file was rewritten fresh on 2026-09-01 (a full
docs cleanup, owner directive) specifically to stop the "CURRENT STATE"
sections accreting on top of each other; if this file starts doing that
again, rewrite it again rather than patching once more.

## Current state, 2026-09-01

`main` carries `ralph/LAND-MEGA-0901` — confirmed landed via
`git merge-base --is-ancestor`, not the CI badge. That branch closed two real
bugs found by full CI, both root-caused and fixed, not band-aided:

- `Verify free_build` — a test-only defect (a test helper carried stale
  height across sloped terrain, embedding the player in the ground and
  triggering an unrelated recovery teleport that corrupted a later
  measurement). The movement-gating game code was never broken.
- `Verify tournament_bracket` — a real player-facing defect: a wild
  creature's in-combat movement was missing the anti-stuck escape logic the
  pre-engagement chase already had, so a trainer battle could get
  permanently stuck. Fixed by sharing that logic into the in-combat path
  (`scripts/creatures/wild_creature.gd::_unstick()`).

A third failure (`Verify traversal`, "the South Bridge gate can be walked
around") was confirmed a flake by a clean re-run on the same commit — not
caused by anything in the branch.

Read `ralph/COORDINATOR_HANDOVER_2026-09-01.md` for the full detail on what
that landing session found and the work it queued behind it. As of this
rewrite, still open from that queue:

- the creature visual lane (capture every species in field/bed/combat →
  blind review → per-defect fix sessions);
- a feasibility call on redoing the Gate F capstone playthrough (a prior run
  found the chapter walled at the South Bridge, bands 2-5 unreachable —
  re-verify against landed `main` before committing to a full redo);
- backlog lanes pulled from `ralph/BACKLOG.md` and the audit-derived ledgers.

## The docs cleanup that produced this rewrite

Owner directive, 2026-09-01: delete old Ralph process/coordination docs and
outdated start-here files, once their content has been acted on. Roughly 30
files were removed from `ralph/` in that pass — dated coordination logs,
closed-gate evidence docs, superseded owner-playtest transcripts (their
substance is preserved in `ralph/BACKLOG.md`/`ralph/DONE.md`), and legacy
process manuals `START_HERE.md` itself already called superseded.

**`ralph/BACKLOG.md` was explicitly kept, not deleted.** It is the canonical
ledger — CLAUDE.md calls it "the complete ledger/history," and
`ralph/GATE_F_MASTER_PROTOCOL.md`'s own Phase B deliverable states outright
that it "remain[s] operationally authoritative... must not be retired." A
few *derived*, one-off ledgers built by past audit sessions
(`ralph/reports/audit/BACKLOG-FROM-AUDIT-2026-08-31.md` and similar) are
separate from it and get folded into fresh lane briefs, then removed, as
that work is picked up — see the backlog-lanes item above.

Kept as still-active, cross-referenced canon (verified by grep before this
rewrite, not assumed from filenames): the whole Gate F protocol chain
(`ralph/GATE_F_PROTOCOL.md`, `ralph/GATE_F_MASTER_PROTOCOL.md`,
`ralph/GATE_F_INSTRUMENTATION_REQUEST.md`), `ralph/MEADOWS_EXIT_CRITERION.md`
(the audit's own acceptance-standard synthesis), `ralph/VISUAL_LEDGER.md`
(the standing whole-game visual ledger — read this before starting the
creature visual lane), every `ralph/OWNER_DIRECTIVES_*.md` and
`ralph/OWNER_FEEDBACK_*.md` file (the owner's own words don't expire), and
`ralph/BLOCKED.md`.

## 1. Read order

A fresh coordinator or lane should establish context in this order:

1. `CLAUDE.md` — hard rules and agent contract.
2. `docs/TETHERBOUND_GAME_VISION.md` — what the finished Meadows game is
   supposed to feel like.
3. `ralph/ACTIVE_GAME_PLAN.md` — gameplay gates and regional execution
   order; this is what decides current priority, not a cold read of
   `BACKLOG.md`.
4. newest `ralph/OWNER_PLAYTEST_*.md` — newest owner-play evidence wins
   where old wording/tests conflict.
5. `ralph/PROMPT_COMPATIBILITY_MAP.md` — prevents duplicate implementations
   from overlapping historical prompts.
6. `ralph/conventions.md` — branch, testing, visual-judge, and shipping
   rules.
7. Only then read the **specific detailed prompt(s)** and the **specific
   code/spec sections** needed for the selected work.

Do **not** cold-read all of `BACKLOG.md` or `DONE.md`. They are
reference/history stores, not the startup briefing.

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
  follow-up (`ralph/../.claude/skills/overnight-coordination/SKILL.md` on a
  landing branch that carries it, or general practice: schedule a check-in);
- runs the full gameplay evidence segment before declaring a gate complete;
- produces integrated playable checkpoints rather than disappearing into
  one giant task.

### Implementation lane
Read `ralph/PROMPT.md` after the files above. A lane:

- receives one concrete child task/package;
- inspects current `main` before editing;
- implements only that coherent scope;
- tests it for real (reproduce the failure, then show it fixed);
- pushes a `ralph/<task>` branch (or the shared landing branch it was
  briefed against);
- records useful findings;
- does not redefine the active game plan or discard owner requirements.

## 3. How work is selected

`ralph/ACTIVE_GAME_PLAN.md` decides **canonical gameplay gate/package
ownership and acceptance order**. The newest owner playtest file is
authoritative evidence — a fresh owner reproduction reopens an older
supposedly-fixed item when they conflict.

`ralph/BACKLOG.md` is the complete ledger and remains authoritative for
whether an old task exists, but does not control current Meadows priority
when the active plan reorders that work. It is consulted for a task already
selected, never cold-read to choose one.

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

These files remain useful but are **not startup documents**:

- `ralph/BACKLOG.md` — complete historical/current ledger; targeted lookup
  only.
- `ralph/DONE.md` — large completion archive; search for a task/commit,
  never read end to end.
- `ralph/BLOCKED.md` — parked work and reasons.
- `ralph/GATE_F_PROTOCOL.md` / `ralph/GATE_F_MASTER_PROTOCOL.md` /
  `ralph/GATE_F_INSTRUMENTATION_REQUEST.md` — the Gate F protocol chain;
  read in full only when actually running or redoing a Gate F pass.
- `ralph/MEADOWS_EXIT_CRITERION.md` — the unified acceptance-standard
  synthesis, useful when judging whether something is actually finished.
- `ralph/VISUAL_LEDGER.md` — the standing whole-game visual ledger; read
  before any visual capture/judge/fix lane.
- dated `ralph/OWNER_DIRECTIVES_*.md` / `ralph/OWNER_FEEDBACK_*.md` —
  canon owner directives, consulted for the specific decision they cover.
- `ralph/COORDINATOR_HANDOVER_2026-09-01.md` — the freshest handover;
  supersede this pointer with a newer one as soon as one exists.

Git history preserves superseded operating instructions. Do not carry
obsolete process forward merely because an old document described it.
