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

## Proof (local, same machine)
- Baseline (coordinator head 91fd9a7a, no fixes): leave-write failure 2/3 runs (CI symptom).
- With the fix: the leave wrote the character 3/3 and no rejoin/gear check failed.
- Unit: owner_passive_sync + research_passive_authority + foundation_resource_save +
  prepared_training_owner_identity: 61 tests, 0 failed. The new test covers the window's bounds.
- Not fixed here: the pre-host-hit checks ("host's opponent strikes ... connected false",
  1/3 runs on baseline and 2/6 with the fix) and the HP arithmetic check after a hit (1/3 with
  the fix). They are separate and pre-existing; see the coordinator message.
