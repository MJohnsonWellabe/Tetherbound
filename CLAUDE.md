# CLAUDE.md — TETHERBOUND CODING AGENT INSTRUCTIONS

You are implementing **Tetherbound**, a Godot 4.7 Windows-first third-person open-world
creature-training adventure with gathering, crafting, building, exploration, care, and
real-time creature combat.

## Start here

Read **`docs/00_START_HERE.md`** first. It is the single routing document: what the
game is, the current gate, which files are authoritative, what to read for each kind of
work, validation expectations, branch rules, and the definition of done.

Do not select work from anything under `archive/`. Do not cold-read history.

The execution principle is binding:

> **A region or system is not done because code and data exist. It is done when the
> complete player path produces the intended Tetherbound experience.**

## Mission

Finish the Meadows as a complete, enjoyable first chapter, not as a collection of
implemented systems. The player builds and cares about a permanent team of five, grows
stronger through meaningful encounters and preparation, travels through increasingly
demanding Meadows regions, defeats Team Tether and the Warden, faces the legendary roster
choice, and sees the world respond. Target: a **3–4 hour focused first clear**, with
more time available for exploration, team experimentation, optional trainers, gathering,
building and side content. `docs/GAME_VISION.md` is the experience contract.

## Hard rules

These override lower-level prompts and implementation convenience:

- Godot is locked.
- Windows / ROG Ally is primary. Controller first. Solo.
- The player can own **only five creatures total**. Never implement creature storage, a
  reserve box, or a hidden sixth slot.
- The human never fights. Creatures do not perform base jobs.
- Creature combat is real-time and directly piloted. No shields.
- Catching is available during wild combat. Trainer-owned creatures cannot be caught.
- No hunting or butchering.
- Light satiety only: slow drain, food restores and buffs, soft drawbacks when low,
  **no starvation death**.
- Slot/stack inventory; no carry-weight system.
- Multiple death satchels persist.
- No Biome 2 implementation until the Meadows passes its exit gate
  (`docs/acceptance/MEADOWS_EXIT_CRITERION.md`). Any reconnection view is distant and
  non-enterable.
- **No new creature meshes or Meshy generations for the Meadows.** Use installed
  creature meshes; differentiate with materials, textures, modest scale, animation, VFX,
  habitat, behaviour, traits and encounter context.
- **Never spend a Meshy generation without owner-supplied reference art.**
- One nature family, one village family, one prop family. Meshy is reserved for Team
  Tether hero objects (pylons, relay apparatus, the tether machine).
- **Reuse the installed humanoid cast** (trainer, Grandpa, Warden, villager male,
  villager female, Team Tether grunt). `docs/art/HUMANOID_ASSET_INVENTORY.md` is
  authoritative. A new humanoid mesh is exceptional and still needs owner reference art.
- The Warden is already rebuilt from the owner's board-16 sheet; inspect
  `assets/characters/warden/warden_lod0.glb` rather than trusting older notes.
- Creatures should stand taller than the 1.80 m trainer; resolve relative-scale defects
  by growing the smaller side, never by shrinking (owner directive 2026-09-01).
- Do not silently invent a major gameplay or story decision.

## Precedence

1. newest owner directive or playtest in `docs/owner/`;
2. this file and `docs/decisions/`;
3. `docs/specs/MEADOWS_PROGRESSION_SPEC.md`;
4. `docs/GAME_VISION.md`;
5. the other `docs/*.md` source-of-truth files;
6. `docs/prompts/` task contracts;
7. anything in `archive/` (history only).

`docs/decisions/D23-the-meadows-is-the-first-game.md` records why the Meadows spec wins
over older design prose. Preserve its named carve-outs.

## How work is chosen

`docs/ROADMAP.md` names the current gate, its bounded tasks, who does them, and the
acceptance evidence. `docs/CURRENT_STATE.md` is the evidence-backed status. A child task
ships independently; its gate passes only when the continuous player path passes.

## Working style

For every implementation task:

1. Inspect current `main` and reproduce the actual player-facing state first.
2. Read only the relevant spec, code, tests and prompt sections.
3. Implement the smallest coherent change that satisfies the task.
4. Run the named tests and the real interaction path; tests exercise real behaviour.
5. For visual work, render the change and run the blind visual judge.
6. Preserve working behaviour outside scope; put tunables in `data/config`.
7. Record findings in `docs/CURRENT_STATE.md` (status) or `docs/decisions/` (decisions).
8. Ship on a branch through CI and a pull request; verify the landing on `main`.

Evidence-backed "already fixed" is valid: verify and reconcile rather than rewrite. A
newer owner reproduction reopens any item a ledger says is fixed.

## Ask instead of inventing

Ask only when implementation requires choosing between materially different game
behaviours nothing in the repo settles: dodge/block, the five-creature limit, human
weapons, the type system, creature storage, a major story rewrite, traversal philosophy,
harsher hunger, the stronghold structure. Implementing a documented owner directive is
ordinary work.

## Process rules that cost real time to learn

- A CI run under five minutes verified nothing. Check that code jobs ran.
- A retry that turns 0-for-1 into green is a finding, not a pass.
- A self-report is not evidence; check the branch and the run.
- Commit evidence verdicts, not screenshot or telemetry payloads.
- Address inventory by item identity, never by slot number.
- Never `--headless` together with a rendering driver.

Full process: `docs/AGENT_WORKFLOW.md`.
