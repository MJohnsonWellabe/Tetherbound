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
previous bounded baseline categories. Schema4 reconnect, full CI, device and
internet acceptance are not implied by this boot or the earlier schema3
reconnect run.
