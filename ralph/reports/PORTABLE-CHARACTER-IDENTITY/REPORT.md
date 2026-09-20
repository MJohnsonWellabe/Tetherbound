# Portable character identity

This report records the bounded source and unit evidence for stable portable
character identity across host saves. It does not certify remote co-op or a
release package.

## Current implementation

The portable identity work is based on source commit `2768c632b` and the
reconnect smoke/map-fixture correction in `44a5680eb`. The existing two-peer
entry point is:

```text
tools/net/run_net_smoke.sh reconnect_keeps_character
```

The smoke now seeds both isolated peer homes through the production ordinary
autosave path before networking, reads the generated IDs, requires them to be
nonempty and distinct, joins using the saved client identity, and checks the
live/file identity plus party, satchel, equipment and player flag through
connected autosave, disconnect, wipe and reconnect. The host registry must
retain one row per canonical identity. `tools/net/peer_runner.gd` preserves the
requested lookup ID while exposing the live PlayerState ID and raw persisted
character-envelope ID for non-tautological checks.

The existing focused evidence is clean on the corrected source tree: the
reviewed unit batches are 121/783, 56/315 and 21/145, each with zero failures
and zero script/plain errors. The earlier map-fixture run on2768c632b was
7tests/144assertions with one failed assertion and a script error: stale split
files masked the intended legacy flat fixture. Its correction is in44a5680eb.

PR138's CI run35489472202 failed unit shards2and3; shards1and4passed. Expanded
local shards2/3 on44a5680eb finished: shard2 ran916tests/1,330,852assertions with
one fallback-worker failure; shard3 ran845tests/1,579,701assertions with zero
failures. Neither emitted a script error. Off-tree negative-fixture engine
diagnostics occurred in both; shard2 also reported resource leaks at shutdown.
Shard2 read a hardcoded `slot-0` character path after a random ID was minted.
The corrected worker fixtures use the actual identity, including the test that
must serialize two writes to the same character file. Combined worker/map
verification passes16tests/237assertions with no script/plain errors
(`tetherbound-identity-focused-fixture-final.log`).

These broad local shard labels are not equivalent to CI's labels: CI excludes
the three separately run terrain/harvest files before partitioning the rest.
PR139 run35490293150 currently has unit shards1/2/3failed and4passed. Reproducing
its exact shard1 selector locally ran973tests/333,509assertions with8failures:
seven alpha-pin save-fixture cases and the previously recorded gate-F threshold
predicate. Exact shard3 finished962tests/69,863assertions with2satchel fixture
failures and a cascading script error. No full-suite pass is claimed.
The alpha-pin fixture now supplies the required identity holder and removes
split authority when deliberately constructing its v16 legacy flat file;
24tests/154assertions pass with no script/plain errors
(`tetherbound-identity-alpha-final.log`). Satchel fixtures likewise require
portable identity and recursive scratch cleanup;8tests/25assertions pass
(`tetherbound-identity-satchel-final-r3.log`), with no script errors and existing
dummy-renderer shutdown RID/resource diagnostics after the summary. All
behavioral assertions remain intact.

The saved-character smoke's unsaved negative control now calls the existing
Session join directly: the LAN title route intentionally selects the existing
local autosave. The positive reconnect still uses the production title route.
The corrected runtime result is recorded below; full-suite acceptance remains open.

The first saved-character runtime on3f20ea19b (`portable-identity-20260920-01`)
failed before admission: both actual character files were created, but the
step returned their IDs outside the harness's existing `data` payload. The
peer runner's verdict serialization discarded those fields, so the coordinator
attempted an empty-ID join, which production correctly refused. Both peer
hello records identify3f20ea19bf03; neither peer log contains script/plain
errors. The correction puts the ID inside `data` and reads it there; it changes
no production save or admission behavior.

## Saved-character runtime result

The corrected existing smoke on8379ab1a6 finished with exit0 and
`ALL CHECKS PASSED`, run `portable-identity-20260920-02`. Root independently
read `SUMMARY.md`, `NET_RUN.json` and peer logs under the OS-temp directory
`tetherbound-identity-net-r2`. Both hello records identify8379ab1a618f and
Godot4.7stable; host16356/client19828 exited normally. Coordinator session85778
is terminal. No new harness or campaign walker was added.

The covered checks include independent ordinary slot-0 saves with distinct
nonempty IDs, pre-existing character-file join, raw-file/live/registry identity,
connected autosaves, disconnect/wipe/production-title reconnect, exact party,
items, worn equipment and player flag restoration, the host's intervening world
change, world equality, movement and the unsaved-character negative control.

Neither peer emitted a script error. The host emitted no plain errors. The
client emitted eight inactive-ENet teardown errors across the forced drops,
then seven missing TrainerSpawner/cache/replication errors in the direct
Session unsaved-character negative control after title teardown. Those errors
remain open diagnostics, not a clean-error claim or evidence that the negative
control created a playable world. The positive saved-character reconnect used
the production title/world path and its movement checks passed. This loopback
result does not prove internet relay, four-account play or return-home pose
provenance across two different worlds sharing a slot number.

## Boundaries

This proves source-level and focused unit behavior for new portable identity
and preservation of legacy IDs, plus the bounded two-peer runtime above.
Legacy IDs are preserved and migration ambiguity remains open.
Manual-slot coverage represents one current portable character. Separate
accounts, separate networks/relay, four-peer play, Steam overlay/device
behavior, export artifacts, and full-suite acceptance remain unproved.

The source tree is not a release package, and no Steam AppID or remote Steam
acceptance is implied by this report.

## Remaining identity boundaries

Do not rename existing slot-based characters at ordinary save time. Session
registration precedes that save, multiple local manual slots may share one
character, and foreign worlds can still hold owned death satchels even when
the portable escrow row says settled (`satchel_escrow.gd::reconcile` and its
retained transaction rows). Re-keying reward receipts also requires changing
both world journal and character escrow together (`reward_delivery.gd`). There
is no authenticated legacy ownership mapping for another host's records. A
local file graph alone does not prove absence of foreign property. Automatic
legacy renaming remains unimplemented rather than risking lost property.

A separate defect was verified in `save_game.gd::load_slot`: it compared
`character.last_world_id` with the selected world file ID when deciding whether
to clear foreign realm/pose. Two independent hosts both use `slot-0`, so that
comparison can falsely treat the friend's location as local. The existing
persisted `reward_delivery_namespace` can distinguish those world instances;
character placement provenance must carry and compare it. The correction and
its distinct validation scope follow.

## Return-home world provenance correction

Sourcea416a43dc on `ralph/world-return-provenance` (parentPR139) reuses the
existing world `reward_delivery_namespace` and stamps it as character-format4
`last_world_instance_id`. `world_identity.gd` mints16random bytes once; host new
game, ordinary split save and outgoing world snapshot establish identity.
Guest character saves carry received identity and scratch writes do not mint.
Matching nonempty instance and locator preserve exact placement; mismatch or
missing/malformed provenance clears foreign pose/pending entry and uses the
home slot's region/map and authored spawn. Personal team, equipment, inventory,
escrow and maps remain portable. Character formats1–3 remain readable; old
builds reject4. This does not rename characters or alter world file paths.

The regression was first reproduced against the parent behavior with the
modified same-slot case:7tests/52assertions/1failed, restoring Cloudreach,
`friend_gate` and pin202 instead of home Meadows and pin101
(`tetherbound-world-provenance-red.log`). The corrected final coherent source
passes103tests/642assertions with no script/plain errors
(`tetherbound-world-provenance-final.log`). The command used the existing
runner's `--only` selectors: authoritative split, character format, session
snapshot, atomic save, immutable legacy split, fallback worker, world format
and split-key coverage. Root read the source diff and logs independently.

Focused coverage includes a same-locator different-instance return, exact
matching-instance location, missing legacy proof, character-only save,
envelope preservation without converting malformed data into identity,
distinct fresh worlds, stable repeated snapshots and no guest minting even
when its namespace is empty. The chunk-transfer path carries the existing
world field. Atomic rollback, old-save original bytes and split partition
checks remain intact. The adjacent general-save fixture needed its real world
identity holder: the old fake had only personal identity, so the corrected
loader conservatively cleared two placement cases. Adding the existing
`SplitFixture.IdHolder` preserves all assertions. Final stock-Godot4.7 general
save coverage passes61tests/407assertions with no script/plain errors
(`tetherbound-save-format-world-fixture-final.log`); its preceding red was
61/404/2failed. The flight test reuses that fixture but has not yet been rerun.

The required existing Playground smoke on sourcea416a43dc1b8 finished exit0,
`smoke: OK` (`tetherbound-world-return-playground-20260920-01.log`, terminal
session63911). Root independently inspected the log: no script/parse errors;
the material-null and dummy-renderer shutdown/resource errors match the
previous bounded baseline categories. This boot alone is not reconnect,
full-CI, device or internet acceptance.

### Character4 reconnect evidence

The existing reconnect smoke completed on92ec4bde0966 with exit0 and
`ALL CHECKS PASSED`, run `world-provenance-20260920-01`. Both peer hello
records name that source; coordinator session13078 is terminal. Root read
`SUMMARY.md`, `NET_RUN.json`, both peer logs and the persisted JSON under
OS-temp `tetherbound-world-provenance-20260920-01`. No script/parse errors or
failed checks occurred. The host emitted no plain errors; the client retains
the earlier forced-drop inactive-ENet and unsaved negative-control
TrainerSpawner/cache/spawner/delta diagnostics. The negative control still
does not prove a playable world; the positive route uses production title join.

Host character `character-fd8fc480740948ed35e2923c74f52d2f` and tested guest
`character-00ed3f0fd2e13f6ca3b64fe97f67108f` are format4, locator `slot-0`,
with `last_world_instance_id=170fe3077795e7a8ae0af53eba26f358`. That matches
the persisted host world. The guest's own world remains a different instance,
`5d39aabe7b08cf5db5aaaba516e0422b`. This verifies actual character-only
save provenance across peers; the focused load tests above exercise subsequent
home placement. No claim of a manual return-home journey or internet relay
follows. GitHub run35492117266 on92ec4bde0 has all four unit shards successful;
other jobs were still running at this observation. Full CI is not yet claimed.

## Related transaction boundary still open

Root review found the same locator assumption in
`scripts/net/satchel_escrow.gd::belongs`: rows match `world_id` and character,
without a world-instance field. `ledger_rpc.gd::reconcile_satchel_escrow`
retries matching pending create/transfer intents in the current realm. Its
`origin_host` check only prevents a former guest from retrying offline; it
does not distinguish two online hosts with the same slot locator. A fresh
UUID character can therefore have a foreign pending death-bag intent treated
as eligible in another same-slot world. This source-level finding has not yet
been reproduced in a dedicated transaction test. The placement correction
does not change this path. Next work must bind new escrow rows to the world
instance and preserve ambiguous legacy rows without guessing ownership,
replaying into another world or refunding a possibly committed drop.

## Death-satchel world scope correction

`ralph/satchel-world-scope`, based on PR140/d4ecc0ca7, corrects the transaction
boundary above. The parent-source regression produced7tests/44assertions/1failure:
a pending drop incorrectly belonged to a different world instance with the
same locator (`tetherbound-satchel-world-instance-red.log`). Root read the failure.

`satchel_escrow.gd` requires a typed nonempty world namespace before inventory
mutation and stamps `world_instance_id` in the durable row and nested intent.
The retry and same-bag pending checks now distinguish world instances.
`world_ledger.gd` checks the requested identity before duplicate handling or
mutation. `ledger_rpc.gd` validates the row, request, verdict and recovery
snapshot; it never substitutes current host identity into an old request.
A wrong-world refusal cannot refund a potentially committed drop, and a foreign
recovery snapshot cannot replace the current world.

Legacy pending rows are preserved without replay or guessed refund. Only an
exact owned death UID or owned transfer transaction receipt resolves one.
Owner-empty bags do not prove a legacy claim. Known durable personal grants or
refunds may settle once elsewhere without a new world mutation. Unproven old
rows get one readable notice; this preserves items but does not supply a manual
recovery tool or infer remote ownership. Character5/merged26 force older readers
to refuse the new semantics. World format2 is unchanged. v4/v25 fixtures retain
their nested pending intents without invented identity.

Final coherent stock-Godot4.7 focused run:101tests/697assertions/0failed, exit0,
no script/parse/plain errors (`tetherbound-satchel-world-scope-final-r2.log`, terminal
session52598). Selectors: `test_satchel_escrow.gd`,
`test_death_satchel_ledger.gd`, `test_character_save_format.gd`,
`test_save_format.gd`. Includes actual LedgerRpc negative paths, no inventory
change without namespace, legacy receipt/no-proof, same-UID foreign pending
isolation, host refusal without sequence/world/transaction mutation, migration
and forward-version refusal. Root reviewed the implementation and logs.

The existing `smoke_net_water_satchel_peer.gd` paired stock-Godot run exits0
on both processes: host6checks/client8checks, zero failures, with the deliberate
lost transfer acknowledgement recovered through retry/snapshot. Logs are
`tetherbound-satchel-peer-host-20260920.log` and
`tetherbound-satchel-peer-client-20260920.log` in OS temp. Root read both:
no script errors; each has one post-close inactive-ENet error in fixture
`is_host` during autosave teardown. The fixture explicitly assigns both peers
one host-world namespace because it bypasses Session admission/snapshot; no
production identity validation was relaxed. This is real ENet/LedgerRPC with
stationary actor fixtures, not a title-join or internet witness. Full CI and
release/device/four-player acceptance remain open.

Required Playground boot also exits0 with `smoke: OK`, terminal session78558,
log `tetherbound-satchel-world-scope-playground-20260920.log`. Root verified
no script/parse errors and the eight existing material-null/dummy-renderer
shutdown/resource error lines. This boot and paired smoke preceded the final
empty-character guard; the final coherent101/697 unit run includes it. That
guard refuses drop/transfer before draining into an unresolvable owner-empty
row. No repeated world boot or new campaign walker was added for this guard.
