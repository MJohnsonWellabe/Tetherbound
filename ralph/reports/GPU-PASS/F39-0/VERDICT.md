# GPU pass: F39#0 Tidewake recapture at Medium: 240/240 frames delivered, landscape rows rescored, no row at 7.5

22 Oct 2026, ~01:30 CT. Remote GPU lane (owner's Windows desktop).

F39#0: "After F26 look-dev, the biome is re-captured (≥200 frames) and its catalog rows re-scored against the new bar." The CPU closure (`RECAP-TIDEWAKE/close-1020/NOTE.md`) disclosed Low/llvmpipe as a substitute and owed a High/Medium GPU pass. This is that pass.

## Recapture

- **Renderer:** Forward+ on Vulkan, NVIDIA GeForce GTX 1060 3GB, **Medium** preset, 1920x1080.
- **Graphics fields:** the tool's own look-dev bootstrap wrote `graphics_capture` with `preset Medium`, `renderer forward_plus` and `adapter NVIDIA GeForce GTX 1060 3GB`.
- **Source:** origin/main 9db3d2146, unmodified.
- **Command** (one per segment, `t` = day, night): `godot --path . --rendering-method forward_plus --rendering-driver vulkan --resolution 1920x1080 --script res://tools/capture_f39_catalogue.gd -- --biome=water --times=$t --preset=Medium --source-commit=9db3d2146d0587d189cf172567b17345f31a0abd --seed=2042 --f39-weather=clear --output=<dir>`. This is the CPU command with the GPU renderer and the Medium preset.
- **Frames:** **240** (120 day + 120 night), 240 unique SHA-256. The list is in `gpu-frame-manifest.json`; frames stay local. Both tool manifests report `complete=true` with no failures. Both segments took about 5 minutes; there were no allocation errors.
- **Destination 10 (Tidal Cradle Saddle Camp):** the CPU run's walkability guard refused it twice. It captured on this source, so all 24 authored destinations × 5 headings × day/night are present.

## Rescore

Three fresh code-blind judges scored two sets in one batch on one scale:
- **Set S:** the 12 GPU survey sheets, each four destinations × five headings, plus the full frames.
- **Set X:** the committed CPU anchor `_sheet_f39_recapture_heading0.jpg`.

They rescored the 11 catalog rows whose evidence is the landscape survey (the CPU "pass 1" rows), each against its recorded defect (`judge_prompt.md`, `row-scores-gpu.json`).

| Row | Subject | GPU S j1/j2/j3 | GPU mean | Verdicts | CPU anchor sheet, same judges | CPU row mean (CPU judges) |
|---|---|---|---|---|---|---|
| P2-055 | named character silhouettes | 6.0/6.0/6.0 | **6.00** | IMPROVED ×3 | 5.0 (one judge; two NOT_PICTURED) | 4.08 |
| P2-057 | grass around named characters | 6.0/6.0/5.5 | **5.83** | IMPROVED ×3 | 5.5 (one judge) | 4.83 |
| P2-009 | water and island depth | 5.0/6.5/5.5 | **5.67** | IMPROVED ×3 | 3.77 (PRESENT ×3) | 5.67 |
| P2-004 | exploration HUD | 6.0/5.5/5.0 | **5.50** | IMPROVED ×2, PRESENT ×1 | 5.33 | 5.58 |
| P2-010 | Veilfall silhouette | 5.0/6.0/5.3 | **5.43** | IMPROVED ×3 | 4.67 | 3.67 |
| P2-008 | shore landforms | 5.0/4.5/5.0 | **4.83** | IMPROVED ×3 | 4.27 | 5.00 |
| P2-033 | ground pickup identity | 3.5/3.5/3.5 | **3.50** | PRESENT ×3 | NOT_PICTURED | 3.67 |
| P2-011 | named destination read | 3.5/3.0/3.0 | **3.17** | PRESENT ×3 | 2.67 | 2.83 |
| P2-026 | Veilfall approach shallows | 2.5/2.5/2.5 | **2.50** | PRESENT ×3 | 2.75 | 3.00 |
| P2-066 | live current streaks | 2.0/2.5/2.5 | **2.33** | PRESENT ×3 (worse) | 2.67 | 2.50 |
| P2-116 | camp workbench identity | NOT_PICTURED ×3 | n/a | | NOT_PICTURED | 3.67 |

- **Overall Bar A:** set S 4.4/4.6/4.3 = **4.43**; anchor X 3.6/3.8/3.4 = **3.60**.
- **Bar B:** S yes/yes/no; X no ×3.
- **Bar:** no row reaches 7.5 (none reached 6.7 on CPU either). By the owner's rule, no Tidewake catalog row closes on this evidence.
- **P2-116:** the camp workbench isn't readable in the landscape frames. The CPU score came from the camps supplemental.

**Rows with no GPU evidence in this pass (33).** These rows' CPU scores came from supplemental tools that were not re-run on the GPU tonight, or they had no evidence on CPU either. Their CPU status stands as recorded, and `row-scores-gpu.json` lists each one's CPU evidence source.

- **Creatures (`phase2_capture_creatures --biome=water`):** P2-016, P2-028, P2-029, P2-030.
- **UI (`phase2_capture_ui --biome=water`):** P2-001, P2-002, P2-007, P2-031, P2-032.
- **Currents:** P2-067.
- **Swimming / mounted:** P2-071, P2-072, P2-108, P2-109.
- **Camps:** P2-115.
- **Venn fight:** P2-063, P2-088, P2-089, P2-090, P2-091, P2-101.
- **Pickups:** P2-045.
- **No evidence on CPU either (the CPU NOTE gives the reasons):** P2-060, P2-061, P2-069, P2-073, P2-074, P2-075, P2-103, P2-104, P2-113, P2-114, P2-119.

**Disposition (as measured):** the F39#0 recapture is delivered on GPU Medium, ≥200 frames (240), with no missing destination. The landscape rows are rescored on GPU. The supplemental rows still carry CPU-only evidence. Whether that closes F39#0 is the coordinator's call.

## Judges' asks (all three, set S)

1. **Currents and shallows (fixable in scene).**
   - P2-066 currents now read as road markings: dashed yellow edge lines with white chevrons, glowing at night. Seen in day_21, day_14, day_24 and night_21. The judges call this worse than the recorded defect.
   - The P2-026 Veilfall approach is still a ruler-straight chain of identical tan discs with foam rims.
2. **Named destinations (fixable in scene; a woven-reed hall may need new art).**
   - P2-011: these destinations are missing in frame: Reedhaven Woven Hall, Salt Crown shrine, Lantern Cove arch, Deep Watch lookout, Drowned Garden terraces.
   - Gull Rest is a small lattice box.
   - One blue banner-post kit is reused at four destinations.
3. **Night creatures render as flat, unlit white ghosts (fixable in scene; outside the rows).**
   - Seen on night_03, night_09, night_11 and night_16.
   - Also outside the rows:
     - The camera sits inside the trainer's hair at Aquaryn basin (day_09).
     - A floating NPC label at Gull Rest.
     - A pale-blue placeholder box at Shellwatch.
     - Grey smudge smoke.
4. **Shore (fixable in scene; close-up rock needs new art).**
   - P2-008 still has no wet-sand band, uses bubble-sprite foam and leaves bare sand walls (day_23, day_10).
   - P2-010 close views of Veilfall (day_15, day_16) show flat planes and stretched dark rock.

Sheet: `_sheet_f39_0_gpu_medium_heading0.png` (GPU Medium, heading-0 day frame for all 24 destinations).
