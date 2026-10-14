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

## Actual predecessor ancestry retention

The finalizer now requires a successful host `load_save` before the piece, with the actual loaded directory, input save hashes, and explicit receipt/provenance presence. The production load snapshots both metadata documents as exact bytes and SHA256 before loading, and refuses if either the saves or metadata change during the load. A split receipt must belong to that loaded checkpoint. `PROOF.json` retains this load witness.

Packaging retains the original metadata bytes under `predecessor/` and records their hashes, source save hashes and load step in both output provenance documents. Lineage follows the coordinator's `checkpoint_lineage.gd::derive` contract without fresh-prefix verification authority: generated origins survive descendants; generated legacy provenance overrides an earned label; missing lineage stays unproven. Only an existing canonical continuous earned lineage can be inherited. Historical proofs without this load witness are refused rather than backfilled.

Six focused finalizer tests PASS, including the historical Tidewake generated provenance, multigeneration origin retention, exact metadata bytes/hashes, legacy earned-label refusal, and missing/guest/duplicate/late/mismatched/corrupt load witnesses. Whitespace check PASS. Review artifact: `D:/tetherbound/.artifacts/codex-takeover-systems/saved-piece-lineage-review/review.json`. This narrow follow-up depends on the saved-piece cohort through `7217e5159d`; it does not require the superseded `02696b38a5` runner import. GDScript parser and runtime validation remain UNRUN and root-owned; no native process, stage mutation, broader merge or acceptance claim.

## Post-main prerequisite audit

Exact ancestry fix: `0e7e539167474e2306aba71024fd1ab71189e64d`; synchronized lane merge: `7d2eabafa343f452c4e4293f42f3d4f38fb60628`, incorporating main `2bda3c7775592191350455737a761fcbd3077a7b`. The six-test result is retained at `D:/tetherbound/.artifacts/codex-takeover-systems/post-main-integration/ancestry-six-tests.txt`.

The audit found one additional ancestry gap: an earned host predecessor could retain earned classification despite the current scenario's generated guest grants and portal fixtures. The finalizer now retains each current `party_grant`, `story_flag` and disclosed `actual_portal_fixture` step as a generated origin; these override earned inheritance and survive descendants. Seven finalizer plus four launcher tests PASS in `corrected-packaging-launcher-tests.txt` in the same artifact directory. No budgets or gameplay assertions change.

- Participant: actual stable IDs must be distinct; both authored rewards require exactly two deliveries including pending rows, exact per-participant accepted identities, full live payout and matching existing owner file. Observation-only readback remains mandatory. Native result still required.
- Feast: the existing generated recipe/party/item boundary remains disclosed. Paid Kitchen cook/feed, cap increase, original UID/level/XP, repeat refusal and save/reload/rejoin checks remain. Rejoin uses the same guest process, not process-restart evidence. Original 900-second harness deadline and reviewed 1200-second outer cap remain.
- Home Key: the post-main retained `stormwood_09_marrow_aftermath` now identifies source `4187155b0f3af17d70209eb514a220e97a286e5b` (superseding the earlier audited fixture identity). It still has no training, ending or creature_progression snapshots and still declares generated rootgate ancestry. Strict Home Key/relic/credits continuation remains BLOCKED_INPUT; do not backfill that receipt. Obtain an actual newly witnessed predecessor first.
- Stormheart: main's actual newcomer ceremony checks authored L55, live/persisted cap60, completed tier prefix, removal of released progression and unchanged retained companions. Existing old L55/cap10 saves remain unchanged during Home Key continuation. The runner copies and verifies saved owner state for aftermath and home boundaries. Actual release/aftermath runtime and saved successor remain prerequisites; source audit cannot supply them.

The post-main code-only patch is based on exact main above, excluding historical reports and the obsolete whole-file training import. It preserves main training helper/tests and Rowan visit/chest routing. Root must re-review and pin its integrated source before any bounded native admission; old packets remain fixed to their original identities.

## Retained runtime evidence and next saved piece

Independently inspected PR685 logs from run38527725042. Job115732097885 shard7 ran `boss_rewards_each_participant` once, exit0 in140s at test merge `5758088292b32d7e509ba782fd246619abf336f1`: distinct actual character IDs, coin/potion accepted exactly once each, and both existing saved counts equal the full live payout. Job115732097859 shard9 also ran `f48_feast_feed` once, exit0 in173s: each feed receipt added once, repeat feeding refused, and both original UID/level/XP and items/caps/recipes/receipts preserved after save/reload/rejoin. These are Ubuntu CI generated-fixture passes, not earned chapter or clean Windows native acceptance. The deleted PR merge ref could not be fetched; exact source identity is retained in checkout/peer-hello logs, not claimed from a new local inspection of that merge.

Decoded logs, focused excerpts and `ci-proof-review.json` are retained under `D:/tetherbound/.artifacts/codex-takeover-systems/feast-next-e30b/`. All47 embedded entries of root's portable systems-d4 native bundle were rehashed successfully. Its scope remains four parsers/six methods/61 assertions/zero failures. Reuse these results; no participant or feast rerun is requested merely to replace uninspected evidence.

Next concrete saved-piece request is `solo07a-request.json` in that directory, pinned to landed main `e30b761bbe6f874df95c3b2153d9fcd7a7c8c6e7`: one existing solo `07a_salt_bex` helper, preceded by a60s runner parser, unchanged1800s route cap, one engine/no peers. The five retained Tidewake05 files are hashed; receipt preflight confirms Water realm, five distinct ordered companions, resolved Aquaryn gate and no pre-completed Bex/Calder/Venn/ending milestones. The input is generated L20, with missing historical training evidence explicitly disclosed. Combat feasibility is unproven; no level/party/flag changes are proposed. Production Load must match receipt state before helper input. Success must produce an actual saved successor with training and generated lineage, then receive root review before07b. Source-run diagnostic only, no export/earned/Home Key closure. Request NOT_ADMITTED; no native launch, stage access, automatic successor or original packet modification.
