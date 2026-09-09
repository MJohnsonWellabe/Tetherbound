# Main landing, CI, export, and release verdict — 57660e4fe

Reviewed 2026-09-09 against repository `MJohnsonWellabe/Tetherbound`.

## Landing identity

PR 90 merged exact PR head `f227816f88cc88e702a6934650f7c8bf1daea871` to main as
`57660e4feb81fcbf8de5b0fe065e0ac107287676` at 03:03 UTC. Root independently
verified the PR head is an ancestor, the merge commit's parents are the prior main
`65267c4bd935d80b2e073799caeffc81b913952c` and `f227816f...`, and merge tree
`7c0e65986d6283cf0e835cbdb4e434c3cdef0da3` equals the PR-head tree.

## Main push CI verdict

Push run `34305636072` covers exact main
`57660e4feb81fcbf8de5b0fe065e0ac107287676`, workflow attempt 1. It ran from
2026-09-09 03:03:38 to 03:28:41 UTC (25m03s) and concluded success.

All 29 job records and all 27 executed-job raw logs were inspected. The 27 executed
jobs succeeded; only the configured `verify-continuous-core-known-red` and
`verify-gate-b-full-known-red` jobs were skipped. `export` executed and succeeded.
Every executed step succeeded. The only skipped steps inside successful jobs were
cache-hit `Install Godot` steps in the four unit shards and export job. No job failed,
was cancelled, or timed out. This was not a code-false shortcut: the changes job set
`code=true`, all validation jobs ran, the solo fence ran, and export ran.

- Four unit shards: **3,076 tests, 487,614 assertions, zero failures** (761/301,989;
  851/138,547; 645/26,672; 819/20,406).
- Five dedicated suites: **79 tests, 3,356,444 assertions, zero failures** (terrain
  freshness 1/1, scatter freshness 1/1, vegetation corridor 9/1,537,510, harvest
  30/799,078, scatter rules 38/1,019,854).
- **86 distinct wrapped smokes** ran exactly once: 50 solo and 36 two-peer. Every one
  used attempt 1; there is no attempt-2 line or runtime failed-attempt line.
- `smoke_traversal.gd` passed attempt 1 of its configured three-attempt allowance.
- `smoke_playground.gd` passed 1/1. Its synchronous durable receipt was 0.397s
  (`0.397 / 0.625 = 0.6352`) with impact-time `clip=chop` at 0.333515, while the
  retained process-frame poll arrived at 0.430s. This verifies the corrected
  identity/durability observation contract on main.

The raw logs retain expected negative-control and cleanup diagnostics: malformed data,
unknown IDs/unscoped flags, off-tree fixture calls, deliberate multiplayer refusals,
the intentionally killed peer, resource/RID cleanup messages, and 29 known
`Parameter "material" is null` lines across four solo shard families. No actual script
parse/load failure, failed assertion, nonzero executed step, internal retry, job
failure, cancellation, or timeout was found. The material diagnostic is disclosed,
not claimed fixed.

## Multiplayer and CI artifacts

Discovery found all 36 `# peers: 2` smokes. The measured planner assigned every file
exactly once across all seven successful shards:

| Shard | Job ID | Files | Artifact ID / bytes |
|---|---:|---|---|
| 1 | `102322377891` | riding; movement_two_peers; farm_race; shared_building; join_by_address | `10086851848` / 9,259,137 |
| 2 | `102322377875` | stormwood_livewire; fog_is_personal; storage_concurrency; water_alpha; sleep_vote; water_swim_stone_late_join | `10086843150` / 9,388,212 |
| 3 | `102322377963` | menu_does_not_freeze_peer; boss_rewards_each_participant; trade; host_exit_saves; peer_death; water_mounted_swimming | `10086869722` / 9,373,006 |
| 4 | `102322377927` | stormwood_hosted_trainers; stormwood_realms; revive; gate_opens_for_both; late_join_modified_world; water_swimming | `10086916511` / 9,376,698 |
| 5 | `102322377888` | catch_race; shared_boss; hearts; shared_wild_fight; two_peers_boot; host_join_leave | `10086842292` / 11,119,203 |
| 6 | `102322377840` | fly; realm_owner_disconnect_mid_fight; behind_character_joins_ahead_world; pickup_race; reconnect_keeps_character; deploy_two_creatures | `10086851920` / 11,137,101 |
| 7 | `102322377948` | split_realms | `10086734618` / 1,877,625 |

All seven artifact receipts were unexpired at review. The deliberate peer-death case
required its killed-peer/coordinator-fatal record and then printed the passing negative
control; it did not consume an internal retry.

## CI debug export

Job `102325077047` ran every export step successfully:

- produced a PE32+ Windows GUI x86-64 debug executable of **102,948,352 bytes**;
- ran the exported executable and reported
  `EXPORT-CHECK terrain=yes ground_at_spawn=0.90 player_y=2.90 props=383004` and
  `export: OK — extension loaded, data present, ground found.`;
- uploaded unexpired `Tetherbound-windows-debug` artifact ID `10087081568`,
  **686,715,029 bytes**, at 03:28:36 UTC;
- GitHub recorded upload SHA-256
  `5d3f75bf1a4df631864aa07868bd35f67baceee4451da812245b5eccfbd5ebb7`.

This establishes the debug export's binary shape and exported-runtime ground check. It
does not turn that expiring authenticated CI artifact into the public release asset.

## Release workflow and published asset identity

Separate push-triggered Release run `34305636213` covers the same exact main SHA,
workflow attempt 1. Its `build` and dependent `pages` jobs both succeeded from
03:03:38 to 03:16:33 UTC; all executed steps succeeded, with only cache-hit Godot
installation skipped.

The release build produced a **109,052,928-byte** PE32+ release executable and ran the
actual exported build successfully:
`EXPORT-CHECK terrain=yes ground_at_spawn=0.90 player_y=2.90 props=383004`, followed
by `export: OK`. It packaged the executable, PCK, staged GDExtension libraries, and
owner kickoff scripts. The publish step found rolling prerelease ID `364540334`,
deleted the previous `Tetherbound-windows.zip`, uploaded the new archive, and finalized
the release. The release body names exact commit
`57660e4feb81fcbf8de5b0fe065e0ac107287676`.

The before/after API receipts distinguish the public build from the pre-existing asset:

| Receipt | Asset ID | Bytes | Created UTC | Updated UTC | Downloads at receipt |
|---|---:|---:|---|---|---:|
| Before this run | `551380323` | 692,234,758 | 2026-09-08 21:47:31 | 2026-09-08 21:47:48 | 2 |
| After successful build/publish | `551867266` | 692,348,692 | 2026-09-09 03:13:32 | 2026-09-09 03:13:54 | 0 |

The release ID/tag remained `364540334` / `latest`; the asset identity, size, and
timestamps changed during this workflow. The public rolling asset therefore comes from
this main landing rather than the older published archive. The Pages job also succeeded.

## Evidence and boundary

Run/job/attempt/artifact JSON, 29 nonempty raw executed-job logs across CI and Release,
parsed smoke/error indexes, and the release asset receipts are preserved under
`.artifacts/ci-main-57660e4fe/`.

This report establishes exact-head landing, first-attempt main CI, debug and release
export/runtime checks, artifact receipts, rolling-release replacement, and Pages
success. It does not claim Stage C completion, visual shipping-art acceptance, a full
fresh opening-to-Tidewake campaign, owner hardware play, or resolution of the handed-off
aim control-phase work.
