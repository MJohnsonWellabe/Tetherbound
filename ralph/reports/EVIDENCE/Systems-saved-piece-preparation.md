# Systems saved-piece preparation

Source preparation only. Root owns native admission, engine processes and export identity checks.

## Home return

`stormwood_chain_runner.gd` now supports this saved sequence:

1. `marrow_aftermath` PASS checkpoint -> `home_key`: actual personal Home Key return.
2. `home_key` PASS checkpoint -> `home_relic`: actual Stormwood pedestal interaction.
3. `home_relic` PASS checkpoint -> `home_credits`: Grandpa's current-team dialogue, production credits, ordinary Skip and continued movement.

Each invocation uses `--segment=<piece> --from=<previous checkpoint> --out=<absent successor directory>`. The existing combined `homecoming` remains available. Each home piece requires the exact named predecessor, checks loaded state before any dialogue input, preserves ordered UIDs and level/XP/cap/breakthrough history, saves through production, and reads the copied authoritative character back. Root's strict training and personal-ending checks are preserved. The runner and training helper dependencies were imported byte-for-byte from merged `29a1b19a0a` before these additions.

Input blocker: the retained `stormwood_09_marrow_aftermath/receipt.json`, source `91fd9a7a26ccc5990ca8e21ed99ab6a1f79ae541`, lacks `training`, `ending` and `creature_progression`. It cannot prove this strict handoff. Do not backfill a PASS, relax the guard, or run the successor against it expecting acceptance. A qualifying preceding checkpoint must supply the missing witnesses. Its generated-arrival lineage also remains disclosed.

## Four-peer successors

The proof runner writes `PROOF.json` after its final harness checks. Owner captures include the loaded-state handoff, production character readback and hashes of the captured files. Split continuations now require training equality in addition to ordered UIDs, flags, inventory and realm.

After an admitted four-peer piece succeeds, package its saved successor with:

```text
python tools/net/finalize_release_piece.py <proof directory> <piece> <absent checkpoint directory>
python tools/net/release_four_peer_scenario.py tidewake <next piece> --checkpoint <checkpoint directory>
```

`TB_COMMIT_SHA` must identify the exact admitted source. Packaging requires a completed PASS, one successful host piece, post-piece peer hash agreement, all four matching owner readbacks, a successful host world save, and unchanged capture hashes. It copies the host's existing save layout, verifies copied bytes, and writes the PASS receipt last. Rejected/partial outputs are retained. The next process still loads through production and compares its state against that receipt.

This is saved-piece preparation, not exported-build acceptance or proof that a complete chapter was played. The three fixture guests, their grants and initial Hall-position setup remain disclosed by the scenario. Solo and four-peer exported replays remain native-UNRUN.

## Participant/feast source review

`18916175f5` requires exact participant IDs, exposes duplicate deliveries, and checks saved payout counts without requesting a new save. Follow-up `31097683f2` is required: the old `character_restore` getter called `characters()`, which drains the fallback worker. Its explicit `observation_only` mode instead obtains the existing saver directly and only invokes `has/read/state`; no fallback flush, save or apply occurs. In-memory reader diagnostics/cache are not durable mutation. Existing reconnect callers retain their behavior.

Feast UID/level/XP preservation follows `breakthrough.prepare_feed`: original UID is checked, tier is appended and cap lifted, with no level/XP bonus. `evolution.prepare_feast_choice` copies the original individual. The bounded smoke now checks those same values after reload/rejoin as well as immediately after feeding.

Validation: seven focused Python launcher/packaging tests passed, including malformed or failed proof, missing peer capture, stale owner/hash, wrong piece, escaped capture and existing-output refusal. Changed GDScript parsers and native smokes remain UNRUN. No blanket suite, engine process, native-stage mutation or cut-key retry was performed.
