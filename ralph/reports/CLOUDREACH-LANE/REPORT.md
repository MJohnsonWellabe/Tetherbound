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
  - Before the finale's `break_the_eye` creature-piloting exam takes the ally, it dismounts any rider, and it takes the ally **only once the rider is off**. With nowhere verified to stand the dismount defers and the exam waits, retried every frame, so the pilot never drives a body somebody is still carried on (coordinator review H-A).
- **`scripts/combat/cloudreach_encounter_director.gd`** (shared with another agent; the smallest isolated change, for the coordinator to sequence): SYSTEMS §8 "Combat admission dismounts safely first. No mounted catch/combat."
  - Lines 601–602: `_start_fight` returns before anything else when `_rider_off_for_admission()` is false.
  - Lines 607–616: the new `_rider_off_for_admission()`, which calls `RidingController.dismount_for_admission()` when it exists.
  - Lines 639–640: the same guard at the top of `begin_trainer_battle`, so a trainer battle is never half-started.
  - There is no pre-fight signal or hook elsewhere: `combat_manager.begin()` places fighters, stands the trainer aside and takes the camera in the same call (review M-A), so the director is the only seam before it.
- **`scripts/world/cloudreach_physical_runtime.gd`:** the grounded-fall anchor check no longer runs while the trainer is carried. The riding controller owns mounted falls.
- **`scripts/player/fly_controller.gd`** (carried-anchor path only, granted to this lane):
  - `observe_carried_ground(at)`: the carrier reports verified ground; same host-authority path as a walk.
  - `tick_carried_anchor(delta)`: a carried trainer never reaches `physics_step` (`player_controller.gd` rides instead), so the pending-proposal clock stood still for the whole ride and an unanswered guest proposal never timed out (review M3). The riding controller ticks it every ride frame; after `pending_timeout_s` the next observation re-proposes, as on foot. `player_controller.gd` and `remote_trainer.gd` are unchanged.
- **`scripts/world/cloudreach_riding_controller.gd` (new):** extends the production `riding_controller.gd`, following the `water_riding_controller.gd` precedent.
  - **Dismount on real collision.** Sixteen candidates (8 directions × the species' dismount distance and 1.2 m further). Each needs a walkable physics-ray floor between 2 m above and 3 m below the mount's feet, room for the trainer's capsule, and a clear line from the saddle.
  - **Never inside the mount.** Capsule fit is checked against world collision and, separately, against the mount's own capsule by geometry (segment distance from the shapes and transforms), so the answer does not depend on the mount's collision layer. A following mount has layer 0, which a physics query never reports (review H3).
  - **Refusal.** SYSTEMS §8 "otherwise show refusal": an asked-for dismount with no clear spot is refused ("No room to dismount here.") and the rider stays seated.
  - **Every other ending** (a modal, the finale pilot, combat admission, a freed mount, a fall) verifies first, in this order. Every rule except `vacated` checks the floor ("airborne" excepted), capsule fit against world and mount, and a clear line from the saddle (review M2), and every rule stays within 8 m of the mount (review H1):
    1. `clear`: the ring above.
    2. `airborne`, during a **real drop** only (airborne for 0.6 s, or no floor within the 3 m probe under the mount): the ring at the mount's own level, no floor required. The trainer comes off beside the mount into the same air and falls as a walker would, never back up the route. During a hop or an edge flicker it is tried only after rules 3–5 (review M-C).
    3. `remembered`: the last clear spot this ride recorded.
    4. `history`: the **newest** ground sample the mount stood on (previously the oldest, about 2 s and 17–40 m back, with no reach limit; review H1).
    5. `mounted_from`: where the trainer stood when the ride began.
    6. `vacated`: the mount was freed; where it stood, its volume now empty.
    7. `deferred`: nothing verifies. `dismount()` returns false, the rider stays seated and is told once, "No room to dismount here." The caller decides: a modal retries every frame; **combat admission is refused** (the fight does not start); the **finale exam waits**.
  - The trainer is never set down on the mount. The earlier `mount_top` rule (standing on the mount's back) is removed: combat is now dismounted before it begins, and the pilot waits (review M-A). The old last resort, the mount's position plus its seat offset, was inside the mount (review M1) and is gone too.
  - **The camera stays with the body's owner.** When a fight or the finale pilot already owns the body, the base dismount's hand-back of the camera to the trainer is skipped (the Cloudreach `dismount` clears the rig reference around the base call; `riding_controller.gd` is unchanged; review H-A (c) and M-B).
  - `_combat_took_the_mount()` also answers true while the finale pilots the creature, so the base does not hand a piloted body back to following.
  - `last_dismount_rule` names the rule used (or `deferred`). `deferred_dismounts` counts deferral **episodes**, not frames; room found again during the ride starts a new episode (review L4).
  - Mount capsules count for overlap even when disabled (a hidden mount turns its collider off; review L3). `_dismount_spot` has no fallback of its own: `dismount` always plans the spot first (review L2).
  - **Mounted-fall recovery.** A carried trainer has no collision layers, so neither the cloud-sea kill volume (`fall_recovery.gd` reports only the trainer's own body) nor the grounded-fall anchor sees them. A mount airborne for more than 0.6 s is recovered, with the rider, when it is 100 m below its last verified ground **or** below the top face of the cloud-sea kill volume, whichever comes first: the same two limits a walker has. A walker is caught on entering `FallRecoveryKillVolume`, a box 40 m tall centred on the plane 50 m under the CloudSea, so its top face is at y −212 with this config; the controller reads that face from the public volume node, not a private field (review L1) (SYSTEMS §8: "Same physical keys/barriers whether mounted or walking"). It returns to the **newest** ground sample that still holds walkable floor and has a clear line from the take-off sample, so a gate or seal that closed behind the mount is never crossed (coordinator review of 358148b1; previously the oldest sample, about 2 s back). If none verifies, the ride ends through the forced chain above (normally `airborne`) and the walker recovery takes over.
  - **Fly's safe anchor follows the ride.** Each ground sample reports the verified clear spot BESIDE the mount (walkable to the trainer's 45°, capsule fits, clear of the mount), not the mount's feet. A guest's proposal there cannot be read by the host's probe as the mount: `remote_trainer.gd::_anchor_params` (817–834) casts from 2 m above the claim to `probe_m` below with the proxy's mask, excluding only the proxy, so a claim under a solid mount on the host could return the capsule surface (refused as `not_floor`, or granted in the air). The spot is 2.7 m from the mount's centre, well inside the arbiter's 6 m drift. A carried proposal consumes `_touched_down` like a walking one (documented in `observe_carried_ground`).
  - **SYSTEMS §8 limits.** The mounted hop is capped at the trainer's own `movement.json` jump height. Mounts climb 45° at most, unless the species authors its own climb (the legendary keeps 60°). Meadows and Water are unchanged.
  - **No ride offer while the finale pilots the creature.**
- **`tools/capture_cloudreach_lane_common.gd`** (this lane's helper): the contact sheet's row index no longer uses integer division (parse warning).
- **Unchanged:** `riding_controller.gd`, `player_controller.gd`, `remote_trainer.gd`, `combat_manager.gd` and all other shared files.

### Result on the fix (local, Godot 4.7-stable headless)

`smoke_cloudreach_saddle_remount.gd` at `ce861a469`: **325 checks, 0 failures, no SCRIPT ERROR.** Dismount placements are recorded on the `dismounted` signal, at the moment of placement, and each one asserts the rule, the distance from the mount, walkable floor under the feet, no geometric overlap with the mount's capsule (any layer), no overlap with world collision, and a clear line from the saddle.
- **M3 timeout (solo, fake client):** a carried guest's proposal goes to the host once, is not re-sent while pending under 5.0 s, and is re-proposed after 5.0 s with no answer. The live ride ticks Fly's clock (0.50 s over 30 frames).
- The ride offer wins the prompt, and the interact press mounts. The stick moves the mount 14.5 m in 1.5 s. The mounted hop is 1.42 m, and the trainer's own is 1.42 m.
- Every interact dismount uses `clear`, lands on the collider top (arrival road: trainer 106.09 m, collider 106.08 m, surface index 105.00 m), and walking back and pressing interact **remounts**.
- A mounted double jump does not deploy Fly. A mounted run at the closed `upper_counterweight_gate` stops 1.84 m short of its plane.
- A mounted pair 368 m below the last anchor raises no fall recovery; Fly's anchor follows the ride (105.2 m, mount at 105.3 m).
- Ledge: riding off the causeway road drops 11.1 m to the floor and lands with no recovery. Terrace: riding into open air falls 100.8 m and is recovered to the road with the rider seated.
- **Refusal and modal (M5):** boxed in by walls, interact is refused with the message. With the modal lockout held, the forced dismount is pinned to `deferred`: the rider stays seated and the trainer stays inside the walls. When the walls come down, the held modal ends the ride on its next retry with `clear`.
- **Rule ladder:** pillars on all 16 ring points. `remembered` is used at P (2.2 m); with a slab between the saddle and P it is rejected and the dismount defers (M2). With history [20 m back, P] the **newest in-reach** sample P is used (`history`); with only the 20 m sample it defers (H1). `mounted_from` is used at P. **Mid-hop (M-C):** with knee-high posts beside every ring point (the air beside the hopping mount stays open) and the remembered spot staged, a forced dismount 0.73 m into a hop stands the trainer on the remembered ground (2.30 m), not in the air.
- **Closed wall (coordinator review):** the mount is ridden 14.8 m by the stick; a slab is raised just behind it, with all 8 of the ride's ground samples beyond it, and pillars block the ring. The forced dismount finds nothing verified on the near side and defers (`deferred`); the trainer stays on the mount's side (1.64 m) instead of being set down among the samples beyond the slab.
- **Mid-drop (H1):** a forced dismount 4 m into the 11 m causeway drop uses `airborne`, 2.7 m beside the mount at y 397.4 (road 401.5), and the trainer lands on the floor at 390.0.
- **Save while mounted (M4):** on foot on the causeway road Fly's anchor is at 401.2 m. Mounted, the pair is placed on the arrival road and ridden; the save is made while mounted. On reload the trainer stands on ground, not carried, at the saved spot, with the same party, and Fly's anchor is at 105.7 m, where the ride was saved. The checks are relative to the fixture's own saved level. This is a fix witness against the controller before `6db201b3c` and a regression guard against current main (see the negative controls).
- **Finale pilot handoff while mounted (H-A):** the finale controller node is moved to the pair on the causeway floor and the captain-victory flag set, so the runtime's `break_the_eye` handoff runs there. Boxed in by walls, the exam waits for 60 frames with the rider seated, and the creature is never piloted while the trainer is carried; those 60 frames are one deferral event, told once. When the walls come down the rider comes off (`clear`, verified placement), the exam pilots the ally, the camera is on the piloted creature a second later, and the trainer stands on ground, not carried. Clearing the flag releases the pilot: the ally follows, no ride resumes on it, and the camera is back on the trainer.
- **Combat admission (M-A/M-B):** on the arrival road, with walls around the mount, the director's `_start_fight` is refused: no fight, the rider stays seated, rule `deferred`, one deferral event. With the walls gone the rider is set down (`clear`, 2.69 m, verified) **before** the fight begins (`is_fighting` false at placement), the fight starts, nothing carries the trainer, the trainer stands on ground in the fight, and a second in the camera is on the ally, not the trainer.
- The same five party UIDs hold at every step.

**Disclosed fixtures:**
- The party, saddle and fitted flag are seeded.
- Teleports: trainer and mount 9 m in front of the upper counterweight gate; the mounted pair to the arrival road (long descent, save leg); trainer and mount to the Broken Causeways ledge road (ride-off, mid-drop, save leg), the arrival terrace road (ride-off), the causeway floor (rule ladder, closed wall, finale pilot) and the arrival road (combat).
- Test-only StaticBody walls around the mount (refusal, finale and combat legs), 16 pillars or knee-high posts and one slab (rule ladder), and a slab across the route behind the mount (closed-wall leg, which also reads `_ground_history`).
- The rule ladder writes the controller's private `_clear_spot`, `_ground_history` and `_mounted_from` and calls `dismount()` directly, as a fight or modal does. The mid-drop dismount is a direct `dismount()` call.
- The modal is the arbiter's lockout set directly (what `sequence_director.gd::_refresh_lockout` does for a panel).
- The combat leg spawns a wild with `spawn_wild` and calls the director's private `_start_fight`.
- The finale leg moves the finale controller node to the causeway floor and sets, then clears, the captain-victory flag.
- The camera checks read the camera rig's private `_target`.
- The M3 wiring check raises Fly's pending flag by hand; the M3 timeout check runs a bare Fly controller with a fake client session and a proxy that never answers.
- Every other mount, ride, dismount and remount is real input.

**Negative controls.** Each run checked out the named commit's lane files into the test tree, kept this branch's smoke (`ce861a469`), ran it, and restored the files. From `537d85a1c` on, the swapped files are `cloudreach_riding_controller.gd`, `fly_controller.gd`, `cloudreach_world_runtime.gd` and `cloudreach_encounter_director.gd`; earlier controls swapped the first two.

| Leg | Reviewed head `66293d06d` | Current main `835744b35` | Pre-anchor main `a0fde6d76` (earlier smoke) |
|---|---|---|---|
| M3 timeout (fake client) and live clock wiring | passes | fails (no `tick_carried_anchor`) | fails |
| Interact dismounts: rule `clear` at placement | passes | fails (no `last_dismount_rule`); placement otherwise passes | same |
| Long descent: Fly's anchor follows the ride | passes | passes | **fails**: anchor still at 473.8 m |
| Ledge ride-off lands with no recovery | passes | passes | **fails**: the 6 m threshold snaps the mount back |
| Refusal/modal (M5): rider stays seated inside the walls | passes | **fails**: dismounted across a wall to the remembered spot | **fails** |
| Rule ladder: remembered behind a wall defers (M2) | passes | **fails**: set down at the rejected spot | **fails** |
| Rule ladder: newest in-reach history (H1) | passes | **fails**: set down at the 20 m sample | **fails**: inside the mount |
| Rule ladder: history out of reach defers (H1) | passes | **fails**: set down 20 m back | **fails** |
| Rule ladder: mid-hop prefers ground (M-C) | **fails**: `airborne`, set down in the air | **fails** | not run |
| Closed wall behind the ride | passes | **fails**: set down 13.07 m beyond the wall | not run |
| Mid-drop forced dismount (H1) | passes | **fails**: back on the upper road | **fails** |
| Save while mounted (M4) | passes | passes (regression guard) | **fails**: reload recovers the trainer to 401 m |
| Finale pilot handoff (H-A) | **fails**: piloted while the trainer is carried; camera not on the piloted creature | **fails**: piloted while boxed in | not run |
| Combat admission (M-A/M-B) | **fails**: the fight begins boxed in with the rider on; camera not on the ally | **fails**: same | not run |
| Totals | 313 checks, 15 failures | 282 checks, 48 failures | 237 checks, 42 failures (smoke at `f1130ddcf`) |

**Not exercised by a test:**
- a freed mount (`vacated`)
- a hidden mount (disabled collider) at dismount
- a trainer-battle admission while mounted (same guard as the wild path, `begin_trainer_battle`)
- `join_encounter` / a shared encounter joined while mounted: that path begins the fight in `encounter_director.gd` (shared) without `_start_fight`, so only the per-frame fallback ends the ride there, deferring if nothing verifies
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
| `run_tests.gd --only=fly,riding,cloudreach` at `ce861a469` | — | 198 tests, 15838 assertions, 0 failed |

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


### Ride-off captures (production camera, `tools/capture_cloudreach_ride_off.gd`)

`captures/ride_off/_sheet_ride_off_after.jpg` (this branch, 76138d367) and `_sheet_ride_off_before.jpg` (the #229 head the coordinator reviewed, 2b38cdeaf). `ride_off_log.txt` holds each frame's trainer and mount positions.
- Both runs have 30.5 s of stick-held motion.
- **Ledge** (the Broken Causeways road's 11 m side):
  - Before: every ride-off is snapped back onto the road by the old 6 m rule, and the mount never reaches the floor below (the trainer stays at y 400–403).
  - After: the mount rides off and lands on the 390 m floor, the rider is dismounted and remounted there, and the ride carries on.
- **Terrace** (open air above the cloud sea): both heads recover the mount. After the recovery, this branch ends with the rider seated on verified ground (`last_dismount_rule=clear`).

Disclosed fixture: the party, saddle and saddle flag are seeded, and the trainer and mount are stood on each edge's upper road. Every mount, ride, dismount and remount uses the real interact and stick input.
