# VIS-CLOUDREACH lane (tb/vis-cloudreach-1104), 4 Nov 2026

Status 4 Nov 05:05 UTC: round 1 judged (cause arm OFF); rounds 2/3/3b capturing my arms; then merge main and quick_judge. Coordinator messages from this session are refused (untrusted device); this file is the channel.

CPU-only (Godot 4.7 llvmpipe, Low/Compatibility). Scores: mapped CPU Bar A via `tools/visual_judge`.

## Landing-ready flags (ON, judged CPU gain)

None yet.

## Arms in flight (flag OFF)

| Arm | Items | State |
|---|---|---|
| `cloudreach_cause.json:enabled` (earlier cause lane) | F40#1, #4, #2, #6, #11, #7 | **Judged r1: flat or worse, stays OFF** (P2-021 5.24->5.06, P2-022 5.59->5.52, P2-023 5.41->5.16, P2-025 5.88->5.27, P2-105 4.65->4.51, P2-106 5.32->5.39; `r1/`, `r1-ride/`). Round 3c retries its `meadow_groves` + `cloud_sea` parts alone. |
| `cloudreach_physical_runtime.json:mounted_drop_no_air_drive` (new) + `cloudreach_visual.json:island_roots.low_mist` (new) | F40#6 P2-105, F40#11 P2-106 | Round 3b ride capture with both flags (CPU base 4.65 / 5.32 from r1) |
| `menu.json:release_choice_focus` (new) | F40#18 P2-118 | Round 2 capture: `phase2_capture_catch.gd --biome=cloudreach`, base vs `--release-choice-focus-candidate` |
| `cloudreach_npc_runtime.json:post_readability` (new) | F40#9 P2-068 | Round 3 capture: `phase2_capture_dialogue.gd` Tavi/Sora/Maela jobs, base vs `--cloudreach-npc-posts-candidate` |
| (baseline) F40 matrix pieces 3, 7, 51, 83 | F40#0, #19, #21 | Round 4: `capture_cloudreach_f40_matrix.gd --preset=Low`, base vs `--cloudreach-cause-candidate` (CPU subset score, stated as a subset) |

## Harness fixes

- `tools/phase2_capture_catch.gd`: a pickup ("Take ...") holding the interact offer beside the wild is taken first (the GPU item-score blocker for P2-117/P2-118 at the Cloudreach arrival road).

## Blockers

None.
