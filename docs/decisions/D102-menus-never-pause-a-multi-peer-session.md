# D102 — Menus never pause a multi-peer session

**Date:** 2026-09-05 · **Decided by:** Fable, Stage B lane 0.A, from `docs/MULTIPLAYER_DIRECTIVE.md` and the codebase facts in `docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` §1. Adversarially reviewed before approval.

## Decision

`Session.pause_local(bool)` replaces the six panels' `get_tree().paused = true`
(`craft_panel, storage_panel, swap_panel, game_menu, creature_bed_panel, shop_panel`) and pauses
the tree only in a one-peer session. In a session the existing `input_owner` group contract
stops world verbs. Buffs and nourishment (`game_state.gd:634`) keep ticking while a panel is open
in a session — a deliberate, recorded behaviour change. Solo keeps true pause.

## Why

Directive §13. The `input_owner` mechanism was built for exactly the case of a live world under an
open panel (`build_menu.gd`, owner report OW10), so the multi-peer path reuses it rather than
inventing a second gate.
