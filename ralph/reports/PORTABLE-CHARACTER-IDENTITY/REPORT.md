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
local shards2/3 on44a5680eb are still running. Shard2has exposed a fallback-worker
test that reads a hardcoded `slot-0` character path after a random ID was minted;
that fixture needs correction without weakening its transaction assertions.
The saved-character smoke's unsaved negative control also needs to call the
existing Session join directly: the LAN title route intentionally selects the
existing local autosave. Keep the positive reconnect on the production title
route. These pending corrections prevent a runtime or full-suite pass claim.

## Boundaries

This proves source-level and focused unit behavior for the portable identity
and migration paths. The existing named-character reconnect smoke remains the
runtime witness to run on the coherent committed tree; no new runtime result
is claimed here. Legacy IDs are preserved and migration ambiguity remains open.
Manual-slot coverage represents one current portable character. Separate
accounts, separate networks/relay, four-peer play, Steam overlay/device
behavior, export artifacts, and full-suite acceptance remain unproved.

The source tree is not a release package, and no Steam AppID or remote Steam
acceptance is implied by this report.
