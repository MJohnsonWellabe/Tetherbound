# Ralph — implementation lane contract

This file is for an **implementation lane**. If you are coordinating multiple lanes, read `ralph/COORDINATED_RUN.md` instead.

## 0. Bootstrap

Before doing anything:

1. read `CLAUDE.md`;
2. read `ralph/START_HERE.md`;
3. read the owning gameplay package/gate in `ralph/ACTIVE_GAME_PLAN.md`;
4. read the selected child task in `ralph/ACTIVE_TASKS.md` if it is part of the current manifest;
5. read `ralph/PROMPT_COMPATIBILITY_MAP.md` if overlapping prompt files exist;
6. read `ralph/conventions.md`;
7. read only the relevant detailed prompt(s), spec sections, tests, and code.

Do **not** cold-read `BACKLOG.md` or `DONE.md`. Search/fetch the selected task history only.

## 1. Your job

You own one coherent child task or one explicitly assigned package slice.

Your goal is not “make a diff.” Your goal is the player-visible outcome named in the brief while preserving the owning gameplay package.

Inspect current `main` first. If the issue is already fixed, prove it and report/reconcile rather than rewriting it.

A newer owner reproduction outranks stale DONE history.

## 2. Scope discipline

- Work only in the assigned scope.
- Do not invent a parallel architecture if an existing system can carry the feature cleanly.
- Do not silently change game design to make implementation easier.
- Do not re-solve adjacent tasks owned by another lane.
- If you discover a prerequisite, report it. Under a coordinator, the prerequisite should usually get its own parallel lane rather than replacing the owner-priority task.
- Preserve the five-creature rule, controller-first behavior, and every `CLAUDE.md` hard rule.

## 3. Branch / shipping

Implementation code ships through a `ralph/<task>` branch and existing CI/merge automation.

- Do not push implementation directly to `main`.
- Do not manually merge to `main` unless the coordinator explicitly owns that operation under the repo process.
- Keep the branch focused enough that failures can be attributed.
- A green branch is not shipped. Verify the content is actually on `main` before bookkeeping calls it done.

## 4. Coordinated vs uncoordinated mode

### If a coordinator launched you

The coordinator owns collision avoidance and bookkeeping.

- Follow the file exclusion list in your brief.
- Do not claim/heartbeat/release `ralph/STATUS.md` leases.
- Do not edit `BACKLOG.md`, `DONE.md`, or `BLOCKED.md` unless the coordinator explicitly assigns that bookkeeping.
- Write useful out-of-scope findings to `ralph/NOTES.md` on the shared status channel when available.
- At your estimated checkpoint, report what is complete, what remains, and any blockers/findings. Going silent is a failure mode.

### If you are an uncoordinated firing

The legacy lease mechanism in `ralph/STATUS.md` remains load-bearing. Follow the lease rules in `ralph/conventions.md`/existing automation before editing shared scope.

## 5. Implement from the detailed prompt, not from the filename

For the assigned work:

1. reproduce/inspect current behavior;
2. read the canonical detailed prompt;
3. inspect the current implementation and existing tests;
4. identify the narrowest correct integration point;
5. implement;
6. test the real interaction path;
7. run the required automated checks;
8. render/visual-judge if visuals changed;
9. report evidence and any remaining issue.

Where two prompt files overlap, `ralph/PROMPT_COMPATIBILITY_MAP.md` tells you which current owner wins. Preserve unique acceptance detail, but implement once.

## 6. Testing rules

Tests must exercise real behavior, not a bypass that merely turns green.

- Controller/UI focus tests should use real parsed input events where the repo conventions require them; poll-only tests can create false positives.
- Modal/input lifecycle bugs require real open/close/cancel cycles, including repeated cycles.
- Save tests must verify persisted player-facing state, not only serialization functions.
- Building tests must prove the actual player construction sequence.
- Gameplay-package work must eventually be judged by the continuous evidence segment in `ACTIVE_GAME_PLAN.md`, not only child unit/smoke tests.
- Run headless smoke/unit checks required by the task and conventions.

If a test is red because the implementation is wrong, fix the implementation. Do not weaken the test to clear CI.

## 7. Visual work

For any player-visible visual change, follow `ralph/conventions.md`:

- render the actual changed state;
- use the repo visual-judge skill/process;
- iterate until it passes or reaches documented convergence/blocker criteria;
- preserve approved visual references and regional composition constraints.

Do not close a visual task because code “should” look right.

## 8. Record useful findings

The highest-value lane output is often a finding that does not belong in the diff.

Record things such as:

- root cause discovered outside your scope;
- an older prompt that current main already satisfies;
- a conflicting config path;
- a regional/content gap the package owner needs to know;
- a test that does not exercise the player path it claims to cover.

Under a coordinator, put those findings in the shared notes channel and include them in your handoff.

## 9. Definition of done for a child task

A child task is done only when:

- its player-facing acceptance criteria are satisfied on current code;
- required automated tests pass;
- required visual evidence passes;
- no obvious regression was introduced in adjacent core behavior;
- the branch is pushed and can ship through normal Ralph CI;
- the coordinator has enough evidence to verify it on `main`.

A child task being done does **not** automatically close its owning gameplay gate.

## 10. What happens next

If a coordinator is running, hand the result back to the coordinator and take the next non-conflicting task it assigns.

If self-chaining is explicitly enabled in your brief, select the next task **inside the same active gameplay gate/package**, not the next historical heading in `BACKLOG.md`.

Never declare Meadows complete because prompts are exhausted. The stop condition is the full chapter integration gate in `ralph/ACTIVE_GAME_PLAN.md` / Prompt 70.
