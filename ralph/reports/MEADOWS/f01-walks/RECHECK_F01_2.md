Result: MET

# Strict re-check: F01#2, "Normal-controller DAY walk reaches every opening NPC, camp and gate"

Re-checker: independent and read-only (it wrote only this file). Branch tb/meadows, HEAD df595482. Phase 1 rule: close on function and readability. Bars A/B go to the Phase 2 catalog.

## (a) Is the input a normal controller? Yes, with disclosed walking aids.

- Every movement, look, interact and recall input is a parsed joypad event. `_pad_event`/`_pad_press` (tests/capture_village_walk.gd:642-675) build an `InputEventJoypadButton`/`InputEventJoypadMotion` from the action's own InputMap pad binding. They send it with `Input.parse_input_event`, not `Input.action_press`. An action with no pad binding fails the walk.
- The walk moves only with `move_forward`, and it steers the camera only with `look_left`/`look_right` stick strength (`_walk`, lines 697-845).
- There is no teleport on this path. The only `_player.global_position =` / `_rig.set("yaw")` writes (lines 311-315) sit in the `if not _from_title` branch. This run used `--from-title` (log line "OPENING played ... at (-16.06, 1.20, -15.94)", and START follows with no placement).
- The opening helper tests/helpers/gate_a_opening_drive.gd also sends only `Input.parse_input_event` (lines 1240/1259/1295). It writes no position, flag or yaw.
- No flags are set. `road_gate_open` is earned by the interact press (log: `pressed interact on "Try the gate" at gate RoadGate; road_gate_open=true`). The script also checks at the end that it was earned (lines 941-945).

Walking aids and shortcuts, disclosed:
1. **An autopilot plans the route.** The script computes the shortest path over the authored road polylines to each target and chooses the visit order, nearest first. It steers with the look stick toward a 2.5 m lookahead point. Inputs are controller-shaped, but a bot decides where to go.
2. **Stall recovery.** When stalled, the script presses interact automatically if an "Open …"/"Try the gate" prompt wins, up to 3 per leg. Otherwise it makes up to 3 sidesteps (a 50° look turn plus 48 frames forward). This run used two door presses and three sidesteps (log: Mira leg sidestep 1; camp leg sidesteps 1-2).
3. **Photo mode.** The 3D view is disabled while walking and switched on for 6 frames at each capture (`_capture`). Physics and input are unchanged.
4. **Scenario controls.** The clock is frozen at day (`apply_time`) and the weather is set to clear.
5. **Opening cut short and companion put away.** The opening stops at the doorway, before the tutorial catch (`stop_after_doorway`), so the walk runs before the first catch (the HUD objective is "Catch your first wild creature"). The companion is put away with the `creature_recall` pad button so it does not block frames.
6. **Photo framing.** Before each "reached" capture, `_frame_for_photo` orbits the camera with the look stick to find a clear angle.
7. **Some arrivals are proximity-only.** The camp (3.10 m from CAMP_AT, limit 7 m) and the TrailGate/PondGate (0.17 m / 0.11 m, limit 3 m) have no prompt (`prompt="-"`). Both gates were already open after the RoadGate key, so the walk reached them but never operated them. Villagers count only when their own prompt wins the arbiter. The key requires the prompt plus a take. The RoadGate requires "Try the gate" plus an open.

None of these aids replaces player input with state writes. The criterion says "normal controller", and the input path meets it.

## (b) Does the log show every target reached, with PASS? Yes.

Source: ralph/reports/MEADOWS/f01-walks/day_d41ff2f0/run_village_walk_lines.txt (118 lines).

- `VISITS Grandpa, Mira, Oskar, Tam, Bram, Halda, the old key, Practice Meadow camp, gate RoadGate, gate PondGate, gate TrailGate`
- VISIT lines:
  - Grandpa 1.21 m "Talk to Grandpa"
  - Bram 1.92 m "Greet Bram"
  - Tam 1.33 m
  - Mira 2.20 m
  - Oskar 1.26 m
  - Halda 1.47 m
  - old key 1.29 m "Take the old key" (satchel key=true)
  - RoadGate 0.50 m "Try the gate" (road_gate_open=true)
  - camp 3.10 m
  - TrailGate 0.17 m
  - PondGate 0.11 m
- Final line: `PASS route=visits time=day captures=85 max_off_road_m=0.00 visited=11`. There were no wild fights.
- The visit list is complete against the data:
  - data/config/village_npcs.json has exactly five villagers within the harness's 70 m village radius: Mira, Oskar, Tam, Bram, Halda. Kell, the next nearest, is 185 m away on the bands.
  - Grandpa is added from the scene.
  - data/config/village_boundary.json has exactly three gates: RoadGate, PondGate, TrailGate.
- CI corroboration, via the GitHub API:
  - Run 36439730921 is titled "render mw-f01-day-d41ff2f0 @ d41ff2f07be3…". It is a workflow_dispatch of render.yml and concluded success.
  - The "Run" step took 14:58 to 16:14. The "Fail if the script failed" step passed, which means exit 0. The harness exits 0 only on the PASS path (line 332).
  - Artifact `render-mw-f01-day-d41ff2f0-36439730921` (ID 10982147898) was uploaded.
  - Limitation: the committed .txt holds only the harness lines, not the raw job log. I did not download the 139 MB artifact to byte-compare the frames.

## (c) Are the frames readable? Yes. I viewed them myself.

- **Key**
  - `visits_day_049_end.jpg`: a large gold, glowing key hangs on a post beside the Rise arch, with the prompt "Take the old key". It is unmistakable. The trainer hides part of the "The Rise" label.
  - `visits_day_050_take-the-old-key.jpg`: side view. The key is smaller but still reads as gold and glowing, and the prompt is up.
  - `visits_day_051_reached-the-old-key.jpg`: the post is empty and the prompt is back to "Call out Bud", so the key was taken.
- **RoadGate "The Rise"**
  - `…054_at-gate-roadgate_-closed.jpg`: a timber arch with a large "The Rise" sign and a signpost. A closed rail leaf fills the opening, and the prompt reads "Try the gate".
  - `…055_reached-gate-roadgate.jpg`: the X-braced leaf has swung open, and Grandpa Elias says "There you go. The old key still turns."
- **TrailGate**
  - `…071_reached-gate-trailgate.jpg`: an arch with a large "South Bridge" sign plus a signpost. The leaf is open on the left, and the trainer stands in the opening.
- **PondGate**
  - `…085_reached-gate-pondgate.jpg`: an arch with a "The Pond" sign. The X-braced leaf is open on the left, and the trainer stands under the arch.
  - The side-on angle is tighter than the TrailGate shot, but the gate is clear.
- **Camp, 056-061**
  - 056: a tent and cart are visible to the right from the village street.
  - 057/058/059: an unobstructed approach showing the cart, pitched tent, fire in a stone ring, log and a bedroll edge.
  - 060: a close view of the fire ring, log, barrel, crate and sack. The cot and bedroll sit at the lower left, partly under the HUD vitals.
  - 061 (arrival): tent, cot with blanket and pillow, fire in a stone ring, log seat, sack, wicker crate and cart against the house. It reads as a lived-in camp.
  - This fixes the b9ad225e FAIL, which had no fire, bed or seat, a distant cache-like cluster, and a foreground creature plus a beacon slab blocking the arrival frame.

The code-blind verdict ralph/reports/MEADOWS/f01-walks/code_blind_judge_verdict_day_d41ff2f0.md (PASS, 11/11) agrees with what I saw.

Readability notes that do not block the criterion (Phase 2 catalog, Bars A/B):
- The fire is a flat two-tone orange cone.
- In 061 the trainer's feet are on the log and the figure overlaps the flame.
- The camp has no name label or prompt.
- Two boars, rabbits and the blue objective beacon crowd the first camp (057-061).
- The open TrailGate/PondGate show no gate prompt.
- The "end" frames often hide the NPC behind the trainer. The "reached" frames fix this.

## (d) Do changes since d41ff2f0 affect the walk? No.

`git diff --stat d41ff2f0 HEAD -- data scripts tests/capture_village_walk.gd` lists 39 files. tests/capture_village_walk.gd is not among them, so the harness is byte-identical. Nothing touches band1, the village, village_npcs, village_boundary, terrain_playground, objectives/objective_beacon, map_landmarks or scenes. The changes by file:

- band3/4/5 trainers.json and water_*, stormwood_*, stormheart_*, craft_*, fly_traversal: other regions or systems.
- combat.json, combat_manager.gd, ally_occlusion_fade.gd and wild_creature.gd: fight-camera head/tell swing. `head_swing` is false by default and applies only to opted-in opponents. These run only in a fight, and the walk had no fights.
- encounter_director.gd:
  - blocks party_cycle/creature_recall only while flying;
  - holds the ally's place during a trainer-victory speech;
  - neither applies here.
- hud.json/playground_hud.gd: `party_vitals_refresh_candidate` defaults to false.
- species.json: Ripplet/Galewisp stats. The walk's starter is Terrapup.
- candy_pickup_presentation: `enabled:false`, and it serves Stormwood/Tidewake adapters.

None of these can change the village, camp, key, gates or beacon.

## (e) Does d41ff2f0 count as "current main"? Yes, in substance.

- `git merge-base --is-ancestor d41ff2f0 origin/main`: it is an ancestor of origin/main 1e0ddd39 (PR #421, 2026-09-28 15:59Z).
- `git diff origin/main HEAD -- data/config/bands/band1_lower_meadows/props.json data/config/objective_beacon.json` is empty, so the camp dressing and beacon stand-down are in main.
- HEAD differs from origin/main only by the evidence commits, one test harness (`capture_named_fight`/`smoke_stronghold_battle_camera`) and two `.uid` files.
- The render SHA is not the literal main tip. It is on main, and nothing relevant to the walk changed between it and the tip (see d), so it represents current main's walk.

## Open observations (not blocking)

- **The camp leg stalled twice on an unseen body.** It sidestepped twice at (27.8, -22.0) with `bodies near: Spawned/Trainers/Trainer_1` (within 2.5 m). No trainer is visible in 058/059 or at the camp in 060/061. The same body name also blocked the Mira leg at (15.6, 4.2), so the trainer is a roaming body. It is off-camera or occluded by the tent/cart. It could also be an invisible collider. A player standing there would bump into something they cannot see. This is worth a look in Phase 2 or a follow-up, but the walk completed.
- **One out-of-scope command.** I ran `git fetch -q origin main` to compare against current main. It updated the remote-tracking ref only. No working-tree or branch changes were made.
