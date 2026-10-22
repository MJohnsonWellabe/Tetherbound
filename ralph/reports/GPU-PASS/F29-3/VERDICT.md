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
