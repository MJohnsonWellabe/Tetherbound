# VIS-STORMWOOD: READY

**Landing-ready flags (judged CPU gains, ON, tests assert ON with the score):**

| Item | Flags ON | CPU score | Verdict | Commit | Test |
|---|---|---|---|---|---|
| F41#19 Glass Field footing | `stormwood_glass_field` `rock_collar_candidate.footing_1104` (10 installed rocks, wider and taller collar; colliders stripped) | **5.09 -> 5.22** (2/3; one calls the flat-base defect FIXED) | `qj/qj_footing/` | `468ed635` | `test_stormwood_basalt_crust`, `test_vis_stormwood_judged_on`, `test_stormwood_glass_field_identity`, `test_stormwood_route_walkability`, `test_stormwood_look` all 0 failed with it ON |
| F41#4 named destinations | `stormwood_ground_finish` `path_loam_1104` (path slot darker, cooler damp earth, deeper relief) | **5.56 -> 5.92** (3/3) | `qj/qj_path/` | `99ed2852` | `test_stormwood_pool_satin`, `test_vis_stormwood_judged_on`, `test_stormwood_look`, `test_stormwood_route_walkability`, `test_stormwood_glass_field_identity`, `test_stormheart_presentation` all 0 failed with it ON |
| F41#19 Glass Field seam clear r2 | `stormwood_glass_field` `seam_clear_1104` (fissures kept, darkened; whole scar cleared of grass; narrower crust) | **4.77 -> 5.59** (3/3; r1 4.34 -> 5.30 withdrawn for dropping fissures) | `qj/qj_seam2/` | (this push) | `test_stormwood_basalt_crust`, `test_vis_stormwood_judged_on`, `test_stormwood_glass_field_identity` run with it ON |
| F41#10 Glass Sink obsidian r3 | `stormwood_glass_sink` `obsidian_1104.r3` (satin black glass, no veins or seams) | **3.96 -> 4.38** | `qj/qj_obs3/` | `c072bc54` | `test_stormwood_glass_sink_obsidian`, `test_vis_stormwood_judged_on`, `test_hero_landmarks_1101`, `test_storm_cams_candidates`, `test_stormwood_charged_ground`, `test_stormwood_route_walkability`, `test_stormwood_surge` (all 0 failed with it ON) |
| F41#10 Glass Sink | `hero_landmarks_1101.glass_sink`, `stormwood_glass_sink` `dark_pool_candidate` + `obsidian_1104` | **4.03 -> 5.07** | `j4/` | `84f06e8a` | `test_vis_stormwood_judged_on`, `test_hero_landmarks_1101`, `test_storm_cams_candidates`, `test_stormwood_glass_sink_obsidian` |
| F41#1 Stormheart | `stormheart_presentation` `deck_light_1101`, `hollow_floor`, `hero_interior.round2` | **3.22 -> 3.94** | `j1/` | `c1ebc1ff` | `test_vis_stormwood_judged_on`, `test_cause_stormwood_candidates` |
| F41#4 destinations | `stormwood_lantern_pools` `arrival_pools`, `basin`, `lantern_model`, `glow_fungi`, `grove` | **4.00 -> 4.59** | `j1/` | `c1ebc1ff` | `test_vis_stormwood_judged_on`, `test_stormwood_lantern_pools_grove` |
| F41#8 named silhouettes | `npc_role_accessories` | **4.72 -> 4.96** (offset-map caveat) | `j3/` | `155cdd39` | `test_vis_stormwood_judged_on` |

**F41#21 / F41#16 (Hollows fight result screens) need the GPU queue (4 Nov 18:15 UTC):** I set up a CPU A/B of `hud.victory_focus` (UIPOSES arm, OFF, never judged alone; aimed at F41#21's "victory line groups with the quickbar") but `phase2_capture_stormwood_fights.gd --ids=hollows_alpha --seconds=120` reached only t=37 s of fight time in its 50 min timeout on llvmpipe (exit 124, no frames), and the win/loss result frames come after the fight ends. **Please judge `hud.json victory_focus` on F41#21 (and F41#16) on the GPU rig.** Character rows F41#8/#18 left alone while NEAR6-TW edits the shared character rim shader.

**Reassignment (coordinator 5 Nov 00:40 UTC):** Stormwood items parked (new art or GPU). Now: F39#7 P2-089 Tidewake fight composition (5.65), F39#19 P2-088 Tidewake fight roster contrast (5.78), F36#29 Innkeeper body (5.83). Building on NEAR6-TW's notes (all_pairs worse; roster_floor no CPU change).
- F39#7 `combat.json trainer_aside.realm_1104` (OFF, `2ff5da7a`): Tidewake (realm `water`) trainer 3.6 m aside instead of 2.4, same depth; judging as `qj_aside`.

**Redirect status (coordinator 22:25), 5 Nov ~00:15 UTC:**
1. F41#5 grove rings: invisible in the fixed views (real ON bake A/B 0.0% px), reverted.
2. F41#19 footing: **ON 5.09 -> 5.22** (`468ed635`).
3. F41#1 floor lanterns: flat (4.15 -> 4.15), parked.

The remaining Stormwood gaps (F41#1 shell and core, F41#5 terrain relief, F41#19 spike base) all read as new art or terrain authoring to every judge. I keep a check-in armed for further direction.

**FOR THE COORDINATOR (4 Nov ~22:00 UTC), after your 19:25 list:** worked lowest-first.
- **ON:** F41#4 darker damp-earth path 5.56 -> 5.92 (`99ed2852`, 7 region tests green).
- **Judged flat, OFF:** F41#5 terrain macro variation (5.31 -> 5.35).
- **No visible change, not judged, OFF:** F41#8/#18 front fill (characters are small mid-distance figures in every frame); F41#5 grass colony mode (the carpet is the terrain moss slot); F41#2 Building sheet glow, r1 and r2 (the F41#2 frames never show a lit Building cloud deck).
- **What is left needs something this lane cannot do on CPU with presentation flags:** F41#1 and F41#19 need new meshes (Blender is blocked here); F41#5 needs terrain relief, grove masses and distance layers (terrain/scatter bake); F41#8/#18 need closer character framing or costume/silhouette art; F41#2 needs frames that show the phase sky, or a capture change; F41#21/#16 need GPU capture. **Please redirect me** (another region's items, a bake-level change you authorise, or GPU-side work). I keep a check-in armed.

**Coordinator (4 Nov 16:44 UTC):** NEAR6-TW takes some of my parked F41 items with fresh approaches and marks them in both READY files. I skip every item it claims and continue on the rest. Parked here and free to take: F41#1 (root floor, arc glow), F41#5/#4 (foliage grade), F41#19 (seat), F41#2 (phase grade), F41#10 wall grade (white wall source unknown). **Claimed by NEAR6-TW:** the F41#10 pale white wall, **DONE there, ON 4.84 -> 5.36** (the wall was `HollowCrownSilhouette`, the Crown Overlook massif, whose 300 m visibility start sat inside its own 560 m footprint). **Next here once NEAR6-TW's character-rim `fill_energy` uniform lands on main:** a Stormwood front fill on the character rim for F41#8/#18 (flat faces, no catchlight).

**Merge (4 Nov ~15:30 UTC):** `10841bda` merges origin/main 78e83f81 (batch 16) cleanly. On it, all 0 failed: `test_vis_stormwood_judged_on` 6/29, `test_stormwood_basalt_crust` 4/17, `test_stormwood_glass_field_identity` 4/73, `test_stormwood_glass_sink_obsidian` 4/18, `test_stormheart_presentation` 7/784, `test_stormwood_look` 8/54. Note: `foliage_grade_1104` r2 asked for darker ferns (brightness 0.85) yet rendered them pale white, so the retexture_adjust path misbehaves on the storm_fern texture; not chased (diagnostics).

**FOR THE COORDINATOR (4 Nov ~14:55 UTC), lane status:** ON and pushed today: F41#19 seam clear r2 (4.77 -> 5.59) and F41#10 obsidian r3 (3.96 -> 4.38), both with region identity/look tests green. Judged and parked: foliage grade (F41#5/#4), Stormheart root floor and arc glow (F41#1). Dead flags found (no visible change, not judged): `ground_zones` r22, `stormwood_look.storm_light` (superseded by `light_pass_1101.rim`). **Requests:** (1) F41#1 needs new art: every judge since qj_heart names the plank-drum shell, radial plank ceiling and missing crown/core; Blender is blocked in this container, so please route it to a mesh-capable lane. (2) Repeated finding for the fight-owning lane (NEAR6-MS): every Stormwood fight set shows flat magenta telegraph rings and, on one arm, the camera buried in canopy for several seconds (i11-i15). (3) F41#22/#24 need a GPU matrix baseline (see below).

**FOR THE COORDINATOR (4 Nov ~08:45 UTC):** seam clear r1 has been withdrawn. r2 is OFF, re-judge queued. Region identity and look tests now run before any flag goes ON. Queued on this head:
- `test_stormheart_*` (presentation, ancient_trunk, canopy_atlas, split_bark, wayfinding)
- `test_stormwood_look`, `test_stormwood_crown_overlook`, `test_stormwood_charged_ground`, `test_stormwood_route_walkability`, `test_stormwood_surge`
- `test_character_appearance_variants`
- `test_stormwood_struck_sentinel_identity`, `test_stormwood_capacitor_grove_identity`, `test_stormwood_glass_field_identity`

Results: below, all 0 failed.

**Region identity and look tests (4 Nov ~10:45 UTC, head with obsidian r3 ON; seam r2 ON separately passed basalt, judged_on, glass_field_identity 4/73, surge 4/46), all 0 failed:**
- `test_stormheart_presentation` 7/784
- `test_stormheart_ancient_trunk` 4/240
- `test_stormheart_canopy_atlas` 2/10
- `test_stormheart_split_bark` 3/10
- `test_stormheart_wayfinding` 3/3952
- `test_stormwood_look` 8/54
- `test_stormwood_crown_overlook` 2/526
- `test_stormwood_charged_ground` 2/7
- `test_stormwood_route_walkability` 4/37
- `test_stormwood_surge` 4/46
- `test_character_appearance_variants` 11/235
- `test_stormwood_struck_sentinel_identity` 2/23
- `test_stormwood_capacitor_grove_identity` 2/24

**Tests on the synced head (06:20 UTC, after main merge `9faa85e1` and the j1-j4 commits), all 0 failed:**
- `test_vis_stormwood_judged_on` 4/25
- `test_cause_stormwood_candidates` 11/95
- `test_stormwood_lantern_pools_grove` 3/11
- `test_stormheart_branching_crown` 2/9
- `test_stormwood_basalt_crust` 2/5
- `test_hero_landmarks_1101` 8/76
- `test_storm_cams_candidates` 15/56
- `test_stormwood_glass_sink_obsidian` 2/8
- `test_stormwood_rank_marks` 2/11
- `test_stormwood_pool_satin` 2/4
- `test_stormwood_surge_presentation` 53/730
- `test_stormwood_restored_sky` 2/39
- `test_texture_import_policy` 2/1591

**Judged flat or worse, stay OFF:**
- F41#2 `phase_grade_1104` r1: 5.46 -> 5.46. r2 is built.
- F41#18 rim r2 + `rank_marks_1104`: 4.96 -> 4.99.
- F41#5 `pool_satin_1104`: 4.13 -> 4.20, and the judges split.
- F41#9 `stormwood_harvest_hero2`: 4.76 -> 4.59.

- F41#19 `basalt_crust_1104`: 5.25 -> 4.42 (`qj/qj_basalt/`).
- F41#2 `phase_grade_1104` r2: 4.40 -> 4.23 (`qj/qj_phase2/`). The approach is parked after two flat rounds.

- Stormwood `stormwood_look.foliage_grade_1104` (F41#5, F41#4): flat, 0.00 on both rows (`qj/qj_foliage/`). Both sides render identically: the variant_retint overlay does not reach the visible canopy. The cause needs an engine probe.

**Ownership change (coordinator, 4 Nov ~07:40):** F41#9, F41#20, F41#15 and F41#3 move to lane NEAR6-MS. My OFF arm `combat.contact_spacing.named_overrides.capacitor_alpha` (`ea108029`, `test_capacitor_spacing_override` 1/5) is theirs to judge. quick_judge cannot capture `phase2_capture_stormwood_fights.gd` (the tool refuses output outside its Phase 2 report folder); `tools/visual_judge/lane_bin/run_group.sh` retries under that folder.

- F41#1 `stormheart_presentation.meshy_interior`: flat, 4.91 -> 4.91, identical sides; it does not render at the judged stands (`qj/qj_heart/`).
- F41#1 `floor_lanterns_1104` (redirect: installed Lantern_Wall posts and warm pools around the hollow floor, 40 m ring, no collider): **flat**, 4.15 -> 4.15 (`qj/qj_lanterns2/`, r2: 12 posts, 3.8 m, energy 5, 26 m range; 6.5% px of warm floor wash), 3/3 identical scores; r1 (8 posts) 0.4% px, not judged. Stays OFF, **parked** (two builds). Every F41#1 judge still names the plank-drum shell and the missing crown and core (new art).
- F41#5 grove rings `dense_stands_1104` (coordinator redirect 22:25; 11 storm_canopy stands, 70 m radius, on 210 m rings round the Struck Sentinel and Crown Overlook, installed tree family through dense_stands): **no visible change, reverted, not committed**. Lesson: an overlay on `stormwood_vegetation.json` stales the bake and Stormwood vegetation then *fails closed* (no forest at all), so the first `qj_groves` round was invalid. Manual A/B `qj_groves2`: a real ON bake (kept 45433; six regions grew, region_-1_0 2.5x) captured clean (no stale error), against the clean `qj_macro` base: 0.0% px over 20. The canopy lod_range is 850 m, so the rings are out of the fixed F41#5 camera frusta or under the storm depth fog. Config, code and bake restored from git (repo clean). A closer ring risks occluding the landmarks; not tried.
- F41#2 `presentation.building_glow_1104` (Building in-cloud sheet glow 0.22 -> 0.7, faster pulse, contrast 0.75): **not judged, no visible change** (`qj_bglow` 0.2% px). The sheet glow is masked to the upper sky (`aloft` = smoothstep(0.14, 0.3, dir.y) in stormwood_surge.gd) and the F41#2 frames show mostly low sky near the horizon, so it never reaches the frame. Stays OFF. r2 (`33c19f91`) added a per-phase `glow_low` uniform (default 0.14 = unchanged; surge, restored_sky and surge_presentation tests green) and set Building to 0.0: `qj_bglow2` still 0.1% px, so the F41#2 frames do not show a lit Building cloud deck at all. **Parked** (two builds, no visible change).
- F41#5 `macro_1104` (Terrain3D macro variation on the Stormwood terrain): **flat**, 5.31 -> 5.35 (`qj/qj_macro/`, 11% px changed); 2/3 judges saw no difference. Stays OFF. All three put F41#5's gap in flat terrain with no relief, no grove masses and a one-band horizon (terrain/scatter, a bake change, not a presentation flag).
- F41#5 `grass_patch_1104` (grass shader colony mode: full clump contrast with a patch ramp): **not judged, no visible change** (`qj_grass` 1.3% px). The "flat green carpet" the judges see is mostly the terrain grass slot (the Meshy wet-moss floor texture tiled evenly under value_lift tint #d2c49e), not grass blades, so thinning blades leaves the same carpet. Stays OFF. The lever left is the terrain grass slot itself (macro variation or a second slot blend), not tried yet.
- F41#8/#18 `stormwood_character_rim.fill_1104` (front fill 0.14 through the shared fill_energy): **not judged, no visible change** (`qj_fill18` 0.3% px, `qj_fill8` 0.4% px). Both rows frame the named characters as small figures at mid-distance beside the trainer, so a face fill cannot read; the rim r2 contrast lever was already flat (4.96 -> 4.99). Stays OFF, parked. These rows need closer dialogue framing (a camera/framing change, not allowed as a dodge) or a silhouette/costume change (new art).
- F41#10 `glass_sink.wall_grade_1104` (dimmer glow, darker cool tint on the Meshy sink shell): **not judged**. `qj_wallgrade` changed 1.6% of pixels: the Meshy shell is only the crystal outcrop at the rim, and the huge pale white wall on the left of every F41#10 frame is untouched, so that wall is something else (terrain cliff or fog; source still unknown). Stays OFF.
- F41#19 `seam_clear_1104.seat_1104` (thinner crust sunk 0.22 m): **flat**, 5.56 -> 5.56 (`qj/qj_seat/`); 3/3 scored both sides identically (the change is a few pixels on a background plate). Stays OFF. Judges keep naming camera framing (a giant trunk filling a third of the frame, trainer and companion in front of the cluster) and the lime fern; no reframing is allowed, so the next F41#19 swing is the fern/foliage grade there or a new spike base (new art).
- F41#1 core arcs `glow_1104` (white-violet core, additive violet halo, jaggier): **worse**, 5.13 -> 4.85 (`qj/qj_arcglow/`); 3/3 read the halo as pink pipes or plastic tubes. Stays OFF, parked. Every F41#1 judge since qj_heart puts the gap in new art (plank drum, no crown or core).
- F41#1 `root_floor_1104` (dark root loam in the Stormheart hollow; r1 sunburst and r2 glossy polka dots retuned unjudged): r3 **worse**, 4.64 -> 3.83 (`qj/qj_rootfloor3/`); 3/3 preferred the shipped moss floor. Stays OFF, **parked**. All three judges put the defect in the plank-drum shell, striped ceiling, line-drawn lightning and missing crown/core: **new art (Blender, blocked here; needs a Codex/Meshy lane)**.
- F41#2/#5/#18 `stormwood_look.storm_light` (r26 rim): **no visible change** in `qj_rim` (mean diff 0.9-1.4). Superseded: `light_pass_1101` (ON) already ships its own `rim` and `with_light_pass()` replaces `storm_light` with it, so the top-level flag is dead. Not judged; stays OFF.
- F41#5/#4 `ground_zones` r22 (authored loam/moss/pools): **no visible change** in `qj_gzones` (mean pixel diff 0.9-1.0, nothing over 20 levels; capture ran with the overlay and no zone error in the Godot log), so not judged. Something later in the terrain material path likely overrides the zone shader; not chased further (diagnostics). Stays OFF.
- F41#5/#4 `foliage_grade_1104` r2 (texture desaturate/brighten): **worse**, 5.09 -> 4.88 / 5.24 -> 5.02 (`qj/qj_foliage2/`); 3/3 preferred the shipped green ferns over the pale-white candidate. Stays OFF; **parked** (r1 flat, r2 worse).
- F41#10 `obsidian_1104.r2`: flat, 3.93 -> 4.02 (`qj/qj_obs2/`). The judges read the glowing seams as "a debug wireframe grid".
- F41#10/F41#4 `stormwood_ground_finish.rock_value_1104`: flat, identical sides (`qj/qj_rock/`). The pale cliff wall is not the terrain rock slot.

**Lesson (this lane):** three arms in a row changed no pixels at the judged stands. Each new arm now needs its effect visible in the frames before it is judged.

**In the queue:**
- `presentation.height_fog` on F41#5, F41#4 and F41#2 (`qj_hfog`, capturing).
- F41#10 `obsidian_1104.r3`: no veins, no seams, a satin black-glass pool (`5e72fdf9`).
- F41#19 seam clear r2 (`qj_seam2`).
- Region identity and look tests.
- Unscored baselines F41#22 / F41#24 (**FOR THE COORDINATOR / GPU queue**): the calm matrix is captured on CPU (`capture_stormwood_f10_matrix.gd --phases=calm`, 10 views: forest, giant, glass, rod_line, stormheart x calm/aftermath, local `.artifacts/vl/u_matrix_calm/out`, exit 0). The break phase takes ~30 min a view on llvmpipe (the calm+break run would time out at 90 min), so it was cut. Neither row is in `item-scores/job.json`, so `quick_judge` cannot score them, and the owner rule gives unscored items a GPU baseline first: please run the matrix (calm, break) on the GPU rig for their baseline. Known F41#24 evidence from my rounds: 3/3 judges called the Stormwood named-fight telegraphs "flat magenta rings/slabs" (fight rows are NEAR6-MS's).

**Open:**
- F41#20: Fenn's dialogue frame is black in both arms. The camera sits behind a dark blocker next to Fenn's seat. Moving the seat stales the scatter bake, so this needs an engine probe of the blocker first.
- Blender is blocked in this session.

**FOR THE COORDINATOR (4 Nov ~02:50 UTC; send_message is refused here, untrusted device):** merged as asked. `ae954029` merges `origin/tb/creatures-ralph` 7568796b: storm-light set ON, `phase_grade_1104` OFF, main's newer CI, routes and docs kept. One commit after it adds the F41#18 `rank_marks_1104` arm (OFF). Tests on this head, all 0 failed:
- `test_stormwood_surge_presentation` 53 tests / 728 assertions
- `test_stormwood_restored_sky` 2/39
- `test_cause_stormwood_candidates` 11/95
- `test_storm_cams_candidates` 15/55
- `test_stormwood_rank_marks` 2/11

## Session 2 (4 Nov 2026, shallow clone): setup

- Godot 4.7-stable installed by `tools/cloud_setup.sh` (first half); full import running; about 11 GB free.
- **Blocked: Blender.** Running a downloaded portable Blender is refused by this session's auto-mode safety check ("code from external"), so new meshes are built as procedural Godot geometry (scene-level, in code) instead. Owner or coordinator can allow it with a Bash permission rule.
- Merged without history (a shallow `--deepen` fetch grew past 4 GB and was stopped): `dc709159` takes the creatures-ralph versions of every lane file (storm-light set retuned and ON, flag-OFF arms, tests, `tools/visual_judge/lane_bin`) and the rim r1 ON from #808 (`tb/land-vis-11`). Nothing main changed later (CI, routes, `tools/earned_saves`) is touched.

## New arms (OFF until judged)

| Item | Arm | Commit | Test |
|---|---|---|---|
| F41#18 P2-056 uniforms | `stormwood_character_presentation.json rank_marks_1104`: pale shoulder knots (LeftArm/RightArm) and a neck collar ring in each officer's identity colour, larger for lieutenants and the captain | see `git log` | `test_stormwood_rank_marks.gd` (2/11) |
| F41#2 P2-042 surge phases | `stormwood_surge.json presentation.phase_grade_1104`: Calm higher-key sky with cloud breaks, Building lower indigo sky, denser fog and rain; Break, energies and ambient unchanged | `442053bb` | `test_cause_stormwood_candidates.gd test_phase_grade_separates_calm_from_building_and_keeps_break_rules` |

## Capture queue (one Godot at a time, `tools/visual_judge/lane_bin`)

1. `s1_base`: rows F41#1,2,3,4,5,8,9,10,15,16,18,19,20,21 (13 boots, `job.json` repro commands).
2. `s1_cand`: the same with `cand1` ON: rim r2 (F41#18), `npc_role_accessories` (F41#8), Stormheart `deck_light_1101`/`hollow_floor`/`hero_interior.round2` (F41#1), `hero_landmarks_1101.glass_sink` + `dark_pool_candidate` (F41#10), lantern pools `arrival_pools`/`basin`/`lantern_model`/`glow_fungi`/`grove` (F41#4), `stormwood_harvest_hero2` (F41#9), `phase_grade_1104` (F41#2), `hud.victory_focus` (F41#21), `combat.contact_spacing.named_overrides.hollows_alpha` (F41#3). Road puddles excluded (3/3 judges called them flat slabs in v1/b10).
3. Unscored baselines: `capture_stormwood_f10_matrix.gd --phases=calm,break` (F41#22, F41#24) and `capture_named_fights_f10_6.gd` (F22#4, Stormwood half).
