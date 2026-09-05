# D97 — Different biomes at once are headless realm shells on the host

**Date:** 2026-09-05 · **Decided by:** Fable, Stage B lane 0.A, from `docs/MULTIPLAYER_DIRECTIVE.md` and the codebase facts in `docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` §1. Adversarially reviewed before approval.

## Decision

The host runs one **realm shell** per occupied realm it is not itself in: the world scene
instanced under `Session/Realms/<realm>` in simulation-only mode (heightfield, encounter director,
world records, pickups/gates/NPC triggers, spawn containers; no grass, water rendering, VFX, HUD or
audio). Spawn containers (`Spawned/Trainers`, `Spawned/Creatures`, `Spawned/Items`) are authored
in both world `.tscn` files so a spawn arriving during a peer's procedural build has a path.
Replication is realm-scoped through synchronizer visibility and per-realm spawners. Every ledger
intent and world record carries an explicit `realm`; nothing authoritative reads
`Game.current_realm`. Until Wave 6 lands this, `enter_realm()` is refused in a multi-peer session
with a message (directive rule 16 permits the interim limitation only during development).

## Why

The first draft delegated an unhosted realm's simulation to its first occupant. Review showed two
things that sink it: a `MultiplayerSpawner` spawns under a `spawn_path` that must exist on the
host, so a host with no Cloudreach scene cannot spawn Cloudreach trainers for a second client; and
a delegating client's disconnect mid-fight loses encounter state nothing else holds. A headless
shell keeps the host authoritative with a bounded cost that spike S2 measures.

## Amended 2026-09-05, after spike S2

A shell is a **skip-build flag** threaded through `playground_world.gd`'s `_dress_the_meadow()`,
`_stand_up_the_grass_field()` and `_build_water()` (and the visual half of vegetation), never a
post-hoc free: freeing after `_ready()` recovered 30 % of frame time but only 1.2 % of memory,
because the 385,333-prop scatter and Terrain3D's resident data were already built. The three
story panels (`DialoguePanel`, `NamePrompt`, `StarterPicker`) stay in a shell —
`sequence_director.gd` calls them every frame. The shell's memory budget is set in Wave 6 only
after a spike measures the skip-build variant; the interim same-realm limitation stands until then.
