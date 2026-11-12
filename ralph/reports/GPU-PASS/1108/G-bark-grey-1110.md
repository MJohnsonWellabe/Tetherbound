# G-bark-grey-1110: Stormwood trunks retinted cool grey-brown (F41#4, #5, #12, #17), High and Medium

Frames: `tb/gpu-frames-1108`, one frame per row per side.
- **Sections:** High (90c92faaf) and Medium (be8160ae1).
- **Frames:** fallen_giant, crown_heartstone, glass_field and crown_arch.
- **Live:** main plus Crown Arch r3 plus root finish.
- **Arm:** live plus grey bark (red-family trunks retinted cool grey-brown; foliage unchanged).

## Pre-judge render check
A hue change barely moves luma (0.1–3% of pixels change), so the colour shift was checked directly. The red-leading pixel share (R > G+25 and R > B+10) drops on every frame:

| Frame | High | Medium |
|---|---|---|
| crown_arch | 5.1% → 1.0% | 5.4% → 1.0% |
| fallen_giant | 13.5% → 3.5% | 13.7% → 3.6% |
| crown_heartstone | 8.4% → 1.2% | 8.7% → 1.2% |
| glass_field | 4.5% → 2.7% | 4.8% → 2.7% |

## Judged
Batch `G-bark`:
- Three code-blind judges and the standard prompt.
- 8 pairs: 4 rows × 2 presets.
- **Anchors:** craft, f10_2_r3_capacitor and **f36_0_npc:C1 (7.47 / 7.53)**. The top anchor is 7.53, so a 7.5 would not be extrapolated. This is a confirming batch.
- Fit: linear, slope 1.548, intercept −2.7966, r 0.919, anchor RMSE 0.545. No warnings.

| Row | Live | Arm (grey bark) | Gain | Judges preferring arm |
|---|---|---|---|---|
| **F41#17 Crown Arch** | 5.30 | **6.49** | **+1.19** | **3/3** |
| F41#4 destinations | 5.56 | 6.08 | +0.52 | 3/3 |
| F41#5 forest ground | 5.46 | 5.98 | +0.52 | 3/3 |
| F41#12 charged road | 5.77 | 6.08 | +0.31 | 3/3 |

High and Medium scored identically for every row (raw per judge are in `yardstick_g_bark/batch.json`). Nothing is above the top anchor.

## Verdict
- **SHIP the grey bark.** Every row gains, with 3/3 on both presets. Crown Arch gains +1.19.
- **F41#17 DOES NOT CLOSE.** The arm maps to 6.49 on both High and Medium, below 7.5.
- **Note on the live scores:** live Crown Arch maps 5.30 here, against 6.27 for the same r3 arch in `G-f41-17-crown-arch-r3`. This fit is steeper (slope 1.55 against 1.16), and the judges marked the crimson trunks down heavily against the grey alternative. Compare gains within a batch, not absolute scores across batches.

## Does any red-family read remain?
- **Trunks: no, with grey bark.** All three judges independently ranked the bark variants:
  - grey-lavender is best everywhere;
  - salmon-pink live trunks read as "candy floss" and are off-palette;
  - the crimson live trunks behind the arch are "oxblood leaking onto scenery … the worst palette problem in this batch".
- **The glass_field red banner remains.** All three flag "a saturated red banner upper-left" in the glass_field frame on both sides, which is acceptable only if it marks Team Tether ground. It is the same red flag noted in swing-2. **The lane should confirm it is a Team Tether element or recolour it.**
- **The bears are pink, not red.** All three call the bears pink, salmon or pink-cream, not oxblood. With pink trunks they blended into the trees; with grey bark they stand apart. Two judges still call them placeholder-looking ("untextured stand-ins").

## Next swing to 7.5
All three judges name the same changes:
1. Break the flat black mud and grass carpet into groves, banks and black pools, and add layered fog and a dark distant forest band, replacing the flat lilac backdrop.
2. Crown Arch: increase its scale against the 1.80 m trainer, and sink the paving apron into moss rather than an exposed disc.
3. Glass field and charged road: replace the busy collage pylon texture.
