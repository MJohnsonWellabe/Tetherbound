# GPU pass: F29#3 Stormursa storm bear: REOPENED (GPU 3.57; broken faint end on GPU frames)

22 Oct 2026, ~02:30 CT. Remote GPU lane (owner's Windows desktop).

- **Renderer:** Forward+ on Vulkan, NVIDIA GeForce GTX 1060 3GB, 1280x720.
- **Preset:** Medium and High set in the device override file. This stage tool builds its own `WorldEnvironment` and doesn't call the preset API, so Medium and High render alike; all three judges saw them as identical.
- **Source:** origin/main 9db3d2146, unmodified.
- **Command:** `godot --path . --rendering-method forward_plus --rendering-driver vulkan --resolution 1280x720 --script res://tools/art_pipeline/capture_f36_poses.gd -- --species=stormursa,staticub --candidate --whole-body --context --out=<dir>`. This is the CPU r8 command line. `--candidate` plays the `f36_candidate/*` recipe clips; stormursa is in `enabled_species`, so these are the shipped poses. Exit 0, 40 frames.
- **First run:** without `--candidate`, it played the raw installed clips (no recipe). That run was discarded and isn't judged.

## Judging

Three fresh code-blind judges scored one batch on one scale:
- **Anchor:** the committed CPU sheet `CREATURES/close-1020/_sheet-f29-3-r8.png`. Variant A is the r7 control and Variant B is r8, the shipping version (CPU judges 6.73). The key was withheld.
- **GPU sheet:** rows C (Medium) and D (High), the same columns as r8 plus the cub.

Judges saw only the sheets, frames, `docs/reference` boards and ART_DIRECTION (`judge_prompt.md`; scores in `f29_3_gpu_key.json`).

| Set | Bar A j1/j2/j3 | Mean | Bar B mean | Hit | Faint | Scale |
|---|---|---|---|---|---|---|
| Anchor A, CPU r7 control | 4.4/4.6/4.0 | 4.33 | 3.43 | WEAK ×3 | PASS ×3 | PASS ×3 |
| **Anchor B, CPU r8, shipping** (CPU judges 6.73) | 4.9/5.0/4.6 | **4.83** | 3.80 | WEAK ×3 | PASS ×3 | PASS ×3 |
| **GPU Medium** | 3.4/3.9/3.4 | **3.57** | 2.93 | WEAK ×3 | **FAIL ×3** | PASS ×3 |
| **GPU High** | 3.4/3.9/3.4 | **3.57** | 2.93 | WEAK ×3 | **FAIL ×3** | PASS ×3 |

**Bar A on GPU is 3.57, below 7.5: REOPENED.** On one scale, the GPU frames score 1.26 *below* the CPU r8 frames. That is the only row in this pass where GPU scores under CPU, and the faint end causes it.

## Finding: broken faint end on the GPU frames

`stormursa-faint-100` (GPU Medium and High; left in the sheet's "faint end" column) shows grey, untextured, stretched mesh slabs:
- a large flap at the hind leg next to the ruler;
- shards under the belly and forepaws.

The torso stays raised with the head up, so the bear never reaches the ground. All three judges call it a blocking defect.

The CPU r8 sheet, captured at an earlier commit with the same command, shows the same bear lying grounded on its side. The cause was not investigated in this pass: no code was inspected or changed. A later F36#1 pose change (the `settle_descent` work noted in `CREATURES/close-1020/note.md` RESUME) is one candidate for whoever owns the recipe.

The cub's faint end (`staticub-faint-100`) reads as a grounded collapse with a small grey sliver at the muzzle.

## Judges' asks (all three)

1. **Faint end (fixable in scene).** Restore a grounded side-lying faint and remove the torn geometry; the judges estimated about +1.0. Faint mid currently reads like the hit lunge.
2. **Hit (fixable in scene).** Hit react is a small head dip and hit recover equals standing. The judges asked for a recoil, head snap, stagger and a vein flash at impact (about +0.5).
3. **Identity and growth.**
   - Measured against the ruler, the cub stands about 3.3–3.4 m and the adult about 4.5 m. The adult reads only about 1.3× the cub. The judges asked to grow the adult, never shrink the cub (fixable in scene).
   - The adult is a realistic grizzly with lightning decals. It needs a readable face and eyes from the cub concept plus copper and glass Stormwood accents (needs new art).
   - On the anchor, Variant A's red-maroon fur drifts toward oxblood. Variant B's brown, which ships, and the GPU colour both avoid it.

Sheet: `_sheet_f29_3_gpu.png` (M = Medium, H = High).

## Re-check after #705 (22 Oct, ~09:30 CT): faint fixed, GPU = CPU r8, still REOPENED

- **Source:** `tb/gpu-pass` edf1435d1, a merge of origin/main 320eb47bf. That includes b8691f02c, "Stormursa faint: back to the judged side-on topple; enabled hurt/faint poses may not tear the mesh".
- **Re-import, then capture:** same command, renderer and presets as above (`--candidate`, Forward+, Medium and High, 1280x720). Exit 0, 40 frames each.
- **Judging:** three fresh code-blind judges, the same r8 anchor in the same batch, and the same prompt plus a creature-model score for the GPU rows (`judge_prompt_r2.md`, `f29_3_gpu_r2_key.json`).

| Set | Bar A j1/j2/j3 | Mean | Hit | Faint | Creature (model) |
|---|---|---|---|---|---|
| Anchor A, CPU r7 | 4.0/4.4/4.2 | 4.20 | WEAK ×3 | PASS ×3 | |
| Anchor B, CPU r8 (CPU judges 6.73) | 4.4/5.0/4.5 | **4.63** | WEAK ×3 | PASS ×3 | |
| **GPU Medium** | 4.4/4.9/4.6 | **4.63** | WEAK ×3 | **PASS ×3** | 4.3/4.8/4.5 = 4.53 |
| **GPU High** | 4.4/4.9/4.6 | **4.63** | WEAK ×3 | **PASS ×3** | 4.3/4.8/4.5 = 4.53 |

**The torn-geometry finding is resolved.** All three judges now see `stormursa-faint-100` as the same grounded side-on collapse as the r8 anchor, with no grey slabs. On one scale the GPU now equals the CPU r8 frames.

**Bar A 4.63, below 7.5: still REOPENED.**

Remaining asks (all three judges):
- **Hit, fixable in scene:** hit react is a crouch and head-dip with no recoil, hitstop or flash, and hit recover equals standing.
- **Faint mid, fixable in scene:** it reads as a lunge, not a buckle.
- **Growth, fixable in scene:** the cub is about 3.4–3.5 m against the adult's 4.5 m (only about 1.3×).
- **Cub faint end, fixable in scene:** `staticub-faint-100` is a contorted lump with a leg touching the ruler (two judges).
- **Faint end texture:** a pale stretched streak on the belly and muzzle (one judge; UVs or texture).
- **Model, needs new art:** a stylised face with readable blue eyes from the cub concept, plus copper and glass Stormwood accents.

The cub's colour now matches the adult's brown (an improvement noted by two judges). Sheet: `_sheet_f29_3_gpu_r2.png`.

## Yardstick rejudge (22 Oct, ~11:15 CT): mapped 7.00, REOPENED (0.5 short)

This rejudge ran in the same yardstick batch as F04#6 (see `../F04-6/yardstick/`, copied to `yardstick/`). The candidate was the post-#705 GPU frames, Medium (A or B) vs High, as a single set. Calibration: linear slope 0.635, RMSE 0.576, top anchor 7.53 (a confirming batch), no warnings.

**F29#3 mapped 7.00** (judges 7.21/6.90/6.90; Medium and High identical; `above_top_anchor` false), **below 7.5: REOPENED.**

The judges' asks:
- The cub reads as nearly the same model and size as the adult, so the evolution step doesn't read.
- The face and eyes are lost at small size.
- The veins read as neon decals on a near-realistic bear rather than Palworld-style chunky design.

The poses read and stay grounded (faint PASS after #705).
