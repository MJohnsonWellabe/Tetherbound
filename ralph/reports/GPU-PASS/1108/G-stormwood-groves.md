# G-stormwood-groves: layered groves around the four open Stormwood stands (F41#4, #5, #12, #17)

Frames: `tb/gpu-frames-1108` 356ed7fa0, High.
- **Base:** main plus the de-pinked swing (G-stormwood-swing-2-depink).
- **Arm:** base plus layered groves around the four open stands, so the comparison isolates the groves.
- **Controls:** the deepwood and struck_sentinel frames.
- **Manifest note:** the base side is labelled `base`; it was mapped to the live slot for pairing.

## Pre-judge render check
The groves are in frame and only where intended:

| Views | Pixels changed | Luma change |
|---|---|---|
| Open stands: crown_overlook, glass_field, crown_heartstone, crown_arch | 9–11% | −4 to −6 |
| Controls: lantern_hollow day and night, fallen_giant, lantern_pools, struck_sentinel | 0.4–1.2% | unchanged |

## Judged
Batch `G-grv`:
- Three code-blind judges and the standard prompt.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, slope 1.3635, intercept −1.2239, r 0.869, anchor RMSE 0.571. No warnings.

| Row | Base (swing) | Arm (swing + groves) | Gain | Judges preferring arm |
|---|---|---|---|---|
| **F41#17 Crown Arch** | 6.68 (raw 5.9, 5.9, 5.6) | **7.23** (raw 6.3, 6.3, 6.0) | **+0.55** | **3/3** |
| **F41#5 forest ground** | 5.78 (raw 5.1, 5.2, 5.1) | **6.28** (raw 5.6, 5.5, 5.4) | **+0.50** | **3/3** |
| F41#4 destinations | 6.23 (raw 5.4, 5.6, 5.4) | 6.50 (raw 5.6, 5.8, 5.6) | +0.27 | 3/3 |
| F41#12 charged road | 6.50 (raw 5.7, 5.6, 5.7) | 6.41 (raw 5.6, 5.6, 5.6) | −0.09 | 0/3 (1 tie) |

## Do the judges read the groves as a "tree wall"?
**No.** No judge uses "tree wall" or describes a continuous band of trunks on the arm side. All three credit the arm with depth:
- "A has layered tree silhouettes instead"
- "A keeps tree layers in depth"
- "A keeps more layered tree silhouettes against the purple sky, so distance reads better there"

The flat-horizon complaint is about the **base**:
- "flat navy cut-out band with a pale wall on the right"
- "flat lavender fog band with a hard white cliff block"
- "cardboard"

## Verdict
**SHIP (swing + groves together, as the coordinator set out).**
- F41#17 (+0.55) and F41#5 (+0.50) each clear the 0.5 bar with 3/3.
- F41#4 adds +0.27 with 3/3.
- F41#12 is flat (−0.09), which is expected: its stands sit at the deepwood and glass_field road views.

**Close-out candidate: F41#17 Crown Arch is now 7.23.** Under the 25 Oct close-out exception, it is worth a small push to 7.5. All three judges name the same remaining gaps:
1. **The plinth:** it reads as "a raised rubble pad over a bare dark plane" or "a rectangular rubble mat dropped onto featureless black mud". Sink it into mossy ground.
2. **The pink bears** behind the arch are off-palette salmon.
3. **The arch stone** is a uniform lavender-blue that "reads slightly plastic".

**Remaining Stormwood gaps all three name:**
- salmon-pink trunks, to be re-tinted toward copper or grey-brown bark;
- near-black flat mud, to be given value-varied wet moss;
- a flat magenta fight telegraph.
