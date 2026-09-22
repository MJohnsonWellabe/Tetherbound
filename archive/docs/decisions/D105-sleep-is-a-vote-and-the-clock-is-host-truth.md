# D105 — Sleep is a vote, and the clock is host truth

**Date:** 2026-09-05 · **Decided by:** Fable, Stage B lane 0.A, from `docs/MULTIPLAYER_DIRECTIVE.md` and the codebase facts in `docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` §1. Adversarially reviewed before approval.

## Decision

The host tracks which peers are in a bed; `pass_the_night` (`scripts/world/night_rest.gd`) runs
on the host only when every connected, non-downed peer is sleeping, and its results — the day
counter, the clock reset, `player_slept_at_home` into each sleeper's store, creature-bed rest
completion — are broadcast. `Game.day` and `clock_elapsed_seconds` are host truth replicated to
peers from Wave 2; `world_look.gd` resumes from the replicated value and never advances the day
on a client.

## Why

Directive rule 9 (Valheim-style). Today one player's sleep advances the day, resets the sky and
autosaves for everyone (`night_rest.gd:57–97`), which is exactly the single-actor assumption a
second player breaks.
