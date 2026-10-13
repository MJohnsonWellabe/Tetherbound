# P0 harness_max_hp leave (#681 blocker): "rejoin: the leave wrote tidesteel_harness_plus_1 ..."

Systems lane, tb/ev-systems, Tue 13 Oct 2026, 12:20 AM CT.

## Symptom (data loss), CI run 38337179074, net-smoke-runs-4
Guest: `save refused: ... (owner passive pending phase=frozen)` then `client leave: could not
write character`. After rejoin, memory and file hold harness "" and the host admits s 1.0000.

## Root cause (not the mastery series; that job runs on the host only)
A host research duty froze the guest's owner-passive checkpoint while the host waited for inputs.
A leave inside that window was refused by the owner-save guard, so it lost every unsaved change.

## Fix
- Product: owner_passive_sync.gd `frozen_unprepared` is true only while the checkpoint is frozen,
  nothing is prepared, and the live record still hashes to the frozen one. In session.gd, only a
  client leave's own save (`_leave_save`) may pass that window; every other save still waits.
  The host re-admits the record and re-requests the checkpoint on rejoin.
- Fixture sequencing (tests/helpers/harness_hp_net_peer.gd; no assertion changed):
  `harness_wear` (a disclosed direct record write) waits for the owner fence, as a player's
  equip would. `harness_host_hit` waits for the wild's pending saved vitals, because the host
  refuses any strike while they are pending ("connected false").

## Proof (local)
- Baseline 91fd9a7a: leave failure 2/3 (the CI symptom), "connected false" 1/3.
- Product fix only: leave wrote 3/3. Remaining failures came from the fixture: the wear inside a
  freeze (1/3) and the strike race (1/3).
- Product fix + sequencing: smoke 3/3 PASS (runs 10-12), leave wrote every time.
- Unit: owner_passive_sync, research_passive_authority, foundation_resource_save,
  prepared_training_owner_identity: 61 tests, 0 failed.
