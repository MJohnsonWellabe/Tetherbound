# D99 — Every story flag has a declared scope, and an undeclared one is a test failure, never a default

**Date:** 2026-09-05 · **Decided by:** Fable, Stage B lane 0.A, from `docs/MULTIPLAYER_DIRECTIVE.md` and the codebase facts in `docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` §1. Adversarially reviewed before approval.

## Decision

`data/progression/flag_scopes.json` classifies every flag id or prefix as `world` or `player`;
`objectives.json` entries carry a matching `scope`; `test_flag_scopes.gd` fails on any id a
writer site or objective names that the table does not. At runtime an unscoped id is a
`push_error` and a world write, so the game does not stall — the test guarantees shipped data
never takes that path. The settled table is in `docs/specs/MP_STATE_SEAM.md` §3. Two residual
calls made here: **home and creature-bed objectives are player flags granted to every connected
peer when the world gains the pieces** (a shared camp is everyone's camp), and `legendary_joined`
is the party-owner's while `legendary_freed` is the world's.

## Why

Directive §16 and rule 14. Defaulting an unknown id either way is wrong in a way that only shows
up with a second player: default-world makes a friend's tutorial already done; default-player
leaves a gate closed for the friend who did not open it.
