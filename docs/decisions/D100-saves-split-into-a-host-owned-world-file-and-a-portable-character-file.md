# D100 — Saves split into a host-owned world file and a portable character file, and the original is never touched

**Date:** 2026-09-05 · **Decided by:** Fable, Stage B lane 0.A, from `docs/MULTIPLAYER_DIRECTIVE.md` and the codebase facts in `docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` §1. Adversarially reviewed before approval.

## Decision

`user://worlds/<world_id>/world.json` (host-owned) and
`user://characters/<character_id>/character.json` (portable, Valheim-shaped). A legacy
`user://saves/slot_<n>.json` (v≤22) is split on first load into one world and one character;
the original file is never modified or deleted, and both new files record `migrated_from`.
Key coverage is a test: the union of the two new key sets equals the v22 key set, the intersection
is empty. Autosave: the host writes the world file; each peer writes only its own character; a
client never writes a world file, and a smoke asserts its `user://worlds/` stays empty.
Partition table: `docs/specs/MP_STATE_SEAM.md` §4.

## Why

Directive §14 and rule 1. "Never silently destroy an old save" is already this project's rule
(`save_game.gd` is never fatal on load); the split extends it to never *rewriting* one either.
