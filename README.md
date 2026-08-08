# Tetherbound

A third-person survival/crafting creature-training game. Godot 4, Windows-first,
built for handheld PCs and the ROG Ally. Controller first, single player.

You may own **five pals, total.** There is no box and no reserve team. Catching a
sixth forces a permanent release. Everything else in the design follows from that
one rule.

## Play it

Windows builds are published on every push to `main`:

**[Download the latest build](https://github.com/MJohnsonWellabe/Tetherbound/releases/download/latest/Tetherbound-windows.zip)**

## Run it from source

Install Godot 4.7, then `Import` this folder's `project.godot`. `F5` runs the
game. `GODOT_AND_CLAUDE_START_HERE.md` is the longer version of that, written for
someone who has not used Godot before.

## The documents

These are authoritative, in this order:

| Document | What it settles |
|---|---|
| `docs/GAME_DESIGN.md` | The whole design. Pillars, systems, roster scope, difficulty. |
| `docs/MEADOWS_VERTICAL_SLICE.md` | The milestone list currently being built, M0–M15. |
| `docs/TECHNICAL_START.md` | Project layout, data/code separation, conventions. |
| `CLAUDE.md` | The rules a coding agent may not break. |

Supporting material:

- `docs/art/` — the Meadows reference-art pack, and which parts of it are canon
  (`REFERENCE_CANON.md`).
- `docs/decisions/` — numbered records of technical and design calls, and why.
- `docs/reviews/` — blind visual critiques of the build, including the failures.
- `docs/ASSET_LEDGER.md` — provenance and licence for every non-original asset.

## Scope

Meadows only. No second biome until the Meadows vertical slice passes its exit
gate.
