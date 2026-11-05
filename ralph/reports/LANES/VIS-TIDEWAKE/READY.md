# VIS-TIDEWAKE lane (tb/vis-tidewake-1104): Tidewake F39 + F13#5, CPU judged

Owner rule (4 Nov): any judged CPU gain ships ON; only flat or worse stays OFF. Yardstick: `tools/visual_judge` (JUDGE_PROMPT verbatim, anchors, 3 judges, calibrate), via `quick_judge.py` from tb/judge-kit-1104.

## Landing-ready flags

| Flag | Row(s) | CPU base -> cand | Test | Commit |
|---|---|---|---|---|
| `water_mount_presentation.json` `enabled` (sink, bob, no blob shadow, new Aquaryn `wake`) | F39#8 | CPU 4.93 -> 6.09 | `test_uiposes_water_mount.gd::test_ships_on_with_its_judged_score` | this commit |
| `water_mount_presentation.json` `camera_hide.enabled` | F39#22 | CPU 5.25 -> 6.28 (FIXED 3/3) | same test; `smoke_camera_pass_through.gd` (hidden inside, shown outside) | this commit |
| `tidewake_look.json` `cause_tidewake.currents.enabled` | F39#17 | CPU 5.54 -> 6.09 | `test_tidewake_cause.gd::test_every_part_ships_off_and_off_changes_nothing`; `smoke_tidewake_b_current_restore.gd` (71 checks, 0 failed) | this commit |
| `tidewake_look.json` `cause_tidewake.stars.enabled` (+ `world_look.gd` per-time star reset) | F39#30b | CPU 4.77 -> 4.89 (F13#5 5.45 -> 5.84) | `test_tidewake_cause.gd::test_every_part_ships_off_and_off_changes_nothing` | look/r6 |
| `tidewake_look.json` `cause_tidewake.night.enabled` | F39#30b | CPU 5.67 -> 6.25 (F13#5 6.12 -> 6.35) | `test_tidewake_cause.gd::test_every_part_ships_off_and_off_changes_nothing` | look/r8 |
| `tidewake_look.json` rain_fog/rain_grade/rain_veil out of `sections_off` | F39#30a/#30b/#31 | CPU 6.09 -> 6.29 / 5.81 -> 6.04 / 5.29 -> 5.56 | `test_tidewake_look_profile.gd::test_shipped_look_is_on_with_unjudged_sections_off` | look/r9 |
| `tidewake_look.json` lesson_clusters/dune_grass/stones/waterline_declutter out of `sections_off` | F39#30a/#30b, F13#5 | CPU 6.19 -> 6.43 / 5.71 -> 5.88 / 5.81 -> 5.85 | `test_tidewake_look_profile.gd`, `test_tidewake_cause.gd::test_dunes_part_restores_dressing_and_sets_dune_form` | look/r12 |
| `water_veilfall_falls_visual.json` `geometry.standoff_m` 0.8 -> 3.0 | F39#30b (F39#31 flat) | CPU 5.75 -> 5.85 | `test_tidewake_look_profile.gd::test_veilfall_fall_sheet_clears_the_rock` | look/r12 |
| `tidewake_look.json` golden_sky + shore_water out of `sections_off` | F13#5 (F39#30a/#30b flat) | CPU 5.69 -> 5.87 | `test_tidewake_look_profile.gd::test_shipped_look_is_on_with_unjudged_sections_off` | look/r14 |
| `tidewake_look.json` shore_surf + shore_surf_vary out of `sections_off` | F39#30a, F13#5 | CPU 5.86 -> 6.19 / 5.31 -> 5.82 | `test_tidewake_look_profile.gd::test_shipped_look_is_on_with_unjudged_sections_off` | look/r15 |
| `tidewake_look.json` first_shore_declutter out of `sections_off` | F39#30a/#30b | CPU 5.64 -> 5.73 / 5.36 -> 5.45 | `test_tidewake_look_profile.gd::test_shipped_look_is_on_with_unjudged_sections_off` | look/r18 |
| `tidewake_look.json` lighting_candidate golden/dawn sun pitch -12/-9 | F39#30a/#30b | CPU 5.98 -> 6.18 / 5.59 -> 5.75 | `test_tidewake_look_profile.gd::test_low_sun_pitch_ships_with_its_score` | look/r22 |

| ~~`human_water_contact_visual.json` base wake values~~ (withdrawn 11:27, superseded by NEAR6-TW's `wake_trail` in batch 11) | F39#5 | CPU 5.31 -> 5.63 (r4) | the test is removed; this branch's view, config and test now equal batch 11 | this commit |

| `tidewake_look.json`: veilfall_rock_detail, veilfall_formation_relief and veilfall_falls sections ON (out of sections_off; `_why_veilfall_near_on`) | F39#31 | CPU 4.94 -> 5.20 (r 0.96); F39#30 matrix level; F13#5 5.68 -> 5.72 | `test_tidewake_look_profile.gd` (asserts ON plus the score); with veilfall_geometry, tidewake_cause and texture_import_policy: 17 tests, 0 failed | this commit |

Round 1 verdict: `qj/r1/VERDICT.md` (calibration r 0.73, RMSE 0.55, confirming). Local: the touched tests plus `test_texture_import_policy.gd` and `test_follower_leader_view_fade.gd`: 19 tests, 0 failed. Both smokes pass.

**Round 1, held OFF (flat or worse in the stacked c1 arm):** F39#1 shore 6.15 -> 5.99; F39#2 Veilfall 6.28 -> 5.19; F39#3 destinations 6.47 -> 5.83; F39#15 approach 6.21 -> 5.48; F39#16 live streaks 6.02 -> 5.89; F39#5 swim pose 5.93 -> 5.67; F39#14 swim contact 5.96 -> 5.57. All three judges blame the c1 Veilfall, a pale floating crystal crown from `veilfall_mountain_candidate` plus the light haze. The swim sections dropped the foam ring that the judges credit. Round 2 judges sea, light, horizon and dunes as separate arms, without the Veilfall mountain section and with the shipping swim ring kept.

## In flight

- **Round 1** (base vs c1, same boots): rows F39#1, #2, #3, #15, #16, #17, #5, #14, #8, #22 via quick_judge; F39#30/#31/#32 and F13#5 via `capture_tidewake_f13_5.gd` F39-look + T2-current.
  - c1 = `tidewake_look.json` cause_tidewake sea, light, currents, horizon, dunes ON; sections shore_surf(_vary), first_shore_declutter, stones, lesson_clusters, golden_sky, veilfall_falls, rain_veil, rain_fog, veilfall_mountain, swim, swim_stroke restored; `water_mount_presentation.json` enabled + new `camera_hide` (P2-109) + new Aquaryn `wake` (P2-108).
- New flag-off code: `creature_body.gd` camera_hide (`87f017f86`), `water_mount_wake.gd` (P2-108 wake).

## Status 04:21 UTC

- Round 1 base: 5/5 boots captured (routes 30, locations 2, current states 16, swimming 7, mounted swim 17 frames). Candidate boots began at 04:05; the judge packet is due about 05:45.
- After round 1: merge origin/main, then single-item quick_judge rounds from the cached base. Each judged gain is pushed ON with its score and a READY line as it passes.

## Plan

- 03:05 UTC: quick_judge is on main (c907b9997). origin/main merges into this branch once round 1's base and candidate captures finish, because a merge mid-round changes the render tree and drops the cached base. From then on, main's `tools/visual_judge/quick_judge.py` replaces the local copy.
- Container note: a container restart at ~01:55 wiped /dev/shm (import and the first base captures). The chain is now `runbook/resume.sh` (resumable, with .done markers) with a tracked background waiter.

## Round 2a (07:55 UTC): flat, stays OFF

Arm: `hero_landmarks_1101.veilfall`, `cause_tidewake.dunes`, and the shore_surf, shore_surf_vary, stones and lesson_clusters sections. Calibration r 0.95, RMSE 0.37 (`qj/r2a/VERDICT.md`).
F39#1 5.40 -> 5.45, F39#2 5.35 -> 5.19, F39#3 5.45 -> 5.40, F39#15 5.50 -> 5.56. All flat.
- Frame diffs change only 2-8% of pixels. The Meshy Veilfall draws only past 1100 m and none of these route stands is that far, so the arm never shows.
- Every judge asks for the same fixes:
  - new art: a terraced, green Veilfall with several broad falls and mist at the base;
  - scene: irregular shallows instead of the rest-shoal disc chain, plus wet-sand, foam, rock and driftwood bands and haze;
  - new art: hero structures at the destinations.
- Owner reassignment (coordinator, 07:42): F39#27/#1/#6/#7/#20/#2/#14/#19/#4 move to the NEAR6-TW lane. This lane keeps #3, #15, #16, #17, #5, #8, #22, #24, #21, #30, #31, #32 and F13#5.
- Coordinator (11:45): stars landed in batch 13 (#821). F39#16/#15/#3/#24/#21 move to NEAR6-TW. This lane keeps F39#30 (night/matrix), #31 Veilfall, #32 matrix cleanliness, #5 (wake_trail reconcile) and F13#5.

## Round 5 (11:15 UTC): unshadowed falls are flat on F39#31, so they stay OFF (`look/r5/VERDICT.md`)

## Batch 11 note (coordinator, 10:49): reconciled 11:27

This branch now carries batch 11's `human_water_contact_visual.json` (base values plus `wake_trail` ON), `human_water_contact_view.gd` and `test_human_water_contact_visual.gd` (8 tests, 0 failed), and drops `test_vis_tidewake_swim_wake.gd`. Next: re-judge F39#5 with ring 2.1 m and interval 0.12 over `wake_trail`.

### Original note

The F39#5 wake (`human_water_contact_visual` base values) was held because NEAR6-TW's `wake_trail` (F39#14 6.10 -> 6.80) overrides them. Once the round-6 capture ends, this branch reverts its base values, drops `test_vis_tidewake_swim_wake.gd`, takes batch 11's `wake_trail` block verbatim, and re-judges F39#5 with ring 2.1 m and interval 0.12 on top of it.

## Round 2c (09:45 UTC): swim stroke is a tie; it is already shipped

- F39#5 5.85 -> 5.85; F39#14 6.98 -> 6.98 (r 0.98). Frames differ by under 2% of pixels.
- `human_swim_visual.json` `uiposes_stroke_candidates` is already ON (GPU 6.60 -> 7.21, 2 Nov) and applies these same pose keys, so the tidewake_look stroke section is redundant.
- A crop of the CPU frame shows the trainer already prone with the arms spread. Judges read "upright, legs hanging" because the legs trail toward the high rear camera and show clearly through the shallows.
- Next arm (r4, config only): a longer, denser foam trail (`human_water_contact_visual.json` ring 2.1 m, 12 trail rings, 2.6 s life). The aim is a wake that also veils the submerged legs.

## Round 2b (09:25 UTC): sea + horizon lost; stays OFF

Arm: `cause_tidewake.sea` + `horizon`. Calibration r 0.84, RMSE 0.45 (`qj/r2b/VERDICT.md`).
- F39#16 6.18 -> 6.00, F39#5 6.03 -> 5.60, F39#14 6.32 -> 5.82.
- All three judges see a hard-edged pale triangular wedge in the shallows on the candidate swim frames, a seam that the sea part's depth-band break draws, and broad regular diagonal bands in the live current.
- The shipped base already maps 6.0 or above on CPU for F39#16 and #5.
- Next judge-named levers: a horizontal swim stroke with a V-wake (r2c tests the existing stroke candidate), and curved, broken current foam.

## Handoff to NEAR6-TW: F39#4 shiny cue (flag OFF, not judged)

- `creatures_visual.json` `shiny_cue` (OFF): the shiny body gets a rim (BaseMaterial3D rim plus `rim_amount` on the creature_surface_finish next_pass overlays) and the alpha mote ring in #dff3ff. Code: `creature_body.gd` `_apply_shiny_cue` / `_rim_finish_overlays`.
- r1b and r1b2 CPU frames (`phase2_capture_creatures --only=aquaryn,cannonback,riptusk --poses=shiny_idle`): base and candidate look identical at the stand distance, so neither round was sent to judges. The motes show only as faint specks, and the rim does not read at about 8 m.
- If it is worth another try: raise the mote size and count (alpha_aura MOTES=7 is fixed), or move to an emission tint on the finish shader.
- Separate finding: the authored-rest capture never completes for Torrentoad (shipped) or for Riptusk once Riptusk is added to `water_creature_rest_visual.json` ("authored rest did not complete before capture"). So F39#24's resting frames cannot be captured on CPU right now. Riptusk's rest GLB is in creatures-ralph's PR #803.

## Harness finding for main's quick_judge.py

- `find_frame` misses every Tidewake route and location frame. Those tools write `water__<stand>__…` files, but job.json ids are `tidewake__<stand>__…`, so F39#1/#2/#3/#15 (and every route row) build no sets. Fix: `runbook/qj_patch.py` part 1 (try `water__` + the id's tail). Main's copy at c907b9997 has the same bug.

## Blockers

- **No merge of origin/main here:** a depth-1 fetch has no merge base, and `git fetch --deepen=40` ran out of disk (66 MB free). The coordinator's landing PR has to merge this branch with main.

- Container disk: the 21 GB `.git` pack fills the allowance (117 MB free). Godot's `.godot` import cache, captures and judge folders run from `/dev/shm` (RAM). Rewriting the pack to depth 1 was refused by the permission classifier.
- qj/r7 (12:10): F39#5 re-judged on the batch-11 wake_trail base: base maps 6.20 (CPU, above 6.0). A wake_trail tune (interval 0.12, spacing 0.55, lifetime 2.8, grow 2.6) was flat (6.20 -> 6.14; F39#14 6.89 -> 6.77) and stays OFF.
- look/r9 (13:05): `current_bands_candidate` lost (F13#5 5.95 -> 5.59) and stays OFF.
- look/r11 (13:20): `veilfall_cladding_candidate` + `veilfall_hero_candidate` flat (F39#31 5.29 -> 5.32, F39#30b 5.40 -> 5.40); stay OFF.
- Coordinator 15:00, batch 17 (#825) `smoke_net_water_alpha` "peer silent (peer 0)": ran locally (`runbook/net_b17.sh`, 4-core container, one Godot at a time), this lane's batch-17 arms ON (HEAD) vs OFF (`ov_b17off.json`: shore dressing, surf, golden sky, shore water back in `sections_off`, standoff 0.8). **Both PASS, ALL CHECKS PASSED**, wall 162 s ON / 160 s OFF. The host's Water shell for the crossing client reports `finished building in 14.2 s` ON and `14.9 s` OFF, so no arm adds main-thread time. Code check agrees: every batch-17 arm is presentation-gated (`simulation_only` skips landmark models/lesson clusters, ground cover, surf/shore water overlays and current markers; the standoff only changes a parameter on a mesh of the same size). The shell build itself (~14-15 s here) sits right at the 15 s heartbeat detector, so a slower CI runner can trip it with or without these arms. That is a pre-existing margin issue in the Water shell build or the harness allowance (the host-shell crossing allowance did not apply), not a change from this lane.
- look/r16 (ripple calm) and look/r17 (low-sun shadow bias): no visible change, stay OFF; the golden-hour sand stripes are not ripple normals, acne or the First Shore props.
- look/r19 calmer night (saturation 0.72, exposure 0.88): flat (F39#30b 5.62 -> 5.62, F13#5 6.07 -> 5.97); stays OFF.
- look/r20 Veilfall fall stream relief: flat (identical scores from all three judges); stays OFF. Scene levers on the Veilfall are exhausted (r5, r11, r12, r20); the remaining judge ask is the new-art rebuild.
- Status 17:40: shipped ON since batch 13: shore dressing, Veilfall standoff, golden sky + shore water, shore surf, First Shore declutter (all CPU gains, tests pass). Flat and OFF: r16 ripples, r17 shadow bias, r19/r21 night dimming, r20 fall relief. Remaining judge asks need new art or code: (1) a Veilfall rebuild (tiered green mountain, several falls, mist, arch; sculpted close cliffs), which needs Blender (not installed; would go into /dev/shm); (2) a night-specific shallow-water colour, which needs a time-of-day input to `water.gdshader` (the night keys do not move the cyan band); (3) the golden-hour sand stripes, which are cast shadows from an unidentified caster behind the First Shore camera (not ripples, acne or the declutter props).
- Stripe probes (look/probes): the golden-hour sand stripes survive the declutter, landmark props, lesson clusters and dock removal; p3 also rules out the trees and shrubs, so the caster is the terrain. Parked for this lane.
- Status 19:45: since the 17:40 status, the higher golden/dawn sun shipped ON (look/r22, F39#30a 5.98 -> 6.18, F39#30b 5.59 -> 5.75). Flat and OFF: r21 dimmer night, r23 clearer rain, r24 darker storm sky; the stripe probes p1-p3 point to a terrain shadow. Config arms for this lane's rows are exhausted. The remaining asks need code or new art: a Veilfall rebuild (Blender not installed), a night shallow-water colour (needs a time-of-day input to `water.gdshader`), and a rain cloud-colour grade (rain preset cloud keys).
- look/r26 (20:15): `world_look.gd` weather sky overlays may now set cloud colours (inert, no preset uses them). The storm-cloud arm is visible but flat with all three judges (rain is one tile of four), so it stays OFF. Config arms on this lane's rows are exhausted.
- look/r27 (21:15): water night dim (inert code, a11146852) visible but flat with the judges; stays OFF.
- Status 22:30 (coordinator 21:35 list): F39#3 arm d3 (8 m drift arch, two extra collider-free terrace walls) is capturing; queued behind it: F39#15 arm s15 (rest shoals in a chain wear different tall silhouettes via a new inert `shoal_pick` selector in `water_rest_shoals.gd`, 78955639e), then F39#3 arm dr (the never-judged world-dressing `tidewake_destination_read.json` candidate). One-item quick_judge rounds; gains ship ON, flat stays OFF. F39#9/#7/#19 follow.
- Coordinator 22:30 (merge land-batch-28): could not merge locally (disk 175 MB free; a fetch pulled 8+ GB and timed out). 17369a598 instead makes `tools/phase2_capture_catch.gd` and `scripts/world/water_rest_shoals.gd` match land-batch-28 exactly in its changed regions (VIS-CLOUDREACH bd004d556 arbiter window verbatim, gated on `_pinned_wild` so the Tidewake pin uses it; NEAR6-TW `rest_shoal_dressing_vary` verbatim), with this lane's Tidewake pin and `shoal_pick` on non-adjacent lines, so the 3-way merge should be clean. Tests: pinned-wild both biomes + tidewake look profile, 12 tests 0 failed. If a conflict remains, please resolve on the landing side keeping both. F39#3 d3's candidate boot was OOM-killed by the fetch (exit 137); d3, s15, dr and F39#9 base are re-queued.
- qj/d3 (23:45): F39#3 named destination read **5.67 -> 5.93** mapped (raw 5.3/4.9/5.3 -> 5.6/5.1/5.5, all three judges prefer it; calibrate r 0.87). Ships ON: `tidewake_look.json` `landmark_models` (Lantern Cove drift arch 5 -> 8 m, lantern posts 3.4 m, two collider-free stepped terrace walls at Drowned Garden), `_why_d3_landmarks`, `test_tidewake_look_profile.gd::test_destination_landmarks_ship_with_their_score` (runs in the queued F39#9 test step). Judges' remaining asks: Veilfall-scale hero architecture (new art), clumped dune grass, flat sand form.
- Coordinator 00:40: F39#3 d3 (5.93) landing in #838. F39#7 and F39#19 move to VIS-STORMWOOD and are dropped here; this lane keeps F39#15 (arm s15 queued) and F39#9 (pinned catch capture, base queued), plus F39#3 arm dr. A container restart at ~00:10 wiped /dev/shm; chain_2350 relaunched (reimport, then s15, dr, F39#9 tests + base).
- qj/s15 (01:50): F39#15 rest shoals with varied tall silhouettes (`shoal_pick`): **5.98 -> 5.91**, flat; stays OFF (the selector is inert without data). All three judges still read the disc chain itself (shape, spacing, white rims) as the defect; props on the discs do not change that.
- qj/dr (01:55): F39#3 world-dressing `tidewake_destination_read.json` on top of the shipped d3: **5.75 -> 5.84**, split judges (one down, two up), treated as flat; stays OFF. Judges cite smoke over the arch and concentric rings in the water on that side.
- F39#15 next step needs a coordinator call: the disc chain is the sheltered-route rest shoals (`water_world.json` `rest_shoals`, every one `shore_radius_m` 20 / `peak_height_m` 1.5), baked into `data/terrain/water/*.res`. The only fix the judges ask for (irregular, varied sandbars) is a terrain re-bake of those shoals plus a route-safety re-proof of the sheltered swim routes, not a presentation arm; this container has ~166 MB of disk, too little for a re-bake. Presentation arms on the shoals (s15) were flat. Parking F39#15 here unless a lane with disk and route-proof ownership takes the re-bake.
