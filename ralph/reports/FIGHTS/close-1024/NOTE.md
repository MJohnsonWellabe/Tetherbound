# Fights lane close-1024 (tb/fights)

## TO COORDINATOR
- 2026-10-25 04:15 CT INFO r6 (your four asks), code-blind CPU batch, 3 fresh judges, mapped (confirming, slope 0.81, r 0.78, RMSE 0.74; files r6_*):
  - Shipped generic look before -> r6 after: Venn 5.92 -> **6.56**, Warden 6.19 -> **6.81**, Riverwatch 6.43 -> **7.05**, Stormwood 6.27 -> 6.38, Veyra 6.46 -> 6.54. Every fight holds or improves and all are above the 5.2 floor.
  - **The big gain is a bug fix, ef4591a18.** P2-062's follower fade (`camera.occlusion_fade.follow_candidate`, ON since 22 Oct) dithers the follower body at 0.85 while it covers the trainer from the camera. In a fight the follower *is* the piloted creature and the trainer stands behind it, so the pilot was a ghost for whole fights. This is the "Ripplet translucent" ask; in the Warden hall the pilot was effectively invisible. The cover test now runs only while following, as its `_why` scopes it, with a new unit test.
    - Judges, 3/3: the player's creature PRESENT -> FIXED at Venn and Riverwatch; at Warden PRESENT -> FIXED or PARTIAL.
  - The rest of r6 (all OFF until this READY):
    1. Dust fill rows plus a timing pulse inside the danger footprint.
    2. Right panels at 0.8.
    3. A fixed meter row in the compact lane: the HUD height jump was real, since the returning grid pushed the title and meter up.
    4. A pilot size floor of 0.10 in every fight. It used to apply only in Stormwood sight-line fights, so the Riverwatch per-trainer 0.10 had been inert.
    - Judges still mark the wind-up "where" PARTIAL or PRESENT everywhere.
  - I turn r6 ON with the r7 READY (your G3 items), which is capturing now on the trainer fights (south_bridge_grunt, warden_aldis, capture_f38_fight.gd). The r7 overlay builds on r6, so r6 stays an overlay until then.
- 2026-10-25 02:25 CT INFO smoke_net_shared_boss vs the fights batch (read from the code; I have not run it):
  - **No new colliders or host positions.** `impact.ground_burst` (enemy_pattern_telegraph.gd contact_burst) adds only a Node3D with MeshInstance3D quads and an OmniLight3D. pilot_mark.all_fights enables combat_arena `_process`, which only moves the pilot light and sets the rim. `sight_fade_active()` still requires a real sight fade, so `_fight_world_sight_targets()` (camera caps, the pilot floor) is unchanged outside Stormwood. `fallback_max_steps` only chooses among fight-camera poses. `compact_when_idle` is UI.
  - **The one input-relevant change is `camera.tracking.composition_yaw_deg` 35 -> 50** (and pitch_start -25 -> -15). The occlusion_fade comment in combat.json says the tracker's composition "moves the camera basis that camera-relative movement reads". Any client or pilot steering by stick input instead of exact placement now maps about 15 deg differently, and the fight lens sits higher. If the smoke's guest creature moves by input after `place_creature` (settle, a pilot approach, hold_inside), that is the prime suspect.
  - Quick bisect: rerun it with combat.json `"composition_yaw_deg": 35.0` and `"pitch_start_deg": -25.0` and the rest of the batch unchanged. If it passes, the fix belongs in the smoke's staging (re-read positions or retry the move after the settle), or I revert composition_yaw for the generic batch (it was part of the judged look). Your call; I can push either.
- 2026-10-25 02:00 CT INFO cherry-picked your 590973c77 (band_split_baseline mirror of the Brooktail power edit) into tb/fights as d6d41836e. My miss: future band balance edits mirror the baseline fixture in the same commit. r6 (your four asks) is capturing now.
- 2026-10-25 02:05 CT READY tb/fights-land 282901fd5 (origin/main f7b9b6a1e + tb/fights 4c330f4d6): your review follow-up on dcb3463d4. Comments, scopes and one accessibility path; what the GPU judges is unchanged with the defaults.
  1. Scopes: `_scope_outline_off`, `_scope_ground_burst` (combat.json), `_scope_compact_when_idle` (tether_commands.json), `_scope_all_fights` and `_scope_ring_enabled` (foliage_camera_visibility.json pilot_mark), `_scope_fallback_max_steps` (camera.json). Each reads: "Client-local presentation only: read by each peer's renderer/HUD; no host authority, save, transaction, network message or gameplay state. Absent = previous behaviour." Same sibling `_scope_<key>` convention as the F22#4 cue keys.
  2. Stale notes now say ON since 25 Oct: `_why_outline_off`, `_why_compact_when_idle`, `_why_fallback_max_steps`, combat_arena.gd (pilot_mark.all_fights), tether_command_meter.gd, cloudreach_summit_presentation.gd.
  3. The one gameplay number in this lane's landing: band3_the_river_lock/trainers.json captain_riverwatch Brooktail combat power 27.5 -> 27.0 (`_why_power_f22_4`). Oreth Flood measured C3 0.501 against the 0.5 ceiling for Terrapup and Galewisp. The Riverwatch 24-seed rerun on it is queued; the result goes in the F22#4 INFO.
  4. Optional, done: with `telegraph.high_contrast_markers` true, Veyra's lanes take `high_contrast_lanes` (fill 0.21, rim 0.85, streaks 0): the filled, rimmed look judged on 24 Oct. Default OFF, so it has no effect on the judged look. Parse check only; there is no test of the ON path.
  - Checks on tb/fights 4c330f4d6: 117 tests, 9055 assertions, 0 failed (combat_system_overlay_layout, f24_host_commands, cloudreach_summit_paving, combat_arena_bystanders/hold_inside, fight_camera, combat_vfx, combat_camera_clear_orbit, combat_spaced_camera, cloudreach_continuous_harness, cloudreach_director_client_veyra, stormwood_pilot_reach, telegraph_glow, enemy_pattern_telegraph). Godot check-only on cloudreach_summit_presentation.gd: clean.
  - Process note: during the dcb3463d4 test run the paused process was the timeout wrapper, so the water C2 smoke ran alongside the tests for about ten minutes. Both finished. This run paused the Godot process itself.
- 2026-10-25 01:25 CT READY tb/fights-land dcb3463d4 (origin/main f7b9b6a1e + tb/fights 53eccce4b, clean merge, no overlap with main's changes): **generic fight presentation ON** (owner 24 Oct: no outlined attack areas). One READY for the Veyra, Meadows grunt/Warden, F10#2 Stormwood, F22#4 Riverwatch and Venn fights.
  - What is ON (every key has `_why_fight_presentation_1025`; the overlay that was judged is `cand_gen_h.py.txt`):
    - combat.json telegraph.soft_style: `outline_off` true, so no painted ring, cone, lane or slab. The tell is kicked dust along the same footprint (alpha 0.9, spacing 0.45 m), a low light curtain and the attacker's element-coloured rim glow (`tell_aura_element`, 0.45). Accessibility: `telegraph.high_contrast_markers` brings the outlines back; default OFF.
    - Impacts: contact disc radius 0.9/1.2 -> 0.55/0.75, and `impact.ground_burst` (dust and stones at the struck creature's feet, P2-063).
    - Fight lens: pitch_start -25 -> -15 deg (horizon in frame), composition_yaw 35 -> 50 deg (ally off the opponent's line). camera.json `fallback_max_steps` 2 stops the Venn seabed pop (the frames.json max camera-to-fighters distance drops from 40.4 m to 24.3 m; the remaining worst case is a 3 s orbit to the sea side at 21 m). Riverwatch pilot floor 0.10.
    - Slim HUD: tether_commands `ui.compact_when_idle` true (the command grid hides while nothing is usable).
    - Veyra: wind lanes ON with fill 0 and rim 0, replaced by moving wind streaks (0.8): no slabs.
    - Pilot: `pilot_mark.all_fights` true (rim and fill light on the player's creature in every fight), `ring_enabled` false.
    - Timings, footprints, the AI's telegraph and gameplay are unchanged.
  - Scores (code-blind, CPU llvmpipe, 3 fresh judges per batch, mapped; both batches confirming):

    | fight | before (main) | after | outlines | impact disc | tell where/when |
    |---|---|---|---|---|---|
    | Meadows grunt/Warden hall (r4) | 4.85 | **5.88** | PRESENT -> FIXED 3/3 | PRESENT -> FIXED 3/3 | PARTIAL (1 judge PRESENT) |
    | Riverwatch (r4) | 5.64 | **6.99** | PRESENT -> FIXED 3/3 | FIXED | PARTIAL |
    | Veyra (r5) | 5.60 | **6.21** | FIXED 2/3, PARTIAL 1; slabs PRESENT -> PARTIAL | FIXED 3/3 | PRESENT (text banner only) |
    | Stormwood glass_field (r5) | 5.71 | **6.13** | FIXED 2/3, PARTIAL 1 | FIXED 3/3 | PARTIAL/PRESENT |
    | Venn (r5) | 5.38 | **6.07** | FIXED 3/3; camera jump PRESENT -> FIXED 3/3 | FIXED 3/3 | PRESENT |

    - r4: slope 1.23, r 0.95, RMSE 0.42. r5: slope 0.83, r 0.77, RMSE 0.52. No warnings; none above the top anchor.
    - Before/after sheet: `_sheet_r5.png` (all five fights; left before, right after).
    - None reaches 7.5, so the GPU decides. Earlier GPU Medium for Riverwatch was 7.26 (after #727), measured before this fix.
  - Judges' common next asks (not in this READY):
    1. A denser dust or spray wall that fills the danger area, with a timing pulse. The dust alone reads as a real object but is diffuse.
    2. The HUD right panels are still large.
    3. The player's creature is small on dark moss and translucent on Tidewake sand (Ripplet).
    4. Flat arena and beach ground.
  - GPU capture commands (repo root, at dcb3463d4, Medium/High; `godot --headless --path . --import` first):
    - Warden: `godot --path . --script res://tools/art_pipeline/capture_named_fight.gd -- --trainer=warden_aldis --ally=ripplet --frames=12 --interval=0.5 --tell-frames --out=res://shots/gpu/warden`
    - Riverwatch: same script with `--trainer=captain_riverwatch --live-member=captain_riverwatch:4 --ally=ripplet --frames=12 --interval=0.5 --tell-frames --out=res://shots/gpu/riverwatch`
    - Stormwood (F10#2): `godot --path . --fixed-fps 20 --script res://tools/capture_named_fights_f10_6.gd -- --ids=glass_field_alpha --seconds=14 --interval=2.0 --camera-view=north --fixture-seed=1042206 --out=res://shots/gpu/stormwood`
    - Veyra: `godot --path . --script res://tools/phase2_capture_cloudreach_live_fight.gd -- --output=res://ralph/reports/VISUAL/phase2/cloudreach/gpu-veyra --seed=7` (the output must sit under that folder).
    - Venn: `godot --path . --script res://tools/phase2_capture_tidewake_fights.gd -- --trainer=water_trainer_venn --seed=2042 --out=res://ralph/reports/VISUAL/phase2/tidewake/gpu-venn`. On CPU it ends "Capture rejected: frame_cap", before and after alike, after writing 40 frames.
    - Frames judged: Warden/Riverwatch t01-mid, t02-mid, 04, 08. Stormwood tell1-b-mid, tell2-b-mid, tell1-e-impact, tell3-c-late. Veyra live-1362/1722/2082/2262. Venn tell-start-000.65, t-006.02, t-012.00, t-024.02.
    - Before = main f7b9b6a1e.
  - Checks on tb/fights 53eccce4b (same combat code and config as the land): 197 tests, 9466 assertions, 0 failed. Suites: tell_aura_overlap, telegraph_glow, charger_lunge, enemy_pattern_telegraph, stormwood_b_named_lunge_lanes/cues, creature_attack_telegraph_animation, shared_opponent_cue_shape, named_tell_text, combat_stagger, combat_feedback, f22_riverwatch_presentation, combat_vfx, body_glow, combat_manager, combat_ai, fight_camera, combat_camera_clear_orbit, combat_spaced_camera, combat_system_overlay_layout, f24_host_commands, f21_hit_presentation, hit_feedback, cloudreach_summit_paving, stormwood_pilot_reach, combat_arena_bystanders/hold_inside, cloudreach_director_client_veyra.
  - Not run: full CI. C2 is not affected (the reader pilots read game state, not pixels).
  - F22#4 C2/C3 per fight (24 seeds, READER vs MASHER, live f22 patterns; pattern id = `named_<case>`; attacks seen across runs):

    | case | pattern | attacks | result (starter) |
    |---|---|---|---|
    | captain_veyra_storm_anchor | named_captain_veyra_storm_anchor | veyra_crosswind, current_zone, diver_retreat, diver_leap | terrapup PASS; ripplet PASS; galewisp PASS |
    | captain_marrow_dynamo_core | named_captain_marrow_dynamo_core | wall_check, wall_quake, diver_leap, diver_retreat, marrow_current_volley, marrow_current_zone, charger_check, charger_rush, marrow_bank_answer | terrapup PASS; ripplet PASS; galewisp PASS |
    | hollows_alpha | named_hollows_alpha | hollows_alpha_charger_rush, hollows_alpha_charger_double_rush | terrapup PASS; ripplet PASS; galewisp PASS |
    | capacitor_alpha | named_capacitor_alpha | capacitor_alpha_charger_rush, capacitor_alpha_diver_leap | terrapup FAIL; ripplet PASS; galewisp PASS |
    | crown_guardian | named_crown_guardian | crown_guardian_wall_check, crown_guardian_wall_slam | terrapup FAIL; ripplet PASS; galewisp PASS |
    | old_rodfolk_hall_guardian | named_old_rodfolk_hall_guardian | old_rodfolk_hall_guardian_ace_lane, old_rodfolk_hall_guardian_ace_exam | terrapup FAIL; ripplet PASS; galewisp PASS |
    | blackwater_elder | named_blackwater_elder | blackwater_elder_current_volley, blackwater_elder_current_zone | terrapup PASS; ripplet PASS; galewisp PASS |
    | glass_field_alpha | named_glass_field_alpha | glass_field_alpha_charger_rush, glass_field_alpha_charger_double_rush | terrapup PASS; ripplet PASS; galewisp PASS |
    | warrens_guardian | named_warrens_guardian | guardian_wall_quick, guardian_earth_fist | terrapup PASS; ripplet PASS; galewisp PASS |
    | relay_officer_dell | named_relay_officer_dell | wall_check, wall_slam, wall_quake, diver_leap, diver_retreat | terrapup PASS; ripplet PASS; galewisp PASS |
    | relay_captain | named_relay_captain | diver_leap, diver_retreat, current_zone, wall_check, wall_quake, wall_slam, charger_rush, charger_double_rush | terrapup PASS; ripplet PASS; galewisp PASS |
    | captain_riverwatch | named_captain_riverwatch | wall_check, wall_slam, charger_check, charger_rush, diver_retreat, diver_leap, oreth_overflow, oreth_flood | terrapup FAIL; ripplet PASS; galewisp FAIL |
    | captain_field | named_captain_field | current_volley, current_zone, halder_range, charger_double_rush, wall_check, wall_quake, wall_slam | terrapup PASS; ripplet PASS; galewisp PASS |
    | captain_ridge | named_captain_ridge | wall_check, wall_quake, current_volley, current_zone, charger_check, charger_rush, wall_slam, diver_retreat, vess_flank | terrapup PASS; ripplet PASS; galewisp PASS |
    | stronghold_elite | named_stronghold_elite | diver_leap, diver_retreat, hald_reset, wall_slam, current_volley, current_zone, wall_quake | terrapup PASS; ripplet PASS; galewisp PASS |
    | warden_aldis | named_warden_aldis | wall_check, wall_quake, diver_retreat, diver_leap, current_volley, current_zone, charger_rush, charger_double_rush, guardian_earth_fist, ace_exam | terrapup PASS; ripplet PASS; galewisp PASS |
    - Pending (the queue is running them now, one Godot process): smoke_water_named_c2c3 (Venn and the water named fights); the Terrapup Stormwood rerun under the COMBAT §7 trivial-fight floor (capacitor 0.94, crown 0.57, old_rodfolk 1.02: the reader wins 100% and takes 3-5% max hit, so trivial, not a tell failure); and the Riverwatch rerun after the Brooktail power trim 27.5 -> 27.0 (Terrapup and Galewisp C3 at 0.501). I will add the result as INFO.
    - For Balance: Meadows chapter galewisp `masher_loses_a_named_fight` 0.12 < 0.25 (Balance lane's per ACCEPTANCE).
  - Balance: game 1 (config ON) / tests-tools 0 in this READY.
  - F10#2 handoff complete with this READY. I am stopping new work after the F22#4 INFO.
- 2026-10-24 23:55 CT INFO generic fight fix, r4 code-blind batch (CPU, 3 fresh judges, mapped; confirming, top anchor f36_0_npc C1 7.53, slope 1.23, r 0.95, RMSE 0.42, no warnings):
  - Meadows grunt/Warden (stronghold_elite hall): **5.88** after (`cand_gen_h`) vs 4.85 before (main config). Outline defect PRESENT -> FIXED and impact disc PRESENT -> FIXED (3/3 judges). HUD PRESENT -> PARTIAL. Wind-up "where" still PARTIAL (one judge PRESENT): the dust reads as a real object but is diffuse.
  - Riverwatch: **6.99** after vs 5.64 before. Outlines and disc FIXED 3/3, HUD PARTIAL.
  - Judges' next asks: a denser dust or spray wall filling the danger area with a timing pulse; a cooler fill and wider value range in the dark hall; hanging foliage cards clip the hall camera on the before side only.
  - Files: r4_{batch,key,spec,calibrate}.json.
- 2026-10-24 07:40 CT INFO F22#4 C2/C3 on current main (45865499d merged into tb/fights): running, 24 seeds, one Godot process. Order: smoke_finale_named_c2c3, smoke_stormwood_b_named_c2c3, smoke_meadows_named_c2c3, smoke_water_named_c2c3. Several hours.
  - Gap 1: the Stormwood named smoke drove combat_depth_pilot (no live patterns), the reason the audit called it stale. It now uses f22_pattern_pilot with the encounter_director context (named pattern by encounter id, authored profile as role) and the switching acceptance reader, as the Meadows and water smokes do.
  - Gap 2: Veyra and Marrow had no C2/C3 smoke. New tests/smoke_finale_named_c2c3.gd (Meadows harness, production translators, party level = region wild band midpoint + 1: 42 and 52).
  - All three harnesses now record `pattern_attacks` per run for the per-fight table. Verdict rules unchanged.
  - One-seed sanity: Veyra and Marrow PASS (terrapup). Capacitor (terrapup, 1 seed) failed the ratio (0.76 > 0.55); the 24-seed run decides.
- 2026-10-24 06:45 CT INFO F22#4 Riverwatch CPU re-judge on current main (77447cf25 + tb/fights): mapped **6.89**, CPU-provisional (6.7 or above; 7.5 still needs the GPU).
  - Batch: confirming (top anchor f36_0_npc C1 7.53), linear fit slope 1.81, r 0.98, RMSE 0.33, not above the top anchor, no warnings.
  - Main before #722 (88398238a): 6.71. Raw now 6.4/6.3/6.6 vs before 6.3/6.1/6.6.
  - Renderer-aware boss aura: already on main from 22 Oct (`aura_renderer_scale`: Compatibility 1/1; Forward+ and Mobile rim x0.3, no omni light; test_enemy_pattern_telegraph). That is the GHOST.md fix, so there was nothing new to ship. The GPU Medium re-judge is the open step.
  - Judges' remaining asks: a real water volume (spray column or wave, foam and an impact splash) instead of the glassy wedge; the HUD covering the lower third.
  - Capture: `tools/art_pipeline/capture_named_fight.gd --trainer=captain_riverwatch --live-member=captain_riverwatch:4 --ally=ripplet --frames=12 --interval=0.5 --tell-frames`. Frames t01-mid, t02-mid, 04, 08.
  - Files: rw_{batch,key,spec,calibrate}.json.
- 2026-10-24 05:30 CT READY tb/fights-land 47eea37f4 (origin/main 77447cf25 + this lane): your review items 1, 3 and 4. No config change, so what ships ON is unchanged from #722.
  1. r3 re-judge of the shipped #b16cff (3 fresh judges, mapped, CPU):
     - Meadows 6.44 vs main-before 5.80; Tidewake 6.39 vs 5.53; Cloudreach 6.28 vs 5.91 (first judged).
     - Slab defect PARTIAL on all three; F38#5-F41#5 stay open.
     - Meadows parked by the gain rule at 6.54; Stormwood parked at 6.21.
  2. Stormwood hue: no cheap per-biome override that reads better was found. Yellow-gold is the owner's road current, white-violet is lightning, teal and oxblood are reserved, and magenta is the defect. The tells sit on blue-green moss, where violet still separates, and the dust and curtain carry the "where". Left as is.
  3. Perf:
     - draw_dust sizes the multimesh only when the count changes, and allocates nothing per frame (two passes over the spacing walk).
     - Curtain bands drop the per-segment tier arrays.
     - Pattern curtain/dust AABBs fit the outline plus rise (was +-4096 m).
  4. Overlapping wind-ups: one counted aura overlay per body, so the glow lifts with the last wind-up. A body_glow hit flash during a tell borrows the glowing meshes and hands them back only while that tell's aura is live. New tests/test_tell_aura_overlap.gd (3 tests).
  - Checks on 47eea37f4: 102 tests (tell_aura_overlap, telegraph_glow, charger_lunge, enemy_pattern_telegraph, stormwood_b_named_lunge_lanes/cues, creature_attack_telegraph_animation, lunge_lane, telegraph, shared_opponent_cue_shape, combat_stagger, combat_feedback, f22_riverwatch_presentation, combat_vfx, body_glow, combat_manager, combat_ai): 0 failed.
  - Not run: full CI, and the C2 smoke (no gameplay or timing change).
  - Balance: game 1 / tests-tools 1 (the focused test).
- 2026-10-24 04:20 CT READY tb/fights-land 570357333: bodied fight telegraphs ON. Built on origin/main 2cde391e4; clean merge, no file overlap with main since base.
  - What changed:
    - Every wind-up (feet ring, charge lane, pattern ring/cone/fan/lane/marker/field, guard cone) raises kicked dust along its outline (drifting down a lane toward the strike), a low light curtain and a faint rim glow on the attacker.
    - The painted line is fainter, and the shared hue is #b16cff (was magenta #ff40e6).
    - Fixes: lingering pattern fields hard-coded magenta (they now follow the tell hue: Cloudreach's magenta rings); the Stormwood hosted-fight observer ring used the retired oxblood-band #ff5a3c; the stagger ring no longer takes the extras.
  - Scores, yardstick r2 (CPU, 3 fresh judges, mapped; arm E judged at #8c6cff):
    - Meadows 6.54 vs shipping 5.51; Tidewake 6.38 vs 5.97; Stormwood 6.13 vs 5.87.
    - Judged slab defect PRESENT -> PARTIAL, so F38#5-F41#5 and the 7.5 bar stay OPEN. ON under the judged-better rule.
  - The hue moved from 253 to 268 deg (#b16cff) so the shared tell stays 72 deg from the Riverwatch water tells (test_f22_riverwatch_presentation). r3 (Meadows, Tidewake, Cloudreach on the shipped config) is capturing to re-judge it; I'll add the result here.
  - Checks run on tb/fights ac8a016d8 (same telegraph code and config as the land commit): 134 tests across telegraph_glow, charger_lunge, enemy_pattern_telegraph, stormwood_b_named_lunge_lanes/cues, creature_attack_telegraph_animation, lunge_lane, telegraph, shared_opponent_cue_shape, named_tell_text, combat_stagger, combat_ai, combat_feedback, f22_riverwatch_presentation, stormwood_road_current, named_fight, fight_camera, combat_arena, combat_manager, stormwood_hosted_combat: 0 failed. stormwood_lightning/surge, water_alpha, tidecoil: 80 tests, 0 failed.
  - Not run: the C2 named-fight smoke (no gameplay or timing change) and full CI.
  - Balance: game 5 commits / tests-tools 0.
- 2026-10-24 INFO Task 1 (fight telegraphs vs F38#5-F41#5 "no flat magenta rings or slabs") started. New OFF hook: bodied tell (`telegraph.soft_style.curtain_height_m`, 0/absent = off; scripts/combat/tell_style.gd). Each tell's outer rim (feet ring, charge-lane rails, pattern ring/cone/fan/lane/marker outline, guard cone) raises a thin depth-tested light curtain that fades upward with a travelling shimmer. Footprints, timings, the AI's telegraph and depth rules unchanged. Candidates are capture-only overlays (`cand_tell.py.txt`).

## HANDED TO STORMWOOD (F10#2, Stormwood named-fight camera; coordinator consolidation 24 Oct)
- **Fixed (on main):**
  - The sight-line fight camera (`foliage_camera_visibility.json line_of_sight_fade`, enabled_realms ["stormwood"]). The lens refuses orbits whose line to either fighter meets trunks or rocks, and canopy fades in fights.
  - Per-named-wild distance caps (`named_max_distance_m`, 11-12 m) and a pilot size floor (`pilot_min_screen_fraction` 0.07).
  - Pilot mark: rim 0.9, pale contact ring over the ground, and a fill light.
  - C3 6/6 on CPU r8 (6.77 mapped, old 6.7 rule).
  - Telegraphs: the bodied tells (#722) apply to the Stormwood named rows. They keep their violet #b48cff row hue, and the shared hue is #b16cff. The Stormwood named tells were judged 6.13 vs 5.87 (r2, `ralph/reports/FIGHTS/close-1024/NOTE.md`) and are parked for scoring (two rounds under +0.5).
- **Open:**
  - The GPU verdict (owner 24 Oct: GPU decides). Medium/High was 3.58-3.68 on the 21 Oct GPU scale, and 5.52 on the 22 Oct yardstick (`ralph/reports/GPU-PASS/F10-2/`, STATE).
  - Judges' standing asks:
    1. The Stormwood grade: dark, monochrome, no purple sky in frame.
    2. The fight HUD covers 35-45% of the frame (UI). A compact Tether Command lane candidate exists: `tether_commands.json ui.compact_when_idle`, OFF.
    3. The pilot (Sparkit) reads as a speck next to Voltarach. A per-trainer pilot floor exists (`camera.json fight.per_trainer.<id>.pilot_min_screen_fraction`); named wilds use `line_of_sight_fade.pilot_min_screen_fraction`, and a global raise to 0.11 would also change Riverwatch, so add a per-named-wild key there if needed.
    4. Canopy at the frame edges.
    5. Tells are still flat ground decals (PARTIAL).
- **C2/C3 (functional, F22#4 run, 24 Oct):** smoke_stormwood_b_named_c2c3 now drives live patterns; 15/18 rows PASS. The Terrapup rows (capacitor, crown, old_rodfolk) re-run under the COMBAT §7 trivial-fight floor; results are in the F22#4 READY line.
- **Camera set (fixed, as judged):**
  - Five fights: `tools/capture_named_fights_f10_6.gd --ids=hollows_alpha,capacitor_alpha,crown_guardian,old_rodfolk_hall_guardian,glass_field_alpha --seconds=18 --interval=1.0 --camera-view=north`.
  - blackwater_elder: the same with `--ids=blackwater_elder` at the default stand.
  - Frames: i00-i17 plus tell1/tell2 a-f.
  - CPU: `--fixed-fps 20`. GPU Medium: `--rendering-method forward_plus --rendering-driver vulkan --resolution 1280x720 --fixed-fps 20` (commands in `ralph/reports/GPU-PASS/F10-2/`).
- **History:** `ralph/reports/CAMERA/close-1020/NOTE.md` (r1-r8), `ralph/reports/STORMWOOD/close-1022/notes.md`.

## Rounds

### r1 (24 Oct, CPU llvmpipe Compatibility 1280x720): arm C vs shipping
- Arm C (`cand_tell.py.txt C`): curtains 0.8 m (alpha 0.9, shimmer 0.6) on every tell rim plus hue #8c6cff (hue 253; >= 25 deg from both reserved oxbloods; not teal/cyan) on `telegraph.colour` and `charger_lunge.lane_colour`. Stormwood named rows keep their own #b48cff.
- Captures (control = clean origin/main config):
  - Meadows: `tools/art_pipeline/capture_named_fight.gd --trainer=captain_field --live-member=captain_field:1 --ally=ripplet --frames=12 --interval=0.5 --tell-frames`.
  - Tidewake: `tests/capture_tidewake_named_fights.gd --trainer=water_trainer_tess --interval=1.0 --max-frames=10`.
  - Stormwood: `tools/capture_named_fights_f10_6.gd --ids=glass_field_alpha --seconds=14 --interval=2.0 --camera-view=north --fixture-seed=1042206` with `--fixed-fps 20`.
  - Cloudreach: the captain capture was still running, so it joins r2.
- Batch: `anchor_tiles.py --pairs 3 --seed 1024` (f36_0_gap C2, f04_6_r22, f36_0_npc C3). Three fresh judges, JUDGE_PROMPT v1 verbatim. Defects slot per fight set: "flat magenta ring or slab telegraph on the ground"; "wind-up warning does not show where and when to move".
- Fit: linear, slope 1.48, intercept -2.12, r 0.85, anchor RMSE 0.54, top anchor 6.90 (not confirming), no warnings.

| Set | Control raw | Control mapped | C raw | C mapped | Slab defect (C) | Readability (C) |
|---|---|---|---|---|---|---|
| Meadows | 4.9/5.4/5.6 | 5.72 | 5.5/5.9/6.1 | **6.51** | PARTIAL x3 | PARTIAL x3 |
| Tidewake | 4.8/5.0/5.3 | 5.32 | 4.9/4.8/5.3 | 5.27 | PARTIAL x3 | PRESENT x3 |
| Stormwood | 5.6/5.3/5.7 | 6.06 | 5.6/5.5/5.8 | 6.21 | PRESENT x2, PARTIAL x1 | PARTIAL x2, PRESENT x1 |

- Control slab defect: PRESENT on Meadows (3/3), PRESENT/PARTIAL elsewhere. All three judges' first change: replace ground decals with a physical wind-up (dust and stones kicked along the charge path, a glowing body part on the attacker, an impact at the end point). Arm C stays OFF.
- Round 2: arm D (kicked dust along every tell outline, attacker rim glow, fainter ground line).

### r2 (24 Oct, CPU llvmpipe Compatibility 1280x720): arm E vs shipping
- Arm D, captured and not judged: kicked dust, attacker glow 0.9, fainter ground line. At 0.9 the glow washed Voltarach and Mirejaw pale on Compatibility, the same "ghost" look as the GPU Riverwatch aura, so D was dropped.
- Arm E (`cand_tell.py.txt E`), the same captures as r1:
  - Kicked dust (`dust_alpha` 0.75, spacing 0.55 m, size 0.8 m, rise 0.9 m, 1.1 Hz, #cdb894) rises along every tell outline and drifts down a lane toward the strike.
  - The attacker glows faintly during its wind-up (`tell_aura` 0.3 on Compatibility, x0.3 on Forward+).
  - Curtain 0.4 m at alpha 0.5.
  - Fainter ground line: edge 0.32, locked 0.6, core 0.75, build start 0.4.
  - Hue #8c6cff.
- Batch: same anchors (seed 1024), three fresh judges, JUDGE_PROMPT v1 verbatim, same defects slot. Fit: linear, slope 1.54, intercept -2.63, r 0.85, RMSE 0.53, top anchor 6.90, no warnings.

| Set | Control raw | Control mapped | E raw | E mapped | Slab defect (E) | Readability (E) |
|---|---|---|---|---|---|---|
| Meadows | 5.5/5.2/5.2 | 5.51 | 6.4/5.7/5.8 | **6.54** | PARTIAL x3 | PARTIAL x3 |
| Tidewake | 6.2/5.3/5.3 | 5.97 | 6.5/5.6/5.5 | **6.38** | PARTIAL x3 | PARTIAL x3 |
| Stormwood | 5.9/5.1/5.6 | 5.87 | 6.2/5.3/5.6 | **6.13** | PARTIAL x3 | PARTIAL x2, PRESENT x1 |

- E beats shipping on every set: 3/3 judges in Meadows and Tidewake; 2/3 in Stormwood, with one tie.
- The control's slab defect read PRESENT in Meadows from all three judges. On E it is PARTIAL everywhere ("grey dust disc", "translucent strip, no longer magenta"), but every judge still sees a flat ground decal, so F38#5-F41#5 do not close on the telegraph.
- Gain on the r1 best: Meadows +0.03, Stormwood -0.08 (round 1 under +0.5), Tidewake +1.06.
- Judges' asks:
  - Cracking ground or stones lifting along the lane, beyond dust.
  - The camera and the HUD covering the lower third (Camera/UI-owned).
  - The judges' readability note: a fainter lane reads "where" less clearly than magenta did.

### r3 (24 Oct, CPU llvmpipe Compatibility): shipped config (#b16cff) vs shipping main
- Arm F is the committed config as is (ac8a016d8 onward); control is origin/main before this lane. Captures:
  - Meadows and Tidewake: the r1/r2 commands.
  - Cloudreach: `tools/phase2_capture_cloudreach_live_fight.gd --seed=7` (1920x1080, captain Veyra; frames live-1722/1902/2082/2262; 40 min cap). It includes the lingering-field colour fix.
- Batch: same anchors (seed 1024), three fresh judges, JUDGE_PROMPT v1 verbatim. Fit: linear, slope 1.61, intercept -2.89, r 0.88, RMSE 0.48, top anchor 6.90, no warnings.

| Set | Control raw | Control mapped | F raw | F mapped | Slab defect (F) |
|---|---|---|---|---|---|
| Meadows | 5.3/5.6/5.3 | 5.80 | 5.8/6.0/5.6 | **6.44** | PARTIAL x3 |
| Tidewake | 5.5/5.0/5.2 | 5.53 | 5.9/5.6/5.8 | **6.39** | PARTIAL x3 |
| Cloudreach | 5.5/5.5/5.4 | 5.91 | 5.8/5.7/5.6 | **6.28** | PARTIAL x3 (control PRESENT x3) |

- The shipped hue holds the r2 result, and all three judges prefer it on every set.
- Gain rule (telegraph rounds, mapped best):
  - Meadows: r2 +0.03, r3 -0.10, two rounds under +0.5, so PARKED at 6.54.
  - Tidewake: r3 +0.01 (round 1 under).
  - Stormwood: parked at 6.21 (r2 -0.08 after r1 +0.15).
  - Cloudreach: first judged here at 6.28.
- Still open in every biome: F38#5-F41#5 (slab defect PARTIAL, not FIXED) and the 7.5 bar.
- Judges' next asks, the same in all three rounds: cracked ground or stones lifting along the lane plus a timing fill (new art or effects); camera and HUD (Camera/UI lanes).
- Sheet: `_sheet_r3.png` (Meadows and Cloudreach, control left, F right).
