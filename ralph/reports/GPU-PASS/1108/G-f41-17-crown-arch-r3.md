# G-f41-17-crown-arch-r3: Crown Arch r3 close-out, High and Medium (F41#17)

Frames: `tb/gpu-frames-1108`, one `crown_arch__day__close` frame per side.
- **Sections:** High (3a84ee01b) and Medium (b3343d8d6).
- **Live:** main with the Stormwood swing shipped.
- **Arm:** the r3 arch, with weathered stone, copper bands and straps, and a ragged flagstone landing in place of the square plinth.

## Pre-judge render check
The arm changes 7.8% of pixels at both presets, with luma within 0.6 levels. The GPU lane's eye check confirms the plinth is gone, the stone is weathered and the copper reads, and that there is no red on the arch.

## Judged
Batch `G-ca3`:
- Three code-blind judges and the standard prompt.
- Pairing: live vs arm at each preset, as separate sets.
- **Anchors:** craft, f10_2_r3_capacitor and **f36_0_npc:C1 (7.47 / 7.53)**. The top anchor is 7.53, so a 7.5 would not be extrapolated. This is a confirming batch.
- Fit: linear, slope 1.1577, intercept −0.2111, r 0.846, anchor RMSE 0.739. No warnings.

| Preset | Live | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| **High** | 6.27 (raw 5.6, 5.6, 5.6) | **6.77** (raw 6.1, 6.0, 6.0; mapped 6.85, 6.74, 6.74) | **+0.50** | **3/3** |
| **Medium** | 6.27 (raw 5.6, 5.6, 5.6) | **6.77** (raw 6.1, 6.0, 6.0; mapped 6.85, 6.74, 6.74) | **+0.50** | **3/3** |

The judges scored High and Medium identically. Defect calls on the arm: FIXED 2/3, PARTIAL 1/3. On live: PARTIAL 3/3.

## Verdict
- **SHIP the r3 arch.** It gains +0.50 with 3/3 on both presets.
- **F41#17 DOES NOT CLOSE.** The arm maps to 6.77 on both High and Medium, below 7.5, and is not extrapolated.
- **About the 7.23 in `G-stormwood-groves`:** this scene (swing + groves) mapped to 7.23 there under a steeper fit (slope 1.36) without the high anchor. Here, with anchors reaching 7.53, live maps to 6.27. The arm's real standing is about 6.8.

## What the judges saw
- **Fixed.** The square slab is gone. The rubble and flagstone ring "breaks the outline and grounds the ruin better", and no grass clipping is seen.
- **The stone still reads as toy-like.** All three call it "pastel lilac with toy-like speckles", "flat, evenly lit … close to plastic or untextured", "toy-like rather than weathered stone". The copper and the weathering do not register at this camera distance, and "the crystal glow does not light the stone" (it is a blown white sprite).
- **The black ground is formless.** The black glossy pool takes up the lower 40–50% of the frame with no form.
- **Possible oxblood leak: the saturated red tree trunks.** All three flag the large **crimson tree trunks** left and right of the arch as close to the reserved oxblood. This affects every Stormwood row and should go to the lane as a red-rule check.
- **The pink bears read as placeholder.** The bears in the midground look unlit or like stand-ins.

## Next swing to 7.5
All three judges name the same scene changes:
1. Stronger weathering on the arch: grey-blue storm stone with moss and grime, and copper or glass inlays that read at this camera distance. Let the crystal light the stone.
2. Moss and puddle breakup on the black ground in front of the arch.
3. Re-tint the crimson trunks toward dark bark or copper.
