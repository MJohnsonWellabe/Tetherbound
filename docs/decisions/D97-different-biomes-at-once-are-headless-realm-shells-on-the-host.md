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
