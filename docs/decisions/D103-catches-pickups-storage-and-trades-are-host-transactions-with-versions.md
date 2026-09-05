# D103 — Catches, pickups, storage and trades are host transactions with versions

**Date:** 2026-09-05 · **Decided by:** Fable, Stage B lane 0.A, from `docs/MULTIPLAYER_DIRECTIVE.md` and the codebase facts in `docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` §1. Adversarially reviewed before approval.

## Decision

A `WorldLedger` (`scripts/net/world_ledger.gd`, pure) on the host validates and commits every
consequential world mutation from an intent: `claim_pickup`, `harvest`, `deplete_vegetation`,
`place_building`, `dismantle`, `storage_txn(expected_revision)`, `set_world_flag`,
`grant_player_flag(peer)`, `transfer_item`, `drop_item`, `reward_grant`, and — through the
encounter host — `catch_attempt`. First committed claim wins; the loser gets an explicit refusal
message; storage carries an expected revision and a stale write is refused. Solo runs the same
ledger in-process. Deterministic interleavings are unit-tested (`test_world_ledger_races.gd`,
`test_catch_arbitration.gd`); the net smokes prove "no duplication regardless of order".

## Why

Directive rules 4, 5, 7, 17 and §10. Today "collected" is a global progression flag
(`item_cache_pickup.gd`, `harvest_node.gd`, `key_pickup.gd`, `tm_pickup.gd`) written by whoever
touched the node; that is already the right *shape* for a world fact, it just needs one writer.
