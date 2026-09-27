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

**Start with `AGENTS.md` (identical to `CLAUDE.md`), then `docs/STATE.md`.**
The live set is `AGENTS.md` = `CLAUDE.md`, seven documents in `docs/` and the ten
design specs in `docs/design/` (WORKFLOW §11). `archive/` is history and is not a
starting point.

| Document | Purpose |
|---|---|
| `AGENTS.md` = `CLAUDE.md` | Hard rules and routing |
| `docs/STATE.md` | What is true right now, what's next, what's broken, owner feedback |
| `docs/GAME_BIBLE.md` | What the game is: four chapters, systems, canon |
| `docs/ACCEPTANCE.md` | What "done" looks like — visual bar, content density, combat, reliability |
| `docs/WORKFLOW.md` | How work is briefed, tested, rendered, landed, and when to stop |
| `docs/TECHNICAL.md` | Engine, structure, systems map, pipelines, CI |
| `docs/PRODUCT.md`, `docs/ROADMAP.md` | Scope, audience and cuts; feature rows F01–F15 and order |
| `docs/design/*.md` | The ten owning design specs (combat, creatures, bosses, world, systems, progression, UX, multiplayer, art, audio) |

Do not create new dated documents. Status goes in `docs/STATE.md`, updated in
place; evidence artifacts go in `ralph/reports/<LANE>/`.

## Scope

Four chapters: the Meadows, Cloudreach Cliffs, the Stormwood, and Tidewake, ending
with the Tidewake regional victory and homecoming. See `docs/STATE.md` for current
status and the pickup list for unfinished work.

## Owner playtesting

Automated evidence is required but real-device play remains the most valuable signal.
Useful feedback is experiential and specific: "input froze after leaving this menu",
"this road has too much empty running", "I do not understand why I am going here", "I
never need to stop and rest". Record it in `docs/STATE.md` (owner direction section); it outranks every
other document for what it covers and reopens anything a ledger says is fixed.
