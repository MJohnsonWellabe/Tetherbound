# CLAUDE.md — TETHERBOUND CODING AGENT INSTRUCTIONS

You are implementing **Tetherbound**, a Godot-based Windows-first third-person survival/crafting creature-training game.

Before coding, read:
1. `docs/GAME_DESIGN.md`
2. `docs/MEADOWS_VERTICAL_SLICE.md`
3. `docs/TECHNICAL_START.md`

These documents are authoritative.

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
- Food buffs; no starvation-death meter.
- Slot/stack inventory; no carry-weight system.
- Multiple death satchels persist.
- No Biome 2 work until Meadows passes its exit gate.
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
- adding mandatory hunger/thirst
- changing stronghold structure

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
