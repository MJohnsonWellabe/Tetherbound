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

- **`scripts/world/cloudreach_world_runtime.gd`**
  - Builds `RidingController` after `EncounterDirector` and `CombatManager` exist. It is skipped in a simulation-only host shell, as Water does.
  - Before the finale's `break_the_eye` creature-piloting exam takes the ally, it dismounts any rider. This stops the pilot and the riding controller from both driving one body.
- **`scripts/world/cloudreach_physical_runtime.gd`:** the grounded-fall anchor check no longer runs while the trainer is carried.
  - `observe_ground()` never advances the anchor under a rider.
  - Without this change, any ordinary mounted descent of more than 100 m read as a fall on every frame.
- **`scripts/world/cloudreach_riding_controller.gd` (new):** extends the production `riding_controller.gd`, following the `water_riding_controller.gd` precedent.
  - **Dismount on real collision.** Candidates are tried beside the mount on either side, then behind, then ahead. Each one needs:
    - a walkable physics-ray floor between 2 m above and 3 m below the mount's feet;
    - room for the trainer's real capsule;
    - clear line of sight from the saddle.
  - **Refusal.** SYSTEMS §8: "otherwise show refusal". An asked-for dismount with no clear spot is refused and shows "No room to dismount here."
  - **Forced dismounts** (a fight, a modal, a freed mount) use the last clear spot seen during the ride if it is within 25 m. Otherwise they use the mount's own footing.
  - **Mounted-fall recovery.** A carried trainer has no collision layers, so the kill plane cannot see them. A mount airborne for more than 0.6 s and more than 6 m below its last ground is returned, with the rider, to where it stood about 2 s earlier.
  - **SYSTEMS §8 limits.**
    - The mounted hop is capped at the trainer's own `movement.json` jump height.
    - Mounts climb 45° at most, unless the species authors its own climb (the legendary keeps 60°).
    - Meadows and Water are unchanged. The shared `riding.json` hop of 1.6 m and the creature scene's 55° floor still apply there.
  - **No ride offer while the finale pilots the creature.**
- **Unchanged:** `riding_controller.gd` and all other shared files.

### Result on the fix (local, Godot 4.7-stable headless)

`smoke_cloudreach_saddle_remount.gd`: **51 checks, 0 failures.** Every check below passes:
- The ride offer wins the prompt, and the interact press mounts. The stick moves the mount 14.5 m in 1.5 s.
- The mounted hop is 1.42 m, and the trainer's own measured hop is 1.42 m.
- Each interact dismount lands on the collider top. On the arrival road the trainer stands at 106.09 m, the collider top is 106.08 m, and the surface index says 105.00 m.
- Walking back and pressing interact **remounts**.
- A mounted double jump does not deploy Fly ("Fly is unavailable while riding or in combat.").
- A mounted run at the closed `upper_counterweight_gate` reaches it and stops 1.85 m short of its plane. The flag is untouched.
- A mounted pair 368 m below the last anchor raises no fall recovery.
- A mount carried out over open air is caught by the mounted-fall recovery and stands on the road with its rider seated.
- The same five party UIDs hold at every step.

**Disclosed fixtures:**
- The party, saddle and fitted flag are seeded.
- The gate leg places the pair 9 m in front of the gate.
- The descent leg places the mounted pair on the arrival road.
- The drop leg places the mounted pair over open air beside it.
- Every mount, ride, dismount and remount is real input.

**Not exercised by a test:**
- the no-room refusal
- a combat-admission dismount in Cloudreach
- the finale pilot handoff while mounted
- a freed mount
- save/reload
- two peers

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
