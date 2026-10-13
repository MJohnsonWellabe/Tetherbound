# P0 harness_max_hp leave (#681 blocker): "rejoin: the leave wrote tidesteel_harness_plus_1 ..."

Systems lane, tb/ev-systems, Tue 13 Oct 2026, 12:05 AM CT.

## Symptom (data loss)
CI run 38337179074 (net-smoke-runs-4). The guest log shows
`save refused: owner training state is mid-transaction (owner passive pending phase=frozen)`
then `client leave: could not write character`. After rejoin, memory and file both hold
harness "" and the host admits s 1.0000.

## Root cause
Not the mastery series: the mastery job only runs on the host. A host research duty for
the guest froze the guest's owner-passive checkpoint (the host was waiting on inputs).
The guest left inside that window. The save guard refuses every owner save until the
checkpoint is prepared and saved, so the leave wrote nothing and lost all unsaved changes.

## Fix (product)
- owner_passive_sync.gd `frozen_unprepared`: true only while the checkpoint is frozen,
  not yet prepared, and the live record is still exactly the frozen one (hash).
- session.gd: only a client leave's own character save (`_leave_save`) may pass that
  window. Every other save still waits. A prepared decision still lands only via its own
  save. On rejoin the host re-admits the record and re-requests the checkpoint.

## Smoke fixture sequencing (tests/helpers/harness_hp_net_peer.gd; no assertion changed)
- `harness_wear` (disclosed direct record write) now waits for the owner fence, as a
  player's equip would. Run 7 wore the Harness inside a frozen checkpoint, so the live
  record differed from the frozen one and the leave correctly refused.
- `harness_host_hit` waits until the wild's own pending hit has settled. The host refuses
  any strike while saved vitals are pending (`ordinary_actor_vitals_pending`, product rule),
  which caused "connected false".

## Proof (local, same machine)
- Baseline (coordinator head 91fd9a7a, no fixes): leave failure 2/3 (CI symptom), "connected false" 1/3.
- Product fix only: leave wrote 3/3; strike flake 1/3; fixture wear in a freeze 1/3.
- Product fix + fixture sequencing: smoke 3/3 PASS (runs 10-12), and the leave wrote every time.
- Unit: owner_passive_sync, research_passive_authority, foundation_resource_save,
  prepared_training_owner_identity: 61 tests, 0 failed.
