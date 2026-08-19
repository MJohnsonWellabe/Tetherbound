# CLAUDE.md — TETHERBOUND CODING AGENT INSTRUCTIONS

You are implementing **Tetherbound**, a Godot-based Windows-first third-person open-world creature-training adventure with gathering, crafting, building, exploration, care, and real-time creature combat.

## Start here

For any current Meadows work, read **`ralph/START_HERE.md` first**. It is the single current routing document.

Do not select work from an old milestone guide, handover, or the top of `ralph/BACKLOG.md` until `START_HERE.md` has routed you through the active game plan.

The current execution principle is binding:

> **A region/system is not done because code/data exists. It is done when the complete player path produces the intended Tetherbound experience.**

## Mission

Finish the Meadows as a complete enjoyable first chapter, not as a collection of implemented systems.

The player should build and care about a permanent team of five creatures, become stronger through meaningful encounters and preparation, travel through increasingly demanding Meadows regions, defeat Team Tether and the Warden, face the legendary roster choice, and see the world respond to that victory.

The target is roughly a **3–4 hour focused first clear**, with additional time available for exploration, team experimentation, optional trainers, gathering, building, and side content.

## Hard rules

These override lower-level prompts and implementation convenience:

- Godot is locked.
- Windows / ROG Ally is primary.
- Controller first.
- Solo.
- Player can own **only five creatures total**.
- Never implement creature storage, a reserve box, or a hidden sixth slot.
- Human never fights.
- Creatures do not perform base jobs.
- Creature combat is real-time and directly piloted.
- No shields.
- Catching is available during wild combat.
- Trainer-owned creatures cannot be caught.
- No hunting/butchering.
- Light satiety only: slow drain, food restores/buffs, soft drawbacks when low, **no starvation death**.
- Slot/stack inventory; no carry-weight system.
- Multiple death satchels persist.
- No Biome 2 implementation until Meadows passes its exit gate. Any reconnection view is distant/non-enterable.
- **No new creature meshes or Meshy generations for Meadows.** Use installed creature meshes; differentiate with materials, textures, modest scale, animation, VFX, habitat, behavior, traits, and encounter context.
- **Never spend a Meshy generation without owner-supplied reference art.**
- One nature family, one village family, one prop family. Meshy is reserved for Team Tether hero objects such as pylons, relay apparatus, and the tether machine.
- **Reuse the installed humanoid cast before generating anything new.** Current `main` has six production humanoid rigs: trainer, Grandpa, Warden, villager male, villager female, and Team Tether grunt. `docs/art/HUMANOID_ASSET_INVENTORY.md` is authoritative for current humanoid availability and reuse. Use existing per-material variants/rank presentation/configuration rather than making every NPC a unique mesh. A new humanoid mesh is exceptional, must solve a real unmet player-facing need, and still requires owner-supplied reference art.
- **The Warden is already rebuilt from the owner-supplied board-16 character sheet.** Do not reopen historical notes claiming his face is painted/unmodelled or that he still needs a production sheet; inspect the current installed `assets/characters/warden/warden_lod0.glb` instead.
- Do not silently invent a major gameplay/story decision.

## Canon / precedence

For current work, use this precedence:

1. explicit newer owner directives / owner-play evidence;
2. `docs/MEADOWS_PROGRESSION_SPEC.md` and settled decisions;
3. `docs/TETHERBOUND_GAME_VISION.md` for experience-level intent;
4. `docs/GAME_DESIGN.md` / `docs/MEADOWS_VERTICAL_SLICE.md` where not superseded;
5. task-specific detailed prompts;
6. historical backlog wording.

For humanoid asset availability/current Warden production state, `docs/art/HUMANOID_ASSET_INVENTORY.md` supersedes older historical statements in `docs/art/HUMANOIDS_PRODUCTION_REPORT.md` and `docs/art/REFERENCE_CANON.md`.

`docs/decisions/D23-the-meadows-is-the-first-game.md` remains the canon record for why the later Meadows spec wins over older conflicting design prose. Preserve its named carve-outs.

## How current work is chosen

Do not blindly work top-down through `ralph/BACKLOG.md`.

- `ralph/ACTIVE_GAME_PLAN.md` determines the current gameplay gate/package.
- `ralph/ACTIVE_TASKS.md` is the compact manifest for the current gate.
- `ralph/BACKLOG.md` is the complete ledger/history and is consulted for the selected task, not cold-read as a startup document.
- `docs/ralph-prompts/` contains detailed implementation contracts.
- `ralph/PROMPT_COMPATIBILITY_MAP.md` prevents duplicate work from overlapping historical prompts.

A child task can ship independently. The owning gameplay package does **not** pass until its continuous player evidence path passes.

## Working style

For each implementation task:

1. Inspect current `main` before changing anything.
2. Reproduce/verify the actual player-facing state.
3. Read only the relevant spec/code/prompt sections.
4. Implement the smallest coherent fix/feature that satisfies the current package.
5. Run relevant tests and the real interaction path.
6. For visual-affecting work, render the actual change and follow `ralph/conventions.md` visual-judge requirements.
7. Preserve working behavior outside scope.
8. Put tunable values in data/config when they will vary.
9. Record meaningful findings/decisions in the appropriate repo docs.
10. Ship through the Ralph branch/CI process; do not bypass it for implementation code.

For package/gate work, additionally:

11. Play the full evidence segment named in `ralph/ACTIVE_GAME_PLAN.md`.
12. Record player purpose, team progression, meaningful choices, wild/trainer/resource/rest cadence, dead-travel intervals, reliability failures, and regional presentation.
13. Fix the highest-impact player-facing failure and replay.
14. Continue automatically when the evidence criteria pass. These are not owner-blocking approval gates.

## Evidence-backed “already fixed” is valid

The repo has repeatedly accumulated stale bug prose after code changed.

If current `main` already satisfies a child prompt, verify it and reconcile bookkeeping. Do not rewrite a working system just to produce a diff.

A newer owner reproduction of the same failure reopens it even if old `DONE.md` says it shipped.

## Ask instead of inventing

Ask/flag only when implementation truly requires choosing between materially different game behaviors not settled by the repo.

Examples:

- adding dodge/block;
- changing the five-creature limit;
- adding human weapons;
- changing the type system;
- adding creature storage;
- major story rewrite;
- changing traversal philosophy;
- adding harsher hunger/thirst;
- changing the stronghold structure.

Implementing a documented owner directive is ordinary work, not invention.

## Asset work

Candidate assets may be sourced for this private project when needed, but:

- maintain visual cohesion;
- record provenance/license in `docs/ASSET_LEDGER.md`;
- never assume redistributability;
- test scale/materials in-engine;
- inspect `docs/art/HUMANOID_ASSET_INVENTORY.md` before any human/NPC asset work;
- do not use placeholder ugliness as evidence that final biome/creature/combat/release/stronghold presentation is good enough.

## Current objective

The old M0/M1 “movement playground” startup era is historical.

**Current work begins at the first incomplete item in Gate A of `ralph/ACTIVE_GAME_PLAN.md`, reconciled against current `main`, then self-chains through the Meadows gameplay gates to Prompt 70.**
