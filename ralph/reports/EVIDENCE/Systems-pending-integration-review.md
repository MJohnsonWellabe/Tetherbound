# Remaining Systems integration set

Reviewed against coordinator `a50c8e7ea64128ba25eff3e5ee19e81c2a092c65`, then checked the advance to `e9b82afa6925599498b3215083a2e31daceac5a4`. That advance changes none of these pending source paths or audited save/feast dependencies. No engine, build, native stage or coordinator checkout mutation occurred.

## Minimal code set

| Cohort | Commits in dependency order | Purpose |
| --- | --- | --- |
| Participant and feast verification | `18916175f5`, `31097683f2` | Actual stable participant IDs, exactly one delivery per participant/source, saved payout readback, retained feast UID/level/XP after reload/rejoin; mandatory observation-only probe correction |
| Saved replay/HomeKey pieces | `a912278b28`, `db6dec58cb`, `b61a29e2c7`, `7217e5159d` | Strict predecessor launcher, comparison after production load, copied owner readback, machine proof/hashed saved successor packaging and split home pieces |

`31097683f2` must accompany `18916175f5`: without it, `character_restore` calls `SaveGame.characters()`, which drains the fallback worker. The explicit observation-only branch reads the existing `_characters` saver and `has/read/state`, without save/apply/fallback drain. The production saver, character reader and atomic reader audited earlier are unchanged in coordinator. Reader cache/diagnostic updates are in-memory only. Accepted rows retain duplicate owners, compare against pre-fight actual IDs, and the smoke requires exactly two total rows per authored source, including pending rows. Saved coin/potion counts must match the full live payout without issuing an extra save.

The feast planner's level/XP behavior is unchanged: it opens the cap while retaining the same individual and adds no XP/level bonus. Coordinator adds chapter guidance elsewhere in `breakthrough.gd`; retain it. The bounded feast smoke's new checks compare UID/level/XP with the original pre-feed values again after host reload and guest rejoin. That rejoin is a new connection in the same process, not a guest process-restart claim.

Do **not** apply `02696b38a5` or overwrite entire source files from the Systems branch. Coordinator already has newer `training_handoff.gd` route-field/alias validation and Rowan `rowan_visit`/`rowan_chest` routing. The older dependency import would regress those. Existing coordinator validation helpers satisfy the pending commits' requirements.

## Concrete application check

All six code patches applied with `git apply --cached --3way --whitespace=error` in a separate temporary index based on `a50c8e7e`. The real index and both checkouts were untouched. The resulting training helper and its existing test are byte-identical to coordinator; Rowan visit/chest paths and the chest-only branch remain present. The result changes 14 code/test paths. The subsequent coordinator advance has no overlap with those paths or audited dependencies.

Artifacts: `D:/tetherbound/.artifacts/codex-takeover-systems/pending-integration-a50c8e7e/` contains six ordered code-only patches, the resulting source files, canonical SHA256 bindings, `apply-review.json`, and `bounded-smoke-commands.json`. The combined `pending-code.patch` is 44,362 bytes, SHA256 `ae29e5c8db10fd90b7835722cc3c5ff3e3bd4cb3a71533c278113b4e2433f070`. Shared append-only handoff prose was excluded from these patches; this review supplies the current scope. Root can apply the combined patch instead of resolving historical handoff append conflicts. No new architecture or product repair is introduced.

## Bounded commands after root admission

Executable: `C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64.exe`. Working project: `C:/CodexTemp/tetherbound-native-service`. Root must first pin the actual resulting integrated commit and runtime dependency hashes, create fresh isolated output/homes, and use the existing serial service/resource/diagnostic controls. The JSON request is **NOT_ADMITTED**, with no invented resulting source SHA.

For each of `tools/net/peer_runner.gd`, `tests/smoke_net_boss_rewards_each_participant.gd`, and `tests/smoke_net_f48_feast_feed.gd`, parse once (60-second outer cap):

```text
--headless --path C:/CodexTemp/tetherbound-native-service --check-only --script <named script>
```

Then the two exact gameplay argv, in order:

```text
--headless --path C:/CodexTemp/tetherbound-native-service --script tests/smoke_net_boss_rewards_each_participant.gd
--headless --path C:/CodexTemp/tetherbound-native-service --script tests/smoke_net_f48_feast_feed.gd
```

Outer caps are 540 and 1,200 seconds respectively, covering the unchanged harness startup and step budgets. Each has two peers and at most three simultaneous engine processes. The request gives separate fresh `TB_NET_RUN_ID` and `TB_NET_OUT_DIR` values. Require natural exit 0, every original/new assertion, empty `NET_RUN.failures`, no fatal state and strict diagnostics; retain all original logs and saved homes. No timeout increase, assertion weakening or broad suite is proposed.

For the saved-piece source only, the next relevant admitted batch needs parse checks of `tools/net/proof_steps.gd`, `tests/smoke_net_proof_two_peer.gd`, and `tools/earned_saves/stormwood_chain_runner.gd`, each using the same parser argv/cap above. The two previously unrun pure witnesses can share one bounded 180-second invocation:

```text
--headless --path C:/CodexTemp/tetherbound-native-service --script tests/run_tests.gd -- --only=test_captured_character_receipt.gd,test_release_piece_handoff.gd
```

Reuse the seven passing Python launcher/packaging checks for unchanged source; no blanket rerun was performed. HomeKey gameplay remains blocked on an actual `marrow_aftermath` predecessor with training/ending witnesses. The retained `91fd` receipt lacks them; do not backfill or relax the comparison. The saved successor route is `home_key -> home_relic -> home_credits`. Actual exported solo/four-peer play, earned chapter closure and P0 shipping/release/Linux gates remain open.
