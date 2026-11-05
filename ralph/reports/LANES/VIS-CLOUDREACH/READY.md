# VIS-CLOUDREACH lane (tb/vis-cloudreach-1104), 4 Nov 2026

Status 4 Nov 23:05 UTC: eight judged gains ON (P2-105 x3, P2-106 x2, P2-118 x3; +8.41 cumulative CPU mapped); origin/main merged (1b2386a9c); on `tools/visual_judge/quick_judge.py`. Coordinator messages from this session are refused (untrusted device); this file is the channel.

**Handoff (20:10).** Branch head is landing-ready: every ON flag below has its CPU score in `_why_on` and an assertion in `tests/test_vis_cloudreach_landed.gd` (7 tests pass; `test_texture_import_policy.gd` passes; `smoke_cloudreach_saddle_remount` 331 checks, only the known `trainer_ila_lower_ring` failure, which also fails with the scramble OFF). Current CPU mapped: P2-105 6.10 (from 4.82), P2-106 6.43 (from 4.97), P2-118 4.98 (from 3.77). **Open / parked:** F40#1 lawn carpet parked (groves flat, clumps invisible, cluster -0.31); dark terrace oval parked (two no-change arms; next idea in the table); F40#18 blocked on the catch capture's unpinned spawn (harness gap below); F40#21 near-clean on the mx1 subset (one judge in three read the gate ledge as floating). **Remaining judge asks on P2-105/106:** flat, ungraded day sky (shared Cloudreach sky; a light-grade arm was flat/worse in r1, so it needs a new idea and touches NEAR6-CR's items), cart on the layby slope with a weak contact shadow, deer and rider small from behind. **Runbook:** `QJ_LANE=VIS-CLOUDREACH python3 tools/visual_judge/quick_judge.py run F40#11 --overlay '<json>'` (~35-60 min); ride frames need a manual 2x2 pair (frames 16/17/18_after/19) via `anchor_tiles.py --candidates spec.json --pairs 3 --include craft`, three judges, `calibrate.py`; quick_judge leaves its overlay in the config file mid-run, so never commit during a capture.

CPU-only (Godot 4.7 llvmpipe, Low/Compatibility). Scores: mapped CPU Bar A via `tools/visual_judge`.

## Landing-ready flags (ON, judged CPU gain)

| Flag | Item | CPU base -> ON | Test | Commit |
|---|---|---|---|---|
| `data/config/cloudreach_physical_runtime.json:mounted_drop_no_air_drive` | F40#6 P2-105 | 4.82 -> **5.91** | `tests/test_vis_cloudreach_landed.gd` (+ `smoke_cloudreach_saddle_remount.gd` terrace leg updated, see r3b rule note) | 570c09678 |
| `data/config/cloudreach_visual.json:island_roots.low_mist` | F40#11 P2-106 | 4.97 -> **6.03** | `tests/test_vis_cloudreach_landed.gd` | 570c09678 |

| `data/config/hud.json:catch_card` (existing UIPOSES arm) | F40#18 P2-118 | 3.77 -> **4.61** | `tests/test_vis_cloudreach_landed.gd`, `tests/test_capture_readout_side.gd` (calm seal follows the card) | see log |

**Smokes (4 Nov 06:48, on the r3b tree):** `smoke_cloudreach_companion_fall` 36 checks, 0 failures. `smoke_cloudreach_saddle_remount` 331 checks, 1 failure: "a later challenge of trainer_ila_lower_ring works" (combat admission refused, the ally overlaps an arrival-route collider). It fails identically with `mounted_drop_no_air_drive` OFF, so the scramble does not cause it; whether it also fails on unmodified main is untested. The first smoke run caught the scramble firing on the survivable causeway ledge; fixed in ea8847741 (the floor probe casts past non-walkable hits and samples a ring), and the ledge checks pass.

| `data/config/hud.json:catch_card.full_team_line` (new) | F40#18 P2-118 | 3.57 -> **4.98** (merged tree, card ON in both arms) | `tests/test_vis_cloudreach_landed.gd` | see log |
| `data/config/cloudreach_visual.json:landing_tree_clear` (new) | F40#6 P2-105 | 3.68 -> **5.28** (+1.60; base had the camera inside LandingTree171 on the road-back frame; `tc/VERDICT.md`) | `tests/test_vis_cloudreach_landed.gd` | see log |
| `cloudreach_physical_runtime.json:mounted_drop_no_air_drive.scramble_after_s` 0.7 -> 0.3 | F40#6 P2-105 | 4.38 -> **6.10** (+1.72; floating mount FIXED 3/3; `sc/VERDICT.md`) | `tests/test_vis_cloudreach_landed.gd`, `smoke_cloudreach_saddle_remount.gd` unchanged: 15:20 run, terrace scramble at 5.8 m PASS, ledge legs PASS, 331 checks with the one known `trainer_ila_lower_ring` failure | see log |
| `cloudreach_visual.json:island_roots.mist_core_alpha` 0.62 -> 0.45 + `low_mist.mist_below_m` 170 -> 260 | F40#11 P2-106 | 6.00 -> **6.43** (+0.43; puff defect PRESENT -> PARTIAL 3/3; `mt/VERDICT.md`) | `tests/test_vis_cloudreach_landed.gd` | see log |
| `hud.json:catch_card.portrait` (new) | F40#18 P2-118 | 5.91 -> **6.19** (+0.28 on the pinned catch capture; `qj/qj_portrait2c`) | `tests/test_vis_cloudreach_landed.gd` | see log |

P2-105/P2-106 judged together in r3b (`r3b/VERDICT.md`). **Decision for the coordinator/owner:** the scramble ends an unsurvivable mounted fall sooner than the walker's 100 m recovery (SYSTEMS §8 parity reading); survivable ride-offs are unchanged. Turning the flag off restores strict parity.

## Arms in flight (flag OFF)

**F40#14 P2-048 (coordinator item 2, 20:50):** no new arm needed. `menu.json:map_region_header` already ships ON with GPU batch 5 (2 Nov) mapped **7.01 -> 7.52** for P2-048 (the 5.87 in the brief is the 28 Oct score from before that arm). The board row needs the GPU High+Medium confirm, not more lane work.

**F40#18 harness fix (20:12, coordinator-directed, commit 564c65f9e):** in Cloudreach, `phase2_capture_catch.gd --seed` now picks the wild species (`pinned_wild()`: skyrill / galecrest / pebbik by seed), places it with `EncounterDirector.spawn_wild` at a fixed arrival-terrace spot (-4, -254), level 30, no wander, and re-seeds the combat manager's catch roll per throw from (seed, throw index). Unit check `tests/test_capture_catch_pinned_wild.gd` (2 tests pass). Follow-up 14b91bd32: the director builds its arbiter lazily, so the capture now builds it first, then widens it (the first attempt never applied; logs now print `arbiter window 600000 ms`). Portrait judged and shipped (5.91 -> 6.19). Previous note: **Harness gap (F40#18):** `phase2_capture_catch.gd --seed=2042` does not fix the wild spawn or the catch outcome across trees: three Cloudreach catch rounds today paired different species (Galecrest/Skyrill/Pebbik) at different spots, and one round never reached the caught banner. A/B on the catch frame is confounded until the spawn is pinned; this lane is not fixing the harness (CRITERION_DELIVERY) and has moved off P2-118.


| Arm | Items | State |
|---|---|---|
| `cloudreach_cause.json:enabled` (earlier cause lane) | F40#1, #4, #2, #6, #11, #7 | **Judged r1: flat or worse, stays OFF** (P2-021 5.24->5.06, P2-022 5.59->5.52, P2-023 5.41->5.16, P2-025 5.88->5.27, P2-105 4.65->4.51, P2-106 5.32->5.39; `r1/`, `r1-ride/`). `meadow_groves` + `cloud_sea` alone, quick_judge on the merged tree (`qj/qj_groves/`): F40#1 6.39 -> 6.16, F40#4 6.47 -> 6.31, F40#7 6.51 -> 6.51; stays OFF. Merged-tree CPU bases: F40#1 6.39, F40#4 6.47, F40#7 6.51 (all above 6.0). |
| `cloudreach_open_terrain_candidate.json:enabled` (existing, unjudged) | F40#1 P2-021 | quick_judge `qj_openterrain` (15:40): no visible change at the sky shrine or realm gate (a few mid-ground rocks shift; the lawn reads the same). Not judged; stays OFF. The flat-lawn ask is parked for this lane after three misses (groves flat, clumps invisible, `cloudreach_ground_cluster` judged -0.31 in CLOUD-JUDGE BATCH4). |
| `hud.json:catch_card.portrait` (new) | F40#18 P2-118 (lowest owned item, 4.98) | The caught species' installed portrait at the card's left edge. **Judged `qj/qj_portrait`: 5.29 -> 3.14, stays OFF** (confounded: the candidate's random spawn put the post-catch camera inside a grass slope; no judge faulted the portrait). Next: the post-catch camera in terrain. |
| `catching.json:resolve_clearance` (new) | F40#18 P2-118 | The catch resolve shot picks a pose (steeper pitch, then yaw swings) whose SpringArm keeps 85% of its length free, so the result card never plays over a camera collapsed into turf (all three `qj_portrait` judges' first ask). quick_judge `qj_resolveclear` (17:50): **inconclusive, not judged, stays OFF**; re-run on the pinned capture `qj_resolveclear3` (23:55): both sides caught the same pebbik with zero `not_claimant` (arbiter window widened, commit 14b91bd32) and the 09 frames match: the pinned flat spot never blocks the arm, so the arm has nothing to change there. **No visible change, not judged, stays OFF** (it only acts on a slope): both sides' catches broke free (no 09-caught-banner frame) and spawned different species (Skyrill vs Pebbik); the 04/08 frames show no clear camera difference. |
| `cloudreach_visual.json:ground_cover.grass_role_edge_feather` (new, 0 = off) | F40#11 P2-106 | Dithers the hard radius edge of the grass role cells. quick_judge `qj_feather` (19:20, 0.14): **no visible change**; the dark terrace oval the mt judges flagged is not a role cell. Not judged; stays 0. A probe of the geometry at the terrace road is running to find what draws the oval. |
| `cloudreach_visual.json:landing_cover_clear` (new) | F40#11 P2-106 | Skips a route landing's own grass ellipse (probe: `CoverPatch094`, 469 tufts at (1.2, 105.5, -260.1), over region patch 037). quick_judge `qj_landcover` (20:00): **no visible change**; the dark oval stays. Not judged; stays OFF. **Dark terrace oval parked** after two misses (role-cell feather, landing ellipse); candidates left for whoever picks it up: `CloudreachLook/LookGroundCoverFinish/CoverFinishMain037` (247 instances over 32 x 34 m) or a turf-material patch, found by toggling each in a probe frame. |
| `cloudreach_f40_items.json:candidates[0]` stone-trail stand candidate (new) | F40#1 P2-021 | Flat path stones and low rock edging along the six shrine and gate stands. `qj/qj_stonetrail` (00:30): 5.68 -> 5.86, **flat** (inside anchor RMSE 0.64, judges split 2-1, read as a generated rubble heap). Stays OFF; **F40#1 parked** per the coordinator. Judges' ask is new art: layered pale-stone shelves and terrace edges at the stands, and hide the island soil skirt. |
| `menu.json:release_choice_focus` (new) | F40#18 P2-118 | Round 2: no visible change (the scored 09-caught-banner frame is before the release ceremony opens); stays OFF. `hud.json:catch_card` judged r2b and shipped ON (above). |
| `cloudreach_npc_runtime.json:post_readability` (new) | F40#9 P2-068 | **Judged r3: flat, stays OFF** (CPU 5.16 -> 5.20; `r3/`). First CPU score for the item. |
| (baseline) F40 matrix pieces 3, 4, 7 | F40#0, #19, #21 | **First CPU subset scores (`mx1/`):** day clear 5.45, rain 4.90, night 5.05, mean 5.13 (12 of 384 frames). F40#21: no magenta/placeholder; one judge read the gate's overhanging ledge as floating. |

## Tried, no change or not judged

- `cloudreach_look.json:tree_canopy_camera_stops` (F40#6): no visible change twice (look trees, then the landing tree the probe found); **parked**; OFF (`qj/qj_canopy/`).

- `catching.json:seal_reveal` (F40#18): **worse, CPU 5.63 -> 3.33** (`qj/qj_reveal/`); the raised camera digs into the hillside. Stays OFF. Merged-tree P2-118 base with card + full-team line ON: **5.63**.

- Night moon key light via `cloudreach_visual.json` `time_overrides.night.sun` (F40#19/#0, matrix piece 7): no visible change; a later light layer overrides it (`mx2/`).

- `cloudreach_visual.json:ground_cover` clumping overlay (F40#1): no visible change at the P2-021 stands; not judged (`qj/qj_clumps/`).
- `hud.json:catch_card.full_team_line` (F40#18): the first candidate capture lost its catch to an arbitration timing refusal ("not_claimant") on the slow CPU render; the confirming rerun caught and was judged (shipped ON above).

## Handed to NEAR6-CR

**4 Nov 14:12:** F40#19 night and rain (mx1 pieces 4 and 7; the night light layer that overrides `time_overrides`, see `mx2/`) also go to NEAR6-CR. This lane keeps F40#0 (re-score), F40#1 (open terrain), F40#21 (cleanliness), F40#6, #11, #18.

**4 Nov 07:42:**

F40#9, #4, #8, #2, #17 now belong to NEAR6-CR (`tb/near6-cr-1104`). From this lane:
- **F40#8 P2-053:** `objective_beacon.json:realm_styles.cloudreach` (fdfb015a7, OFF, not captured): Cloudreach-only paler, thinner, quieter objective beacon (the cyan post judges call a debug marker). Overlay: `{"data/config/objective_beacon.json": {"realm_styles": {"cloudreach": {"enabled": true}}}}`.
- **F40#17 P2-102 (idea, not built as a flag):** night moon key light instead of ambient (ambient lifts the trainer more than the terrain). Overlay tried here but never run: `{"data/config/cloudreach_visual.json": {"time_overrides": {"night": {"sun": {"energy": 1.0, "shadow_opacity": 0.55, "colour": "#c4d4f2"}, "environment": {"ambient_colour": "#5568b4"}}}}}`.
- **F40#9 P2-068:** `post_readability` judged flat (r3, 5.16 -> 5.20); judges want NPCs unoccluded by the trainer, larger, with role props.
- **F40#4/#2:** r1 base CPU 5.41 / 5.59; F40#4 is also in this lane's running `qj_groves` round (meadow_groves + cloud_sea overlay, with F40#1/#7); merged-tree CPU base 6.47 (`qj/qj_groves/`); the groves arm is worse there (6.31).

## Harness fixes

- `tools/phase2_capture_catch.gd`: a pickup ("Take ...") holding the interact offer beside the wild is taken first (the GPU item-score blocker for P2-117/P2-118 at the Cloudreach arrival road).

## Blockers

None.
