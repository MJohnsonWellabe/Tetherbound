# Tetherbound — Godot and Claude setup for a human

This file is a **human setup guide**, not the autonomous task queue.

For Claude/Ralph task selection, start with:

1. `CLAUDE.md`
2. `ralph/START_HERE.md`

Do **not** use this file to choose the next gameplay milestone.

## What you need on Windows

1. Godot 4.7.
2. Git.
3. Claude Code/Codex or another coding-agent workflow with repository access.
4. This repository cloned locally.

## Open and run Tetherbound

1. Open Godot.
2. Choose **Import**.
3. Select this repository's `project.godot`.
4. Open the project.
5. Press **F5** to run the game.
6. Use Godot's Debugger/Output panels for runtime errors.
7. Test exported builds on the ROG Ally regularly.

On ROG Ally, set Command Center to **Gamepad Mode** before launching the game.

## Export a Windows build

The repository already contains the Windows export configuration.

In Godot:

1. Open **Project → Export**.
2. Select the Windows Desktop preset.
3. Export when a local build is needed.

Normal pushes to `main` also use the repository's automated build/release workflow.

## How Claude should work now

The project is far beyond its original movement-playground milestones.

Do **not** tell a fresh agent to begin with M0/M1 or “implement the next milestone.” Those instructions are historical and will send it backwards.

Instead, start the autonomous process from `CLAUDE.md` / `ralph/START_HERE.md`. The current Ralph control plane will:

- reconcile the current gameplay gate against `main`;
- fix the highest-impact incomplete child tasks;
- test the full player path for that gate;
- keep iterating until the segment passes;
- move automatically into the next Meadows region/package.

The target is a complete enjoyable Meadows chapter, not a sequence of isolated technical milestones.

## What the owner should personally test

Automated gameplay/test/render evidence is required, but occasional real-device play remains extremely valuable for things an automated runner cannot truly feel.

Useful owner feedback is experiential and specific, for example:

- input froze after leaving this exact menu;
- this throw interaction feels awkward;
- I cannot build a roof cleanly;
- this road has too much empty running;
- this region looks great and should be preserved as a visual reference;
- I do not understand why I am going here;
- I never need to stop and rest;
- I am not finding enough creatures worth considering for my five;
- a fight is too easy/hard at this point in the chapter.

New owner-play evidence should be recorded in the current owner-play/backlog layer and can reopen a task even if an old automated pass marked it complete.

## Git / Ralph workflow

Implementation code should follow the repository Ralph workflow:

- focused `ralph/<task>` branch;
- relevant tests/render evidence;
- CI;
- merge/ship through the existing automation/coordinator process;
- verify the result actually reached `main`.

Do not use direct-to-main implementation pushes as a shortcut.

## Current orientation

The current execution path is approximately:

**core verbs → opening/tournament → progression backbone → Lower Meadows → Quarry/Warrens → River/Relay → Upper Meadows → Stronghold Approach → Warden/legendary finale → full chapter tuning**.

See `ralph/START_HERE.md` for the exact current process and `docs/TETHERBOUND_GAME_VISION.md` for the intended game experience.
