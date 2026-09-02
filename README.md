# Tetherbound

Tetherbound is a third-person open-world creature-training adventure built in Godot 4.7
for Windows and handheld PCs (ROG Ally first), controller-first, with gathering,
crafting, building, exploration, care, and real-time piloted creature combat.

The defining rule:

> **You may own five creatures, total.**

No reserve box, no hidden storage. Catching beyond five forces a real keep/release
choice. The game is built around making those five capable and personally meaningful.

## Play it

Windows builds are published from `main`:
**[Download the latest build](https://github.com/MJohnsonWellabe/Tetherbound/releases/download/latest/Tetherbound-windows.zip)**

On the ROG Ally use **Gamepad Mode**; Desktop Mode sends mouse/keyboard input and an
otherwise working build looks unresponsive. Check the release asset's timestamp: a merge
to `main` does not always publish a build.

## Run from source

1. Install Godot 4.7-stable.
2. Clone this repository and import `project.godot`.
3. Press F5. Godot's Debugger/Output panels show runtime errors.
4. Export: Project → Export → the Windows Desktop preset (configured in
   `export_presets.cfg`).

Headless verification from a shell:

```
godot --headless --path . --import
godot --headless --path . --script tests/run_tests.gd          # unit suite, ~28 min
godot --headless --path . --script tests/smoke_opening.gd      # one smoke test
```

## Working on the project (humans and agents)

**Start with `CLAUDE.md`, then `docs/00_START_HERE.md`.** Everything else in `docs/` is
reached from there. `archive/` is history and is not a starting point.

| Document | Purpose |
|---|---|
| `CLAUDE.md` | Hard rules and the agent contract |
| `docs/00_START_HERE.md` | Routing: current stage, what is authoritative, validation, done |
| `docs/GAME_VISION.md` | What the finished Meadows chapter should feel like |
| `docs/CURRENT_STATE.md` | Evidence-backed status and known issues |
| `docs/ROADMAP.md` | Sequential gates with tasks and acceptance |
| `docs/AGENT_WORKFLOW.md` | How work is briefed, tested, rendered, landed |
| `docs/GAMEPLAY_SYSTEMS.md`, `docs/WORLD_AND_CONTENT.md`, `docs/CREATURE_DESIGN.md` | System, world and creature references |
| `docs/TECHNICAL_ARCHITECTURE.md` | Engine, structure, pipelines, CI |
| `docs/VISUAL_BIBLE.md` | Visual target and gap list |

## Scope

The Meadows is the current game. No second biome until the Meadows passes its exit gate.

## Owner playtesting

Automated evidence is required but real-device play remains the most valuable signal.
Useful feedback is experiential and specific: "input froze after leaving this menu",
"this road has too much empty running", "I do not understand why I am going here", "I
never need to stop and rest". Record it in `docs/owner/`; it outranks every other
document for what it covers and reopens anything a ledger says is fixed.
