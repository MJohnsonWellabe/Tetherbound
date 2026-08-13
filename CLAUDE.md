# CLAUDE.md — TETHERBOUND CODING AGENT INSTRUCTIONS

You are implementing **Tetherbound**, a Godot-based Windows-first third-person survival/crafting creature-training game.

Before coding, read:
1. `docs/GAME_DESIGN.md`
2. `docs/MEADOWS_VERTICAL_SLICE.md`
3. `docs/MEADOWS_PROGRESSION_SPEC.md`
4. `docs/TECHNICAL_START.md`

These documents are authoritative. Where (3) disagrees with (1) or (2), **(3)
wins** — it is the owner's later word, made canon by
`docs/decisions/D23-the-meadows-is-the-first-game.md`, which also names the two
carve-outs where an older rule still governs.

## Mission

Build the Meadows vertical slice quickly and iteratively. The goal is not maximum feature count. The goal is a game the owner voluntarily wants to keep playing.

## Hard Rules

- Godot is locked.
- Windows/ROG Ally is primary.
- Controller first.
- Solo.
- Player can own only five pals total.
- Never implement pal storage beyond five.
- Human cannot fight.
- Pals do not perform base jobs.
- Combat is real-time pal-vs-pal.
- No shields.
- Catching is available during wild combat.
- Trainer-owned pals cannot be caught.
- No hunting/butchering.
- Light satiety: slow drain, food restores and buffs, soft debuffs when low; NO starvation death (D29).
- Slot/stack inventory; no carry-weight system.
- Multiple death satchels persist.
- No Biome 2 work until Meadows passes its exit gate. The spec's reconnection
  event (§38 step 45) is a distant, non-enterable **view** — never a place.
- No new creature meshes or Meshy generations for the Meadows. The installed
  meshes are the meshes; differentiate by material, texture, modest scale,
  animation, VFX, habitat and behaviour (spec §20, D23). **Reaffirmed
  2026-08-11 with 5000 credits available** — this is not a budget rule and
  having credits does not lift it.
- **Never spend a Meshy generation on an asset the owner has not supplied
  reference art for** (owner directive, 2026-08-11). Reference art is now the
  constraint, not credits. In-engine survey and screenshot renders are not
  affected — they are how anything gets verified. If a task seems to need a
  generation and no board exists, stop and ask.
- One nature family, one village family, one prop family (D24). Meshy is for
  Team Tether hero objects only — pylons, relay apparatus, the tether machine.
  Routine trees, rocks, crates, fences and HUD icons come from coherent packs.
- Human NPCs reuse the trainer, Grandpa and Warden rigs through **per-material**
  variants, never one global tint. At most one or two new human generations,
  owner-supplied only, and only for reusable archetypes (spec §21–§22, D23).
- Do not silently invent major design decisions.

## Working Style

Prefer small, playable increments.

For each milestone:
1. State the concrete player-visible outcome.
2. Implement the smallest coherent version.
3. Run the game/tests.
4. Fix obvious regressions.
5. Record meaningful technical/design decisions in `docs/decisions/`.
6. Keep data out of gameplay code when it will clearly vary by species/move/item.
7. Do not over-generalize speculative future systems.

## Asset Work

You may source candidate assets. They do not need to be CC0 for this private project, but:
- maintain visual cohesion
- record provenance/license in `docs/ASSET_LEDGER.md`
- never assume an asset is redistributable
- prefer assets with animations appropriate to their role
- test scale/materials in-engine before committing to a roster

## Prototyping

Placeholder assets are acceptable to prove mechanics.

However, do not judge final:
- biome look
- creature appeal
- combat readability
- emotional release scene
- stronghold presentation

using ugly placeholders. Representative art is required before those systems are considered successful.

## Tunable Values

You may choose temporary numbers for:
- speeds
- cooldowns
- damage
- energy
- stamina
- HP
- catch rates
- build costs
- spawn rates

Put them in data/config and label them tunable.

Do not turn temporary numbers into a new permanent mechanic.

## Ask/Flag Instead of Inventing

Flag a design decision if work truly requires choosing among fundamentally different game behaviors.

Examples:
- adding dodge/block
- changing party limit
- introducing weapons
- changing type system
- adding storage
- major story rewrite
- changing traversal philosophy
- adding mandatory hunger/thirst — the owner settled a *light* version of this
  via `docs/decisions/D29` (satiety, soft debuffs, no starvation death); that
  much is built and is canon. Anything harsher (starvation death, thirst)
  still needs asking.
- changing stronghold structure

**Implementing an owner directive is not inventing one.** The Team Tether /
Tether Rift macro-story and the Meadows chapter structure are owner-supplied
and settled by `docs/decisions/D23`. Building them is ordinary work. Extending
them past what `docs/MEADOWS_PROGRESSION_SPEC.md` actually says still belongs
on this list. This paragraph exists because a firing reading "major story
rewrite" above would otherwise be right to park the whole chapter.

## First Objective

Start with **M0 and M1** from `MEADOWS_VERTICAL_SLICE.md`:
- clean Godot project
- Windows export preset
- controller input
- third-person movement playground
- walk/sprint/jump
- stamina
- fall damage
- camera orbit
- representative rolling meadow test terrain

Do not start creature content until movement is comfortable.
