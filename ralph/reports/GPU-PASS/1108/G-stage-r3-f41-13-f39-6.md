# G-stage-r3-f41-13-f39-6: the round 3 creature stage on F41#13 and F39#6 (GPU High, no new capture)

Frames: the round 3 stage pairs from `tb/gpu-frames-1108` 34865ea78 (section G-floor2-creature-ruler-depth-r3), High, seed 2042.
- base = `tb/floor2` aac9c84a3 with `creature_ruler_depth` off.
- arm = base + `FLOOR2-STAGE/overlay_ruler_depth.json`, the landing version in `G-floor2-creature-ruler-depth-r3.md`.
- Render check and blank check as in that report.

Sets, each stacked at full size:
- **F41#13**, electric creature finish, with its catalogue defect: fulgocobra idle above stormraven idle. The sides are as in `G-rescore-f39-21-f41-13.md`.
- **F39#6**, creature faint state, with its catalogue defect ("Several fainted aquatic creatures keep raised alert heads or upright crouches instead of reading as defeated"): aquaryn idle, resting and fainted.

Batch `G-x13`:
- three code-blind judges, standard prompt;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22 (the Stormwood fight anchor f10_2 was left out), so this is a confirming batch.

Fit: linear, slope 1.3027, intercept −1.356, r 0.960, anchor RMSE 0.278. No warnings.

## Verdict: the stage alone lifts both rows, 3/3 on each

| Row | Base | Arm (stage) | Gain | Judges preferring arm | Board |
|---|---|---|---|---|---|
| **F41#13** electric creature finish | 5.64 | **6.46** | **+0.82** | 3/3 | 5.14 |
| **F39#6** creature faint state (aquaryn) | 6.03 | **7.24** | **+1.21** | 3/3 | — |

Raw Bar A, base → arm (judges a, b, c):
- F41#13: 5.1, 5.6, 5.4 → 5.8, 6.2, 6.0.
- F39#6: 5.3, 6.2, 5.5 → 6.3, 7.1, 6.4.

Recorded defect:
- **F41#13:** base PARTIAL 3/3; arm FIXED 3/3.
- **F39#6:** base PARTIAL 3/3; arm FIXED 3/3. No judge sees a raised alert head on either side.

**F41#13 rises above 6 (6.46)** with the stage, at no extra cost if it lands with #901. That lifts it off the below-6 list. The charge-lines approach stays parked (`G-newapproach-charge-lines-r2.md`).

**F39#6 at 7.24** is near the bar. It counts under the close-out exception for a near-bar change.

## Caveats: the gain is staging, not a fix to the subject
**F41#13: most of the gain is that the creatures are now near and large.**
- **Fulgocobra reads well up close:** hood, glowing eye, blue edge lines.
- **The stormraven is worse in kind, not better.** At close range the whole bird blooms to "a near-white ghost", losing its feather detail (3/3). That breaks the owner's one-elemental-trait rule.
- **The cobra's bands** bloom into "white-hot spots" or read as amber "light bulbs" (3/3).
- **Palette drift from the roster board (judge a):** Fulgocobra should be olive and black with gold veins (the game shows navy); Stormraven should be black with blue arcs (the game shows white).
- The F41#13 base here (5.64) is close to the 8 Nov board 5.14 and to `G-rescore-f39-21-f41-13.md` (5.00), allowing for scale scatter.

**F39#6: the pose problem remains.**
- **What got better:** the stage makes aquaryn large, grounded and readable, and the head lies down in the fainted frame.
- **What remains (3/3):**
  - the fainted pose has stiff legs up in the air ("dead bug", "toppled toy or statue");
  - the body looks slightly lifted off the sand;
  - resting and fainted are nearly the same pose, so resting does not read as its own state.
- This is the pose-float issue the round 3 judges named. The stage does not move it.

## What would add the most
1. **Electric emission, F41#13 (scene):**
   - cap it to thin veins or lines and the eyes, with no full-body bloom;
   - move the stormraven to a black body with blue arcs and the cobra's bands from amber to white-violet, or the board's gold veins on olive.
   - All three judges name this first or second.
2. **Water-creature poses, F39#6 (scene):**
   - a grounded side-lying faint with folded, relaxed limbs and full body contact;
   - a distinct curled resting pose.
