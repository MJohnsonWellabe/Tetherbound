# D98 — One autoload keeps its surface: WorldState and PlayerState live behind Game's forwarding properties

**Date:** 2026-09-05 · **Decided by:** Fable, Stage B lane 0.A, from `docs/MULTIPLAYER_DIRECTIVE.md` and the codebase facts in `docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` §1. Adversarially reviewed before approval.

## Decision

`Game` stays the project's only autoload. It gains `world: WorldState`, `local: PlayerState` and
`players: Dictionary[peer_id → PlayerState]` (host holds every peer's). Every existing
`Game.<x>` property keeps its name and type as a forwarding property: `Game.party` permanently
means "the local player's party"; `Game.day` means `world.day`. `Game.progression` becomes a
merged view over the world and player flag stores whose `revision` is the sum of both and whose
`set_flag` routes by scope (D99). Only authority-side code addresses `Game.players[peer]`.
Contract: `docs/specs/MP_STATE_SEAM.md`.

## Why

Directive §3 allows adapters and forbids rewriting working systems for purity. The inventory
(`docs/specs/MP_ASSUMPTION_INVENTORY.md` §1) counts 390 `Game.<field>` sites; a facade keeps them
all working and bounds the sweep to host-side code. Every process still has exactly one local
player, so "the local player's party" is a permanent meaning, not a transitional one.
