# D107 — Item trading is in; creature trading is out

**Date:** 2026-09-05 · **Decided by:** Fable, Stage B lane 0.A, from `docs/MULTIPLAYER_DIRECTIVE.md` and the codebase facts in `docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` §1. Adversarially reviewed before approval.

## Decision

Player-to-player item transfer by direct offer/accept and by drop-to-world entities
(`scripts/world/dropped_item.gd`), both as ledger transactions so a disconnect mid-offer
duplicates nothing. Creature trading is not built in this pass and no seam for it is added.

## Why

Directive rules 17 and 18. The five-creature limit is per player (`CLAUDE.md`), and a trade seam
is a place a sixth creature could hide; the directive defers it and so does this pass.
