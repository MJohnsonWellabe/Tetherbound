# VIS-CLOUDREACH lane (tb/vis-cloudreach-1104), 4 Nov 2026

Status 4 Nov 07:20 UTC: three judged gains ON (P2-105, P2-106, P2-118; +2.99 cumulative CPU); origin/main merged (1b2386a9c) and re-imported; now on `tools/visual_judge/quick_judge.py`. Coordinator messages from this session are refused (untrusted device); this file is the channel.

CPU-only (Godot 4.7 llvmpipe, Low/Compatibility). Scores: mapped CPU Bar A via `tools/visual_judge`.

## Landing-ready flags (ON, judged CPU gain)

| Flag | Item | CPU base -> ON | Test | Commit |
|---|---|---|---|---|
| `data/config/cloudreach_physical_runtime.json:mounted_drop_no_air_drive` | F40#6 P2-105 | 4.82 -> **5.91** | `tests/test_vis_cloudreach_landed.gd` (+ `smoke_cloudreach_saddle_remount.gd` terrace leg updated, see r3b rule note) | 570c09678 |
| `data/config/cloudreach_visual.json:island_roots.low_mist` | F40#11 P2-106 | 4.97 -> **6.03** | `tests/test_vis_cloudreach_landed.gd` | 570c09678 |

| `data/config/hud.json:catch_card` (existing UIPOSES arm) | F40#18 P2-118 | 3.77 -> **4.61** | `tests/test_vis_cloudreach_landed.gd`, `tests/test_capture_readout_side.gd` (calm seal follows the card) | see log |

**Smokes (4 Nov 06:48, on the r3b tree):** `smoke_cloudreach_companion_fall` 36 checks, 0 failures. `smoke_cloudreach_saddle_remount` 331 checks, 1 failure: "a later challenge of trainer_ila_lower_ring works" (combat admission refused, the ally overlaps an arrival-route collider). It fails identically with `mounted_drop_no_air_drive` OFF, so the scramble does not cause it; whether it also fails on unmodified main is untested. The first smoke run caught the scramble firing on the survivable causeway ledge; fixed in ea8847741 (the floor probe casts past non-walkable hits and samples a ring), and the ledge checks pass.

| `data/config/hud.json:catch_card.full_team_line` (new) | F40#18 P2-118 | 3.57 -> **4.98** (merged tree, card ON in both arms) | `tests/test_vis_cloudreach_landed.gd` | see log |

P2-105/P2-106 judged together in r3b (`r3b/VERDICT.md`). **Decision for the coordinator/owner:** the scramble ends an unsurvivable mounted fall sooner than the walker's 100 m recovery (SYSTEMS §8 parity reading); survivable ride-offs are unchanged. Turning the flag off restores strict parity.

## Arms in flight (flag OFF)


| Arm | Items | State |
|---|---|---|
| `cloudreach_cause.json:enabled` (earlier cause lane) | F40#1, #4, #2, #6, #11, #7 | **Judged r1: flat or worse, stays OFF** (P2-021 5.24->5.06, P2-022 5.59->5.52, P2-023 5.41->5.16, P2-025 5.88->5.27, P2-105 4.65->4.51, P2-106 5.32->5.39; `r1/`, `r1-ride/`). `meadow_groves` + `cloud_sea` alone, quick_judge on the merged tree (`qj/qj_groves/`): F40#1 6.39 -> 6.16, F40#4 6.47 -> 6.31, F40#7 6.51 -> 6.51; stays OFF. Merged-tree CPU bases: F40#1 6.39, F40#4 6.47, F40#7 6.51 (all above 6.0). |
| `menu.json:release_choice_focus` (new) | F40#18 P2-118 | Round 2: no visible change (the scored 09-caught-banner frame is before the release ceremony opens); stays OFF. `hud.json:catch_card` judged r2b and shipped ON (above). |
| `cloudreach_npc_runtime.json:post_readability` (new) | F40#9 P2-068 | **Judged r3: flat, stays OFF** (CPU 5.16 -> 5.20; `r3/`). First CPU score for the item. |
| (baseline) F40 matrix pieces 3, 4, 7 | F40#0, #19, #21 | **First CPU subset scores (`mx1/`):** day clear 5.45, rain 4.90, night 5.05, mean 5.13 (12 of 384 frames). F40#21: no magenta/placeholder; one judge read the gate's overhanging ledge as floating. |

## Tried, no change or not judged

- `cloudreach_look.json:tree_canopy_camera_stops` (F40#6): no visible change twice (look trees, then the landing tree the probe found); **parked**; OFF (`qj/qj_canopy/`).

- `catching.json:seal_reveal` (F40#18): **worse, CPU 5.63 -> 3.33** (`qj/qj_reveal/`); the raised camera digs into the hillside. Stays OFF. Merged-tree P2-118 base with card + full-team line ON: **5.63**.

- Night moon key light via `cloudreach_visual.json` `time_overrides.night.sun` (F40#19/#0, matrix piece 7): no visible change; a later light layer overrides it (`mx2/`).

- `cloudreach_visual.json:ground_cover` clumping overlay (F40#1): no visible change at the P2-021 stands; not judged (`qj/qj_clumps/`).
- `hud.json:catch_card.full_team_line` (F40#18): the first candidate capture lost its catch to an arbitration timing refusal ("not_claimant") on the slow CPU render; the confirming rerun caught and was judged (shipped ON above).

## Handed to NEAR6-CR (coordinator, 4 Nov 07:42)

F40#9, #4, #8, #2, #17 now belong to NEAR6-CR (`tb/near6-cr-1104`). From this lane:
- **F40#8 P2-053:** `objective_beacon.json:realm_styles.cloudreach` (fdfb015a7, OFF, not captured): Cloudreach-only paler, thinner, quieter objective beacon (the cyan post judges call a debug marker). Overlay: `{"data/config/objective_beacon.json": {"realm_styles": {"cloudreach": {"enabled": true}}}}`.
- **F40#17 P2-102 (idea, not built as a flag):** night moon key light instead of ambient (ambient lifts the trainer more than the terrain). Overlay tried here but never run: `{"data/config/cloudreach_visual.json": {"time_overrides": {"night": {"sun": {"energy": 1.0, "shadow_opacity": 0.55, "colour": "#c4d4f2"}, "environment": {"ambient_colour": "#5568b4"}}}}}`.
- **F40#9 P2-068:** `post_readability` judged flat (r3, 5.16 -> 5.20); judges want NPCs unoccluded by the trainer, larger, with role props.
- **F40#4/#2:** r1 base CPU 5.41 / 5.59; F40#4 is also in this lane's running `qj_groves` round (meadow_groves + cloud_sea overlay, with F40#1/#7); merged-tree CPU base 6.47 (`qj/qj_groves/`); the groves arm is worse there (6.31).

## Harness fixes

- `tools/phase2_capture_catch.gd`: a pickup ("Take ...") holding the interact offer beside the wild is taken first (the GPU item-score blocker for P2-117/P2-118 at the Cloudreach arrival road).

## Blockers

None.
