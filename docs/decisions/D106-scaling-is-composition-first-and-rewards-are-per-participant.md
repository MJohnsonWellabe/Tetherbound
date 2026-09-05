# D106 — Scaling is composition-first, and rewards are per participant

**Date:** 2026-09-05 · **Decided by:** Fable, Stage B lane 0.A, from `docs/MULTIPLAYER_DIRECTIVE.md` and the codebase facts in `docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` §1. Adversarially reviewed before approval.

## Decision

Per participant count, `multiplayer.json` names extra opponents or roles and targeting rules,
plus a modest stat multiplier; never HP × players. An encounter's mandatory personal rewards (XP,
items, player-scoped key flags) are granted to every participant through a per-encounter
`reward_grant` in the ledger; the world's defeat flag is set once. Fable authors the scaling
table in lane 4.A; lane 4.D builds `reward_grant`, because no per-player reward mechanism exists
today (Cloudreach's "reward receipts" are HUD banner events in `progression_feed.gd`, not
grants).

## Why

Directive rules 6, 15 and 20. Four-player fights must be more interesting, not four times longer.
