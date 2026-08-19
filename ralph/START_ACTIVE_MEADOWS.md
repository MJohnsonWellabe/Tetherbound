# Restarting Ralph — Active Meadows Build

Use this when the autonomous/coordinated Ralph loop is turned back on.

The repository has been restructured so **the task ledger remains intact but current work is selected by gameplay gates**.

## Bootstrap

Every coordinator/firing should begin by reading:

1. `CLAUDE.md`
2. `docs/TETHERBOUND_GAME_VISION.md`
3. `ralph/ACTIVE_GAME_PLAN.md`
4. `ralph/PROMPT_COMPATIBILITY_MAP.md`
5. `ralph/OWNER_PLAYTEST_2026-08-18.md`
6. `ralph/conventions.md`
7. the relevant portion of `ralph/BACKLOG.md`
8. relevant detailed prompt(s) under `docs/ralph-prompts/`
9. relevant canonical spec/decision sections

If running one coordinator session, also follow `ralph/COORDINATED_RUN.md` for lane management, file exclusions, CI, bundling and bookkeeping. Its operational guidance remains valid; `ralph/ACTIVE_GAME_PLAN.md` replaces the old flat backlog order for **which Meadows work should be chosen next**.

## First action after restart

Reconcile **Gate A** against current `main` before launching implementation lanes.

For every Gate A child:
- if clearly shipped and current evidence passes, mark/reconcile it rather than rebuilding;
- if a newer owner reproduction says it is still broken, reopen/fix it even if old DONE history says otherwise;
- if two prompt files overlap, use `PROMPT_COMPATIBILITY_MAP.md` and implement once;
- preserve every old backlog item in the ledger.

Then launch parallel non-conflicting lanes on the highest-impact incomplete Gate A children.

## Self-chain order

Continue automatically:

**Gate A — trustworthy core verbs**
→ **Gate B — opening through tournament**
→ **Gate C — progression/reward/trainer/wild/rest backbone**
→ **D1 Lower Meadows**
→ **D2 Quarry/Warrens**
→ **D3 River/Relay**
→ **D4 Upper Meadows**
→ **D5 Stronghold Approach**
→ **Gate E Stronghold Finale**
→ **Gate F full 3–4 hour Meadows integration**.

Gate C cross-chapter work can run in parallel with regional packages after the first-session proof, when file ownership permits.

## What a lane should receive

In addition to the existing coordinator brief requirements, every lane should be told:

- which gameplay gate/package owns its work;
- the owning prompt filename;
- the exact child prompt/backlog item it is implementing;
- what complete evidence segment will eventually judge the package;
- files held by other lanes;
- newer owner decisions that supersede old wording;
- to inspect current `main` and prefer evidence-backed `already fixed` over rewriting;
- to write useful findings that are outside its diff to `ralph/NOTES.md` when running coordinated.

A child lane is allowed to finish one mechanism. The coordinator/package owner is responsible for assembling the complete gameplay segment.

## Evidence gates

These are autonomous verification gates, **not owner approval gates**.

For each completed gameplay segment:
- run the real player path;
- capture/render when visuals matter;
- record player purpose;
- record team progression;
- record meaningful choices;
- record trainers/wilds/resources/detours/rest opportunities;
- record longest dead-travel interval;
- record freezes/input/save/gate failures;
- fix the highest-impact failure;
- replay until the written criteria pass.

Do not stop and ask the owner merely because a segment reached a gate. Continue.

## Priority rule

Within the active gate, prioritize:

1. freezes/data loss/progression blockers;
2. broken core verbs;
3. unclear objective/gate;
4. dead/empty traversal;
5. progression/reward/difficulty problems;
6. creature attachment/five-slot pressure;
7. regional content identity;
8. visual/UI/performance polish.

A newly discovered prerequisite does not silently replace the owner’s active package. Run it in parallel where possible or state explicitly why the package truly cannot proceed.

## Bookkeeping

`ralph/BACKLOG.md` remains the complete project ledger.

- Do not delete tasks simply because they are grouped into a new package.
- Close a child only when its own work is on `main` and verified.
- Record shipped work in `DONE.md` according to existing conventions.
- A gameplay package closes only after its continuous evidence run passes.
- Any old Meadows task not explicitly named in `ACTIVE_GAME_PLAN.md` remains live; assign it to the package it affects when encountered rather than dropping it.

## Stop condition

Do not declare Meadows complete because the prompt list is exhausted.

Stop only after `70-MEADOWS-full-chapter-integration-playthrough.md` passes and the game demonstrates the acceptance criteria in `docs/TETHERBOUND_GAME_VISION.md`.

The target is a complete enjoyable first chapter, not an empty backlog.