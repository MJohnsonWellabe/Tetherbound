# D104 — Downed precedes death, and a death satchel has an owner

**Date:** 2026-09-05 · **Decided by:** Fable, Stage B lane 0.A, from `docs/MULTIPLAYER_DIRECTIVE.md` and the codebase facts in `docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` §1. Adversarially reviewed before approval.

## Decision

`player_controller.died` becomes a `downed` state for a configurable window
(`multiplayer.json`); a teammate's `interact` revives; on timeout the existing satchel-drop and
respawn in `scripts/world/player_death.gd` run unchanged. Solo has no window. A death satchel is
a world entity tagged with the owner's `character_id`; only the owner can open it, others see it
labelled with the owner's name. One player's death never touches an encounter's state or the
world's progression.

## Why

Directive §12 and rule 19 ("each player's dropped recovery state remains personal").
`register_death_satchel` (`game_state.gd:919`) records no owner today, so the tag is the one
data change; the rest is a state in front of the existing flow.
