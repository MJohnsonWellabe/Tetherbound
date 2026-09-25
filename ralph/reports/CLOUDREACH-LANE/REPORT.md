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
- **`scripts/player/fly_controller.gd`** (granted to this lane): adds `observe_carried_ground(at)`.
- **`scripts/world/cloudreach_riding_controller.gd` (new):** extends the production `riding_controller.gd`, following the `water_riding_controller.gd` precedent.
  - **Dismount on real collision.** Candidates are tried beside the mount on either side, then behind, then ahead. Each one needs:
    - a walkable physics-ray floor between 2 m above and 3 m below the mount's feet;
    - room for the trainer's real capsule;
    - clear line of sight from the saddle.
  - **Refusal.** SYSTEMS §8: "otherwise show refusal". An asked-for dismount with no clear spot is refused and shows "No room to dismount here."
  - **Forced dismounts** (a fight, a modal, a freed mount) use the last clear spot seen during the ride if it is within 25 m. Otherwise they use the mount's own footing.
  - **Mounted-fall recovery.** A carried trainer has no collision layers, so the kill plane cannot see them. A mount airborne for more than 0.6 s and 100 m below its last verified ground is returned, with the rider, to the oldest still-supported ground sample from about 2 s earlier. The 100 m is the same distance a walking trainer falls before recovery; SYSTEMS §8 says "Same physical keys/barriers whether mounted or walking".
  - **Fly's safe anchor follows the ride.** The mount's floor samples go through the new `fly_controller.gd::observe_carried_ground()`, which uses the same host authority path as a walk. After a long mounted descent, getting off or reloading no longer "recovers" the trainer back up to where the ride began (second review, F1).
  - **Forced dismounts are re-checked.** The remembered clear spot is re-checked for capsule fit before use; its floor and line of sight are not re-checked. The next fallback is the last re-probed ground sample. Only if neither fits does the trainer go to the mount's own position, which can be in the air, for example when combat starts mid-fall. A trainer set down in the air is solid again, so the ordinary walker recovery catches them.
  - **No endless mounted fall.** If a fall passes 100 m and there is no verified ground to return to, the ride ends and the walker recovery takes over.
  - **Only standable ground becomes the anchor.** A sample steeper than the trainer's own 45° is not reported as a Fly anchor.
  - **SYSTEMS §8 limits.**
    - The mounted hop is capped at the trainer's own `movement.json` jump height.
    - Mounts climb 45° at most, unless the species authors its own climb (the legendary keeps 60°).
    - Meadows and Water are unchanged. The shared `riding.json` hop of 1.6 m and the creature scene's 55° floor still apply there.
  - **No ride offer while the finale pilots the creature.**
- **Unchanged:** `riding_controller.gd` and all other shared files.

### Result on the fix (local, Godot 4.7-stable headless)

`smoke_cloudreach_saddle_remount.gd`: **66 checks, 0 failures.** Every check below passes:
- The ride offer wins the prompt, and the interact press mounts. The stick moves the mount 14.5 m in 1.5 s.
- The mounted hop is 1.42 m, and the trainer's own measured hop is 1.42 m.
- Each interact dismount lands on the collider top. On the arrival road the trainer stands at 106.09 m, the collider top is 106.08 m, and the surface index says 105.00 m.
- Walking back and pressing interact **remounts**.
- A mounted double jump does not deploy Fly ("Fly is unavailable while riding or in combat.").
- A mounted run at the closed `upper_counterweight_gate` reaches it and stops 1.85 m short of its plane. The flag is untouched.
- A mounted pair 368 m below the gate where the ride began raises no fall recovery.
- Fly's anchor follows the mount's ground (105.3 m).
- Getting off leaves the trainer at 105.1 m.
- **Negative control (run locally, not committed as a switch):** with the anchor reporting disabled, the in-ride anchor check fails, with the anchor still at 473.8 m. The in-ride and dismount checks are the real F1 witnesses.
- A save/reload after the drop leg keeps the trainer at 105.4 m. That save happens on foot, and Fly's `safe_anchor` is not written to the save, so this leg does not test F1.
- A mount carried out over open air falls 100.8 m (no earlier than a walker would), is caught by the mounted-fall recovery, and stands on the road with its rider seated.
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
- saving while mounted
- two peers

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

**Existing failures on main**, none of which is in CI:
- **Camp exit.** The fixture's straight-line walk runs into the wandering `lower_cliff_foragers` NPCs, and fails on main as well as on the branch.
- **Finale.** This fixture does not load the realm.
- **Physical runtime.** Fails on the same line on main.

**New F06 finding, left open here.** On the arrival road near (8, 105, −245), the ordinary `creature_recall` press summoned the companion about 21 m below the trainer, at y 83.9. The trainer then walked off the edge toward it and was recovered to camp. It is the next F06 work order: a recalled companion must appear on the trainer's own level.

### Still open under F06

This work order does not cover:
- a riding witness from the earned Meadows handoff (C1 order)
- two-peer mounted rejoin
- mount state across realm crossing and save/reload
- combat dismount inside Cloudreach
- Peblik's paint rejection, which is visual and has no shared-art grant

## WO-2 · F07 / C2: activity payoffs for couriers and aeries

**Baseline:** origin/main `bcf46366c`, after integration batch 1.

**Input:** a read-only audit of WORLD §11's six Cloudreach activities against ACCEPTANCE §5. None fully qualifies:

| Activity | Gaps found |
|---|---|
| `three_bells_against_silence` | Reward partial: no landing points revealed. |
| `packs_on_the_wrong_side` | Potion reward missing. The acknowledgement needs a backtrack to Galefoot. |
| `aeries_of_cloudreach` | The reward was a full night-rest bed (health, satiety, a day advance and an autosave), not WORLD's stamina-only landing rest. No map knowledge. |
| `the_cliff_circuit` | TM choice missing. The "Windscar pair" are story fights. The rematch tier exists although WORLD defers it. |
| `side_waycamp_shelter_complete`, `side_observatory_latch_complete` | Unbuilt. The latch needs traversable geometry in `cloudreach_world.gd`. |

### Changes

- **Couriers.** A new `activity_rewards` entry in `cloudreach_physical_runtime.json` offers "Take the couriers' thanks" at Galefoot once `side_stranded_couriers_complete` holds.
  - It sits at (-288, 180, 516), beside the Galefoot fire, 8 m or more from every Galefoot person, so no talk prompt competes. It is in plain sight from the fire's approach, and uses the courier `Bag.gltf` with the pickup glow so it reads at camera distance. Earlier spots were rejected: one was inside a house, and one lost the prompt to Iven.
  - The new lane-owned `cloudreach_personal_reward.gd` claims through the ledger's `reward_grant`: two `potion_small` per CHARACTER, once, recorded as the player-scoped `cloudreach_payout:couriers_thanks` flag. This is the same host-authoritative delivery the Meadows herd visit uses.
  - A first-come world cache would have let one co-op peer take the only copy. The first version of this work order did exactly that; the independent review failed it, and it was replaced.
  - The reward is kept out of `chapter.pickups`, so the route census of 178 pickups (100 candy, 75 recovery, three TMs) stays unchanged, as in WORLD §4.4.
  - The pack and the delivery grant nothing, so no equivalent award is paid elsewhere.
  - Neri says where the thanks is before the report line that completes the chain.
- **Aeries.** The `SurveyRest` night-rest beds are removed. A Fly landing within 12 m and 3 m of height of a surveyed aerie refills the trainer's traversal stamina, every time, and nothing else: no healing, no satiety, no day advance.
  - The aerie's landing sign (`LandingLabel`) was a flat Label3D. It read mirrored from half the directions a flyer lands from, which showed up in this work order's own capture. It now billboards around the vertical.

### Result (local, Godot 4.7-stable headless)

**`smoke_cloudreach_activity_rewards.gd`: 19 checks, 0 failures.**
- The fixture saves once first, which gives the fresh test character the stable identity that a personal reward is delivered to.
- Nothing is offered before the report. Neri's report goes through the real dialogue guard.
- The offer sits 8 m or more from every Galefoot person. From the plaza stand (-282, 181.6, 516), no collider blocks the sight line, and it clears the hearth, which has no collider, by more than 2.3 m. The prompt reads "Take the couriers' thanks".
- The interact press gives exactly two potions and sets this character's player-scoped receipt. No world cache flag is written.
- The offer is withdrawn, and pressing again pays nothing.
- After save and reload, the receipt holds, nothing is offered again, and there are still exactly two potions.
- No second character or peer is exercised. The per-character property rests on the shared `reward_grant` delivery, which has its own tests (`test_reward_delivery*.gd`, `test_world_ledger_races.gd`).
- **Independent review:** the first version failed (it was world-scoped). The re-review passed with low findings:
  - A claim the host never answers would leave a dead prompt. It is now re-enabled after 8 s.
  - A reload while a delivery waits on a full satchel makes a re-press say "already claimed". The potions still settle once there is room. This is disclosed.
  - A client-trusted `reward_grant` carries over the existing herd-visit trust model.

**`smoke_cloudreach_world_payoffs.gd`: 66 checks, 0 failures.**
- For each of the three aeries: no rest before it is surveyed; once surveyed, no bed, a landing restores stamina and health stays at 50%; a landing 30 m away gives no rest.
- The landing signal is emitted with the trainer on the aerie floor. This is a fixture, not a flown landing.

**`run_tests.gd --only=cloudreach_cast_dialogue,cloudreach_physical_runtime,cloudreach_world_payoffs`:** 16 tests, 1536 assertions, 0 failed. This was run after merging integration batch 2. The earlier `--only=cloudreach` run gave 162 tests, 0 failed.

### Captures (production camera, `tools/capture_cloudreach_activity_payoffs.gd`)

`captures/activity_payoffs/_sheet_activity_payoffs.png` has seven frames showing before and after within one run. The frames are also saved as JPEG next to it.
1. Galefoot before Neri's report: no bag.
2. After the report: the bag beside the fire.
3. The prompt.
4. After the press: the bag is gone and there are ×2 potions in the hotbar.
5. The surveyed High Perches aerie. Its sign now billboards, and it is raised above the 3.2 m poles so no pole cuts through it.
6. Landing with low stamina: the stamina arc is shown.
7. After the landing: the arc is gone because stamina is full.

**Before sheet:** `_sheet_activity_payoffs_before_placement_fix.png` is the first version. The thanks was an unreadable small potion model, partly hidden behind the trainer, and the aerie's landing sign read mirrored. Inspecting those frames led to the placement and model change.

Disclosed fixture:
- A five-creature party is seeded, and `fly_traversal_unlocked` is set.
- The trainer's stamina is set to 12 before the landing.
- The frames are converted to JPEG outside the tool.
- The chain's step flags and the survey are seeded, the trainer is stood at each viewpoint, and the landing is the Fly `landed` signal emitted on the ring. The claim is the real interact press. The tool renders only the saved frames, at `--fixed-fps 60`.

### Open under F07

- **Bells map reveal.** The three known landing points are held for an interpretation. The third landing point, the Waterward roost, maps to the `waterward_overlook` landmark. That landmark is deliberately withheld until the finale (`stormward_route_revealed`: "future realm direction appear after the finale").
- **Aeries map knowledge.** Not added.
- **Couriers' acknowledgement.** Still needs a backtrack to Galefoot.
- **Circuit.** TM choice and rematch.
- **Unbuilt activities.** Waycamp shelter and Observatory latch.
- **Cadence.** The 885-second no-action stretch and the A7 intervals.
- **Ledger.** The route resource/XP ledger.
## WO-M · F08 / C2: the Cloudreach frame matrix and blind judgment

**Tool:** `tools/capture_cloudreach_frame_matrix.gd`. It uses the production `CameraRig` following the real trainer, aimed only through its public yaw/pitch. Stands come from route data and are held until a floor collider exists. The HUD is hidden.

**Disclosed fixture:** flags are seeded per row (Act I/II, pre-finale, post-finale), the clock is pinned for day and night, and the trainer is teleported to each stand. The fight itself is not played.

**Output:** `captures/frame_matrix/`, 36 frames (JPEG), `manifest.txt`, five group sheets, and the 30 s motion sheet `_sheet_frame_matrix_motion.jpg` (60 frames). Rendered on main 835744b3 plus the tool; one stand fell back to its second candidate.

**Blind judge.** A sub-agent that saw only the frames, the two Cloudreach boards, the Meadows key art and the Palworld references.
- **A: does it belong to the key-art / Cloudreach-board world? No.**
  - Sky, sunlit greens and the gate arch match the Meadows mood.
  - Cloudreach's own identity is missing: the pale limestone / slate-blue / gold palette, verticality, waterfalls, a soft cloud sea and aviary architecture.
- **B: beside Palworld, the same kind of game? Yes, at a clearly lower tier.** It is let down by density, the rock material mix, camera failures and creature texture quality.

**The five biggest gaps, as the judge ranked them:**
1. It doesn't read as a sky-cliff region. It is a green grass ridge, and the cloud sea shows as faceted ice slabs (01, 09, 12, 30).
2. Landmarks fail:
   - the stronghold is invisible at 400 m (33) and a "greenhouse on farmland" at 100 m (34);
   - the shrine is a grey monolith (15) and the perches are silos (19, 20);
   - nothing visibly changes after the finale (35 vs 34, 36 vs 05).
3. The ground reads as generated:
   - mown lawn fills half the frame;
   - grass sits in rectangular strips;
   - trees are evenly spaced single lollipops, with a tuft row in 33;
   - path edges are dithered;
   - untextured pale rocks sit beside textured ones.
4. Staging and camera break frames:
   - the camera sits in geometry (16, 18);
   - creatures overlap (06, 21, 32, 33);
   - the night route is black (31; mean luma 10.5/255).
5. Creature texture and a world that doesn't feel lived-in: griffin speckle, Stormcapra reads as clay, Pebbik's face is smeared, and settlements are nearly empty.

**Scene-fixable work orders (proposed; each ends with a matrix re-render and a re-judge):**

| # | Work order | Frames | Owner scope |
|---|---|---|---|
| M1 | Placement bugs: floating logs and neon plant through the trainer (24), floating banner (20), magenta object (13), courtyard seam (29) | 13, 20, 24, 29 | lane |
| M2 | **Oxblood rule:** crimson shrubs beside the friendly observatory (24); check the red boxes in the camp (34/35) | 24, 34 | lane |
| M3 | Use one rock material: textured mossy rock on every pale untextured boulder and cliff mesh | 01, 08, 12, 15, 17, 26, 27 | lane |
| M4 | Night fill: moon and ambient light on slopes facing away from the moon; the ram ignores night lighting | 30, 31, 32 | lane (atmosphere) |
| M5 | Soft cloud sea: layered cloud cards plus height fog in place of faceted slabs; remove cloud meshes sitting on the ground | 01, 09, 12, 23, 26, 30 | lane |
| M6 | Scatter authoring: tree groves with scale variety; no evenly spaced singles, tuft rows or neon plants; varied grass value; no hard-edged patches | 02, 03, 07, 08, 12, 13, 14, 17, 22, 33 | lane |
| M7 | Stronghold as landmark: a sightline from the route at 400 m, no surrounding wheat field, and the lighter gate stone, gold dome ribs and blue banners already in the build | 29, 33, 34 | lane |
| M8 | Visible homecoming: after the finale, banners go up, NPCs gather and Tether camp props go away | 35, 36 | lane |
| M9 | Settlements: dress with installed props (cart, bells, banners, lanterns, rope lines, fences) and more NPCs; put Cliffhold on a cliff edge | 05, 25 | lane |
| M10 | Capture tool: the empty "beacon" detail (14) and camera-in-geometry stands (16, 18, 10, 20); check whether the trainer's idle animation runs in held stands (A-pose in every frame) | 10, 14, 16, 18, 20 | lane (tool) |
| M12 | **The camera goes inside scenery.** The 30 s walk (`_sheet_frame_matrix_motion.jpg`, 60 frames at 0.5 s, stick input) goes through the lower-cliffs gate arch. The camera then passes through the gate's timber beam (m37–m41), a wild creature fills the frame (m42–m44), and for about 15 frames the camera sits inside a dark rock mass beside the road (m45–m56). These visual rock masses have no collider, so the spring arm doesn't stop. The gate-seal review found the same kind of non-colliding rock spurs. Fix: give the visual rock masses along walkable routes a camera-blocking collider on a layer that doesn't block the trainer, or keep them out of the arm's reach. Either needs the spring arm's mask to include that layer, which is shared camera code. | m37–m56 | lane (collider layer) + **shared** (rig mask) |
| M11 | Camera pull-in / occluder fade and companion separation, so creatures don't overlap and the griffin doesn't clip through bridge rails | 03, 06, 09, 21, 32, 33 | **shared** (camera, follower): needs a grant |

**Needs art not in the build (owner/art-lane evidence):**
- the aviary stronghold to the board;
- waterfalls;
- a vertical limestone cliff kit;
- Sky Shrine and perch models;
- broken stone causeway pieces;
- Cloudreach foliage;
- cliff-village architecture;
- creature re-texture: the griffin's speckle, Stormcapra's plates, crystal and face, and Pebbik's face;
- a trainer idle pose, if none exists.
