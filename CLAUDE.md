# Tetherbound — agent instructions

> `AGENTS.md` and `CLAUDE.md` are intentionally identical. Different tools read
> different filenames. **If you change one, change both.**

You are building **Tetherbound**: a Godot 4.7, Windows-first, controller-first,
third-person open-world creature-training adventure with 1–4 player co-op.
Gathering, crafting, building, exploration, creature care, and real-time
creature combat. Four chapters: **the Meadows → Cloudreach Cliffs → the
Stormwood → Tidewake** (the Water Archipelago).

## Read these five, and only these

| File | When |
|---|---|
| `docs/STATE.md` | **Always, first.** What is true right now, what's next, what's broken, what the owner last said. |
| `docs/GAME_BIBLE.md` | What the game is: the four chapters, the systems, the canon, the rules that stay true. |
| `docs/ACCEPTANCE.md` | What "done" looks like — the visual bar, content density, combat, reliability. |
| `docs/WORKFLOW.md` | How work gets done here: tiers, briefs, tests, evidence, CI, stop conditions. |
| `docs/TECHNICAL.md` | Where the code lives, how to build, test, capture, ship. |

Everything under `archive/` is history. **Do not cold-read it and do not take
work from it.** The 125 decision records are archived at
`archive/docs/decisions/` with an index; every decision that still binds is
already in the Bible. Open one only if a code comment sends you to it by number.

**Do not create new dated documents.** No `GOAL_<date>.md`, no
`HANDOFF_<date>.md`, no `DIRECTIVE_<date>.md`. That pattern produced sixty-odd
stale files and a routing layer two handoffs out of date, and it is retired.
Session state, progress and owner feedback go in `docs/STATE.md`, updated in
place. Evidence artifacts still go in `ralph/reports/<LANE>/`. If you think you
need a new document, you almost certainly need to edit an existing one.

## Hard rules

These override lower-level prompts and implementation convenience.

- Godot is locked. Windows / ROG Ally is primary. Controller first.
- The player owns **five creatures total**. No storage, no reserve box, no
  hidden sixth slot. This is the emotional center of the game, not a limitation
  on it.
- **The human never fights.** Creatures fight creatures, and creatures do not
  perform base jobs. The player pilots the active creature directly, in real
  time. **No shields, no blocking, no held buttons.**
- Catching happens during wild combat. Trainer-owned creatures cannot be caught.
- No hunting, no butchering.
- Satiety is light: slow drain, food restores and buffs, soft drawbacks when
  low, **never starvation death**.
- Slot/stack inventory. No carry weight. Multiple death satchels persist.
- Creatures stand taller than the 1.80 m trainer. **Fix relative-scale problems
  by growing the smaller side, never by shrinking.**
- **No new creature meshes without owner-supplied reference art.** Differentiate
  with material, texture, modest scale, animation, VFX, habitat, behaviour and
  encounter context. One nature family, one village family, one prop family.
  Meshy is reserved for Team Tether hero objects.
- **Never spend a Meshy generation without owner reference art.** Two scoped
  carve-outs exist and are recorded in the Bible §1.4; neither is a general
  licence.
- Reuse the installed humanoid cast (trainer, Grandpa, Warden, villagers, Team
  Tether grunt). `docs/art/HUMANOID_ASSET_INVENTORY.md` is authoritative. The
  Warden is already rebuilt — inspect `assets/characters/warden/warden_lod0.glb`
  rather than trusting older notes.
- Oxblood/red is reserved for Team Tether.
- Anything new is multiplayer-native from its first implementation.
- **Do not silently invent a major gameplay or story decision.** If two
  materially different behaviours are both defensible and nothing in these five
  documents settles it, record the question in `docs/STATE.md` §5 and take the
  conservative option — do not stall waiting for an answer nobody is there to
  give.

## Precedence, when documents disagree

1. The owner's most recent feedback (`docs/STATE.md` §6)
2. This file's hard rules
3. `docs/GAME_BIBLE.md`
4. `docs/ACCEPTANCE.md`
5. `docs/STATE.md`, `docs/WORKFLOW.md`, `docs/TECHNICAL.md`
6. Anything under `archive/` — history only, never authority

## The execution principle

> **A region or system is not done because code and data exist. It is done when
> the complete player path produces the intended Tetherbound experience.**

## Working style

1. Read `docs/STATE.md`. **Reproduce the actual current state before trusting
   any document's claim about what is or isn't built** — a document is a report
   written at a point in time, and it goes stale the moment something else
   lands.
2. Implement the smallest coherent change that satisfies the task.
3. Test it, run it, and capture it if it's visual. That is the evidence bar:
   **tests pass + it actually ran + a screenshot if visual.** A code-blind judge
   is required for a *big* visual pass, not for every fix. `docs/ACCEPTANCE.md`
   §3–4 is precise about this.
4. Preserve working behaviour outside your scope. Put tunables in `data/config`.
5. Update `docs/STATE.md` as you go, in place.
6. Land through a pull request. **Never push to `main`.**

## Stop conditions

- Two unsuccessful attempts at the same fix, or two consecutive report-only
  turns, means change approach or hand off — not keep spinning.
- "Flake" is not a root cause. At most one confirming re-run.
- An open owner decision does not halt the session: record it, take the
  conservative option, continue.
- Measurement infrastructure is not the deliverable. If you are spending more
  time fixing a harness than fixing the game it measures, re-scope.
- Commit and land continuously. One giant unreviewed diff at the end is itself a
  risk.

## Branches

Branch from current `main`. `ralph/<task>` is the shipping prefix,
`claude/<task>` for orchestrator sessions, `scratch/<x>` for throwaways. **CI
runs only on pull requests and pushes to `main`**, so open a draft PR early or
nothing is verified. A run under five minutes verified nothing — check that code
jobs ran. Never push to `main` directly.
