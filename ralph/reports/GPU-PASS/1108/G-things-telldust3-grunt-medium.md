# G-things-telldust3-grunt-medium: F38#3 closer at Medium, with F38#11 no-loss (GPU Medium, base vs arm)

## Verdict: F38#3 Medium does NOT meet the bar. The arm passes the ship rule through F38#11.

| Set | Base (telldust r1) | Arm (TELLDUST3) | Gain | Prefer arm | Raw a / b / c (base → arm) | Defect, both sides |
|---|---|---|---|---|---|---|
| **F38#3 Medium** (grunt 01/02/03) | 7.24 | **7.28** | +0.04 | 1/3 (2 ties) | 6.6=6.6, 6.2→6.3, 6.8=6.8 | PARTIAL 3/3 |
| **F38#11 Medium** (grunt t01-stand-mid, 02, 03) | 6.55 | **7.06** | **+0.51** | 3/3 | 6.1→6.5, 5.6→6.0, 6.3→6.7 | PARTIAL 3/3 |
| Control F38#38 (High \| Medium) | 8.01 | 8.01 | n/a | n/a | 7.0, 7.1, 7.3 | FIXED 3/3 |

All scores are mapped.
- **Panel strictness:** the control reads 8.01 against its closing 8.16 and 8.30, so the panel is about 0.2 strict, about the same as the earlier closing batches.
- **F38#3 Medium is 0.22 short.** Last round's 7.47 Medium was a different batch. This round's base side, telldust r1 as on main, reads 7.24.
- **Not closed:** F38#3 stays open whatever the grunt High pair shows.
- **No set loses.** F38#11 gains +0.51 at 3/3 and F38#3 is level, so the arm ships as the tell arm.

## What the judges see
- **F38#11 (3/3):**
  - Base: the tell is "a shapeless smoke loop that veils the creatures" and crosses the boar's snout and Terrapup's face.
  - Arm: the tell is "a crisp wedge with concentric arcs from the tusks", directional and readable at a glance.
  - Still there on both sides: the tell is a drawn overlay rather than physical dust or stone, and the "! incoming — move" banner carries the warning. On hit there is only a tiny amber disc and white spark, with no debris and no recoil pose on the boar.
  - Judge c: in frame 3 the arm's arcs cross the trainer.
- **F38#3 (3/3):**
  - The ally no longer fills half the view, scale is correct, and nothing clips.
  - The opposing Tether trainer is still a small dark figure half-hidden behind the boar (Mudsnout) in all three frames.
  - Judge c: the player trainer is pressed against Terrapup's muzzle.
  - The grade is a flat olive overcast with no rim light on the creatures, and the grass is a uniform carpet.
- **Flags for LANE-SCENE (judge a):**
  - Terrapup's HUD element reads "WIND" on a stone-plated dog. Check that the element label is right.
  - A bright red-orange marker and crate in the bottom-right corner under the HUD is a red leak on a non-enemy prop.

## Frames and batch
- Section: `tb/gpu-frames-1113` e363003f8. Medium; cameras matched at 0.00 m. Per-frame mean pixel difference is 1.0–3.4.
- Not judged: the 99-after frame (difference 23.5).
- Control: `gpu-frames-1108/F38-38/live` on the same branch.
- Batch `yardstick_g_telldust3_medium/`:
  - Anchors: craft, f36_0_npc:C1, f04_6_r22.
  - Fit: linear, slope 1.291, intercept −1.199, r 0.972, anchor RMSE 0.24.
  - The control is above the top anchor (7.53) and extrapolated; this is the confirming batch.

## Next asks (LANE-SCENE)
1. **F38#3: move the opposing trainer clear of the wild creature's silhouette** (south bridge grunt: the Tether trainer stands behind the boar in every frame), and give the player trainer a minimum gap from the ally's muzzle. That is the remaining half of the F38#3 defect. Scene.
2. **Fight grade:** a warm key light, rim light on the creatures, and grass broken into clumps, instead of the flat olive overcast. It is the top ask from 3/3 judges, and it is the most likely way to lift F38#3 past 7.5 at Medium. Scene.
3. **F38#11:** keep the TELLDUST3 wedge. Add a physical dirt or stone burst and a short recoil pose on hit, and make the text banner a secondary cue. Scene.
4. **Judge the grunt High pair** when it lands. A High read alone cannot close F38#3, because Medium is under the bar.
