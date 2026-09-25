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
- **`scripts/world/cloudreach_physical_runtime.gd`:** the grounded-fall anchor check no longer runs while the trainer is carried. The riding controller owns mounted falls.
- **`scripts/player/fly_controller.gd`** (carried-anchor path only, granted to this lane):
  - `observe_carried_ground(at)`: the carrier reports verified ground; same host-authority path as a walk.
  - `tick_carried_anchor(delta)`: a carried trainer never reaches `physics_step` (`player_controller.gd` rides instead), so the pending-proposal clock stood still for the whole ride and an unanswered guest proposal never timed out (review M3). The riding controller ticks it every ride frame; after `pending_timeout_s` the next observation re-proposes, as on foot. `player_controller.gd` and `remote_trainer.gd` are unchanged.
- **`scripts/world/cloudreach_riding_controller.gd` (new):** extends the production `riding_controller.gd`, following the `water_riding_controller.gd` precedent.
  - **Dismount on real collision.** Sixteen candidates (8 directions × the species' dismount distance and 1.2 m further). Each needs a walkable physics-ray floor between 2 m above and 3 m below the mount's feet, room for the trainer's capsule, and a clear line from the saddle.
  - **Never inside the mount.** Capsule fit is checked against world collision and, separately, against the mount's own capsule by geometry (segment distance from the shapes and transforms), so the answer does not depend on the mount's collision layer. A following mount has layer 0, which a physics query never reports (review H3).
  - **Refusal.** SYSTEMS §8 "otherwise show refusal": an asked-for dismount with no clear spot is refused ("No room to dismount here.") and the rider stays seated.
  - **Forced dismounts** (a fight, a modal, the finale pilot, a freed mount, a fall) verify first, in this order. Every rule except `vacated` checks the floor ("airborne" excepted), capsule fit against world and mount, and a clear line from the saddle (review M2), and every rule stays within 8 m of the mount (review H1):
    1. `clear`: the ring above.
    2. `airborne`: only while the mount is off the ground. The ring at the mount's own level, no floor required: the trainer comes off beside the mount into the same air and falls as a walker would, never back up the route.
    3. `remembered`: the last clear spot this ride recorded.
    4. `history`: the **newest** ground sample the mount stood on (previously the oldest, about 2 s and 17–40 m back, with no reach limit; review H1).
    5. `mounted_from`: where the trainer stood when the ride began.
    6. `mount_top`: standing on the mount's back (capsule top plus 5 cm, capsule fit, a landing ray that must hit the mount with a walkable normal). Only when the body stays solid afterwards: a fight or the finale pilot took it. A following mount loses its collision layer, so a trainer on its back would drop into it (review M1).
    7. `vacated`: the mount was freed; where it stood, its volume now empty.
    8. `deferred`: nothing verifies. `dismount()` returns false and the rider stays seated with the stick ignored. The base's per-frame "not allowed, dismount" (and the fall watch) retries every physics frame until a spot verifies.
  - The old last resort put the trainer at the mount's position plus its seat offset. The seat (2.19 m) is below the Meadowhart capsule top (3.45 m), and the offset ignored the mount's rotation, so it was inside the mount (review M1). It is gone.
  - `_combat_took_the_mount()` also answers true while the finale pilots the creature, so the base does not hand a piloted body back to following.
  - `last_dismount_rule` names the rule used (or `deferred`); `deferred_dismounts` counts deferrals.
  - **Mounted-fall recovery.** A carried trainer has no collision layers, so neither the cloud-sea kill volume (`fall_recovery.gd` reports only the trainer's own body) nor the grounded-fall anchor sees them. A mount airborne for more than 0.6 s is recovered, with the rider, when it is 100 m below its last verified ground **or** below the kill plane (50 m under the CloudSea, y −232 with this config), whichever comes first: the same two limits a walker has (SYSTEMS §8: "Same physical keys/barriers whether mounted or walking"). It returns to the **newest** ground sample that still holds walkable floor and has a clear line from the take-off sample, so a gate or seal that closed behind the mount is never crossed (coordinator review of 358148b1; previously the oldest sample, about 2 s back). If none verifies, the ride ends through the forced chain above (normally `airborne`) and the walker recovery takes over.
  - **Fly's safe anchor follows the ride.** Each ground sample reports the verified clear spot BESIDE the mount (walkable to the trainer's 45°, capsule fits, clear of the mount), not the mount's feet. A guest's proposal there cannot be read by the host's probe as the mount: `remote_trainer.gd::_anchor_params` (817–834) casts from 2 m above the claim to `probe_m` below with the proxy's mask, excluding only the proxy, so a claim under a solid mount on the host could return the capsule surface (refused as `not_floor`, or granted in the air). The spot is 2.7 m from the mount's centre, well inside the arbiter's 6 m drift. A carried proposal consumes `_touched_down` like a walking one (documented in `observe_carried_ground`).
  - **SYSTEMS §8 limits.** The mounted hop is capped at the trainer's own `movement.json` jump height. Mounts climb 45° at most, unless the species authors its own climb (the legendary keeps 60°). Meadows and Water are unchanged.
  - **No ride offer while the finale pilots the creature.**
- **Unchanged:** `riding_controller.gd`, `player_controller.gd`, `remote_trainer.gd` and all other shared files.

### Result on the fix (local, Godot 4.7-stable headless)

`smoke_cloudreach_saddle_remount.gd` at ``992295cb1``: **284 checks, 0 failures, no SCRIPT ERROR.** Dismount placements are recorded on the `dismounted` signal, at the moment of placement, and each one asserts the rule, the distance from the mount, walkable floor under the feet, no geometric overlap with the mount's capsule (any layer), no overlap with world collision, and a clear line from the saddle.
- **M3 timeout (solo, fake client):** a carried guest's proposal goes to the host once, is not re-sent while pending under 5.0 s, and is re-proposed after 5.0 s with no answer. The live ride ticks Fly's clock (0.50 s over 30 frames).
- The ride offer wins the prompt, and the interact press mounts. The stick moves the mount 14.5 m in 1.5 s. The mounted hop is 1.42 m, and the trainer's own is 1.42 m.
- Every interact dismount uses `clear`, lands on the collider top (arrival road: trainer 106.09 m, collider 106.08 m, surface index 105.00 m), and walking back and pressing interact **remounts**.
- A mounted double jump does not deploy Fly. A mounted run at the closed `upper_counterweight_gate` stops 1.84 m short of its plane.
- A mounted pair 368 m below the last anchor raises no fall recovery; Fly's anchor follows the ride (105.2 m, mount at 105.3 m).
- Ledge: riding off the causeway road drops 11.1 m to the floor and lands with no recovery. Terrace: riding into open air falls 100.8 m and is recovered to the road with the rider seated.
- **Refusal and modal (M5):** boxed in by walls, interact is refused with the message. With the modal lockout held, the forced dismount is pinned to `deferred`: the rider stays seated and the trainer stays inside the walls. When the walls come down, the held modal ends the ride on its next retry with `clear`.
- **Rule ladder:** pillars on all 16 ring points. `remembered` is used at P (2.2 m); with a slab between the saddle and P it is rejected and the dismount defers (M2). With history [20 m back, P] the **newest in-reach** sample P is used (`history`); with only the 20 m sample it defers (H1). `mounted_from` is used at P.
- **Closed wall (coordinator review):** the mount is ridden 14.8 m by the stick; a slab is raised just behind it, with all 8 of the ride's ground samples beyond it, and pillars block the ring. The forced dismount finds nothing verified on the near side and defers (`deferred`); the trainer stays on the mount's side (1.64 m) instead of being set down among the samples beyond the slab.
- **Mid-drop (H1):** a forced dismount 4 m into the 11 m causeway drop uses `airborne`, 2.7 m beside the mount at y 397.4 (road 401.5), and the trainer lands on the floor at 390.0.
- **Save while mounted (M4):** on foot on the causeway road Fly's anchor is at 401.2 m. Mounted, the pair is placed on the arrival road and ridden; the save is made while mounted. On reload the trainer stands on ground, not carried, at the saved spot, with the same party, and Fly's anchor is at 105.7 m, where the ride was saved. The checks are relative to the fixture's own saved level. This is a fix witness against the controller before `6db201b3c` and a regression guard against current main (see the negative controls).
- **Combat start (H3/M1):** walls go up around the mount after the director admits it, before the riding controller sees the fight. The ride ends with `mount_top`: 3.50 m from the mount's feet, standing on its back (landing ray hits the mount), no overlap, clear line; the mount keeps layer 1; a second later the trainer is still not inside it.
- The same five party UIDs hold at every step.

**Disclosed fixtures:**
- The party, saddle and fitted flag are seeded.
- Teleports: trainer and mount 9 m in front of the upper counterweight gate; the mounted pair to the arrival road (long descent, save leg); trainer and mount to the Broken Causeways ledge road (ride-off, mid-drop, save leg), the arrival terrace road (ride-off), the causeway floor (rule ladder) and the arrival road (combat).
- Test-only StaticBody walls around the mount (refusal and combat legs), 16 pillars and one slab (rule ladder), and a slab across the route behind the mount (closed-wall leg, which also reads `_ground_history`).
- The rule ladder writes the controller's private `_clear_spot`, `_ground_history` and `_mounted_from` and calls `dismount()` directly, as a fight or modal does. The mid-drop dismount is a direct `dismount()` call.
- The modal is the arbiter's lockout set directly (what `sequence_director.gd::_refresh_lockout` does for a panel).
- The combat leg spawns a wild with `spawn_wild` and calls the director's private `_start_fight`.
- The M3 wiring check raises Fly's pending flag by hand; the M3 timeout check runs a bare Fly controller with a fake client session and a proxy that never answers.
- Every other mount, ride, dismount and remount is real input.

**Negative controls.** Each run checked out that commit's `cloudreach_riding_controller.gd` and `fly_controller.gd` into the test tree, kept this branch's smoke, ran it, and restored the files:

| Leg | Current main `835744b35` (= 358148b12's controller) | Pre-anchor main `a0fde6d76` |
|---|---|---|
| M3 timeout (fake client) and live clock wiring | fails (no `tick_carried_anchor`) | fails (no carried-anchor path) |
| Interact dismounts: rule `clear` at placement | fails (no `last_dismount_rule`); placement otherwise passes | same |
| Long descent: Fly's anchor follows the ride | passes | **fails**: anchor still at 473.8 m |
| Ledge ride-off lands with no recovery | passes | **fails**: 6 m recovery threshold snaps the mount back |
| Refusal/modal (M5): rider stays seated inside the walls | **fails**: dismounted to the remembered spot outside the walls, crossing a wall | **fails**, same |
| Rule ladder: remembered behind a wall defers (M2) | **fails**: set down at the rejected spot | **fails**, same |
| Rule ladder: newest in-reach history (H1) | **fails**: set down at the 20 m sample | **fails**: set down inside the mount's capsule |
| Rule ladder: history out of reach defers (H1) | **fails**: set down 20 m back | **fails** |
| Rule ladder: mounted_from | **fails**: 20 m sample | **fails**: inside the mount |
| Closed wall (coordinator) | **fails**: set down 13.07 m beyond the wall, 15.0 m from the mount | not run (leg added after this control) |
| Mid-drop forced dismount (H1) | **fails**: put back on the upper road (y 401.5), 8.4 m away | **fails**, same |
| Save while mounted (M4) | passes (regression guard) | **fails**: reload recovers the trainer to the causeway road, anchor at 401.2 m |
| Combat start boxed in (H3/M1) | **fails**: set down outside the walls; no clear line from the saddle | **fails**, same |
| Totals | 253 checks, 40 failures (with this head's final smoke) | 237 checks, 42 failures (smoke at `f1130ddcf`, before the closed-wall leg) |

An earlier control against current main with the `f1130ddcf` smoke gave 238 checks and 36 failures; the difference is the closed-wall leg.

**Not exercised by a test:**
- the finale pilot handoff while mounted
- a freed mount (`vacated`)
- a deferred combat dismount (nothing verifies, not even `mount_top`)
- two peers (another lane's smoke)

### Neighbouring checks

| Check | Main `49ef712fb` | With fix |
|---|---|---|
| `run_tests.gd --only=cloudreach,fly,riding` | — | 188 tests, 0 failed |
| `smoke_cloudreach_arrival_walk` (CI job) | — | pass |
| `smoke_cloudreach_fall_recovery` | — | pass |
| `smoke_cloudreach_camp_exit` | 4/7 pass | 4/6 pass |
| `smoke_cloudreach_finale` | fails | fails identically |
| `smoke_cloudreach_physical_runtime` | fails ("reload preserves durable progress but no temporary trial") | fails identically |
| `smoke_fly_traversal` | — | 30 assertions, 0 failures |
| `run_tests.gd --only=fly,riding,cloudreach_physical` at `992295cb1` | — | 34 tests, 792 assertions, 0 failed |

**Existing failures on main**, none of which is in CI:
- **Camp exit.** The fixture's straight-line walk runs into the wandering `lower_cliff_foragers` NPCs, and fails on main as well as on the branch.
- **Finale.** This fixture does not load the realm.
- **Physical runtime.** Fails on the same line on main.

**New F06 finding, left open here.** On the arrival road near (8, 105, −245), the ordinary `creature_recall` press summoned the companion about 21 m below the trainer, at y 83.9. The trainer then walked off the edge toward it and was recovered to camp. It is the next F06 work order: a recalled companion must appear on the trainer's own level.

### Still open under F06

This work order does not cover:
- a riding witness from the earned Meadows handoff (C1 order)
- two-peer mounted rejoin, and a two-peer mounted-descent anchor check (the two-peer smoke is another lane's)
- mount state across a realm crossing
- the capture tool's ride-off frames at this head (the lead's render chain owns the renders)
- Peblik's paint rejection, which is visual and has no shared-art grant
