# Cloudreach lane (F06–F08) — evidence

Lane session for ROADMAP F06–F08. This file holds the lane's evidence and is updated in place. It is not a status document; STATE is the status record, and the coordinator updates it.

## WO-1 · F06 / C1: the owner's Cloudreach saddle-remount report

**Owner report (2026-09-11):** "I couldn't get back on the creatures with the saddle after going into cloudreach."
The source is `archive/docs/owner-2026-09-19/OWNER_PLAYTEST_2026-09-11_COMBAT_CLOUDREACH.md`. ROADMAP step 11 requires reproducing it on exact source before changing any controls.

**Baseline:** origin/main `49ef712fb`.

### Reproduced on main

`tests/smoke_cloudreach_saddle_remount.gd` loads the production `cloudreach_cliffs.tscn` with this setup:
- a five-creature party led by a Meadowhart
- a saddle in the bag
- the Meadows-earned `saddle_fitted_meadowhart` flag

It then summons the companion with the ordinary `creature_recall` press.

On unmodified main the run fails with `FAIL Cloudreach has a ground-riding controller`:
- **Cause:** Cloudreach never had a `RidingController`. Meadows authors one in its scene, and Water builds one at run time.
- **Git history:** `git log -S RidingController` shows one was never added to Cloudreach.
- **Player effect:** no mount offer exists in Cloudreach. This is the owner's report.

### Second defect, found once riding existed

The first dismount on the arrival road left the trainer frozen:
- Position stayed fixed at y 105.12 while vertical velocity grew to −37 m/s.
- The base controller sets the trainer at the world's `ground_height_at() + 0.2`.
- Cloudreach's surface index reported 105.00 m there. A physics ray at the same x/z hits `ArrivalGateRoadCliffShoulders/Ridge000/Collision` at 106.01 m.
- So the trainer's capsule was placed inside the cliff shoulder. `fly_controller.gd` already avoids trusting that index on stacked strata.

### Fix (lane-owned paths only)

- **`scripts/world/cloudreach_riding_controller.gd` (new):** extends the production `riding_controller.gd`, following the precedent of `water_riding_controller.gd`.
  - Only `_dismount_spot()` changes. It measures the floor with a physics ray from 2 m above to 3 m below the mount's feet, accepting walkable surfaces only.
  - The trainer's real capsule must fit at that spot. If it does not, the mirrored side is tried, then the mount's own footing.
  - SYSTEMS §8: "dismount at supported nearby clearance".
- **`scripts/world/cloudreach_world_runtime.gd`:** builds that controller as `RidingController`, after `EncounterDirector` and `CombatManager` exist.
  - It is skipped in a simulation-only host shell, the same way Water skips it.
  - The existing fall-recovery backstop already looks the controller up by that name.
- **Unchanged:** the Meadows and Water riding code, and shared files.

### Result on the fix (local, Godot 4.7-stable headless)

`smoke_cloudreach_saddle_remount.gd`: **35 checks, 0 failures.** Every check below passes:
- The ride offer wins the prompt, and the interact press mounts.
- The stick moves the mount 14.5 m in 1.5 s.
- Interact dismounts onto real ground at the mount's level (106.06 m).
- Walking back and pressing interact **remounts**.
- A mounted double jump does not deploy Fly, which reports "Fly is unavailable while riding or in combat." even with Fly unlocked.
- A mounted run straight at the closed `upper_counterweight_gate` stops 1.85 m short of its plane. The unlock flag is untouched.
- The same five party UIDs, in the same order with no sixth, hold at every step.

**Disclosed fixtures:**
- The party, saddle and fitted flag are seeded, standing in for the Meadows arrival.
- The closed-gate leg places the trainer and the mount 9 m in front of the gate.
- All mount, ride, dismount and remount actions are real input bindings.

### Neighbouring checks

| Check | Main `49ef712fb` | With fix |
|---|---|---|
| `run_tests.gd --only=cloudreach,fly,riding` | — | 188 tests, 0 failed |
| `smoke_cloudreach_arrival_walk` (CI job) | — | pass |
| `smoke_cloudreach_fall_recovery` | — | pass |
| `smoke_cloudreach_camp_exit` | 3/3 pass | 2/3 pass (first run failed) |

**Camp-exit finding.** The failed run stuck against `lower_cliff_foragers_0/1` at (−190, 194, 620):
- The fixture walks a straight line at wandering NPCs, and both variants touch the same foragers on the way.
- The fix adds no body and changes no NPC or collision code. The difference is still disclosed as a finding, not claimed as a pass.
- That smoke is not in CI.

### Still open under F06

This work order does not cover:
- a riding witness from the earned Meadows handoff (C1 order)
- two-peer mounted rejoin
- mount state across realm crossing and save/reload
- combat dismount inside Cloudreach
- Peblik's paint rejection, which is visual and has no shared-art grant
