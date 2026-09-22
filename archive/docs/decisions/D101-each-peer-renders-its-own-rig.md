# D101 — Each peer renders its own rig; the camera belongs to the peer that renders

**Date:** 2026-09-05 · **Decided by:** Fable, Stage B lane 0.A, from `docs/MULTIPLAYER_DIRECTIVE.md` and the codebase facts in `docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` §1. Adversarially reviewed before approval.

## Decision

`scenes/player/local_rig.tscn` = Player + CameraRig + FlyController + HUD binding, one per
process. `scenes/player/remote_trainer.tscn` = model, animation state, nameplate, synchronizer —
no camera, no input. The fifteen-plus lookups by node name `"Player"` and both world roots'
`$Player` go through `Game.local_player()` (promoted from the existing `_find_player()`,
`game_state.gd:716`) or the `local_player` group. Terrain3D's camera, the grass field, scatter
collision streaming, weather and the perimeter all read the local rig.

## Why

Every process has exactly one local player (plan §2), so the scene singletons — `CombatManager`,
`EncounterDirector`, `InteractionArbiter`, the HUD — do not become multi-player within a process;
they key on the local rig and tolerate remote bodies. That is the single largest simplification
in the conversion and it keeps every existing smoke meaningful as solo regression.
