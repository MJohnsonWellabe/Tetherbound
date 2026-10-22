# GPU pass: P2-094 placed homestead wall: REOPENED (Medium 5.53, High 5.47; defect FIXED ×2, PARTIAL ×1)

22 Oct 2026, ~02:45 CT. Remote GPU lane (owner's Windows desktop).

- **Renderer:** Forward+ on Vulkan, NVIDIA GeForce GTX 1060 3GB, 1920x1080. Medium and High were set through the tool's look-dev bootstrap.
- **Source:** origin/main 9db3d2146, unmodified (`build_wall_interior.json meshy_wall.enabled = true`, as shipped).
- **Command:** `godot --path . --rendering-method forward_plus --rendering-driver vulkan --resolution 1920x1080 --script res://tools/phase2_capture_build_systems.gd -- --biome=meadows --preset=<Medium|High> --source-commit=9db3d2146d0587d189cf172567b17345f31a0abd --output=<dir>`.
- **Judged frame:** `meadows__system__building.jpg`, the catalog's own `meadows__system__building` fixture, plus a close crop of the same frame. Both runs exit 0.

## Judging

Three fresh code-blind judges scored this in one batch with P2-018 and P2-095/096 (`judge_prompt.md`, `p2_gpu_key.json`).

**Anchor:** the committed CPU sheet `LOOK/close-1020/_sheet-F38-P2-094-r4.png`. A, the left column, is Y, the shipping r4 (CPU judges 6.73). B, the right column, is X, before.

| Set | j1/j2/j3 | Mean | Defect verdict |
|---|---|---|---|
| Anchor A, CPU r4 shipping (CPU judges 6.73) | 5.0/6.0/5.0 | 5.33 | FIXED, FIXED, PARTIAL |
| Anchor B, CPU before | 2.5/3.0/2.5 | 2.67 | PRESENT ×3 |
| **GPU Medium** | 5.4/6.2/5.0 | **5.53** | FIXED, FIXED, PARTIAL |
| **GPU High** | 5.3/6.2/4.9 | **5.47** | FIXED, FIXED, PARTIAL |

**Bar A 5.53 / 5.47, below 7.5: REOPENED.** On one scale the GPU frames sit +0.2 above the CPU r4 frames. This prompt scores the CPU anchor about 1.4 below the CPU judges.

The recorded defect is answered: the timber frame and brace, controlled infill, cap plank and separate stone footing are all there. The remaining gap is that the wall doesn't read as part of a built homestead.

## Judges' asks

1. **Material, fixable in scene:** weather the infill with grime and lower its value (it is the brightest surface in frame), and add wood grain.
2. **Grounding, fixable in scene:** add a contact decal and dirt or grass transition at the footing, and remove the stray brown plank at the left base.
3. **Context, fixable in scene:** show the module as a short snapped run with end or corner posts. A lone segment reads as an outhouse door or wardrobe.
4. **Cap, needs new art:** a thicker capping beam or shingled overhang to give a silhouette and shadow line.

Render 2 (High) also shows a small cluster of dark specks on the far bank to the right of the wall.

Sheet: `_sheet_p2_094_gpu.png` (Medium | High).

## Yardstick rejudge (22 Oct, ~12:00 CT): mapped 5.96 (Medium) / 5.94 (High), REOPENED

Batch: `anchor_tiles.py --pairs 4 --include f36_0_npc:C1`. Anchors: craft (after/before), F36#0 gap C1, F36 NPC C1, F04#6 r22. The candidates are the overnight GPU frames, Medium vs High as sides A/B (shuffled): P2-018 per biome (normal | shiny grids), the P2-095/096 craft panel, and the P2-094 wall (close + full). Three fresh judges, `JUDGE_PROMPT.md` verbatim. Calibration: linear slope 0.618, intercept 3.218, r 0.813, anchor RMSE 0.563, top anchor 7.53 (a confirming batch), no warnings, `above_top_anchor` false for every candidate. Files in `yardstick/`.

**P2-094: mapped 5.96 / 5.94** (judges 6.06/6.00/5.81 Medium), with the defect PARTIAL on all six calls: the cap and stone footing are present, but it is still a lone pale panel. **Below 7.5: REOPENED.**

The judges' asks:
- A joined, thick run of wall with corner posts.
- Darker, weathered infill.
- A grounded footing.
- Replace the faceted placeholder boulder and the painted mountain card.
- Black specks over the pond in one frame; a pink effect at the right edge.
