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
Runtime and full-suite acceptance remain pending.

The first saved-character runtime on3f20ea19b (`portable-identity-20260920-01`)
failed before admission: both actual character files were created, but the
step returned their IDs outside the harness's existing `data` payload. The
peer runner's verdict serialization discarded those fields, so the coordinator
attempted an empty-ID join, which production correctly refused. Both peer
hello records identify3f20ea19bf03; neither peer log contains script/plain
errors. The correction puts the ID inside `data` and reads it there; it changes
no production save or admission behavior. The corrected runtime is pending.

## Boundaries

This proves source-level and focused unit behavior for new portable identity
and preservation of legacy IDs. The existing named-character reconnect smoke remains the
runtime witness to run on the coherent committed tree; no new runtime result
is claimed here. Legacy IDs are preserved and migration ambiguity remains open.
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

A separate, verified defect remains in `save_game.gd::load_slot`: it compares
`character.last_world_id` with the selected world file ID when deciding whether
to clear foreign realm/pose. Two independent hosts both use `slot-0`, so that
comparison can falsely treat the friend's location as local. The existing
persisted `reward_delivery_namespace` can distinguish those world instances;
character placement provenance must carry and compare it before this case can
be accepted. That correction is not part of the current source evidence.
