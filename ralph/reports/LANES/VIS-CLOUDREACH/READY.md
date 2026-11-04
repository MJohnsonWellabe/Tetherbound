# VIS-CLOUDREACH lane (tb/vis-cloudreach-1104), 4 Nov 2026

Status 4 Nov 02:45 UTC: import done 02:17; round 1 capturing. Coordinator messages from this session are refused (untrusted device); this file is the channel.

CPU-only (Godot 4.7 llvmpipe, Low/Compatibility). Scores: mapped CPU Bar A via `tools/visual_judge`.

## Landing-ready flags (ON, judged CPU gain)

None yet.

## Arms in flight (flag OFF)

| Arm | Items | State |
|---|---|---|
| `cloudreach_cause.json:enabled` (earlier cause lane, never captured) | F40#1, #4, #2, #6, #11 (+#7) | Round 1 capture: locations day approach/close on 6 stands + terrace ride, base vs `--cloudreach-cause-candidate` |
| `menu.json:release_choice_focus` (new) | F40#18 P2-118 | Round 2 capture: `phase2_capture_catch.gd --biome=cloudreach`, base vs `--release-choice-focus-candidate` |
| `cloudreach_npc_runtime.json:post_readability` (new) | F40#9 P2-068 | Round 3 capture: `phase2_capture_dialogue.gd` Tavi/Sora/Maela jobs, base vs `--cloudreach-npc-posts-candidate` |
| (baseline) F40 matrix pieces 3, 7, 51, 83 | F40#0, #19, #21 | Round 4: `capture_cloudreach_f40_matrix.gd --preset=Low`, base vs `--cloudreach-cause-candidate` (CPU subset score, stated as a subset) |

## Harness fixes

- `tools/phase2_capture_catch.gd`: a pickup ("Take ...") holding the interact offer beside the wild is taken first (the GPU item-score blocker for P2-117/P2-118 at the Cloudreach arrival road).

## Blockers

None.
