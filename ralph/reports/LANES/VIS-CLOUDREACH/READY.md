# VIS-CLOUDREACH lane (tb/vis-cloudreach-1104), 4 Nov 2026

Status 4 Nov 05:05 UTC: round 1 judged (cause arm OFF); rounds 2/3/3b capturing my arms; then merge main and quick_judge. Coordinator messages from this session are refused (untrusted device); this file is the channel.

CPU-only (Godot 4.7 llvmpipe, Low/Compatibility). Scores: mapped CPU Bar A via `tools/visual_judge`.

## Landing-ready flags (ON, judged CPU gain)

| Flag | Item | CPU base -> ON | Test | Commit |
|---|---|---|---|---|
| `data/config/cloudreach_physical_runtime.json:mounted_drop_no_air_drive` | F40#6 P2-105 | 4.82 -> **5.91** | `tests/test_vis_cloudreach_landed.gd` (+ `smoke_cloudreach_saddle_remount.gd` terrace leg updated, see r3b rule note) | 570c09678 |
| `data/config/cloudreach_visual.json:island_roots.low_mist` | F40#11 P2-106 | 4.97 -> **6.03** | `tests/test_vis_cloudreach_landed.gd` | 570c09678 |

Judged together in r3b (`r3b/VERDICT.md`). **Decision for the coordinator/owner:** the scramble ends an unsurvivable mounted fall sooner than the walker's 100 m recovery (SYSTEMS §8 parity reading); survivable ride-offs are unchanged. Turning the flag off restores strict parity.

## Arms in flight (flag OFF)

| Arm | Items | State |
|---|---|---|
| `cloudreach_cause.json:enabled` (earlier cause lane) | F40#1, #4, #2, #6, #11, #7 | **Judged r1: flat or worse, stays OFF** (P2-021 5.24->5.06, P2-022 5.59->5.52, P2-023 5.41->5.16, P2-025 5.88->5.27, P2-105 4.65->4.51, P2-106 5.32->5.39; `r1/`, `r1-ride/`). Round 3c retries its `meadow_groves` + `cloud_sea` parts alone. |
| `menu.json:release_choice_focus` (new) | F40#18 P2-118 | Round 2: no visible change (the scored 09-caught-banner frame is before the release ceremony opens); stays OFF. Round 2b captures the existing `hud.json:catch_card` arm (`--catch-card-candidate`) on that frame. |
| `cloudreach_npc_runtime.json:post_readability` (new) | F40#9 P2-068 | **Judged r3: flat, stays OFF** (CPU 5.16 -> 5.20; `r3/`). First CPU score for the item. |
| (baseline) F40 matrix pieces 3, 7, 51, 83 | F40#0, #19, #21 | Round 4: `capture_cloudreach_f40_matrix.gd --preset=Low`, base vs `--cloudreach-cause-candidate` (CPU subset score, stated as a subset) |

## Harness fixes

- `tools/phase2_capture_catch.gd`: a pickup ("Take ...") holding the interact offer beside the wild is taken first (the GPU item-score blocker for P2-117/P2-118 at the Cloudreach arrival road).

## Blockers

None.
