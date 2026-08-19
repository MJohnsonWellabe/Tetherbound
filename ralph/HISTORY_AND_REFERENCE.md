# Ralph history and reference index

Current autonomous work starts at **`ralph/START_HERE.md`**.

This file explains what the large remaining Ralph documents are for so a fresh agent does not mistake history for current priority.

## Current control plane

These are current and may control work:

- `CLAUDE.md` — hard rules.
- `ralph/START_HERE.md` — single routing entry point.
- `docs/TETHERBOUND_GAME_VISION.md` — experience contract.
- `ralph/ACTIVE_GAME_PLAN.md` — gameplay gate/package order.
- `ralph/ACTIVE_TASKS.md` — compact current-gate manifest.
- `ralph/OWNER_PLAYTEST_2026-08-18.md` — latest owner-play evidence currently recorded.
- `ralph/PROMPT_COMPATIBILITY_MAP.md` — duplicate-prompt resolution.
- `ralph/conventions.md` — implementation/shipping/test rules.
- `ralph/PROMPT.md` — current implementation-lane contract.
- `ralph/COORDINATED_RUN.md` — current multi-lane coordinator manual.

## Large reference stores

### `ralph/BACKLOG.md`

Complete project ledger with extensive historical commentary.

Use targeted search/fetch for a specific task ID or symptom. Do not use its physical top-to-bottom order to select current Meadows work; `ACTIVE_GAME_PLAN.md` owns that.

### `ralph/DONE.md`

Very large completion archive.

Search it for a task ID, commit, or previous root cause. Never cold-read it end to end during startup.

### `ralph/BLOCKED.md`

History/current record of parked work and why it was blocked. Consult when a selected task is known or suspected to be blocked.

## Legacy operating material

The following files may contain useful lessons/history but do not override the current `START_HERE` → `ACTIVE_GAME_PLAN` flow:

- `ralph/MANUAL.md`
- `ralph/KEYED_PROMPT.md`
- `ralph/LANE_PROMPT.md`
- dated `ralph/HANDOVER-*` files
- historical decision/review documents that explicitly identify themselves as superseded

If one of these contains a process rule that conflicts with current `CLAUDE.md`, `START_HERE.md`, `PROMPT.md`, or `COORDINATED_RUN.md`, the current file wins.

## Prompt history

`docs/ralph-prompts/` intentionally retains detailed prompts from multiple review passes.

- prompts `55`–`70` are the current gameplay-package owning layer;
- the newer owner-play implementation prompts `39`–`54` remain child contracts;
- prompts `01`–`38` preserve the original Meadows review work;
- seven older `OP-*` files overlap later prompts and are resolved by `ralph/PROMPT_COMPATIBILITY_MAP.md`.

Do not execute prompt files merely by numeric order.

## Git is the deep archive

Superseded startup/process documents are preserved in Git history even when the current tree is simplified. The control plane should favor current clarity over carrying every historical instruction inline.

Cleanup baseline before this control-plane simplification: commit `72324b14bb118338a64b4b5e66939d574d0c6f88` contains the pre-cleanup current startup layer, and earlier Git history contains the longer legacy Ralph manuals.
