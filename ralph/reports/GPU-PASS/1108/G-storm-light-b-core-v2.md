# G-storm-light-b and G-storm-core-v2

Frames: `tb/gpu-frames-1108`, High, live main 52a633598.
- **`G-storm-light-b`** (a54fa583): the arm is live plus `ITEM-STORM-LIGHT/overlay_fight_sight.json` at f0ef9c642 (`line_of_sight_fade` on).
- **`G-storm-core-v2`** (d2669bd6): the arm is live plus the blender-1109 assets, `stormheart_tree.gd`, `stormwood_glass_sink.gd`, `stormwood_world.gd` and two config files at cdb3cbe1b, plus `ITEM-STORM-CORE/overlay_heart_core.json` (`heart_core_1109` on).

Judged:
- **F41#3** (storm-light-b).
- **F41#1** (storm-core-v2).

Not judged:
- **F41#6:** its one frame (`capacitor_alpha-tell1-e-impact`) is the same image as an F41#3 frame.
- **F41#21:** not like-for-like; the fight camera frames it differently between runs.

Batch `G-slb`:
- Three code-blind judges and the standard prompt.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, slope 1.2625, intercept −1.0689, r 0.854, anchor RMSE 0.601. No warnings.

| Row | Arm | Live | Arm score | Gain | Judges preferring arm | Ship |
|---|---|---|---|---|---|---|
| F41#3 | storm-light-b (line-of-sight fade) | 6.21 (raw 5.3, 6.0, 6.0) | 6.21 (raw 5.3, 6.0, 6.0) | **0.00** | 0/3 (3 ties) | no |
| F41#1 | storm-core-v2 (heart core) | 5.75 (raw 5.4, 5.2, 5.6) | 5.62 (raw 5.5, 5.0, 5.4) | **−0.13** | 1/3 | no |

## F41#3: line-of-sight fade, no change in these frames
All three judges call the two sides "effectively identical" or "nearly the same". Sparkit is still jammed into Voltarach's forelegs in frames 1–2 on both sides, and Voltarach is over-bloomed gold (3/3).

The capture shows no canopy blocking on either side, so there is nothing for a line-of-sight fade to clear. These three F41#3 stands (i01, tell1-a, tell1-e) are not where the canopy problem shows.

The canopy-blocked frames the judges keep naming (i11–i15) are in the **f10_2_r3_capacitor anchor**, not in this row's capture. If the fade is meant to fix them, judge it on a capture that includes the interval frames i11–i16, and run several runs per side, since the fight is not deterministic.

## F41#1: heart core v2, flat to slightly worse
The recorded defect ("a dark cylindrical ring … rather than a giant living tree with a branching crown and visible core") is PARTIAL on both sides (3/3). The judges disagree on which side's core reads better:

| Judge | Read |
|---|---|
| a | the arm's purple and blue core crystal through the ceiling gap "reads slightly better" |
| b and c | the live side's pale crystal clusters behind the balcony "help slightly" |

No judge sees a branching crown on either side.

The judges' unchanged asks (3/3):
- A visible crown.
- A glowing core column.
- Volumetric lightning in place of the flat white strokes.
- Warmer lantern-lit wood.

They class these as new art.

**Verdict: neither arm ships.** Both are flat, with F41#1 at −0.13.

## Recurring (both sides, 3/3)
- Voltarach's gold over-bloom hides its form and face.
- The fight telegraphs are flat magenta rings.
- The Stormheart lightning is drawn as flat white strokes.
- The Meadows aftermath anchor and the craft anchor are consistent with earlier batches.

Glass-sink-lip had not landed when this batch started.
