Result: MET

# Strict re-check: F01#3, "Normal-controller NIGHT walk reaches every opening NPC, camp and gate"

Re-checker: independent and read-only. It wrote only this file and ran `git fetch`. Branch tb/meadows, HEAD 174f0636c. Phase 1 rule: close on function and readability. Bars A/B go to the Phase 2 catalog. The CLAUDE_START_HERE §4 Meadows row 2 fix ("make the key read in the world") is checked specifically in (b).

## Input path (reused from RECHECK_F01_2.md, the same harness)

The night run is the same `tests/capture_village_walk.gd --route=visits --from-title` harness that RECHECK_F01_2.md audited. That file is unchanged since d41ff2f0 (see d). Every input is a parsed joypad event: movement, look, interact and recall. The opening is played from the title screen, and no position, yaw or flag is written on the `--from-title` path. `road_gate_open` is earned by the interact press.

The disclosed walking aids carry over unchanged:
- an autopilot route planner that steers with the look stick;
- automatic door and gate presses when a walk stalls, plus sidesteps;
- photo-mode captures;
- a frozen clock and clear weather;
- the opening stops at the doorway and the companion is put away with `creature_recall`;
- `_frame_for_photo` orbits the camera with the stick;
- the camp, TrailGate and PondGate count as reached by proximity alone, with no prompt.

The only differences at night are `--time=night`, with the clock frozen at 23:00 (every frame shows "Day 1 · 23:00" and a moon), and the route itself. This run needed no sidesteps or stall recovery. The log has no stall, sidestep, wild or fight lines, and START reports `events=0`. Its only aids were two door presses, "Open Door" on the Bram and Mira legs.

## (a) The log shows all 11 targets reached at night, with PASS. Yes.

Source: `night_d41ff2f0/run_village_walk_lines.txt`.
- START line: `route=visits time=night`. The VISITS list names all 11 targets.
- VISIT lines:
  - Grandpa 1.10 m "Talk to Grandpa"
  - Bram 1.68 m "Greet Bram"
  - Tam 1.27 m
  - Mira 2.06 m
  - Oskar 1.22 m
  - Halda 1.25 m
  - the old key 1.32 m "Take the old key" (NOTE: `satchel has key=true`)
  - RoadGate 0.48 m "Try the gate" (NOTE: `road_gate_open=true`)
  - Practice Meadow camp 2.79 m
  - TrailGate 0.11 m
  - PondGate 0.40 m
- Final line: `PASS route=visits time=night captures=81 max_off_road_m=0.00 visited=11`.
- CI corroboration (GitHub API): run 36439735704 is "render mw-f01-night-d41ff2f0 @ d41ff2f07be365c1…", a workflow_dispatch of render.yml. It completed with conclusion `success`. Limitation: the committed .txt holds the harness lines only, not the raw job log, and I did not download the artifact to byte-compare the frames.
- Target completeness is unchanged from RECHECK_F01_2 (b): five village_npcs within the village radius plus Grandpa, and exactly three gates in village_boundary.json. Neither file is in the diff in (d).

## (b) The key reads in the world at night, as an object and not only through its prompt. Yes.

I viewed the frames myself.
- `night_d41ff2f0/visits_night_048_end.jpg`: a large gold key hangs on a dark post to the right of the "The Rise" arch, at about chest height, above the grass. It has a clearly key-shaped ring, shaft and teeth. Warm glow halos sit around the base area, and the key reads unambiguously as a key apart from the "Take the old key" prompt. This is the mid-range read that the fix was for.
- `visits_night_049_take-the-old-key.jpg`: side-on at close range. The key is a small yellow shape hanging on the post beside a warm glow. It is still visible, but small. The code-blind judge makes the same observation (#6).
- `visits_night_050_reached-the-old-key.jpg`: the post stands bare, and the prompt has reverted to "Call out Bud". The log says `satchel has key=true`, so the take is shown in the world.

What makes the key visible, verified in data and scripts:
- `data/config/key_post.json`:
  - `enabled: true`, `post_height_m 1.45`, `peg_height_m 1.3`, `key_scale 2.0`, `facing_yaw_deg -90` (facing the village approach);
  - its `_why` cites the earlier finding that the key "read only by its UI prompt".
- `scripts/world/playground_world.gd`:
  - `_build_gate_key_post()` builds the post, and it stays after the key is taken;
  - `_spawn_gate_key()` calls `setup(..., "post")` when the post is enabled (around line 1866).
- `scripts/world/key_pickup.gd`:
  - `_hang_on_post()` hangs the key ring-up on the peg at 2x scale and returns the glow height on the key;
  - the key material has `emission_enabled = true` with the item colour (multiplier 0.8/1.1, lines 175-177 and 229-231);
  - `PICKUP_GLOW.attach(self, _item_colour(), glow_height)` (line 88) adds the shared pickup halo;
  - `_deactivate()` hides the key and detaches the glow.
- `data/config/pickup_glow.json` has `enabled: true`.

History of the "key by prompt only" finding:
- It was the verdict in `code_blind_judge_verdict.md`, which covers the night_7fe6e703 set: "no key object is rendered".
- Commit f5b4dc36c, "the old key hangs on a post by the road", is not an ancestor of 7fe6e703. It is an ancestor of 122a8efb and of d41ff2f0.
- The 122a8efb judge (`code_blind_judge_verdict_122a8efb.md`) already called the night key "clearly visible and glowing on the post". The d41ff2f0 night judge agrees (key row: YES).

## (c) The camp and three gates read at night. Yes.

I viewed the frames myself.
- **RoadGate "The Rise"**:
  - `visits_night_053_at-gate-roadgate_-closed.jpg` shows a timber arch with a legible "The Rise" sign, two lit lanterns, a closed rail leaf, a signpost at the left and the prompt "Try the gate".
  - `visits_night_054_reached-gate-roadgate.jpg` shows the X-braced leaf swung open and Grandpa Elias saying "There you go. The old key still turns."
- **TrailGate**: `visits_night_067_reached-gate-trailgate.jpg` shows an arch with a large "South Bridge" sign, a matching "South Bridge" fingerpost and a lantern. The leaf is open at the left and the trainer stands in the gateway.
- **PondGate**: `visits_night_081_reached-gate-pondgate.jpg` shows an arch with a "The Pond" sign and a lantern. The leaf is open, a "…ond" fingerpost is at the left edge, and the trainer is on the path under the arch.
- **Practice Meadow camp**:
  - `visits_night_056_travel.jpg` (approach) is a clear camp read: a wooden cart, a pitched canvas tent, a campfire burning in a ring, a bedroll/log and a barrel. The objective beacon column stands to the right, and wild creatures (a moss-backed deer-like creature and rabbits) stand around it.
  - `visits_night_057_end.jpg` and `visits_night_058_reached-practice-meadow-camp.jpg` (arrival): the tent, a dark bedroll and the cart are directly behind the trainer, and the lit fire's flame tips show at the lower right. It still reads as a camp.
  - This is the fix for the 122a8efb FAIL, where the camp was only a supply cluster.

Readability notes that do not block the criterion (Phase 2 catalog, Bars A/B):
- In 057/058 the hotbar panel covers most of the campfire, and the arrival camera faces away from the fire. 056 is the best camp shot.
- A wild boar crowds the right edge of the camp arrival frames. A creature and the beacon column crowd 056.
- The camp has no prompt or name label (`prompt="-"`). This walk proves the camp can be reached and recognised, not that it can be used.
- At close range (049) the key is small and competes with the post's glow.
- The gate arch lintels and piers render near-black at night. The signs and lanterns carry the read.
- The villagers take a strong blue/magenta cast, and Grandpa's room has pure-black furniture silhouettes (judge #4/#5).

## (d) Nothing changed since d41ff2f0 that alters the walk. Confirmed.

`git diff --stat d41ff2f0 HEAD -- data scripts tests/capture_village_walk.gd` lists 45 files (+999/−129). `tests/capture_village_walk.gd` is not among them, so the harness is byte-identical. None of these files is in the diff:
- key_post.json, key_pickup.gd, pickup_glow.json;
- playground_world.gd, village_boundary.json, village_npcs.json;
- band1 props.json, objective_beacon/objectives.json, dialogue/village.json.

The files named in the brief, and the other HUD/input-path changes:
- **`scripts/player/conversation_camera.gd` (+15)**: adds a `max_speaker_distance_m` cap in `solve()`. It reads `cfg.get("max_speaker_distance_m", INF)`, and the branch runs only when the value is less than INF.
  - `grep -rn max_speaker_distance_m data scripts` finds the key only in the `profiles.aftermath` entry of `data/config/camera.json` (line 35). It is not in the base conversation config that `profile_config("")` returns for a villager greeting.
  - The only caller that asks for `"aftermath"` is `encounter_director.gd::_present_trainer_victory` (`push_in.call("begin", speaker, "aftermath")`, around line 5940), which runs after a trainer fight.
  - The walk had no fights. The villager greeting push-ins therefore take the unchanged path.
- **`scripts/ui/combat_hud.gd`**: `_windup_text()` changes only the wind-up telegraph wording inside `_draw_enemy()`, which draws in combat. The walk had no combat.
- **`scripts/combat/encounter_director.gd`**:
  - `_player_is_flying()` blocks `party_cycle`/`creature_recall` only while `fly_controller.is_flying()` is true. The walk's companion put-away presses `creature_recall` on foot, so the block does not apply.
  - The ally keeping its place applies only during trainer-victory lines.
- **`scripts/ui/playground_hud.gd` / `hud.json`**: the vitals refresh is behind `party_vitals_refresh_candidate`, which is `false`. It is presentation-only either way.
- **The rest**:
  - combat_manager, ally_occlusion_fade and wild_creature are fight-camera code, opt-in;
  - fly_controller covers flight only;
  - trainer_aftermath is used after a trainer victory;
  - craft_panel is a UI panel that the walk does not open;
  - band3-5 trainers and water/stormwood/stormheart files belong to other regions;
  - species.json and moves.json do not change the walk's starter path, which uses Terrapup.

None of these changes the village, NPC greetings, key, camp, gates or night lighting.

## (e) The key, camp and gate content is in origin/main. Yes.

- `git merge-base --is-ancestor d41ff2f0 origin/main` is true. origin/main is 13800d035 (PR #423, 2026-09-28 16:52Z).
- The key-post commit f5b4dc36c is also an ancestor of origin/main.
- `git diff origin/main HEAD` over key_post.json, key_pickup.gd, pickup_glow.json, village_boundary.json, band1 props.json and playground_world.gd is empty.
- HEAD differs from origin/main in data/scripts only by the aftermath camera cap, the combat tell text and trainer_aftermath/combat tweaks (7 files), all covered in (d).

## Summary

- The night walk from the title screen reached all 11 targets using the controller-event input path, and ended with PASS.
- At night the key reads as a gold object hung on a post at chest height (frame 048), and the bare post in 050 shows it was taken. The prompt is no longer the only cue.
- The camp (056-058) and the three gates (053/054, 067, 081) read at night.
- The code-blind judge (`code_blind_judge_verdict_night_d41ff2f0.md`, PASS) agrees.
- Nothing merged after d41ff2f0 alters the walk, and all the content is on main.
