# START HERE — Ralph / Claude on Tetherbound

This is the **single current entry point for autonomous Meadows work**.

If another document looks like a startup guide, milestone guide, handover, or old Ralph manual, do not treat it as current merely because it exists. Start here.

## 1. Read order

A fresh coordinator or lane should establish context in this order:

1. `CLAUDE.md` — hard rules and agent contract.
2. `docs/TETHERBOUND_GAME_VISION.md` — what the finished Meadows game is supposed to feel like.
3. `ralph/ACTIVE_GAME_PLAN.md` — gameplay gates and regional execution order.
4. `ralph/ACTIVE_TASKS.md` — compact current work manifest for the active gate.
5. `ralph/OWNER_PLAYTEST_2026-08-18.md` — newest owner-play evidence; newer owner evidence wins where old wording conflicts.
6. `ralph/PROMPT_COMPATIBILITY_MAP.md` — prevents duplicate implementations from overlapping historical prompts.
7. `ralph/conventions.md` — branch, testing, visual-judge, and shipping rules.
8. Only then read the **specific detailed prompt(s)** and the **specific code/spec sections** needed for the selected work.

Do **not** cold-read all of `BACKLOG.md`, `DONE.md`, or every prompt file. They are reference/history stores, not the startup briefing.

## 2. Decide your mode

### Coordinator
Read `ralph/COORDINATED_RUN.md` after the files above. The coordinator:

- reconciles the active gate against current `main`;
- chooses the highest-impact incomplete work inside that gate;
- launches 3–5 non-conflicting lanes when useful;
- owns cross-lane file exclusions and package-level integration;
- verifies what actually landed on `main`;
- runs the full gameplay evidence segment before advancing a gate.

### Implementation lane
Read `ralph/PROMPT.md` after the files above. A lane:

- receives one concrete child task/package;
- inspects current `main` before editing;
- implements only that coherent scope;
- tests it;
- pushes a `ralph/<task>` branch;
- records useful findings;
- does not redefine the active game plan.

## 3. How work is selected

`ralph/ACTIVE_GAME_PLAN.md` decides **which gameplay gate matters now**.

`ralph/ACTIVE_TASKS.md` gives the compact current manifest.

`ralph/BACKLOG.md` is the complete ledger and remains authoritative for whether an old task exists, but it **does not control current Meadows priority** when the active plan groups/reorders that work.

Detailed files under `docs/ralph-prompts/` explain individual implementation requirements. Read only the prompt(s) relevant to the current task/package.

When two prompt files overlap, use `PROMPT_COMPATIBILITY_MAP.md`; implement once, preserving any unique acceptance detail.

## 4. Definition of progress

A commit is not the unit of progress.

A child task can be complete when its own acceptance criteria are verified on `main`.

A gameplay package/gate is complete only when the **continuous player path** named in `ACTIVE_GAME_PLAN.md` passes.

For every gameplay gate/package, verify:

- player purpose is clear;
- core inputs/interactions remain reliable;
- team progression makes sense;
- wilds/trainers/resources/detours/rest opportunities create meaningful choices;
- long dead-travel intervals are identified and fixed when they are not intentional breathing room;
- regional presentation is readable and coherent;
- save/progression/gates work through the whole segment;
- relevant controller, smoke, render, visual-judge, and performance checks pass.

Do not wait for owner approval between evidence gates. Fix the segment and continue automatically. Ask only for a genuinely unresolved design decision.

## 5. Current chapter flow

The active Meadows build progresses:

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

The stop condition is not an empty task list. It is a complete Meadows chapter that passes the vision and Prompt 70.

## 6. Reference/history — read only when needed

These files remain useful but are **not startup documents**:

- `ralph/BACKLOG.md` — complete historical/current ledger; targeted lookup only.
- `ralph/DONE.md` — large completion archive; search for a task/commit, never read end to end.
- `ralph/BLOCKED.md` — parked work and reasons.
- `ralph/MANUAL.md`, `ralph/KEYED_PROMPT.md`, `ralph/LANE_PROMPT.md` — legacy operating material; current coordinator/lane rules are in `COORDINATED_RUN.md` and `PROMPT.md`.
- dated `HANDOVER-*` files — historical snapshots.
- `GODOT_AND_CLAUDE_START_HERE.md` — human Godot setup, not autonomous task selection.

Git history preserves superseded operating instructions. Do not carry obsolete process forward merely because an old document described it.