# Tetherbound

Tetherbound is a third-person open-world creature-training adventure built in Godot 4 for Windows/handheld PCs, with controller-first play, gathering, crafting, building, exploration, care, and real-time creature combat.

The defining rule is:

> **You may own five creatures, total.**

There is no reserve box and no hidden storage team. Catching beyond five forces a real keep/release choice. The game is built around making those five increasingly capable and personally meaningful.

## Play it

Windows builds are published from `main`:

**[Download the latest build](https://github.com/MJohnsonWellabe/Tetherbound/releases/download/latest/Tetherbound-windows.zip)**

On ROG Ally, use **Gamepad Mode**. Desktop Mode sends controls as mouse/keyboard and can make an otherwise running build appear unresponsive.

## Run from source

1. Install Godot 4.7.
2. Clone this repository.
3. Import `project.godot` in Godot.
4. Press F5 to run the project.

`GODOT_AND_CLAUDE_START_HERE.md` is the human setup guide.

## Autonomous Claude / Ralph work

For any coding-agent or Ralph session:

**Start with `CLAUDE.md`, then `ralph/START_HERE.md`.**

Do not start from the old milestone sequence or read the giant backlog top-down.

Current Meadows execution is organized around **finished gameplay gates**, not a flat feature queue:

- trustworthy core verbs;
- fresh start through the village tournament;
- progression/reward/trainer/wild/rest backbone;
- finished Lower Meadows;
- finished Quarry / Burrow Warrens;
- finished River / Tether Relay;
- finished Upper Meadows;
- finished Stronghold Approach;
- Warden / legendary finale;
- full 3–4 hour Meadows integration playthrough.

The complete routing and execution order is in `ralph/START_HERE.md` and `ralph/ACTIVE_GAME_PLAN.md`.

## Current authoritative documents

| Document | Purpose |
|---|---|
| `CLAUDE.md` | Hard rules and coding-agent contract. |
| `ralph/START_HERE.md` | Single current autonomous-work entry point. |
| `docs/TETHERBOUND_GAME_VISION.md` | Experience-level definition of the finished Meadows game. |
| `ralph/ACTIVE_GAME_PLAN.md` | Current gameplay-gate execution order. |
| `ralph/ACTIVE_TASKS.md` | Compact current-gate task manifest. |
| `docs/MEADOWS_PROGRESSION_SPEC.md` | Canonical Meadows chapter/progression detail. |
| `docs/GAME_DESIGN.md` | Broader game design where not superseded by later Meadows decisions. |
| `docs/TECHNICAL_START.md` | Project/data/code structure. |
| `ralph/conventions.md` | Branch, CI, testing, visual-judge, and shipping conventions. |

## History/reference

The repository intentionally retains extensive design and Ralph history. Files such as `ralph/BACKLOG.md`, `ralph/DONE.md`, `ralph/BLOCKED.md`, dated handovers, and older prompt/manual files are references, not startup documents.

Search them for a specific task or decision when needed; do not load them wholesale into a fresh agent session.

## Scope

Meadows is the current game. No second biome implementation until the Meadows chapter passes its full exit/integration gate.
