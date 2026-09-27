# F10#4 capture context (lane lead only; do not show to the judge)

## Build and runs
- Tool commit: tb/vis `f0d278c62c416abb6ecdc7b12d39fc0c21babf21` (merge of origin/main `4316362e26ed78589551ccf61de9c66974bc91c6` plus the VIS capture-tool edit). No game code differs from main; `git diff origin/main f0d278c6 -- scripts data scenes assets` is empty apart from VIS reports and the tool.
- Tool edit (this task): `tools/capture_visual_audit.gd` gains `--flags=a,b` (extra story flags set on Game.progression before the scene is instanced; logged as a manifest note) and `--times=a,b` (overrides every row's times/phases). Existing behaviour is unchanged when both are absent. A headless parse check passed locally.
- Run A (before victory): render.yml run 36310761889, artifact render-f10-4-storm-pre-36310761889 (id 10929443446). 39 frames, 0 skips.
  args: `--section=region --region=stormwood --times=calm,building,break --only=env_cinder_verge_0,env_glowmoss_hollows_0,env_glowmoss_hollows_1,env_conductor_run_1,env_deepwood_0,env_dynamo_0,env_cinder_verge_1,env_conductor_run_0,place_verge_rod_station,place_hollows_rod_station,place_deepwood_rod_station,place_dynamo_outer_works,place_rodline_post`
  Flags: the spec defaults only, `realm_key_stormwood` and `stormwood:rootgate_released`.
- Run B (after victory): render.yml run 36310774685, artifact render-f10-4-storm-after-36310774685 (id 10929482117). 20 frames, 0 skips.
  args: `--section=region --region=stormwood --variant=aftermath --times=calm,break --only=<the 8 env ids above>,place_verge_rod_station,place_dynamo_outer_works --flags=<below>`
  Flags: the spec defaults, plus `stormwood:long_storm_ended` (from `--variant=aftermath`), plus 42 flags. The 42 are every main-path `flag_id` and `grants_flags` in data/config/stormwood_chapter.json, and each rod station's guard-defeat and `rod_*_disabled` flag from stormwood_rod_stations.json. Side-quest `side_*` flags are left out.
  `stormwood:chapter_started,stormwood:crisis_learned,stormwood:first_break_witnessed,stormwood:first_stormglass_gathered,stormwood:ashfoot_arch_relit,stormwood:lantern_pools_linked,stormwood:lower_rods_disabled,stormwood:rodline_linked,stormwood:bryn_met,stormwood:act_i_complete,stormwood:varga_defeated,stormwood:arch_recipe_known,stormwood:crown_glass_gathered,stormwood:crown_arch_built,stormwood:crown_reached,stormwood:engine_truth_learned,stormwood:rootgate_released,stormwood:act_ii_complete,stormwood:lantern_hollow_reached,stormwood:captive_truth_learned,stormwood:deepwood_station_disabled,stormwood:all_rods_disabled,stormwood:ember_bivouac_reached,stormwood:kestrel_defeated,stormwood:core_reached,stormwood:marrow_defeated,stormwood:legendary_freed,realm_heart_stormwood_earned,stormwood:long_storm_ended,stormwood:legendary_offer_made,stormwood:waterward_revealed,realm_key_water,waterward_route_revealed,stormwood:chapter_complete,stormwood:trainer:officer_maren_verge_rod:defeated,stormwood:rod_verge_disabled,stormwood:trainer:lieutenant_dace_hollows_rod:defeated,stormwood:rod_hollows_disabled,stormwood:trainer:officer_nysa_deepwood_rod:defeated,stormwood:rod_deepwood_disabled,stormwood:trainer:outerworks_lieutenant_sera:defeated,stormwood:rod_dynamo_disabled`
- Both runs: mode=render (xvfb + opengl3, Compatibility), 1920x1080, dispatched on main with checkout_ref as above.
- Raw artifacts (all 59 frames, manifests, tool sheets): /tmp/claude-0/-home-user-Tetherbound/17284e0f-c457-5bb8-96a5-6e50038613d5/scratchpad/pre and /tmp/claude-0/-home-user-Tetherbound/17284e0f-c457-5bb8-96a5-6e50038613d5/scratchpad/after.

## Frame map
| id | group | phase | state | source file | feet (x,y,z) | yaw deg | target dist m | companion |
|---|---|---|---|---|---|---|---|---|
| F01 | forest | calm | before | pre/001_stormwood_env_cinder_verge_0_calm.png | [-320.0, 31.5, 240.0] | 151.9 | 603.1 | terrapup |
| F02 | forest | break | before | pre/003_stormwood_env_cinder_verge_0_break.png | [-320.0, 31.5, 240.0] | 151.9 | 603.1 | terrapup |
| F03 | forest | calm | before | pre/007_stormwood_env_glowmoss_hollows_0_calm.png | [-380.0, 33.8, 1400.0] | -137.0 | 792.5 | terrapup |
| F04 | forest | break | before | pre/009_stormwood_env_glowmoss_hollows_0_break.png | [-380.0, 33.8, 1400.0] | -137.0 | 792.5 | terrapup |
| F05 | forest | calm | before | pre/010_stormwood_env_glowmoss_hollows_1_calm.png | [160.0, 27.3, 1980.0] | 110.4 | 917.6 | terrapup |
| F06 | forest | break | before | pre/012_stormwood_env_glowmoss_hollows_1_break.png | [160.0, 27.3, 1980.0] | 110.4 | 917.6 | terrapup |
| F07 | forest | calm | before | pre/016_stormwood_env_conductor_run_1_calm.png | [-1080.0, 78.1, 3020.0] | -78.3 | 1571.9 | terrapup |
| F08 | forest | break | before | pre/018_stormwood_env_conductor_run_1_break.png | [-1080.0, 78.1, 3020.0] | -78.3 | 1571.9 | terrapup |
| F09 | forest | calm | before | pre/019_stormwood_env_deepwood_0_calm.png | [-450.0, 57.5, 3960.0] | -157.4 | 545.6 | terrapup |
| F10 | forest | break | before | pre/021_stormwood_env_deepwood_0_break.png | [-450.0, 57.5, 3960.0] | -157.4 | 545.6 | terrapup |
| F11 | forest | calm | before | pre/022_stormwood_env_dynamo_0_calm.png | [-310.0, 65.3, 5050.0] | -153.4 | 469.6 | terrapup |
| F12 | forest | break | before | pre/024_stormwood_env_dynamo_0_break.png | [-310.0, 65.3, 5050.0] | -153.4 | 469.6 | terrapup |
| F13 | rod line | calm | before | pre/004_stormwood_env_cinder_verge_1_calm.png | [-604.0, 24.9, 772.0] | 141.6 | 90.0 | terrapup |
| F14 | rod line | calm | before | pre/025_stormwood_place_verge_rod_station_calm.png | [-627.2, 22.4, 917.2] | 14.6 | 90.2 | parked behind camera |
| F15 | rod line | building | before | pre/029_stormwood_place_hollows_rod_station_building.png | [-868.1, 27.4, 1862.9] | 21.0 | 88.8 | parked behind camera |
| F16 | rod line | calm | before | pre/031_stormwood_place_rodline_post_calm.png | [-645.0, 54.6, 2370.7] | 37.9 | 89.6 | parked behind camera |
| F17 | rod line | break | before | pre/036_stormwood_place_deepwood_rod_station_break.png | [-845.5, 49.3, 4567.2] | 29.9 | 89.1 | parked behind camera |
| F18 | rod line | calm | before | pre/037_stormwood_place_dynamo_outer_works_calm.png | [-151.3, 104.4, 5276.7] | -145.0 | 89.5 | parked behind camera |
| F19 | sky-after-victory | calm | after | after/001_stormwood_env_cinder_verge_0_calm.png | [-320.0, 31.5, 240.0] | 151.9 | 603.1 | terrapup |
| F20 | sky-after-victory | break | after | after/002_stormwood_env_cinder_verge_0_break.png | [-320.0, 31.5, 240.0] | 151.9 | 603.1 | terrapup |
| F21 | sky-after-victory | calm | after | after/005_stormwood_env_glowmoss_hollows_0_calm.png | [-380.0, 33.8, 1400.0] | -137.0 | 792.5 | terrapup |
| F22 | sky-after-victory | calm | after | after/013_stormwood_env_deepwood_0_calm.png | [-450.0, 57.5, 3960.0] | -157.4 | 545.6 | terrapup |
| F23 | sky-after-victory | calm | after | after/015_stormwood_env_dynamo_0_calm.png | [-310.0, 65.3, 5050.0] | -153.4 | 469.6 | terrapup |
| F24 | sky-after-victory | calm | after | after/017_stormwood_place_verge_rod_station_calm.png | [-627.2, 22.4, 917.2] | 14.6 | 90.2 | parked behind camera |

Stand key: S1 Struck Sentinel (-320,240); S2 Lantern Pools (-380,1400); S3 Crown Overlook (160,1980); S4 Capacitor Grove (-1080,3020); S5 Lantern Hollow (-450,3960); S6 Glass Field (-310,5050), which are debug_teleport_spots.json stands looking toward the next spot. R1 Verge Rod Station env stand (-604,772, heading -38.4); R2 to R6 are the tool's road-approach stands about 90 m from verge_rod_station (-650,830), hollows_rod_station (-900,1780), rodline_post (-700,2300), deepwood_rod_station (-890,4490) and dynamo_outer_works (-100,5350, where the dynamo approach rod station also stands).

## Shortcuts and limitations
- Stormwood has no day/night look (owner ruling WO-F10-08, storm_base pin_time_of_day). The brief asked for day/dusk/night, so the captures use the Surge phases calm/building/break instead, pinned through the tool's `_stormwood_phase` hook (it writes realm_environment.stormwood.elapsed and calls settle_presentation). In the after-victory state the phases run on the aftermath_seconds timings.
- The after-victory state is built from flags. Nobody played the finale. The session starts fresh (reset_for_new_game), and the party is the tool default (terrapup active). No legendary joins the party.
- The before-victory state is the mid-chapter state (Rootgate released, no rods disabled). It is not the moment just before the Stormheart fight. The rod stations therefore show their active pre-disable state in F13 to F18, and their disabled state in F24.
- The tool pauses the encounter director after the companion summons (a disclosed fixture), and the companion is pinned beside the trainer on env rows. Place rows (R2 to R6) park the companion behind the camera. On env rows the terrapup fills a large part of the frame.
- The HUD (CanvasLayers) is hidden. No dialogue was closed in any frame (closed_dialogue empty).
- Not captured: building phase for most stands, fading phase, the aftermath 'building' phase, and the Dynamo core and Stormheart Tree itself (not in scope). Audio and motion are not part of this set; lightning flashes are single stills.
- Frames not used from the runs: building-phase forest frames, env_conductor_run_0 (Rodline Post env), and after-victory frames for S3, S4, R1 and R6 and for break at most stands. All are available in the raw artifacts.
