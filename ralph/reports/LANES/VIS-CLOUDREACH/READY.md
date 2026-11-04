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

P2-105/P2-106 judged together in r3b (`r3b/VERDICT.md`). **Decision for the coordinator/owner:** the scramble ends an unsurvivable mounted fall sooner than the walker's 100 m recovery (SYSTEMS §8 parity reading); survivable ride-offs are unchanged. Turning the flag off restores strict parity.

## Arms in flight (flag OFF)

| Arm | Items | State |
|---|---|---|
| `cloudreach_cause.json:enabled` (earlier cause lane) | F40#1, #4, #2, #6, #11, #7 | **Judged r1: flat or worse, stays OFF** (P2-021 5.24->5.06, P2-022 5.59->5.52, P2-023 5.41->5.16, P2-025 5.88->5.27, P2-105 4.65->4.51, P2-106 5.32->5.39; `r1/`, `r1-ride/`). Round 3c retries its `meadow_groves` + `cloud_sea` parts alone. |
| `menu.json:release_choice_focus` (new) | F40#18 P2-118 | Round 2: no visible change (the scored 09-caught-banner frame is before the release ceremony opens); stays OFF. `hud.json:catch_card` judged r2b and shipped ON (above). |
| `cloudreach_npc_runtime.json:post_readability` (new) | F40#9 P2-068 | **Judged r3: flat, stays OFF** (CPU 5.16 -> 5.20; `r3/`). First CPU score for the item. |
| (baseline) F40 matrix pieces 3, 7, 51, 83 | F40#0, #19, #21 | Round 4: `capture_cloudreach_f40_matrix.gd --preset=Low`, base vs `--cloudreach-cause-candidate` (CPU subset score, stated as a subset) |

## Harness fixes

- `tools/phase2_capture_catch.gd`: a pickup ("Take ...") holding the interact offer beside the wild is taken first (the GPU item-score blocker for P2-117/P2-118 at the Cloudreach arrival road).

## Blockers

None.
